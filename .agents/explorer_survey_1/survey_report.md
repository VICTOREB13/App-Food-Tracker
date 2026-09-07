# Survey Report: Codebase & Database Architecture for Phase 2
**Victor Engineer - Food Tracker (NutriTracker Local-First)**  
**Author:** Codebase & Database Explorer (`explorer_survey_1`)  
**Date:** 2026-09-07T16:10:00Z  
**Context:** Phase 2 Survey & Assessment (Requirements R1 - R5)

---

## 1. Executive Summary

This report delivers an exhaustive architectural survey of the Phase 1 Flutter/Dart codebase located at `C:\Users\vmesp\Documents\Cositas\App-Food-Tracker`. It evaluates data models, SQLite persistence, concurrency defenses, controller data access patterns, and provides precise implementation blueprints for:
1. **Requirement R4**: SQLite `weight_logs` table, indexed date-range queries (7, 30, 90 days), transactional queries, `WeightLog` model with `_sentinel` pattern, and integration into `DatabaseService`, `MealController`, and `BackupService`.
2. **Requirement R3**: User profile & metabolic data persistence, evaluating storage options (SQLite `user_profile` table vs `FlutterSecureStorage` vs `SharedPreferences`), Mifflin-St Jeor TMB/TDEE calculations, Master Prompt synthesis, and automatic syncing to `DailyGoals`.

### Core Architectural Discoveries
| Component | Existing Phase 1 State | Phase 2 Insertion Strategy |
|---|---|---|
| **SQLite Engine** | Version 1 in `database_service.dart:103`. Pragmas: WAL (`rawQuery`), `synchronous = NORMAL`, `foreign_keys = ON`. Tables: `meals`, `pantry_items`. | Upgrade to `version: 2`. Implement `_onUpgrade` callback. Add `weight_logs` table and optional `user_profile` table. |
| **Model Inmutability & Sentinel** | Implemented in `FoodItem`, `Meal`, `PantryItem` using `static const Object _sentinel = Object();`. | Apply identical pattern to `WeightLog` and `UserProfile` to support explicitly clearing nullable fields with `null`. |
| **Data Sanitization** | `ModelSanitizer` handles string truncation, double clamping, and ISO-8601 parsing. | Reused for `weight` (clamped 20.0 to 500.0 kg), `height` (clamped 50.0 to 300.0 cm), and notes. |
| **Controllers & Reactivity** | `MealController` and `SettingsController` as `ChangeNotifier` singletons with encapsulated state and unmodifiable getters. | Expand `MealController` with weight logging and range query methods (< 180 LoC total, adhering to < 300 LoC rule). |
| **Backup Pipeline** | `BackupService` exports/imports `meals` and `pantry_items` in a single JSON transaction. | Extend to export and import `weight_logs` and `user_profile` inside `db.transaction(...)`. |

---

## 2. Codebase Audit: Data Models & Sentinel Pattern

### 2.1 Existing Model Structure
All models in `lib/models/` enforce immutability, runtime bounds defensive clamping via `ModelSanitizer`, and JSON serialization.

- **`FoodItem` (`lib/models/food_item.dart`)**:
  - Encapsulates: `id`, `name`, `estimatedGrams`, `calories`, `protein`, `carbs`, `fat`, `visualJustification` (`String?`).
  - Fields are sanitized in initializer lists (`id` fallback Uuid v4, `name` truncated to 255, double clamped 0 to 9999).
- **`Meal` (`lib/models/meal.dart`)**:
  - Encapsulates: `id`, `name`, `mealType`, `date`, `imagePath` (`String?`), `calories`, `protein`, `carbs`, `fat`, `notes` (`String?`), `aiBreakdownJson` (`String?`).
  - Contains helper `recalculateFromItems(List<FoodItem> items)` which updates macros and serialized JSON.
  - Generates SQLite map via `toSqliteMap()` and parses from `Meal.fromSqliteMap(Map<String, dynamic> map)`.
