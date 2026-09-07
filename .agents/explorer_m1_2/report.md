# Architectural Design Report: Models & Sentinel Pattern for Phase 2 (Milestone 1)
**Project:** Victor Engineer - Food Tracker (NutriTracker Local-First)  
**Author:** M1 Models & Sentinel Explorer (`explorer_m1_2`)  
**Date:** 2026-09-07T16:14:00Z  
**Target Artifacts:** `lib/models/weight_log.dart`, `lib/models/user_profile.dart`  
**Test Artifacts:** `test/models/weight_log_model_test.dart`, `test/models/user_profile_model_test.dart`

---

## 1. Executive Summary

This investigation establishes the definitive specification, mathematical bounds, serialization contracts, and Sentinel pattern implementations for the two core data models of Phase 2 Milestone 1:
1. **`WeightLog` (`lib/models/weight_log.dart`)**: Represents individual historical body weight entries, supporting indexed date-range queries (7d, 30d, 90d), immutable updates, and defensive sanitization.
2. **`UserProfile` (`lib/models/user_profile.dart`)**: Represents the persistent local metabolic profile, capturing biometric inputs (name, age, biological sex, height, weight, activity level, body goal, estimated steps), calculated Mifflin-St Jeor metrics (BMR, TDEE, macro targets), and the contextual AI Master Prompt.

### Core Guarantees
- **Strict Immutability**: Enforced via `@immutable` (from `package:flutter/foundation.dart`), `final` fields, and value equality (`operator ==` and `hashCode`).
- **Sentinel Pattern for Nullable Fields**: Eliminates the Dart optional parameter ambiguity, enabling callers to explicitly clear nullable fields (`notes`, `name`, `masterPrompt`) by passing `null`, while preserving existing values when parameters are omitted.
- **Defensive Sanitization**: Integrated with `ModelSanitizer` to enforce positive bounds (`weight > 0 && <= 500`), valid date parsing, string truncation, and numeric clamping.
- **Full Serialization Parity**: Exposes `toMap()` / `fromMap()`, `toSqliteMap()` / `fromSqliteMap()`, and `toJson()` / `fromJson()` to guarantee seamless interoperability across SQLite queries, `DatabaseService`, and `BackupService`.

---

## 2. Codebase Audit & Existing Model Conventions

### 2.1 Audit of Existing Models
The existing codebase contains three domain models in `lib/models/`:
- **`FoodItem` (`lib/models/food_item.dart`)**: Implements `_sentinel` for `visualJustification` (`String?`), uses `ModelSanitizer` in constructor initializer lists, clamps macros between `0.0` and `9999.0`, and uses UUID v4 as fallback ID.
- **`Meal` (`lib/models/meal.dart`)**: Implements `_sentinel` for `imagePath`, `notes`, and `aiBreakdownJson`. Provides `toSqliteMap()`, `fromSqliteMap()`, `toJson()`, `fromJson()`, and helper `recalculateFromItems()`.
- **`PantryItem` (`lib/models/pantry_item.dart`)**: Implements `_sentinel` for `brand` (`String?`) and `category` (`String?`). Stores `isFavorite` as SQLite integer (`1` or `0`).
- **`DailyGoals` (`lib/models/daily_goals.dart`)**: Encapsulates `calories`, `protein`, `carbs`, `fat`, sanitized via `ModelSanitizer.clampDouble` with custom ranges (calories: 500–10000; macros: 10–1000).

### 2.2 The Sentinel Pattern Mechanics
In Dart, optional named arguments cannot distinguish between an argument omitted by the caller (intending to leave the field untouched) and passing `null` explicitly (intending to wipe out or clear the value).

The project standardizes on a private static object instance:
```dart
static const Object _sentinel = Object();
```
When a nullable parameter (e.g., `Object? notes = _sentinel`) is evaluated in `copyWith`:
1. **Omitted Parameter**: Evaluates `identical(notes, _sentinel) == true` $\rightarrow$ preserves `this.notes`.
2. **Explicit `null`**: Evaluates `identical(null, _sentinel) == false` $\rightarrow$ casts `notes as String?` (yielding `null`), successfully clearing the field.
3. **New Value**: Evaluates `identical('new value', _sentinel) == false` $\rightarrow$ casts `notes as String?` (yielding `'new value'`).

This behavior is strictly verified in existing test `test/models/meal_model_test.dart:76-102`.

---

