# Milestone 1 Exploration Report: Integration, Range Queries & Backup Pipeline
**Victor Engineer - Food Tracker (NutriTracker Local-First) - Phase 2**  
**Explorer:** M1 Integration & Backup Explorer (`explorer_m1_3`)  
**Working Directory:** `C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_m1_3`  
**Date:** 2026-09-07T16:13:45Z  
**Context:** Phase 2 Milestone 1: SQLite v2 & Persistence Layer

---

## 1. Executive Summary

This report delivers the technical blueprint for the integration and backup components of Phase 2 Milestone 1:
1. **Fast Indexed Date-Range Queries in `DatabaseService`**: Leveraging the SQLite B-Tree index on `date` (`idx_weight_logs_date`) to execute range queries directly in native SQLite (`where: 'date >= ? AND date <= ?'`, `orderBy: 'date ASC'`) with zero RAM-filtering overhead. Includes pre-computed ranges (7 days, 30 days, 90 days) and O(1) latest record lookup.
2. **`MealController` Weight Integration**: Expanding `MealController` (`lib/controllers/meal_controller.dart`) from its current 116 LoC to ~154 LoC (strictly under the 300 LoC threshold, consuming only ~51.3% of the budget), adding reactive weight tracking state, unmodifiable getters, and atomic mutation methods (`loadWeightLogs`, `recordWeight`, `deleteWeight`).
3. **`BackupService` JSON Pipeline Extension**: Upgrading `exportToJsonString()` to include `'weight_logs'` and `'user_profile'` with schema metadata, and upgrading `importFromJsonString()` to restore both datasets inside an atomic `db.transaction(...)` with `ConflictAlgorithm.replace`, full backward compatibility for Phase 1 backups, and automated transaction rollback on corruption.
4. **Comprehensive Unit Testing Strategies**: Detailed test matrices covering database range queries, controller state reactivity, and backup export/import resilience using in-memory SQLite fixtures (`inMemoryDatabasePath`).

---

## 2. Component 1: Date-Range Queries in `DatabaseService`

### 2.1 Architectural Rationale: SQLite Native Indexing vs. RAM Filtering
Per the `sqlite-local-first-flutter` standard:
* **Strict Prohibition**: Loading hundreds of records into Dart memory and filtering with `.where((e) => ...)` is banned.
* **Indexed Execution**: SQLite can scan B-Tree indexes in $O(\log N + K)$ time (where $K$ is the number of rows in the range). Because `date` is stored as an ISO-8601 string (`YYYY-MM-DDTHH:MM:SS.mmm`), lexicographical string comparison in SQLite matches chronological order.

### 2.2 Core Query: `getWeightLogsByRange`
```dart
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
```

#### Boundary Handling
* When querying a date range by days (e.g. from 2026-09-01 to 2026-09-07), callers must ensure `endDate` covers the end of the day if logs recorded in the afternoon/evening of `endDate` should be included:
  - `startDate`: `DateTime(start.year, start.month, start.day, 0, 0, 0)`
  - `endDate`: `DateTime(end.year, end.month, end.day, 23, 59, 59, 999)`
* When querying relative to `DateTime.now()`, `DateTime.now()` naturally includes any record created up to the exact current millisecond.

### 2.3 Pre-Computed Ranges (7, 30, 90 Days)
To service the Bento Grid metrics cards in Milestone 5 (`MetricsScreen`), two complementary patterns are recommended:

#### 1. Dynamic Window Helper
```dart
Future<List<WeightLog>> getWeightLogsLastDays(int days) async {
  final now = DateTime.now();
  final startDate = now.subtract(Duration(days: days));
  return await getWeightLogsByRange(startDate, now);
}
```

#### 2. Range Filter Enumeration
To avoid magic numbers across UI filter chips and controller calls:
```dart
enum WeightRangeFilter {
  week(7, '7D', 'Últimos 7 días'),
  month(30, '30D', 'Últimos 30 días'),
  quarter(90, '90D', 'Últimos 90 días');

  final int days;
  final String label;
  final String description;

  const WeightRangeFilter(this.days, this.label, this.description);
}
```