- **`PantryItem` (`lib/models/pantry_item.dart`)**:
  - Encapsulates: `id`, `name`, `brand` (`String?`), `category` (`String?`), `calories`, `protein`, `carbs`, `fat`, `isFavorite` (`bool`).
- **`DailyGoals` (`lib/models/daily_goals.dart`)**:
  - Encapsulates non-nullable nutritional thresholds: `calories` (default 2000), `protein` (140), `carbs` (220), `fat` (65).
  - Sanitized with custom limits (calories: 500 to 10000; macros: 10 to 1000).

### 2.2 The `_sentinel` Pattern Analysis
The Dart language cannot natively distinguish between an omitted optional parameter (meaning "do not modify") and passing `null` explicitly (meaning "set this nullable field to null").

In `lib/models/food_item.dart:14`, `lib/models/meal.dart:26`, and `lib/models/pantry_item.dart:15`, the pattern is implemented with mathematical precision:

```dart
static const Object _sentinel = Object();

Meal copyWith({
  String? id,
  String? name,
  String? mealType,
  DateTime? date,
  Object? imagePath = _sentinel,
  double? calories,
  double? protein,
  double? carbs,
  double? fat,
  Object? notes = _sentinel,
  Object? aiBreakdownJson = _sentinel,
}) {
  return Meal(
    id: id ?? this.id,
    name: name ?? this.name,
    mealType: mealType ?? this.mealType,
    date: date ?? this.date,
    imagePath: identical(imagePath, _sentinel) ? this.imagePath : (imagePath as String?),
    calories: calories ?? this.calories,
    protein: protein ?? this.protein,
    carbs: carbs ?? this.carbs,
    fat: fat ?? this.fat,
    notes: identical(notes, _sentinel) ? this.notes : (notes as String?),
    aiBreakdownJson: identical(aiBreakdownJson, _sentinel)
        ? this.aiBreakdownJson
        : (aiBreakdownJson as String?),
  );
}
```

#### Verification Mechanism (`test/models/meal_model_test.dart:76-102`):
- `meal.copyWith(notes: null)`: `identical(null, _sentinel)` evaluates to `false`, casting `null as String?`, which successfully clears the notes field.
- `meal.copyWith(name: 'New Name')`: `notes` defaults to `_sentinel`. `identical(_sentinel, _sentinel)` evaluates to `true`, retaining `this.notes`.

---

## 3. Codebase Audit: SQLite Database Service (`database_service.dart`)

### 3.1 Concurrency Defense: Memoized Initialization (`_initFuture`)
In `lib/services/database_service.dart:38-53`, the database getter implements memoization:

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
**Audit Finding:** This design protects the engine from `DatabaseException: database is locked`. Under high concurrency (verified by `test/services/database_service_test.dart:75-83` with 50 concurrent requests), all requests wait on the single `_initFuture` promise.

### 3.2 Pragmas and Engine Configuration
Configured inside `onConfigure` (`lib/services/database_service.dart:104-124`):
1. `PRAGMA journal_mode = WAL;`
   - *Implementation detail:* Executed using `db.rawQuery()` rather than `db.execute()`. Android SQLite native bridge throws an exception if a PRAGMA returning a row is executed via `execSQL()`.
2. `PRAGMA synchronous = NORMAL;`
   - Low disk I/O overhead while maintaining WAL durability.
3. `PRAGMA foreign_keys = ON;`
   - Enforces referential integrity on cascades.

### 3.3 Platform Adaptations
- **Desktop (Windows/Linux/macOS):** `sqfliteFfiInit()` and `databaseFactory = databaseFactoryFfi` are configured dynamically in `_initDatabase()` (`lib/services/database_service.dart:94-97`).
- **Path Resolution:** Uses `getApplicationDocumentsDirectory()` from `path_provider` (`lib/services/database_service.dart:59-91`), storing `app_food_tracker.db` safely within the application's scoped sandbox.