## 3. Specification: `WeightLog` Model (`lib/models/weight_log.dart`)

### 3.1 Field Requirements & Bounds
| Field | Type | SQLite Column | Bounds & Sanitization | Default / Fallback |
|---|---|---|---|---|
| `id` | `String` | `id TEXT PRIMARY KEY` | Truncated to 128 chars | `const Uuid().v4()` |
| `date` | `DateTime` | `date TEXT NOT NULL` | ISO-8601 string in SQLite | `DateTime.now()` |
| `weight` | `double` | `weight REAL NOT NULL` | Clamped: `min: 0.1, max: 500.0` (weight > 0, <= 500) | Required `num` |
| `notes` | `String?` | `notes TEXT` | Truncated to 2000 chars | `null` |

*Note on Weight Clamping:* The dispatch explicitly requires defensive sanitization: `weight > 0, weight <= 500`. Clamping with `min: 0.1` and `max: 500.0` guarantees strict positivity ($> 0$) and caps astronomical inputs. If clinical adult limits are preferred, `min: 20.0` can also be used, but `min: 0.1` strictly satisfies general positive weight tracking.

### 3.2 Complete Implementation Blueprint
```dart
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'model_sanitizer.dart';

@immutable
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
        weight = ModelSanitizer.clampDouble(weight, min: 0.1, max: 500.0),
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

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'weight': weight,
        'notes': notes,
      };

  factory WeightLog.fromMap(Map<String, dynamic> map) {
    return WeightLog(
      id: map['id']?.toString(),
      date: ModelSanitizer.parseDate(map['date']),
      weight: ModelSanitizer.clampDouble(map['weight'], min: 0.1, max: 500.0),
      notes: map['notes']?.toString(),
    );
  }

  /// SQLite compatibility alias
  Map<String, dynamic> toSqliteMap() => toMap();
  factory WeightLog.fromSqliteMap(Map<String, dynamic> map) => WeightLog.fromMap(map);

  /// JSON / BackupService compatibility alias
  Map<String, dynamic> toJson() => toMap();
  factory WeightLog.fromJson(Map<String, dynamic> json) => WeightLog.fromMap(json);

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
  int get hashCode =>
      id.hashCode ^
      date.toIso8601String().hashCode ^
      weight.hashCode ^
      notes.hashCode;

  @override
  String toString() =>
      'WeightLog(id: $id, date: ${date.toIso8601String()}, weight: $weight, notes: $notes)';
}
```

---

## 4. Specification: `UserProfile` Model (`lib/models/user_profile.dart`)

### 4.1 Schema Reconciliation & Alignment
Reviewing `ORIGINAL_REQUEST.md` (R3, R5), `PROJECT.md`, and `survey_report.md` highlights the necessary fields for a complete nutritional and metabolic profile:
1. **Biometrics (R3)**:
   - `name` (`String?`): Display name for personalization and Master Prompt injection.
   - `age` (`int`): Clamped between `10` and `120`.
   - `gender` (`String`): Biological sex (`male` or `female`).
   - `height` (`double`): Height in cm, clamped between `50.0` and `300.0`.
   - `weight` (`double`): Current weight in kg, clamped between `20.0` and `500.0`.
   - `activityLevel` (`String`): Physical activity level (`sedentary`, `light`, `moderate`, `very_active`).
   - `bodyGoal` (`String`): Fitness goal (`fat_loss`, `maintenance`, `muscle_gain`).
   - `estimatedSteps` (`int`): Estimated daily steps (R3, R5: steps streak card), clamped between `0` and `100000`.
2. **Calculated Metabolic Rates (Mifflin-St Jeor)**:
   - `bmr` (`double`): Basal Metabolic Rate in kcal, clamped between `500.0` and `5000.0`.
   - `tdee` (`double`): Total Daily Energy Expenditure in kcal, clamped between `500.0` and `8000.0`.
3. **Macro Targets**:
   - `targetCalories` (`double`): Target daily calories, clamped `500.0` to `8000.0`.
   - `targetProtein` (`double`): Target daily protein in grams, clamped `10.0` to `1000.0`.
   - `targetCarbs` (`double`): Target daily carbs in grams, clamped `10.0` to `1000.0`.
   - `targetFat` (`double`): Target daily fat in grams, clamped `10.0` to `1000.0`.