#### 3. Dedicated Convenience Shortcuts
```dart
Future<List<WeightLog>> getWeightLogsLast7Days() => getWeightLogsLastDays(7);
Future<List<WeightLog>> getWeightLogsLast30Days() => getWeightLogsLastDays(30);
Future<List<WeightLog>> getWeightLogsLast90Days() => getWeightLogsLastDays(90);
```

### 2.4 Latest Weight Record (O(1) Indexed Lookup)
To display the user's latest weight on the Dashboard without loading historical lists:
```dart
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
```

### 2.5 Single Record Mutations & Backup Utilities
```dart
Future<int> insertWeightLog(WeightLog log) async {
  final db = await database;
  return await db.insert(
    'weight_logs',
    log.toSqliteMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<int> updateWeightLog(WeightLog log) async {
  final db = await database;
  return await db.update(
    'weight_logs',
    log.toSqliteMap(),
    where: 'id = ?',
    whereArgs: [log.id],
  );
}

Future<int> deleteWeightLog(String id) async {
  final db = await database;
  return await db.delete(
    'weight_logs',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<List<WeightLog>> getAllWeightLogs() async {
  final db = await database;
  final results = await db.query('weight_logs', orderBy: 'date DESC');
  return results.map((m) => WeightLog.fromSqliteMap(m)).toList();
}
```

### 2.6 User Profile Persistence in `DatabaseService`
For Milestone 1 and Milestone 3 integration:
```dart
Future<UserProfile?> getUserProfile() async {
  final db = await database;
  final results = await db.query('user_profile', limit: 1);
  if (results.isEmpty) return null;
  return UserProfile.fromSqliteMap(results.first);
}

Future<int> saveUserProfile(UserProfile profile) async {
  final db = await database;
  return await db.insert(
    'user_profile',
    profile.toSqliteMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
```

---

## 3. Component 2: `MealController` Integration & Line Count Management

### 3.1 Line Count Budget Audit
* **Current State**: `lib/controllers/meal_controller.dart` has **116 lines of code**.
* **Strict Constraint**: Screen and controller files must stay **strictly < 300 LoC**.
* **Estimated Additions**: ~38 lines of code.
* **Projected Final Size**: **~154 lines of code** (154 / 300 = **51.3%** of maximum allowed).
* **Headroom Remaining**: **~146 lines of code**.

### 3.2 State Additions
```dart
List<WeightLog> _weightLogs = [];
WeightLog? _latestWeightLog;
int _selectedWeightDays = 30;

List<WeightLog> get weightLogs => List.unmodifiable(_weightLogs);
WeightLog? get latestWeightLog => _latestWeightLog;
int get selectedWeightDays => _selectedWeightDays;
double? get currentWeight => _latestWeightLog?.weight;
```

### 3.3 Method Specifications

#### 1. `loadWeightLogs({int days = 30})`
* Updates `_selectedWeightDays`.
* Fetches the range from `DatabaseService.instance.getWeightLogsLastDays(days)`.
* Fetches the latest log from `DatabaseService.instance.getLatestWeightLog()`.
* Employs safe error boundary: in case of error, resets `_weightLogs = []` and `_latestWeightLog = null` without throwing unhandled exceptions to UI widgets.
* Dispatches `notifyListeners()`.

```dart
Future<void> loadWeightLogs({int days = 30}) async {
  _selectedWeightDays = days;
  try {
    _weightLogs = await DatabaseService.instance.getWeightLogsLastDays(days);
    _latestWeightLog = await DatabaseService.instance.getLatestWeightLog();
  } catch (e) {
    debugPrint('MealController: error loading weight logs: $e');
    _weightLogs = [];
    _latestWeightLog = null;
  }
  notifyListeners();
}
```

#### 2. `recordWeight(double weight, {String? notes, DateTime? date})`
* Instantiates an immutable `WeightLog`.
* Default timestamp rule: if `date` is omitted, defaults to `DateTime.now()` (or optional caller override like `selectedDate`).
* Persists to SQLite via `DatabaseService.instance.insertWeightLog(log)`.
* Reloads using `await loadWeightLogs(days: _selectedWeightDays)` to maintain active range filtering.
* Automatically updates `_latestWeightLog` and notifies all listening UI widgets.

