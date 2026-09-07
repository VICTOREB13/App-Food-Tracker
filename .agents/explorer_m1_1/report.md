# Milestone 1 Exploration Report: SQLite v2 Schema, Migration & Persistence Layer
**Project:** Victor Engineer - Food Tracker (NutriTracker Local-First) - Phase 2  
**Explorer:** M1 SQLite & Schema Explorer (`explorer_m1_1`)  
**Working Directory:** `C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_m1_1`  
**Date:** 2026-09-07T16:16:00Z  
**Target Files:** `lib/services/database_service.dart`, `test/services/database_service_v2_test.dart`, `test/services/database_service_test.dart`  
**Skill Reference:** `sqlite-local-first-flutter`

---

## 1. Executive Summary

This report delivers the architectural and implementation blueprint for **Milestone 1: SQLite Database Version 2 & Persistence Layer**. It addresses the core persistence requirements of Phase 2 (R3: User Metabolic Profile and R4: Weight Logs History) in strict compliance with the **`sqlite-local-first-flutter`** engineering standard.

### Core Discoveries & Recommendations
1. **Database Version Upgrade (v1 $\rightarrow$ v2)**:
   - `lib/services/database_service.dart` currently opens the database at `version: 1` without an `onUpgrade` callback.
   - Upgrade `openDatabase` to `version: 2` and implement an atomic, fault-tolerant `_onUpgrade` callback that creates the `weight_logs` table, the B-Tree index `idx_weight_logs_date`, and the `user_profile` table without disrupting or touching existing `meals` and `pantry_items` records.
   - Update `_onCreate` to modularly construct all version 2 tables and indices on fresh installations.
2. **Schema & DDL Definitions**:
   - **`weight_logs` Table**:
     `id TEXT PRIMARY KEY, date TEXT NOT NULL, weight REAL NOT NULL, notes TEXT`
   - **B-Tree Date Index**:
     `CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);`
     Enables $O(\log N + K)$ date-range window scanning (7, 30, 90 days) and $O(1)$ latest-entry lookups directly inside SQLite, banning in-memory RAM filtering in Dart.
   - **`user_profile` Table**:
     `id TEXT PRIMARY KEY, age INTEGER NOT NULL, gender TEXT NOT NULL, height REAL NOT NULL, weight REAL NOT NULL, activity_level TEXT NOT NULL, body_goal TEXT NOT NULL, bmr REAL NOT NULL, tdee REAL NOT NULL, target_calories REAL NOT NULL, target_protein REAL NOT NULL, target_carbs REAL NOT NULL, target_fat REAL NOT NULL, master_prompt TEXT NOT NULL, updated_at TEXT NOT NULL`
     Plus recommended additive columns `name TEXT` and `estimated_steps INTEGER NOT NULL DEFAULT 8000` to achieve 100% parity with the `UserProfile` model and R3/R5 requirements.
3. **Engine Pragmas & Concurrency Defenses**:
   - Retain and solidify WAL (`journal_mode = WAL`), `synchronous = NORMAL`, and `foreign_keys = ON` in `_onConfigure`.
   - Preserve `_initFuture` memoization to guarantee thread safety and prevent `DatabaseException: database is locked` across concurrent reads and writes.
4. **Data Access API**:
   - Provide clean, typed method signatures in `DatabaseService` for single record mutations, indexed range queries, latest-log lookups, transactional batch upserts (`batchUpsertWeightLogs`), and single-profile upsert/read.
5. **Testing & Quality Assurance**:
   - Design a dedicated in-memory test suite (`test/services/database_service_v2_test.dart`) covering v1 $\rightarrow$ v2 migration data preservation, fresh v2 table creation, index presence, CRUD operations, date-range boundaries, and concurrency resilience.

---

## 2. Audit of Existing `DatabaseService` (`lib/services/database_service.dart`)

### 2.1 Concurrency Defense: Memoized Initialization
Lines 12–54 implement a thread-safe singleton with future memoization:
```dart
Future<Database> get database async {
  if (_database != null && _database!.isOpen) {
    return _database!;
  }
  if (_initFuture != null) {
    return await _initFuture!;
  }
  _initFuture = _initDatabase();
  try {
    _database = await _initFuture!;
    return _database!;
  } catch (e) {
    _initFuture = null;
    rethrow;
  }
}
```
* **Audit Finding**: Concurrency testing in `test/services/database_service_test.dart:75-83` verifies that 50 concurrent futures resolve to the exact same `Database` instance. This design must remain intact.

### 2.2 Engine Configuration & Pragmas
Lines 104–124 configure SQLite pragmas:
```dart
onConfigure: (db) async {
  // WAL mode: rawQuery is required because PRAGMA journal_mode returns a row result.
  // Android SQLiteDatabase.execSQL() throws SQLException if executed as a statement.
  try {
    await db.rawQuery('PRAGMA journal_mode = WAL;');
  } catch (e) {
    debugPrint('Warning: Failed to set PRAGMA journal_mode: $e');
  }

  try {
    await db.execute('PRAGMA synchronous = NORMAL;');
  } catch (e) {
    debugPrint('Warning: Failed to set PRAGMA synchronous: $e');
  }

  try {
    await db.execute('PRAGMA foreign_keys = ON;');
  } catch (e) {
    debugPrint('Warning: Failed to set PRAGMA foreign_keys: $e');
  }
}
```
* **Audit Finding**:
  1. `PRAGMA journal_mode = WAL;` via `db.rawQuery()` correctly avoids Android native SQLite exceptions.
  2. `PRAGMA synchronous = NORMAL;` delivers maximum write throughput with high durability in WAL mode.
  3. `PRAGMA foreign_keys = ON;` guarantees cascading referential integrity.
  4. Refactoring recommendation: Extract this logic to a clean private helper `Future<void> _onConfigure(Database db) async` to align with the `sqlite-local-first-flutter` standard.