4. **Master Prompt & Timestamps**:
   - `masterPrompt` (`String?`): Synthesized clinical instruction for `GeminiVisionService`.
   - `updatedAt` (`DateTime`): Timestamp of creation or last edit.
   - `id` (`String`): Identifier (defaults to `'primary'` or UUID).

### 4.2 Handling Column Alias Variations
To safeguard against naming differences across migrations or peers:
- `height` accepts `map['height'] ?? map['height_cm']`
- `weight` accepts `map['weight'] ?? map['current_weight_kg']`
- `bodyGoal` accepts `map['body_goal'] ?? map['goal']`
- `bmr` accepts `map['bmr'] ?? map['tmb']`
- `targetProtein` accepts `map['target_protein'] ?? map['target_protein_g']`
- `targetCarbs` accepts `map['target_carbs'] ?? map['target_carbs_g']`
- `targetFat` accepts `map['target_fat'] ?? map['target_fat_g']`

### 4.3 Sentinel Pattern in `UserProfile`
The fields `name` and `masterPrompt` are nullable. If a user wants to reset their custom master prompt or remove their name, `copyWith` must support setting them to `null` using `_sentinel`:
```dart
Object? name = _sentinel,
Object? masterPrompt = _sentinel,
```

### 4.4 Complete Implementation Blueprint
```dart
import 'package:flutter/foundation.dart';
import 'daily_goals.dart';
import 'model_sanitizer.dart';
import 'weight_log.dart';

@immutable
class UserProfile {
  final String id;
  final String? name;
  final int age;
  final String gender;
  final double height;
  final double weight;
  final String activityLevel;
  final String bodyGoal;
  final int estimatedSteps;
  final double bmr;
  final double tdee;
  final double targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final String? masterPrompt;
  final DateTime updatedAt;

  static const Object _sentinel = Object();

  UserProfile({
    String? id,
    String? name,
    required int age,
    String gender = 'male',
    required num height,
    required num weight,
    String activityLevel = 'sedentary',
    String bodyGoal = 'maintenance',
    int estimatedSteps = 8000,
    required num bmr,
    required num tdee,
    required num targetCalories,
    required num targetProtein,
    required num targetCarbs,
    required num targetFat,
    String? masterPrompt,
    DateTime? updatedAt,
  })  : id = ModelSanitizer.truncate(id, 128, fallback: 'primary'),
        name = ModelSanitizer.truncateNullable(name, ModelSanitizer.maxNameLength),
        age = age.clamp(10, 120),
        gender = _sanitizeGender(gender),
        height = ModelSanitizer.clampDouble(height, min: 50.0, max: 300.0),
        weight = ModelSanitizer.clampDouble(weight, min: 20.0, max: 500.0),
        activityLevel = _sanitizeActivity(activityLevel),
        bodyGoal = _sanitizeGoal(bodyGoal),
        estimatedSteps = estimatedSteps.clamp(0, 100000),
        bmr = ModelSanitizer.clampDouble(bmr, min: 500.0, max: 5000.0),
        tdee = ModelSanitizer.clampDouble(tdee, min: 500.0, max: 8000.0),
        targetCalories = ModelSanitizer.clampDouble(targetCalories, min: 500.0, max: 8000.0),
        targetProtein = ModelSanitizer.clampDouble(targetProtein, min: 10.0, max: 1000.0),
        targetCarbs = ModelSanitizer.clampDouble(targetCarbs, min: 10.0, max: 1000.0),
        targetFat = ModelSanitizer.clampDouble(targetFat, min: 10.0, max: 1000.0),
        masterPrompt = ModelSanitizer.truncateNullable(masterPrompt, ModelSanitizer.maxJsonLength),
        updatedAt = updatedAt ?? DateTime.now();

  static String _sanitizeGender(String? raw) {
    if (raw == null) return 'male';
    final lower = raw.trim().toLowerCase();
    if (lower == 'female' || lower == 'femenino' || lower == 'mujer') return 'female';
    return 'male';
  }

  static String _sanitizeActivity(String? raw) {
    if (raw == null) return 'sedentary';
    final lower = raw.trim().toLowerCase();
    if (lower.contains('light') || lower.contains('ligero')) return 'light';
    if (lower.contains('moderat') || lower.contains('moderado')) return 'moderate';
    if (lower.contains('very') || lower.contains('muy')) return 'very_active';
    return 'sedentary';
  }

  static String _sanitizeGoal(String? raw) {
    if (raw == null) return 'maintenance';
    final lower = raw.trim().toLowerCase();
    if (lower.contains('fat') || lower.contains('perdid') || lower.contains('déficit')) return 'fat_loss';
    if (lower.contains('gain') || lower.contains('gananc') || lower.contains('superávit')) return 'muscle_gain';
    return 'maintenance';
  }

  UserProfile copyWith({
    String? id,
    Object? name = _sentinel,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? activityLevel,
    String? bodyGoal,
    int? estimatedSteps,
    double? bmr,
    double? tdee,
    double? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
    Object? masterPrompt = _sentinel,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: identical(name, _sentinel) ? this.name : (name as String?),
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      bodyGoal: bodyGoal ?? this.bodyGoal,
      estimatedSteps: estimatedSteps ?? this.estimatedSteps,
      bmr: bmr ?? this.bmr,
      tdee: tdee ?? this.tdee,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFat: targetFat ?? this.targetFat,
      masterPrompt: identical(masterPrompt, _sentinel)
          ? this.masterPrompt
          : (masterPrompt as String?),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Direct conversion to DailyGoals for effortless synchronization
  DailyGoals get dailyGoals => DailyGoals(
        calories: targetCalories,
        protein: targetProtein,
        carbs: targetCarbs,
        fat: targetFat,
      );

  /// Synchronous conversion to WeightLog when profile weight is updated
  WeightLog toWeightLog({String? notes}) => WeightLog(
        weight: weight,
        date: updatedAt,
        notes: notes ?? 'Registro automático desde actualización de perfil',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'age': age,
        'gender': gender,
        'height': height,
        'weight': weight,
        'activity_level': activityLevel,
        'body_goal': bodyGoal,
        'estimated_steps': estimatedSteps,
        'bmr': bmr,
        'tdee': tdee,
        'target_calories': targetCalories,
        'target_protein': targetProtein,
        'target_carbs': targetCarbs,
        'target_fat': targetFat,
        'master_prompt': masterPrompt,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id']?.toString(),
      name: map['name']?.toString(),
      age: (map['age'] as num?)?.toInt() ?? 25,
      gender: map['gender']?.toString() ?? 'male',
      height: ModelSanitizer.clampDouble(
        map['height'] ?? map['height_cm'],
        min: 50.0,
        max: 300.0,
      ),
      weight: ModelSanitizer.clampDouble(
        map['weight'] ?? map['current_weight_kg'],
        min: 20.0,
        max: 500.0,
      ),
      activityLevel: (map['activity_level'] ?? 'sedentary').toString(),
      bodyGoal: (map['body_goal'] ?? map['goal'] ?? 'maintenance').toString(),
      estimatedSteps: (map['estimated_steps'] as num?)?.toInt() ?? 8000,
      bmr: ModelSanitizer.clampDouble(
        map['bmr'] ?? map['tmb'],
        min: 500.0,
        max: 5000.0,
      ),
      tdee: ModelSanitizer.clampDouble(
        map['tdee'],
        min: 500.0,
        max: 8000.0,
      ),
      targetCalories: ModelSanitizer.clampDouble(
        map['target_calories'],
        min: 500.0,
        max: 8000.0,
      ),
      targetProtein: ModelSanitizer.clampDouble(
        map['target_protein'] ?? map['target_protein_g'],
        min: 10.0,
        max: 1000.0,
      ),
      targetCarbs: ModelSanitizer.clampDouble(
        map['target_carbs'] ?? map['target_carbs_g'],
        min: 10.0,
        max: 1000.0,
      ),
      targetFat: ModelSanitizer.clampDouble(
        map['target_fat'] ?? map['target_fat_g'],
        min: 10.0,
        max: 1000.0,
      ),
      masterPrompt: map['master_prompt']?.toString(),
      updatedAt: ModelSanitizer.parseDate(map['updated_at']),
    );
  }

  /// SQLite compatibility alias
  Map<String, dynamic> toSqliteMap() => toMap();
  factory UserProfile.fromSqliteMap(Map<String, dynamic> map) => UserProfile.fromMap(map);

  /// JSON / BackupService compatibility alias
  Map<String, dynamic> toJson() => toMap();
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile.fromMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          age == other.age &&
          gender == other.gender &&
          height == other.height &&
          weight == other.weight &&
          activityLevel == other.activityLevel &&
          bodyGoal == other.bodyGoal &&
          estimatedSteps == other.estimatedSteps &&
          bmr == other.bmr &&
          tdee == other.tdee &&
          targetCalories == other.targetCalories &&
          targetProtein == other.targetProtein &&
          targetCarbs == other.targetCarbs &&
          targetFat == other.targetFat &&
          masterPrompt == other.masterPrompt &&
          updatedAt.toIso8601String() == other.updatedAt.toIso8601String();

  @override
  int get hashCode =>
      id.hashCode ^
      (name?.hashCode ?? 0) ^
      age.hashCode ^
      gender.hashCode ^
      height.hashCode ^
      weight.hashCode ^
      activityLevel.hashCode ^
      bodyGoal.hashCode ^
      estimatedSteps.hashCode ^
      bmr.hashCode ^
      tdee.hashCode ^
      targetCalories.hashCode ^
      targetProtein.hashCode ^
      targetCarbs.hashCode ^
      targetFat.hashCode ^
      (masterPrompt?.hashCode ?? 0) ^
      updatedAt.toIso8601String().hashCode;

  @override
  String toString() =>
      'UserProfile(id: $id, name: $name, age: $age, gender: $gender, height: $height, weight: $weight, tdee: $tdee, targetCalories: $targetCalories)';
}
```