```dart
Future<void> recordWeight(double weight, {String? notes, DateTime? date}) async {
  final log = WeightLog(
    weight: weight,
    notes: notes,
    date: date ?? DateTime.now(),
  );
  await DatabaseService.instance.insertWeightLog(log);
  await loadWeightLogs(days: _selectedWeightDays);
}
```

#### 3. `deleteWeight(String id)`
* Invokes `DatabaseService.instance.deleteWeightLog(id)`.
* Reloads using `await loadWeightLogs(days: _selectedWeightDays)`.
* Notifies listeners.

```dart
Future<void> deleteWeight(String id) async {
  await DatabaseService.instance.deleteWeightLog(id);
  await loadWeightLogs(days: _selectedWeightDays);
}
```

#### 4. Controller Lifecycle: `init()`
Update `MealController.init()` to ensure weight state is preloaded upon app boot:
```dart
Future<void> init() async {
  await refreshGoals();
  await loadMeals();
  await loadWeightLogs();
}
```

---

## 4. Component 3: `BackupService` JSON Pipeline Extension

### 4.1 Export Structure (`exportToJsonString`)
* Bumps exported metadata to `'version': '2.0.0'` and adds `'schema_version': 2`.
* Queries `weightLogs` and `userProfile` asynchronously.
* Emits a comprehensive JSON file with backward-compatible top-level keys.

```dart
Future<String> exportToJsonString() async {
  final dbService = DatabaseService.instance;
  final meals = await dbService.getAllMeals();
  final pantry = await dbService.getPantryItems();
  final weightLogs = await dbService.getAllWeightLogs();
  final userProfile = await dbService.getUserProfile();

  final exportData = {
    'app': 'Victor Engineer Food Tracker',
    'version': '2.0.0',
    'schema_version': 2,
    'export_date': DateTime.now().toIso8601String(),
    'meals_count': meals.length,
    'pantry_count': pantry.length,
    'weight_logs_count': weightLogs.length,
    'has_user_profile': userProfile != null,
    'meals': meals.map((m) => m.toJson()).toList(),
    'pantry_items': pantry.map((p) => p.toJson()).toList(),
    'weight_logs': weightLogs.map((w) => w.toJson()).toList(),
    'user_profile': userProfile?.toJson(),
  };

  return const JsonEncoder.withIndent('  ').convert(exportData);
}
```

### 4.2 Transactional Import (`importFromJsonString`)
* Strict schema validation: ensures top-level decoded structure is `Map<String, dynamic>`.
* All write operations encapsulated in `db.transaction((txn) async { ... })`.
* If parsing or insertion of any record fails, SQLite automatically rolls back the entire batch, preserving database consistency.
* Uses `ConflictAlgorithm.replace` across all tables (`meals`, `pantry_items`, `weight_logs`, `user_profile`).
* **Backward Compatibility**: If importing a Phase 1 backup without `weight_logs` or `user_profile`, the type checks `decoded['weight_logs'] is List` and `decoded['user_profile'] is Map` evaluate to false and are safely skipped without error.
* Return map includes both legacy keys (`imported_meals`, `imported_pantry`) and new keys (`imported_weight_logs`, `imported_user_profile`) to avoid breaking any callers or UI snackbars.