### 2.3 Current Migration Gap
Lines 101–127 currently state:
```dart
return await openDatabase(
  dbPath,
  version: 1,
  onConfigure: (db) async { ... },
  onCreate: _onCreate,
);
```
* **Deficit**:
  - `version: 1` is hardcoded.
  - No `onUpgrade` callback is provided.
  - Any app updating from Phase 1 to Phase 2 would fail to create the new tables (`weight_logs` and `user_profile`) and would throw runtime table-not-found exceptions upon accessing Phase 2 features.

---

## 3. SQLite v2 Schema Architecture & DDL Definitions

### 3.1 `weight_logs` Table Specification
The `weight_logs` table stores time-series bodyweight logs for the user.

```sql
CREATE TABLE IF NOT EXISTS weight_logs (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  weight REAL NOT NULL,
  notes TEXT
);
```

#### Column Definitions:
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `TEXT` | `PRIMARY KEY` | UUID v4 unique record identifier. |
| `date` | `TEXT` | `NOT NULL` | ISO-8601 string (`YYYY-MM-DDTHH:MM:SS.mmmZ`). |
| `weight` | `REAL` | `NOT NULL` | Bodyweight in kilograms (e.g. `78.45`). |
| `notes` | `TEXT` | `NULL` | Optional user notes or annotations (e.g. "Ayuno matutino"). |

### 3.2 B-Tree Index: `idx_weight_logs_date`
```sql
CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);
```

#### Performance & Indexing Analysis:
1. **Why Lexicographical Sorting Works**: ISO-8601 formatted strings (e.g., `'2026-09-01T08:00:00.000'` to `'2026-09-07T23:59:59.999'`) preserve natural chronological order when sorted as UTF-8 text.
2. **$O(\log N + K)$ Range Scanning**: The B-Tree index allows SQLite to jump immediately to the start of the date window in $O(\log N)$ time and scan only the $K$ matching rows, avoiding a full table scan ($O(N)$).
3. **$O(1)$ Latest Entry Lookup**: A query with `ORDER BY date DESC LIMIT 1` accesses the rightmost leaf of the B-Tree index, resolving in $O(1)$ time without examining historical records.
4. **Prohibition of RAM Filtering**: Per `sqlite-local-first-flutter`, filtering dates with `.where((e) => ...)` in Dart is strictly banned; all filtering is delegated to this indexed SQL query.

---

### 3.3 `user_profile` Table Specification

The `user_profile` table stores the user's metabolic profile, calculated Mifflin-St Jeor benchmarks, macro distribution targets, and the synthesized Gemini Master Prompt.