### 3.4 Existing Schema & Index Strategy
Currently at `version: 1`:
- **`meals`**: `id TEXT PRIMARY KEY`, `name TEXT NOT NULL`, `meal_type TEXT NOT NULL`, `date TEXT NOT NULL`, `image_path TEXT`, `calories REAL NOT NULL`, `protein REAL NOT NULL`, `carbs REAL NOT NULL`, `fat REAL NOT NULL`, `notes TEXT`, `ai_breakdown_json TEXT`.
- **`pantry_items`**: `id TEXT PRIMARY KEY`, `name TEXT NOT NULL`, `brand TEXT`, `category TEXT`, `calories REAL NOT NULL`, `protein REAL NOT NULL`, `carbs REAL NOT NULL`, `fat REAL NOT NULL`, `is_favorite INTEGER NOT NULL DEFAULT 0`.
- **Indexes:**
  - `idx_meals_date ON meals(date)` (B-Tree for range and daily filtering)
  - `idx_meals_meal_type ON meals(meal_type)`
  - `idx_meals_date_type ON meals(date, meal_type)` (Composite B-Tree)
  - `idx_pantry_name ON pantry_items(name COLLATE NOCASE)` (Case-insensitive B-Tree)
  - `idx_pantry_category ON pantry_items(category)`
  - `idx_pantry_favorite ON pantry_items(is_favorite)`

### 3.5 Database Migration Deficit
`openDatabase` in `lib/services/database_service.dart:101-127` **lacks an `onUpgrade` handler**. For Phase 2, `openDatabase` must be upgraded to `version: 2` with an explicit, atomic `onUpgrade` callback.

---

## 4. Codebase Audit: Controllers & Data Access Patterns

### 4.1 `MealController` (`lib/controllers/meal_controller.dart`)
- Extends `ChangeNotifier` as a singleton.
- **State:**
  - `DateTime _selectedDate`: Selected day.
  - `List<Meal> _meals`: Filtered list of meals for `_selectedDate`.
  - `DailyGoals _dailyGoals`: Cached goals loaded from `SecureStorageService`.
  - `bool _isLoading`: State flag for asynchronous operations.
- **Data Access Pattern:**
  - Date filtering is delegated to SQLite via `DatabaseService.instance.getMealsForDay(_selectedDate)`.
  - Date boundary query in `database_service.dart:209-221`:
    ```dart
    final startOfDay = DateTime(day.year, day.month, day.day).toIso8601String();
    final nextDay = DateTime(day.year, day.month, day.day + 1).toIso8601String();
    where: 'date >= ? AND date < ?'
    ```
    This avoids loading all historical meals into RAM and leverages `idx_meals_date`.
  - On write operations (`saveMeal`, `updateMeal`, `deleteMeal`), `DatabaseService` executes the query and `MealController` calls `loadMeals()`, which re-fetches from SQLite and notifies all listening UI widgets.

### 4.2 `SettingsController` (`lib/controllers/settings_controller.dart`)
- Orchestrates API keys, daily goals, vacuum operations, and JSON backup/restore.
- When daily goals are updated via `saveDailyGoals`, it persists to `SecureStorageService` and immediately updates `MealController.instance.refreshGoals()`.

---

## 5. Architectural Blueprints for Requirement R4: Weight Tracking

Requirement R4 dictates:
- Table `weight_logs` with schema: `id TEXT PRIMARY KEY`, `date TEXT NOT NULL`, `weight REAL NOT NULL`, `notes TEXT`.
- B-Tree index on `date`.
- Transactional queries and date-range queries (7 days, 30 days, 90 days).
- Ingestion into `DatabaseService` and `MealController`.
- `WeightLog` model with `_sentinel` pattern.

### 5.1 SQLite DDL & Index Definition
```sql
CREATE TABLE IF NOT EXISTS weight_logs (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  weight REAL NOT NULL,
  notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);
```