---

## 5. SQLite Table Schema Compatibility

To ensure seamless SQLite DDL execution, the table definition recommended for `lib/services/database_service.dart` in Milestone 1 is:

### 5.1 `weight_logs` Table & Index
```sql
CREATE TABLE IF NOT EXISTS weight_logs (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  weight REAL NOT NULL,
  notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);
```

### 5.2 `user_profile` Table
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
  master_prompt TEXT,
  updated_at TEXT NOT NULL
);
```

---

## 6. Unit Testing Strategy

To ensure zero regressions and pass Acceptance Criteria A4, two dedicated unit test suites must be created:

### 6.1 `test/models/weight_log_model_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/weight_log.dart';

void main() {
  group('WeightLog Model Tests', () {
    test('toMap y fromMap preservan todos los campos fielmente', () {
      final now = DateTime(2026, 9, 7, 10, 15);
      final log = WeightLog(
        id: 'weight-uuid-101',
        date: now,
        weight: 78.4,
        notes: 'Pesaje en ayunas tras cardio matutino',
      );

      final map = log.toMap();
      expect(map['id'], equals('weight-uuid-101'));
      expect(map['date'], equals(now.toIso8601String()));
      expect(map['weight'], equals(78.4));
      expect(map['notes'], equals('Pesaje en ayunas tras cardio matutino'));

      final restored = WeightLog.fromMap(map);
      expect(restored, equals(log));
      expect(restored.id, equals(log.id));
      expect(restored.date, equals(log.date));
      expect(restored.weight, equals(log.weight));
      expect(restored.notes, equals(log.notes));
    });

    test('Límites defensivos se aplican a pesos inválidos y notas desmedidas', () {
      final superLongNotes = 'W' * 3000;
      final negativeLog = WeightLog(
        weight: -15.0,
        notes: superLongNotes,
      );

      expect(negativeLog.weight, equals(0.1));
      expect(negativeLog.notes!.length, equals(2000));
      expect(negativeLog.id, isNotEmpty);

      final excessiveLog = WeightLog(weight: 999.0);
      expect(excessiveLog.weight, equals(500.0));
    });

    test('copyWith con Sentinel borra notas al pasar null explícito', () {
      final log = WeightLog(
        id: 'wl-1',
        weight: 80.0,
        notes: 'Nota existente',
      );

      final cleared = log.copyWith(notes: null);
      expect(cleared.notes, isNull);
      expect(cleared.weight, equals(80.0));

      final updatedWeight = log.copyWith(weight: 79.2);
      expect(updatedWeight.weight, equals(79.2));
      expect(updatedWeight.notes, equals('Nota existente'));
    });

    test('Igualdad y hashCode respetan los valores de los campos', () {
      final date = DateTime(2026, 9, 7, 8, 0);
      final logA = WeightLog(id: 'w1', date: date, weight: 70.0, notes: 'A');
      final logB = WeightLog(id: 'w1', date: date, weight: 70.0, notes: 'A');
      final logC = WeightLog(id: 'w2', date: date, weight: 70.0, notes: 'A');

      expect(logA, equals(logB));
      expect(logA.hashCode, equals(logB.hashCode));
      expect(logA == logC, isFalse);
    });
  });
}
```

### 6.2 `test/models/user_profile_model_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/user_profile.dart';