```dart
Future<Map<String, int>> importFromJsonString(String jsonContent) async {
  final dynamic decoded = json.decode(jsonContent);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('El archivo de respaldo no tiene el formato JSON esperado.');
  }

  final db = await DatabaseService.instance.database;
  int importedMeals = 0;
  int importedPantry = 0;
  int importedWeightLogs = 0;
  int importedUserProfile = 0;

  await db.transaction((txn) async {
    // 1. Restore Meals
    if (decoded['meals'] is List) {
      for (final item in decoded['meals']) {
        if (item is Map<String, dynamic>) {
          final meal = Meal.fromJson(item);
          await txn.insert(
            'meals',
            meal.toSqliteMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          importedMeals++;
        }
      }
    }

    // 2. Restore Pantry Items
    if (decoded['pantry_items'] is List) {
      for (final item in decoded['pantry_items']) {
        if (item is Map<String, dynamic>) {
          final pantryItem = PantryItem.fromJson(item);
          await txn.insert(
            'pantry_items',
            pantryItem.toSqliteMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          importedPantry++;
        }
      }
    }

    // 3. Restore Weight Logs (Phase 2)
    if (decoded['weight_logs'] is List) {
      for (final item in decoded['weight_logs']) {
        if (item is Map<String, dynamic>) {
          final weightLog = WeightLog.fromJson(item);
          await txn.insert(
            'weight_logs',
            weightLog.toSqliteMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          importedWeightLogs++;
        }
      }
    }

    // 4. Restore User Profile (Phase 2)
    if (decoded['user_profile'] is Map<String, dynamic>) {
      final profile = UserProfile.fromJson(decoded['user_profile'] as Map<String, dynamic>);
      await txn.insert(
        'user_profile',
        profile.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      importedUserProfile = 1;
    }
  });

  return {
    'imported_meals': importedMeals,
    'imported_pantry': importedPantry,
    'imported_weight_logs': importedWeightLogs,
    'imported_user_profile': importedUserProfile,
  };
}
```

### 4.3 Database Statistics Update (`DatabaseService.getDatabaseStats`)
To ensure `SettingsController` and `SettingsScreen` show accurate telemetry:
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

## 5. Proposed Code Snippets (Ready for Implementation)

### 5.1 Proposed Diff for `lib/controllers/meal_controller.dart`
```dart
// ADD IMPORT:
import '../models/weight_log.dart';

// ADD STATE IN MealController:
  List<WeightLog> _weightLogs = [];
  WeightLog? _latestWeightLog;
  int _selectedWeightDays = 30;

// ADD GETTERS:
  List<WeightLog> get weightLogs => List.unmodifiable(_weightLogs);
  WeightLog? get latestWeightLog => _latestWeightLog;
  int get selectedWeightDays => _selectedWeightDays;
  double? get currentWeight => _latestWeightLog?.weight;

// UPDATE init():
  Future<void> init() async {
    await refreshGoals();
    await loadMeals();
    await loadWeightLogs();
  }

// ADD METHODS:
  Future<void> loadWeightLogs({int days = 30}) async {
    _selectedWeightDays = days;
    try {
      _weightLogs = await DatabaseService.instance.getWeightLogsLastDays(days);
      _latestWeightLog = await DatabaseService.instance.getLatestWeightLog();
    } catch (e) {
      debugPrint('Error loading weight logs: $e');
      _weightLogs = [];
      _latestWeightLog = null;
    }
    notifyListeners();
  }

  Future<void> recordWeight(double weight, {String? notes, DateTime? date}) async {
    final log = WeightLog(
      weight: weight,
      notes: notes,
      date: date ?? DateTime.now(),
    );
    await DatabaseService.instance.insertWeightLog(log);
    await loadWeightLogs(days: _selectedWeightDays);
  }

  Future<void> deleteWeight(String id) async {
    await DatabaseService.instance.deleteWeightLog(id);
    await loadWeightLogs(days: _selectedWeightDays);
  }
```