### 5.2 `WeightLog` Model Architecture
File: `lib/models/weight_log.dart`

```dart
import 'package:uuid/uuid.dart';
import 'model_sanitizer.dart';

class WeightLog {
  final String id;
  final DateTime date;
  final double weight;
  final String? notes;

  static const Object _sentinel = Object();

  WeightLog({
    String? id,
    DateTime? date,
    required num weight,
    String? notes,
  })  : id = ModelSanitizer.truncate(id, 128, fallback: const Uuid().v4()),
        date = date ?? DateTime.now(),
        weight = ModelSanitizer.clampDouble(weight, min: 20.0, max: 500.0),
        notes = ModelSanitizer.truncateNullable(notes, ModelSanitizer.maxNotesLength);

  WeightLog copyWith({
    String? id,
    DateTime? date,
    double? weight,
    Object? notes = _sentinel,
  }) {
    return WeightLog(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      notes: identical(notes, _sentinel) ? this.notes : (notes as String?),
    );
  }

  Map<String, dynamic> toSqliteMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'weight': weight,
        'notes': notes,
      };

  factory WeightLog.fromSqliteMap(Map<String, dynamic> map) {
    return WeightLog(
      id: map['id']?.toString(),
      date: ModelSanitizer.parseDate(map['date']),
      weight: ModelSanitizer.clampDouble(map['weight'], min: 20.0, max: 500.0),
      notes: map['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => toSqliteMap();

  factory WeightLog.fromJson(Map<String, dynamic> json) => WeightLog.fromSqliteMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date.toIso8601String() == other.date.toIso8601String() &&
          weight == other.weight &&
          notes == other.notes;

  @override
  int get hashCode => id.hashCode ^ date.hashCode ^ weight.hashCode ^ notes.hashCode;
}
```

### 5.3 `DatabaseService` Additions for R4
File additions in `lib/services/database_service.dart`:

```dart
// 1. Single record mutations
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
  return await db.delete('weight_logs', where: 'id = ?', whereArgs: [id]);
}

// 2. Latest weight lookup (O(1) with index)
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

// 3. Date range queries for 7d, 30d, 90d analytics
Future<List<WeightLog>> getWeightLogsRange(DateTime startDate, DateTime endDate) async {
  final db = await database;
  final results = await db.query(
    'weight_logs',
    where: 'date >= ? AND date <= ?',
    whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    orderBy: 'date ASC',
  );
  return results.map((e) => WeightLog.fromSqliteMap(e)).toList();
}

Future<List<WeightLog>> getWeightLogsLastDays(int days) async {
  final now = DateTime.now();
  final startDate = now.subtract(Duration(days: days));
  return await getWeightLogsRange(startDate, now);
}

// 4. Batch upsert for atomic bulk restoration or imports
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

### 5.4 `MealController` Additions for R4
In `lib/controllers/meal_controller.dart`:
```dart
List<WeightLog> _weightLogs = [];
WeightLog? _latestWeight;

List<WeightLog> get weightLogs => List.unmodifiable(_weightLogs);
WeightLog? get latestWeight => _latestWeight;

Future<void> loadWeightLogs({int days = 30}) async {
  try {
    _weightLogs = await DatabaseService.instance.getWeightLogsLastDays(days);
    _latestWeight = await DatabaseService.instance.getLatestWeightLog();
  } catch (_) {
    _weightLogs = [];
  }
  notifyListeners();
}

Future<void> recordWeight(double weight, {String? notes, DateTime? date}) async {
  final log = WeightLog(
    weight: weight,
    notes: notes,
    date: date ?? _selectedDate,
  );
  await DatabaseService.instance.insertWeightLog(log);
  await loadWeightLogs();
}