void main() {
  group('UserProfile Model Tests', () {
    test('toMap y fromMap realizan ciclo de serialización idéntico', () {
      final now = DateTime(2026, 9, 7, 12, 0);
      final profile = UserProfile(
        id: 'primary',
        name: 'Victor Engineer',
        age: 28,
        gender: 'male',
        height: 178.0,
        weight: 76.5,
        activityLevel: 'moderate',
        bodyGoal: 'fat_loss',
        estimatedSteps: 10000,
        bmr: 1750.0,
        tdee: 2712.5,
        targetCalories: 2212.5,
        targetProtein: 153.0,
        targetCarbs: 245.0,
        targetFat: 61.0,
        masterPrompt: 'Prompt de sistema para IA',
        updatedAt: now,
      );

      final map = profile.toMap();
      expect(map['name'], equals('Victor Engineer'));
      expect(map['bmr'], equals(1750.0));
      expect(map['tdee'], equals(2712.5));
      expect(map['target_calories'], equals(2212.5));

      final restored = UserProfile.fromMap(map);
      expect(restored, equals(profile));
      expect(restored.dailyGoals.calories, equals(2212.5));
      expect(restored.dailyGoals.protein, equals(153.0));
    });

    test('Límites defensivos se aplican a entradas desmedidas', () {
      final invalidProfile = UserProfile(
        age: 150,
        height: 450.0,
        weight: 1200.0,
        bmr: 99999.0,
        tdee: 99999.0,
        targetCalories: 99999.0,
        targetProtein: 99999.0,
        targetCarbs: 99999.0,
        targetFat: 99999.0,
      );

      expect(invalidProfile.age, equals(120));
      expect(invalidProfile.height, equals(300.0));
      expect(invalidProfile.weight, equals(500.0));
      expect(invalidProfile.bmr, equals(5000.0));
      expect(invalidProfile.tdee, equals(8000.0));
      expect(invalidProfile.targetCalories, equals(8000.0));
      expect(invalidProfile.targetProtein, equals(1000.0));
    });

    test('copyWith con Sentinel borra name y masterPrompt con null explícito', () {
      final profile = UserProfile(
        name: 'Victor',
        age: 25,
        height: 175.0,
        weight: 70.0,
        bmr: 1600.0,
        tdee: 2200.0,
        targetCalories: 2000.0,
        targetProtein: 140.0,
        targetCarbs: 220.0,
        targetFat: 65.0,
        masterPrompt: 'Prompt guardado',
      );

      final cleared = profile.copyWith(name: null, masterPrompt: null);
      expect(cleared.name, isNull);
      expect(cleared.masterPrompt, isNull);
      expect(cleared.age, equals(25));

      final updatedAge = profile.copyWith(age: 26);
      expect(updatedAge.name, equals('Victor'));
      expect(updatedAge.masterPrompt, equals('Prompt guardado'));
    });

    test('toWeightLog genera un registro fiel sincronizado con el perfil', () {
      final profile = UserProfile(
        weight: 74.2,
        age: 30,
        height: 170.0,
        bmr: 1600.0,
        tdee: 2000.0,
        targetCalories: 2000.0,
        targetProtein: 140.0,
        targetCarbs: 220.0,
        targetFat: 65.0,
      );

      final weightLog = profile.toWeightLog();
      expect(weightLog.weight, equals(74.2));
      expect(weightLog.notes, contains('perfil'));
    });
  });
}
```

---

## 7. Next Steps for Implementation Agents

1. **Implementer M1**:
   - Create `lib/models/weight_log.dart` verbatim according to Section 3.2 (~70 LoC).
   - Create `lib/models/user_profile.dart` verbatim according to Section 4.4 (~150 LoC).
   - Create `test/models/weight_log_model_test.dart` and `test/models/user_profile_model_test.dart` according to Section 6.
   - Run `flutter test test/models/` to guarantee 100% test pass rate.
2. **Database Implementer M1**:
   - Add `weight_logs` and `user_profile` table definitions to `DatabaseService` (`_onCreate` and `_onUpgrade`).
   - Implement date-range queries `getWeightLogsByRange` utilizing `idx_weight_logs_date`.
3. **Backup Implementer M1**:
   - Include `weight_logs` and `user_profile` in `BackupService.exportToJsonString` and `importFromJsonString`.