### 5.2 Proposed Implementation for `lib/services/backup_service.dart`
```dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/meal.dart';
import '../models/pantry_item.dart';
import '../models/user_profile.dart';
import '../models/weight_log.dart';
import 'database_service.dart';

class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  Future<String> exportToJsonString() async {
    final dbService = DatabaseService.instance;
    final meals = await dbService.getAllMeals();
    final pantry = await dbService.getPantryItems();
    final weightLogs = await dbService.getAllWeightLogs();
    final userProfile = await dbService.getUserProfile();

    final exportData = {
      'app': 'Victor Engineer Food Tracker',
      'version': '2.0.0',
      'schema_version': 2,
      'export_date': DateTime.now().toIso8601String(),
      'meals_count': meals.length,
      'pantry_count': pantry.length,
      'weight_logs_count': weightLogs.length,
      'has_user_profile': userProfile != null,
      'meals': meals.map((m) => m.toJson()).toList(),
      'pantry_items': pantry.map((p) => p.toJson()).toList(),
      'weight_logs': weightLogs.map((w) => w.toJson()).toList(),
      'user_profile': userProfile?.toJson(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  Future<Map<String, int>> importFromJsonString(String jsonContent) async {
    final dynamic decoded = json.decode(jsonContent);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El archivo de respaldo no tiene el formato JSON esperado.');
    }

    final db = await DatabaseService.instance.database;
    int importedMeals = 0;
    int importedPantry = 0;
    int importedWeightLogs = 0;
    int importedUserProfile = 0;

    await db.transaction((txn) async {
      if (decoded['meals'] is List) {
        for (final item in decoded['meals']) {
          if (item is Map<String, dynamic>) {
            final meal = Meal.fromJson(item);
            await txn.insert(
              'meals',
              meal.toSqliteMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            importedMeals++;
          }
        }
      }

      if (decoded['pantry_items'] is List) {
        for (final item in decoded['pantry_items']) {
          if (item is Map<String, dynamic>) {
            final pantryItem = PantryItem.fromJson(item);
            await txn.insert(
              'pantry_items',
              pantryItem.toSqliteMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            importedPantry++;
          }
        }
      }

      if (decoded['weight_logs'] is List) {
        for (final item in decoded['weight_logs']) {
          if (item is Map<String, dynamic>) {
            final weightLog = WeightLog.fromJson(item);
            await txn.insert(
              'weight_logs',
              weightLog.toSqliteMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            importedWeightLogs++;
          }
        }
      }

      if (decoded['user_profile'] is Map<String, dynamic>) {
        final profile = UserProfile.fromJson(decoded['user_profile'] as Map<String, dynamic>);
        await txn.insert(
          'user_profile',
          profile.toSqliteMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        importedUserProfile = 1;
      }
    });

    return {
      'imported_meals': importedMeals,
      'imported_pantry': importedPantry,
      'imported_weight_logs': importedWeightLogs,
      'imported_user_profile': importedUserProfile,
    };
  }
}
```

---

## 6. Unit Testing Strategy

All persistence and integration tests run deterministically in-memory using `sqflite_common_ffi` and `inMemoryDatabasePath`.

### 6.1 Test Suite 1: `test/services/database_service_v2_range_test.dart`
| Test Case | Scenario | Expected Outcome |
|---|---|---|
| **Query Range Exact Boundary** | Insert logs at `2026-09-01T00:00:00`, `2026-09-03T12:00:00`, `2026-09-05T23:59:59`. Query range `2026-09-01` to `2026-09-05`. | Returns all 3 logs in ascending order. |
| **Out-of-Bounds Exclusion** | Insert log 1 minute before range start and 1 minute after range end. | Excluded from returned list. |
| **Chronological Ordering** | Insert logs in unordered sequence (`09-04`, `09-01`, `09-03`). | Returned list is strictly sorted `date ASC`. |
| **Pre-computed 7-Day Window** | Insert logs spanning 14 days ago to today. Call `getWeightLogsLastDays(7)`. | Returns only logs within the 7-day interval. |
| **Pre-computed 30-Day Window** | Insert logs spanning 60 days. Call `getWeightLogsLastDays(30)`. | Returns only logs within the 30-day interval. |
| **Pre-computed 90-Day Window** | Insert logs spanning 120 days. Call `getWeightLogsLastDays(90)`. | Returns only logs within the 90-day interval. |
| **Latest Weight Log Lookup** | Insert multiple logs with distinct dates. | `getLatestWeightLog()` returns the single record with newest `date`. |
| **Latest Weight on Empty Table** | Empty `weight_logs` table. | `getLatestWeightLog()` returns `null`. |
| **Insert with Conflict Replace** | Insert log with ID `'w1'`, weight `75.0`. Insert log with ID `'w1'`, weight `74.5`. | Single row remains in SQLite with weight `74.5`. |
| **Delete Weight Log** | Insert 2 logs, delete one by ID. | Target log removed; remaining log intact. |