Future<void> deleteWeight(String id) async {
  await DatabaseService.instance.deleteWeightLog(id);
  await loadWeightLogs();
}
```

### 5.5 `BackupService` Integration
Update `lib/services/backup_service.dart`:
- Include `'weight_logs': weightLogs.map((w) => w.toJson()).toList()` in `exportToJsonString()`.
- Add transactional ingestion of `weight_logs` in `importFromJsonString()` using `txn.insert('weight_logs', ...)`.
- Update `DatabaseService.getDatabaseStats()` to return `'weight_logs_count': weightCount`.

---

## 6. Architectural Blueprints for Requirement R3: User Profile & Metabolic Data

Requirement R3 dictates:
- Onboarding & profile screen (`UserProfileScreen` / `OnboardingScreen`).
- Biometric inputs: Name, age, gender, height (cm), current weight (kg), physical activity level, fitness goal.
- Standard Mifflin-St Jeor equation for Basal Metabolic Rate (BMR/TMB) and Total Daily Energy Expenditure (TDEE).
- Synthesis of the **Master Prompt** injected into `GeminiVisionService`.
- Direct action to update and apply daily goals (`DailyGoals`).

### 6.1 Storage Strategy Evaluation

| Storage Option | Evaluation & Trade-offs | Verdict |
|---|---|---|
| **A. `FlutterSecureStorage`** | Good for cryptographic secrets (`api_key`), but profile is not secret. Slower async I/O. Does not integrate with SQLite backup pipeline. | ❌ Only use for credentials (`gemini_api_key`, `usda_api_key`). |
| **B. `SharedPreferences`** | Ideal for simple flags (e.g. `has_completed_onboarding: bool`, `selected_gemini_model: String`). Not transactional and excluded from SQLite backups. | ⚠️ Use exclusively for UI routing flags and selected model ID. |
| **C. SQLite `user_profile` Table** | **Single Source of Truth**. 100% Local-First & ACID. Backed up atomically via `BackupService`. Directly relates to `weight_logs` (logging an updated weight in the profile automatically inserts a `WeightLog` record). | ✅ **Recommended for full profile & Master Prompt**. |

### 6.2 Recommended Hybrid Architecture
1. **SQLite Table `user_profile`**:
   Authoritative storage for user biometric parameters, calculated TMB/TDEE, and Master Prompt.
2. **`SharedPreferences`**:
   `has_completed_onboarding` (`bool`) for instant, synchronous check in `main.dart` or `DashboardScreen` during startup.
3. **`SecureStorageService`**:
   Keeps `gemini_api_key`, `usda_api_key`, and synchronizes `DailyGoals` updated from the biometric calculations.

### 6.3 SQLite Schema for `user_profile`
```sql
CREATE TABLE IF NOT EXISTS user_profile (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  age INTEGER NOT NULL,
  gender TEXT NOT NULL,
  height_cm REAL NOT NULL,
  current_weight_kg REAL NOT NULL,
  activity_level TEXT NOT NULL,
  goal TEXT NOT NULL,
  estimated_steps INTEGER NOT NULL DEFAULT 8000,
  tmb REAL NOT NULL,
  tdee REAL NOT NULL,
  target_calories REAL NOT NULL,
  target_protein_g REAL NOT NULL,
  target_carbs_g REAL NOT NULL,
  target_fat_g REAL NOT NULL,
  master_prompt TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

### 6.4 Mathematical Engine: Mifflin-St Jeor Standard
The calculations must be encapsulated in a pure Dart service or model:

```dart
class MetabolicCalculator {
  /// Mifflin-St Jeor Basal Metabolic Rate (BMR / TMB)
  /// Men:   (10 * weight_kg) + (6.25 * height_cm) - (5 * age) + 5
  /// Women: (10 * weight_kg) + (6.25 * height_cm) - (5 * age) - 161
  static double calculateBmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender, // 'male' or 'female'
  }) {
    final base = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age);
    return gender.toLowerCase() == 'male' ? base + 5.0 : base - 161.0;
  }

  /// Activity factor multiplier (PAL)
  static double getActivityMultiplier(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
      case 'sedentario':
        return 1.2;
      case 'light':
      case 'ligero':
        return 1.375;
      case 'moderate':
      case 'moderado':
        return 1.55;
      case 'very_active':
      case 'muy activo':
      case 'muy_activo':
        return 1.725;
      default:
        return 1.2;
    }
  }

  /// Total Daily Energy Expenditure (TDEE)
  static double calculateTdee(double bmr, String activityLevel) {
    return bmr * getActivityMultiplier(activityLevel);
  }

  /// Goal adjustment:
  /// Fat loss: -500 kcal (or 20% deficit)
  /// Maintenance: 0 kcal
  /// Muscle gain: +300 kcal
  static double calculateTargetCalories(double tdee, String goal) {
    switch (goal.toLowerCase()) {
      case 'fat_loss':
      case 'perdida_grasa':
      case 'pérdida de grasa':
        return (tdee - 500.0).clamp(1200.0, 6000.0);
      case 'muscle_gain':
      case 'ganancia_muscular':
      case 'ganancia de masa muscular':
        return (tdee + 300.0).clamp(1500.0, 7000.0);
      case 'maintenance':
      case 'mantenimiento':
      default:
        return tdee.clamp(1200.0, 6000.0);
    }
  }

  /// Macro Distribution Strategy:
  /// - Protein: 2.0g per kg of bodyweight (4 kcal/g)
  /// - Fat: 25% of target calories (9 kcal/g)
  /// - Carbs: Remaining calories (4 kcal/g)
  static DailyGoals calculateDailyGoals({
    required double weightKg,
    required double targetCalories,
  }) {
    final proteinGrams = (weightKg * 2.0).clamp(50.0, 300.0);
    final proteinCals = proteinGrams * 4.0;

    final fatCals = targetCalories * 0.25;
    final fatGrams = (fatCals / 9.0).clamp(30.0, 150.0);

    final remainingCals = targetCalories - proteinCals - (fatGrams * 9.0);
    final carbsGrams = (remainingCals > 0 ? remainingCals / 4.0 : 50.0).clamp(50.0, 600.0);

    return DailyGoals(
      calories: double.parse(targetCalories.toStringAsFixed(0)),
      protein: double.parse(proteinGrams.toStringAsFixed(0)),
      carbs: double.parse(carbsGrams.toStringAsFixed(0)),
      fat: double.parse(fatGrams.toStringAsFixed(0)),
    );
  }
}
```

### 6.5 Master Prompt Synthesis & Injection
The Master Prompt provides personalized context directly into `GeminiVisionService`:

```dart
String buildMasterPrompt({
  required String name,
  required String gender,
  required int age,
  required double heightCm,
  required double weightKg,
  required String activityLevel,
  required int steps,
  required String goal,
  required double bmr,
  required double tdee,
  required double targetCalories,
  required DailyGoals goals,
}) {
  return '''
[PERFIL METABÓLICO DEL USUARIO — NUTRI-TRACKER]
- Nombre: $name
- Biometría: $gender, $age años, ${heightCm.toStringAsFixed(0)} cm, ${weightKg.toStringAsFixed(1)} kg.
- Nivel de actividad: $activityLevel (~$steps pasos/día).
- Objetivo metabólico: $goal.
- Parámetros calóricos: TMB: ${bmr.toStringAsFixed(0)} kcal | TDEE: ${tdee.toStringAsFixed(0)} kcal | Meta: ${targetCalories.toStringAsFixed(0)} kcal.
- Distribución de macros: ${goals.protein.toInt()}g Proteínas, ${goals.carbs.toInt()}g Carbohidratos, ${goals.fat.toInt()}g Grasas.

INSTRUCCIÓN ESPECIAL DE VISIÓN CLÍNICA:
En cada análisis fotográfico, evalúa los alimentos identificados en relación con el perfil metabólico de este usuario. Justifica visualmente el cubicaje teniendo en cuenta el contexto de sus metas calóricas y de macronutrientes.
'''.trim();
}
```

#### Injection into `GeminiVisionService`:
In `lib/services/gemini_vision_service.dart:158-167`:
Accept an optional `String? masterPrompt` parameter in `GeminiVisionService` constructor.
When present:
```dart
final combinedInstruction = masterPrompt != null && masterPrompt.isNotEmpty
    ? '$systemInstruction\n\n$masterPrompt'
    : systemInstruction;

final model = GenerativeModel(
  model: modelName,
  apiKey: apiKey,
  systemInstruction: Content.system(combinedInstruction),
  generationConfig: GenerationConfig(
    responseMimeType: 'application/json',
    responseSchema: schema,
    temperature: 0.2,
  ),
);
```

---

## 7. Migration Roadmap (Database Version 1 -> Version 2)

### 7.1 Atomic Migration Script in `DatabaseService`
Update `_initDatabase()` in `lib/services/database_service.dart`:
1. Change `version: 1` to `version: 2`.
2. Add `onUpgrade: _onUpgrade`.

```dart
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

Future<void> _onCreate(Database db, int version) async {
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

  await _createWeightLogsTable(db);
  await _createUserProfileTable(db);
  await _createIndices(db);
}

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await _createWeightLogsTable(db);
    await _createUserProfileTable(db);
    await _createIndices(db);
  }
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
      name TEXT NOT NULL,
      age INTEGER NOT NULL,
      gender TEXT NOT NULL,
      height_cm REAL NOT NULL,
      current_weight_kg REAL NOT NULL,
      activity_level TEXT NOT NULL,
      goal TEXT NOT NULL,
      estimated_steps INTEGER NOT NULL DEFAULT 8000,
      tmb REAL NOT NULL,
      tdee REAL NOT NULL,
      target_calories REAL NOT NULL,
      target_protein_g REAL NOT NULL,
      target_carbs_g REAL NOT NULL,
      target_fat_g REAL NOT NULL,
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
```

---

## 8. Verification & Quality Assurance Strategy

To satisfy Acceptance Criteria A4 (`flutter analyze` with 0 warnings and thorough test suites):
1. **Unit Test Coverage for Models & Calculations:**
   - `test/models/weight_log_model_test.dart`: Validates `toSqliteMap`, `fromSqliteMap`, defensive clamping on weight (20.0 to 500.0), and the `_sentinel` pattern when clearing notes with `null`.
   - `test/services/metabolic_calculator_test.dart`: Validates Mifflin-St Jeor BMR for men/women, activity factors, calorie targets for fat loss (-500) and muscle gain (+300), and macro distribution.
2. **Persistence & Migration Tests:**
   - `test/services/database_service_v2_test.dart`: Opens in-memory SQLite at `version: 1`, inserts meals, then calls `openDatabase` at `version: 2` to verify zero data loss and successful creation of `weight_logs` and indices.
   - Date range queries (7d, 30d, 90d) verified with boundary timestamps.
3. **Backup/Restore Tests:**
   - `test/services/backup_service_test.dart` updated to verify `weight_logs` JSON export and atomic import.

---

## 9. Conclusion

The Phase 1 architecture is robust, clean, and follows modern Flutter and SQLite local-first best practices. Integrating Phase 2 requirements (R4 weight logs and R3 user metabolic profile) requires:
1. Adding the `WeightLog` model with sentinel pattern.
2. Promoting SQLite schema to `version: 2` with atomic `onUpgrade`.
3. Implementing B-Tree indexed date range queries in `DatabaseService`.
4. Exposing weight mutations and queries in `MealController`.
5. Persisting the User Profile & Master Prompt in SQLite/Preferences, and dynamically injecting it into `GeminiVisionService`.