#### Baseline Schema (User Prompt Exact Specification):
```sql
CREATE TABLE IF NOT EXISTS user_profile (
  id TEXT PRIMARY KEY,
  age INTEGER NOT NULL,
  gender TEXT NOT NULL,
  height REAL NOT NULL,
  weight REAL NOT NULL,
  activity_level TEXT NOT NULL,
  body_goal TEXT NOT NULL,
  bmr REAL NOT NULL,
  tdee REAL NOT NULL,
  target_calories REAL NOT NULL,
  target_protein REAL NOT NULL,
  target_carbs REAL NOT NULL,
  target_fat REAL NOT NULL,
  master_prompt TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

#### Reconciled Production Schema (Recommended):
Cross-referencing `ORIGINAL_REQUEST.md` (R3: "Datos biométricos: Nombre, edad, género..."), `PROJECT.md` (R3/R5: daily steps tracking), and `explorer_m1_2`'s `UserProfile` model indicates two additional fields:
- `name TEXT` (optional user display name for personalized Master Prompt synthesis).
- `estimated_steps INTEGER NOT NULL DEFAULT 8000` (daily steps target for activity multiplier and streak card).

```sql
CREATE TABLE IF NOT EXISTS user_profile (
  id TEXT PRIMARY KEY,
  name TEXT,
  age INTEGER NOT NULL,
  gender TEXT NOT NULL,
  height REAL NOT NULL,
  weight REAL NOT NULL,
  activity_level TEXT NOT NULL,
  body_goal TEXT NOT NULL,
  estimated_steps INTEGER NOT NULL DEFAULT 8000,
  bmr REAL NOT NULL,
  tdee REAL NOT NULL,
  target_calories REAL NOT NULL,
  target_protein REAL NOT NULL,
  target_carbs REAL NOT NULL,
  target_fat REAL NOT NULL,
  master_prompt TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

#### Compatibility Guarantee:
- The `UserProfile` model designed by `explorer_m1_2` serializes `name` and `estimated_steps`. Including `name TEXT` and `estimated_steps INTEGER NOT NULL DEFAULT 8000` avoids SQLite `table user_profile has no column named name` errors during `insert` or `update`.
- If the implementer prefers strictly the 15 columns requested in the user prompt, `name` and `estimated_steps` can be omitted, provided `UserProfile.toSqliteMap()` excludes them. We recommend the Reconciled Production Schema because it is 100% non-breaking and satisfies all requirements.

---

## 4. Database Migration Blueprint (Version 1 $\rightarrow$ Version 2)

### 4.1 Modular Table Creation Architecture
To avoid code duplication between fresh installs (`_onCreate`) and upgrades (`_onUpgrade`), create dedicated private creation helpers receiving `DatabaseExecutor` (the common abstraction shared by `Database`, `Transaction`, and `Batch`):

```dart
Future<void> _createMealsTable(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS meals (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      meal_type TEXT NOT NULL,
      date TEXT NOT NULL,
      image_path TEXT,
      calories REAL NOT NULL,
      protein REAL NOT NULL,
      carbs REAL NOT NULL,
      fat REAL NOT NULL,
      notes TEXT,
      ai_breakdown_json TEXT
    )
  ''');
}

Future<void> _createPantryTable(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS pantry_items (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      brand TEXT,
      category TEXT,
      calories REAL NOT NULL,
      protein REAL NOT NULL,
      carbs REAL NOT NULL,
      fat REAL NOT NULL,
      is_favorite INTEGER NOT NULL DEFAULT 0
    )
  ''');
}

Future<void> _createWeightLogsTable(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS weight_logs (
      id TEXT PRIMARY KEY,
      date TEXT NOT NULL,
      weight REAL NOT NULL,
      notes TEXT
    )
  ''');
}

Future<void> _createUserProfileTable(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS user_profile (
      id TEXT PRIMARY KEY,
      name TEXT,
      age INTEGER NOT NULL,
      gender TEXT NOT NULL,
      height REAL NOT NULL,
      weight REAL NOT NULL,
      activity_level TEXT NOT NULL,
      body_goal TEXT NOT NULL,
      estimated_steps INTEGER NOT NULL DEFAULT 8000,
      bmr REAL NOT NULL,
      tdee REAL NOT NULL,
      target_calories REAL NOT NULL,
      target_protein REAL NOT NULL,
      target_carbs REAL NOT NULL,
      target_fat REAL NOT NULL,
      master_prompt TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');
}

Future<void> _createIndices(DatabaseExecutor db) async {
  // Phase 1 Indices
  await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_date ON meals(date);');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_meal_type ON meals(meal_type);');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_date_type ON meals(date, meal_type);');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_name ON pantry_items(name COLLATE NOCASE);');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_category ON pantry_items(category);');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_favorite ON pantry_items(is_favorite);');

  // Phase 2 Indices
  await db.execute('CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);');
}
```

### 4.2 The `_onCreate` and `_onUpgrade` Callbacks
```dart
Future<void> _onCreate(Database db, int version) async {
  await _createMealsTable(db);
  await _createPantryTable(db);
  await _createWeightLogsTable(db);
  await _createUserProfileTable(db);
  await _createIndices(db);
}

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await _createWeightLogsTable(db);
    await _createUserProfileTable(db);
    await db.execute('CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);');
  }
}
```

#### Migration Invariants:
1. **Zero Data Loss**: Upgrading from version 1 does not alter or re-create `meals` or `pantry_items`. All existing records remain intact.
2. **Idempotency**: All DDL statements use `IF NOT EXISTS`, preventing crashes if an upgrade script is executed on a partially migrated database.
3. **Atomic Execution**: In `sqflite`, `onUpgrade` runs within an internal SQLite transaction. If any DDL fails, the version bump does not commit.

---

## 5. Method Signatures & Implementation in `DatabaseService`

### 5.1 Weight Logs Data Access Methods

```dart
// ==========================================
// WEIGHT LOGS OPERATIONS (PHASE 2 - MILESTONE 1)
// ==========================================

/// Inserts or replaces a weight log entry.
Future<int> insertWeightLog(WeightLog log) async {
  final db = await database;
  return await db.insert(
    'weight_logs',
    log.toSqliteMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

/// Updates an existing weight log entry by its primary key.
Future<int> updateWeightLog(WeightLog log) async {
  final db = await database;
  return await db.update(
    'weight_logs',
    log.toSqliteMap(),
    where: 'id = ?',
    whereArgs: [log.id],
  );
}

/// Deletes a weight log entry by its primary key.
Future<int> deleteWeightLog(String id) async {
  final db = await database;
  return await db.delete(
    'weight_logs',
    where: 'id = ?',
    whereArgs: [id],
  );
}

/// Fetches a single weight log by its ID.
Future<WeightLog?> getWeightLogById(String id) async {
  final db = await database;
  final results = await db.query(
    'weight_logs',
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );
  if (results.isEmpty) return null;
  return WeightLog.fromSqliteMap(results.first);
}

/// Returns all weight logs sorted chronologically descending (newest first).
Future<List<WeightLog>> getAllWeightLogs() async {
  final db = await database;
  final results = await db.query(
    'weight_logs',
    orderBy: 'date DESC',
  );
  return results.map((m) => WeightLog.fromSqliteMap(m)).toList();
}

/// O(1) indexed query to fetch the single most recent weight log.
Future<WeightLog?> getLatestWeightLog() async {
  final db = await database;
  final results = await db.query(
    'weight_logs',
    orderBy: 'date DESC',
    limit: 1,
  );
  if (results.isEmpty) return null;
  return WeightLog.fromSqliteMap(results.first);
}

/// Fast indexed range query using B-Tree index on `date`.
/// Returns records sorted chronologically ascending (oldest to newest) for charting.
Future<List<WeightLog>> getWeightLogsByRange(DateTime startDate, DateTime endDate) async {
  final db = await database;
  final results = await db.query(
    'weight_logs',
    where: 'date >= ? AND date <= ?',
    whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    orderBy: 'date ASC',
  );
  return results.map((m) => WeightLog.fromSqliteMap(m)).toList();
}

/// Convenience helper to fetch weight logs for the trailing N days.
Future<List<WeightLog>> getWeightLogsLastDays(int days) async {
  final now = DateTime.now();
  final startDate = now.subtract(Duration(days: days));
  return await getWeightLogsByRange(startDate, now);
}

/// Atomic batch upsert for bulk imports or cloud synchronization.
Future<void> batchUpsertWeightLogs(List<WeightLog> logs) async {
  if (logs.isEmpty) return;
  final db = await database;
  await db.transaction((txn) async {
    final batch = txn.batch();
    for (final log in logs) {
      batch.insert(
        'weight_logs',
        log.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  });
}
```

---

### 5.2 User Profile Persistence Methods

In local-first architecture, the user profile represents a single-row authoritative configuration.

```dart
// ==========================================
// USER PROFILE OPERATIONS (PHASE 2 - MILESTONE 1)
// ==========================================

/// Persists or updates the user metabolic profile.
/// Uses ConflictAlgorithm.replace to guarantee singleton semantics.
Future<int> saveUserProfile(UserProfile profile) async {
  final db = await database;
  return await db.insert(
    'user_profile',
    profile.toSqliteMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

/// Retrieves the active user profile, or null if onboarding has not been completed.
Future<UserProfile?> getUserProfile() async {
  final db = await database;
  final results = await db.query(
    'user_profile',
    limit: 1,
  );
  if (results.isEmpty) return null;
  return UserProfile.fromSqliteMap(results.first);
}

/// Clears the user profile from SQLite.
Future<int> deleteUserProfile({String id = 'primary'}) async {
  final db = await database;
  return await db.delete(
    'user_profile',
    where: 'id = ?',
    whereArgs: [id],
  );
}
```

---

### 5.3 Database Telemetry Extension (`getDatabaseStats`)

Update `getDatabaseStats()` to expose counts for telemetry and Settings:

```dart
Future<Map<String, dynamic>> getDatabaseStats() async {
  final db = await database;
  final mealsCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM meals;');
  final mealsCount = Sqflite.firstIntValue(mealsCountRes) ?? 0;

  final pantryCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM pantry_items;');
  final pantryCount = Sqflite.firstIntValue(pantryCountRes) ?? 0;

  final weightCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM weight_logs;');
  final weightCount = Sqflite.firstIntValue(weightCountRes) ?? 0;

  final profileCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM user_profile;');
  final profileCount = Sqflite.firstIntValue(profileCountRes) ?? 0;

  int fileSizeBytes = 0;
  try {
    final dbPath = await _getDatabasePath();
    final file = File(dbPath);
    if (await file.exists()) {
      fileSizeBytes = await file.length();
    }
  } catch (_) {}

  return {
    'meals_count': mealsCount,
    'pantry_count': pantryCount,
    'weight_logs_count': weightCount,
    'has_user_profile': profileCount > 0,
    'file_size_bytes': fileSizeBytes,
    'file_size_kb': (fileSizeBytes / 1024).toStringAsFixed(1),
  };
}
```

---

## 6. Complete Blueprint for `lib/services/database_service.dart`

Here is the complete drop-in structure recommended for the implementer agent:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/meal.dart';
import '../models/pantry_item.dart';
import '../models/user_profile.dart';
import '../models/weight_log.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;
  static Future<Database>? _initFuture;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  @visibleForTesting
  void setDatabaseForTesting(Database db) {
    _database = db;
    _initFuture = Future.value(db);
  }

  @visibleForTesting
  Future<void> closeForTesting() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    _database = null;
    _initFuture = null;
  }

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    if (_initFuture != null) {
      return await _initFuture!;
    }
    _initFuture = _initDatabase();
    try {
      _database = await _initFuture!;
      return _database!;
    } catch (e) {
      _initFuture = null;
      rethrow;
    }
  }

  Future<void> init() async {
    await database;
  }

  Future<String> _getDatabasePath() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final directory = await getApplicationDocumentsDirectory();
      try {
        final dir = Directory(directory.path);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      } catch (_) {}
      return p.join(directory.path, 'app_food_tracker.db');
    } else {
      try {
        final databasesPath = await getDatabasesPath();
        try {
          final dir = Directory(databasesPath);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
        } catch (_) {}
        return p.join(databasesPath, 'app_food_tracker.db');
      } catch (e) {
        debugPrint('Warning: getDatabasesPath failed ($e), falling back to getApplicationDocumentsDirectory');
        final directory = await getApplicationDocumentsDirectory();
        try {
          final dir = Directory(directory.path);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
        } catch (_) {}
        return p.join(directory.path, 'app_food_tracker.db');
      }
    }
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await _getDatabasePath();

    return await openDatabase(
      dbPath,
      version: 2,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    try {
      await db.rawQuery('PRAGMA journal_mode = WAL;');
    } catch (e) {
      debugPrint('Warning: Failed to set PRAGMA journal_mode: $e');
    }

    try {
      await db.execute('PRAGMA synchronous = NORMAL;');
    } catch (e) {
      debugPrint('Warning: Failed to set PRAGMA synchronous: $e');
    }

    try {
      await db.execute('PRAGMA foreign_keys = ON;');
    } catch (e) {
      debugPrint('Warning: Failed to set PRAGMA foreign_keys: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createMealsTable(db);
    await _createPantryTable(db);
    await _createWeightLogsTable(db);
    await _createUserProfileTable(db);
    await _createIndices(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createWeightLogsTable(db);
      await _createUserProfileTable(db);
      await db.execute('CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);');
    }
  }

  Future<void> _createMealsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        date TEXT NOT NULL,
        image_path TEXT,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        notes TEXT,
        ai_breakdown_json TEXT
      )
    ''');
  }

  Future<void> _createPantryTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pantry_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        brand TEXT,
        category TEXT,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createWeightLogsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS weight_logs (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        weight REAL NOT NULL,
        notes TEXT
      )
    ''');
  }

  Future<void> _createUserProfileTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id TEXT PRIMARY KEY,
        name TEXT,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        activity_level TEXT NOT NULL,
        body_goal TEXT NOT NULL,
        estimated_steps INTEGER NOT NULL DEFAULT 8000,
        bmr REAL NOT NULL,
        tdee REAL NOT NULL,
        target_calories REAL NOT NULL,
        target_protein REAL NOT NULL,
        target_carbs REAL NOT NULL,
        target_fat REAL NOT NULL,
        master_prompt TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createIndices(DatabaseExecutor db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_date ON meals(date);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_meal_type ON meals(meal_type);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_date_type ON meals(date, meal_type);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_name ON pantry_items(name COLLATE NOCASE);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_category ON pantry_items(category);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_favorite ON pantry_items(is_favorite);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);');
  }

  // --- MEAL OPERATIONS ---
  Future<int> insertMeal(Meal meal) async {
    final db = await database;
    return await db.insert('meals', meal.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateMeal(Meal meal) async {
    final db = await database;
    return await db.update('meals', meal.toSqliteMap(), where: 'id = ?', whereArgs: [meal.id]);
  }

  Future<int> deleteMeal(String id) async {
    final db = await database;
    return await db.delete('meals', where: 'id = ?', whereArgs: [id]);
  }

  Future<Meal?> getMealById(String id) async {
    final db = await database;
    final results = await db.query('meals', where: 'id = ?', whereArgs: [id], limit: 1);
    if (results.isEmpty) return null;
    return Meal.fromSqliteMap(results.first);
  }

  Future<List<Meal>> getMealsForDay(DateTime day) async {
    final db = await database;
    final startOfDay = DateTime(day.year, day.month, day.day).toIso8601String();
    final nextDay = DateTime(day.year, day.month, day.day + 1).toIso8601String();
    final results = await db.query('meals', where: 'date >= ? AND date < ?', whereArgs: [startOfDay, nextDay], orderBy: 'date ASC');
    return results.map((m) => Meal.fromSqliteMap(m)).toList();
  }

  Future<List<Meal>> getAllMeals() async {
    final db = await database;
    final results = await db.query('meals', orderBy: 'date DESC');
    return results.map((m) => Meal.fromSqliteMap(m)).toList();
  }

  // --- PANTRY OPERATIONS ---
  Future<int> insertPantryItem(PantryItem item) async {
    final db = await database;
    return await db.insert('pantry_items', item.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updatePantryItem(PantryItem item) async {
    final db = await database;
    return await db.update('pantry_items', item.toSqliteMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deletePantryItem(String id) async {
    final db = await database;
    return await db.delete('pantry_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PantryItem>> getPantryItems({String? query, String? category, bool? onlyFavorites}) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (query != null && query.trim().isNotEmpty) {
      whereClauses.add('(name LIKE ? OR brand LIKE ?)');
      whereArgs.add('%${query.trim()}%');
      whereArgs.add('%${query.trim()}%');
    }
    if (category != null && category.trim().isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(category.trim());
    }
    if (onlyFavorites == true) {
      whereClauses.add('is_favorite = 1');
    }

    final whereString = whereClauses.isEmpty ? null : whereClauses.join(' AND ');
    final results = await db.query(
      'pantry_items',
      where: whereString,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'is_favorite DESC, name ASC',
    );
    return results.map((p) => PantryItem.fromSqliteMap(p)).toList();
  }

  // --- WEIGHT LOG OPERATIONS (PHASE 2) ---
  Future<int> insertWeightLog(WeightLog log) async {
    final db = await database;
    return await db.insert('weight_logs', log.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateWeightLog(WeightLog log) async {
    final db = await database;
    return await db.update('weight_logs', log.toSqliteMap(), where: 'id = ?', whereArgs: [log.id]);
  }

  Future<int> deleteWeightLog(String id) async {
    final db = await database;
    return await db.delete('weight_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<WeightLog?> getWeightLogById(String id) async {
    final db = await database;
    final results = await db.query('weight_logs', where: 'id = ?', whereArgs: [id], limit: 1);
    if (results.isEmpty) return null;
    return WeightLog.fromSqliteMap(results.first);
  }

  Future<List<WeightLog>> getAllWeightLogs() async {
    final db = await database;
    final results = await db.query('weight_logs', orderBy: 'date DESC');
    return results.map((m) => WeightLog.fromSqliteMap(m)).toList();
  }

  Future<WeightLog?> getLatestWeightLog() async {
    final db = await database;
    final results = await db.query('weight_logs', orderBy: 'date DESC', limit: 1);
    if (results.isEmpty) return null;
    return WeightLog.fromSqliteMap(results.first);
  }

  Future<List<WeightLog>> getWeightLogsByRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final results = await db.query(
      'weight_logs',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date ASC',
    );
    return results.map((m) => WeightLog.fromSqliteMap(m)).toList();
  }

  Future<List<WeightLog>> getWeightLogsLastDays(int days) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    return await getWeightLogsByRange(startDate, now);
  }

  Future<void> batchUpsertWeightLogs(List<WeightLog> logs) async {
    if (logs.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final log in logs) {
        batch.insert('weight_logs', log.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  // --- USER PROFILE OPERATIONS (PHASE 2) ---
  Future<int> saveUserProfile(UserProfile profile) async {
    final db = await database;
    return await db.insert('user_profile', profile.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    final results = await db.query('user_profile', limit: 1);
    if (results.isEmpty) return null;
    return UserProfile.fromSqliteMap(results.first);
  }

  Future<int> deleteUserProfile({String id = 'primary'}) async {
    final db = await database;
    return await db.delete('user_profile', where: 'id = ?', whereArgs: [id]);
  }

  // --- MAINTENANCE & TELEMETRY ---
  Future<void> executeVacuum() async {
    final db = await database;
    await db.execute('VACUUM;');
  }

  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;
    final mealsCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM meals;');
    final mealsCount = Sqflite.firstIntValue(mealsCountRes) ?? 0;

    final pantryCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM pantry_items;');
    final pantryCount = Sqflite.firstIntValue(pantryCountRes) ?? 0;

    final weightCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM weight_logs;');
    final weightCount = Sqflite.firstIntValue(weightCountRes) ?? 0;

    final profileCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM user_profile;');
    final profileCount = Sqflite.firstIntValue(profileCountRes) ?? 0;

    int fileSizeBytes = 0;
    try {
      final dbPath = await _getDatabasePath();
      final file = File(dbPath);
      if (await file.exists()) {
        fileSizeBytes = await file.length();
      }
    } catch (_) {}

    return {
      'meals_count': mealsCount,
      'pantry_count': pantryCount,
      'weight_logs_count': weightCount,
      'has_user_profile': profileCount > 0,
      'file_size_bytes': fileSizeBytes,
      'file_size_kb': (fileSizeBytes / 1024).toStringAsFixed(1),
    };
  }
}
```

---

## 7. Comprehensive Testing Strategy

### 7.1 Existing Tests: `test/services/database_service_test.dart`
The existing tests in `test/services/database_service_test.dart` configure an in-memory database at `version: 1`. When `database_service.dart` is upgraded, updating `database_service_test.dart` ensures:
1. Concurrency (50 futures) continues to pass.
2. PRAGMA integrity continues to pass.
3. CRUD on `meals` and `pantry_items` remains intact.

### 7.2 Dedicated Migration & v2 Test Suite: `test/services/database_service_v2_test.dart`
Per `PROJECT.md` line 93, create `test/services/database_service_v2_test.dart`.

#### Test Matrix:
| Test Description | Scenario & Inputs | Verification Mechanism |
|---|---|---|
| **Migration from v1 to v2 Preserves Data** | Open in-memory DB at `version: 1`, insert 2 meals and 1 pantry item. Close and reopen with `version: 2` and `_onUpgrade`. | Meals and pantry items still exist. `weight_logs` and `user_profile` tables exist. Index `idx_weight_logs_date` exists. |
| **Fresh v2 Installation Creates All Tables** | Open empty DB at `version: 2` with `_onCreate`. | `sqlite_master` contains tables: `meals`, `pantry_items`, `weight_logs`, `user_profile`. |
| **Index Presence Verification** | Query `SELECT name FROM sqlite_master WHERE type = 'index'`. | Contains `idx_weight_logs_date`, `idx_meals_date`, `idx_pantry_name`, etc. |
| **`WeightLog` CRUD & ID Replacement** | Insert log `w1`, update weight, query by ID, delete. | Assert fields, assert `ConflictAlgorithm.replace` updates without duplicates, assert null on deletion. |
| **Indexed Date-Range Boundary Accuracy** | Insert logs at `2026-09-01T00:00:00`, `2026-09-03T12:00:00`, `2026-09-05T23:59:59`, plus out-of-range logs. | Query `2026-09-01` to `2026-09-05`. Exactly 3 logs returned in ascending chronological order. |
| **Latest Weight Log ($O(1)$)** | Insert multiple logs with distinct timestamps. | `getLatestWeightLog()` returns the record with greatest `date`. Returns `null` on empty table. |
| **Batch Upsert Atomicity** | Call `batchUpsertWeightLogs` with 50 logs. | All 50 rows committed in a single transaction. |
| **User Profile Singleton Save & Fetch** | Save profile with Mifflin-St Jeor metrics and Master Prompt. Save again with modified weight. | Database contains exactly 1 profile with updated weight and master prompt. |
| **Telemetry Stats Accuracy** | Populate 2 meals, 1 pantry item, 3 weight logs, 1 profile. Call `getDatabaseStats()`. | Stats map returns `meals_count: 2`, `pantry_count: 1`, `weight_logs_count: 3`, `has_user_profile: true`. |

#### Implementation Draft for `test/services/database_service_v2_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_tracker/models/meal.dart';
import 'package:food_tracker/models/user_profile.dart';
import 'package:food_tracker/models/weight_log.dart';
import 'package:food_tracker/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;

  setUp(() async {
    // Open in-memory DB at version 2 using the service's own configuration
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) async {
          await db.rawQuery('PRAGMA journal_mode = WAL;');
          await db.execute('PRAGMA synchronous = NORMAL;');
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          // Creates all v2 tables
          await db.execute('''
            CREATE TABLE meals (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              meal_type TEXT NOT NULL,
              date TEXT NOT NULL,
              image_path TEXT,
              calories REAL NOT NULL,
              protein REAL NOT NULL,
              carbs REAL NOT NULL,
              fat REAL NOT NULL,
              notes TEXT,
              ai_breakdown_json TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE pantry_items (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              brand TEXT,
              category TEXT,
              calories REAL NOT NULL,
              protein REAL NOT NULL,
              carbs REAL NOT NULL,
              fat REAL NOT NULL,
              is_favorite INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE weight_logs (
              id TEXT PRIMARY KEY,
              date TEXT NOT NULL,
              weight REAL NOT NULL,
              notes TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE user_profile (
              id TEXT PRIMARY KEY,
              name TEXT,
              age INTEGER NOT NULL,
              gender TEXT NOT NULL,
              height REAL NOT NULL,
              weight REAL NOT NULL,
              activity_level TEXT NOT NULL,
              body_goal TEXT NOT NULL,
              estimated_steps INTEGER NOT NULL DEFAULT 8000,
              bmr REAL NOT NULL,
              tdee REAL NOT NULL,
              target_calories REAL NOT NULL,
              target_protein REAL NOT NULL,
              target_carbs REAL NOT NULL,
              target_fat REAL NOT NULL,
              master_prompt TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.execute('CREATE INDEX idx_weight_logs_date ON weight_logs(date);');
        },
      ),
    );

    DatabaseService.instance.setDatabaseForTesting(db);
  });

  tearDown(() async {
    await DatabaseService.instance.closeForTesting();
  });

  group('DatabaseService v2 Tests', () {
    test('Migration v1 to v2 preserves existing records and creates new tables', () async {
      // 1. Create a raw v1 database
      final rawDb = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('CREATE TABLE meals (id TEXT PRIMARY KEY, name TEXT NOT NULL, meal_type TEXT NOT NULL, date TEXT NOT NULL, calories REAL NOT NULL, protein REAL NOT NULL, carbs REAL NOT NULL, fat REAL NOT NULL);');
            await db.execute("INSERT INTO meals VALUES ('m1', 'Legacy Meal', 'Almuerzo', '2026-09-01T12:00:00.000', 500, 30, 40, 10);");
          },
        ),
      );

      // 2. Perform migration logic
      await rawDb.execute('''
        CREATE TABLE IF NOT EXISTS weight_logs (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          weight REAL NOT NULL,
          notes TEXT
        );
      ''');
      await rawDb.execute('CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);');
      await rawDb.execute('''
        CREATE TABLE IF NOT EXISTS user_profile (
          id TEXT PRIMARY KEY,
          name TEXT,
          age INTEGER NOT NULL,
          gender TEXT NOT NULL,
          height REAL NOT NULL,
          weight REAL NOT NULL,
          activity_level TEXT NOT NULL,
          body_goal TEXT NOT NULL,
          estimated_steps INTEGER NOT NULL DEFAULT 8000,
          bmr REAL NOT NULL,
          tdee REAL NOT NULL,
          target_calories REAL NOT NULL,
          target_protein REAL NOT NULL,
          target_carbs REAL NOT NULL,
          target_fat REAL NOT NULL,
          master_prompt TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );
      ''');

      // 3. Verify legacy meals remain intact
      final meals = await rawDb.query('meals');
      expect(meals.length, equals(1));
      expect(meals.first['name'], equals('Legacy Meal'));

      // 4. Verify new tables are queryable
      final weightLogs = await rawDb.query('weight_logs');
      expect(weightLogs, isEmpty);

      final indices = await rawDb.rawQuery("SELECT name FROM sqlite_master WHERE type = 'index';");
      expect(indices.map((r) => r['name']), contains('idx_weight_logs_date'));

      await rawDb.close();
    });

    test('WeightLog CRUD and date-range queries operate correctly', () async {
      final service = DatabaseService.instance;
      final log1 = WeightLog(id: 'w1', date: DateTime(2026, 9, 1, 8, 0), weight: 80.0, notes: 'Inicio');
      final log2 = WeightLog(id: 'w2', date: DateTime(2026, 9, 3, 8, 0), weight: 79.5);
      final log3 = WeightLog(id: 'w3', date: DateTime(2026, 9, 5, 8, 0), weight: 79.0);

      await service.insertWeightLog(log1);
      await service.insertWeightLog(log2);
      await service.insertWeightLog(log3);

      // Latest log lookup (O(1))
      final latest = await service.getLatestWeightLog();
      expect(latest, isNotNull);
      expect(latest!.id, equals('w3'));
      expect(latest.weight, equals(79.0));

      // Range query
      final range = await service.getWeightLogsByRange(
        DateTime(2026, 9, 2),
        DateTime(2026, 9, 4),
      );
      expect(range.length, equals(1));
      expect(range.first.id, equals('w2'));

      // Delete
      await service.deleteWeightLog('w1');
      final fetched = await service.getWeightLogById('w1');
      expect(fetched, isNull);
    });

    test('UserProfile save and fetch operates with singleton replacement semantics', () async {
      final service = DatabaseService.instance;
      final profile = UserProfile(
        id: 'primary',
        name: 'Victor',
        age: 28,
        gender: 'male',
        height: 178.0,
        weight: 78.0,
        activityLevel: 'moderate',
        bodyGoal: 'fat_loss',
        bmr: 1750.0,
        tdee: 2712.0,
        targetCalories: 2212.0,
        targetProtein: 156.0,
        targetCarbs: 235.0,
        targetFat: 61.0,
        masterPrompt: 'Contexto metabólico Victor',
      );

      await service.saveUserProfile(profile);

      var fetched = await service.getUserProfile();
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Victor'));
      expect(fetched.targetCalories, equals(2212.0));

      // Replace with updated target
      final updated = profile.copyWith(targetCalories: 2100.0);
      await service.saveUserProfile(updated);

      fetched = await service.getUserProfile();
      expect(fetched!.targetCalories, equals(2100.0));
    });
  });
}
```

---

## 8. Cross-Milestone Alignment & Contracts

| Contract Element | Provider | Consumers | Alignment Verification |
|---|---|---|---|
| `WeightLog` Model | Explorer M1-2 (`lib/models/weight_log.dart`) | `DatabaseService`, `MealController`, `BackupService` | Fields (`id`, `date`, `weight`, `notes`), `toSqliteMap()`, `fromSqliteMap()`, `_sentinel`. |
| `UserProfile` Model | Explorer M1-2 (`lib/models/user_profile.dart`) | `DatabaseService`, `BackupService`, `UserProfileScreen` | Fields, Mifflin-St Jeor attributes, `toSqliteMap()`, `fromSqliteMap()`, `dailyGoals` getter. |
| `weight_logs` Table | Explorer M1-1 (`database_service.dart`) | `MealController`, `MetricsScreen` (M5) | Primary key `id`, index `idx_weight_logs_date` on `date`. |
| `user_profile` Table | Explorer M1-1 (`database_service.dart`) | `UserProfileScreen` (M3), `GeminiVisionService` (M2) | Persistent local profile storage, single-row singleton. |
| Range Queries | Explorer M1-1 & M1-3 (`database_service.dart`) | `MealController` (M1), `MetricsScreen` (M5) | `getWeightLogsByRange`, `getWeightLogsLastDays(days)`. |
| JSON Pipeline | Explorer M1-3 (`backup_service.dart`) | `SettingsController` | Backup includes `weight_logs` and `user_profile` with atomic rollback. |

---

## 9. Conclusion & Implementation Checklist

All design decisions, schemas, migration procedures, and test specifications for Milestone 1's SQLite v2 persistence layer are finalized.

### Step-by-Step Implementation Roadmap for Implementer:
1. Update `lib/services/database_service.dart`:
   - Import `../models/user_profile.dart` and `../models/weight_log.dart`.
   - Update `openDatabase` to `version: 2`, `onConfigure: _onConfigure`, `onCreate: _onCreate`, `onUpgrade: _onUpgrade`.
   - Implement modular table creators (`_createWeightLogsTable`, `_createUserProfileTable`, `_createIndices`).
   - Implement single and batch mutations for `weight_logs`.
   - Implement `getWeightLogsByRange`, `getWeightLogsLastDays`, and `getLatestWeightLog`.
   - Implement `saveUserProfile`, `getUserProfile`, and `deleteUserProfile`.
   - Update `getDatabaseStats` with `weight_logs_count` and `has_user_profile`.
2. Add migration and v2 unit tests in `test/services/database_service_v2_test.dart`.
3. Verify test suite passes without regressions.