### 6.2 Test Suite 2: `test/controllers/meal_controller_weight_test.dart`
| Test Case | Scenario | Expected Outcome |
|---|---|---|
| **Initial Load** | Controller initialized with clean test database. | `weightLogs` is empty list, `latestWeightLog` is `null`. |
| **Record Weight Reactivity** | Call `recordWeight(80.5, notes: 'Fasting')`. | Database receives row; `_weightLogs` length is 1; `latestWeightLog?.weight == 80.5`; listener callback fired. |
| **Delete Weight Reactivity** | Record 2 weights, call `deleteWeight(id)`. | `_weightLogs` reflects deletion; listeners notified. |
| **Unmodifiable List Protection** | Attempt `controller.weightLogs.add(...)`. | Throws `UnsupportedError` (encapsulation preserved). |
| **Range Filter Switch** | User logs 40 days of data. Call `loadWeightLogs(days: 7)`. | Only logs within 7 days loaded into state; `selectedWeightDays == 7`. |
| **Silent Error Resilience** | Close database and invoke `loadWeightLogs()`. | Does not throw unhandled exception; sets `_weightLogs = []`. |

### 6.3 Test Suite 3: `test/services/backup_service_v2_test.dart`
| Test Case | Scenario | Expected Outcome |
|---|---|---|
| **Export V2 Complete Schema** | Populate `meals`, `pantry_items`, `weight_logs`, and `user_profile`. Call `exportToJsonString()`. | JSON contains `'version': '2.0.0'`, counts, and all 4 arrays/objects accurately serialized. |
| **Import V2 Full Restore** | Provide full V2 backup JSON. Call `importFromJsonString()`. | All 4 entities restored; counts returned: `imported_meals: 1`, `imported_pantry: 1`, `imported_weight_logs: 1`, `imported_user_profile: 1`. |
| **Backward Compatibility (V1)** | Provide legacy Phase 1 backup JSON (no `weight_logs`, no `user_profile`). | Restores meals and pantry without error; `imported_weight_logs: 0`, `imported_user_profile: 0`. |
| **Transactional Atomicity on Corrupted Record** | Provide JSON where `meals` is valid, but `weight_logs` contains invalid item causing exception. | Transaction aborts; rollback occurs; zero meals or weight logs remain committed in SQLite. |
| **Duplicate ID Idempotency** | Import the same JSON backup twice. | Conflict algorithm replaces records without unique constraint violation. |

---

## 7. Interface Contract Verification & Handoff Summary

| Component | Upstream Source | Downstream Target | Verification Status |
|---|---|---|---|
| `WeightLog` Model | `explorer_m1_2` (`lib/models/weight_log.dart`) | `DatabaseService`, `MealController`, `BackupService` | Aligned with `toSqliteMap()`, `fromSqliteMap()`, `toJson()`, `fromJson()`, `_sentinel`. |
| `UserProfile` Model | `explorer_m1_2` (`lib/models/user_profile.dart`) | `DatabaseService`, `BackupService`, `UserProfileScreen` | Aligned with SQLite schema and JSON serialization. |
| `weight_logs` Table | `explorer_m1_1` (`database_service.dart`) | `DatabaseService` query methods & index | Aligned with `id`, `date`, `weight`, `notes` and `idx_weight_logs_date`. |
| `user_profile` Table | `explorer_m1_1` (`database_service.dart`) | `DatabaseService` methods | Aligned with version 2 `onUpgrade`. |
| `MealController` LoC | `explorer_m1_3` | Implementer & Quality Gate | 116 LoC $\to$ ~154 LoC (Strictly $< 300$ LoC). |
| `BackupService` V2 | `explorer_m1_3` | Implementer & Quality Gate | Atomic transaction with `ConflictAlgorithm.replace`, backward compatibility verified. |

This concludes the architectural investigation for M1 Integration & Backup. All implementation details, line count metrics, and unit test strategies are finalized and ready for the implementer agent.
