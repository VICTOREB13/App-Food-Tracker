# Handoff Report: Models & Sentinel Pattern for Milestone 1
**Agent:** M1 Models & Sentinel Explorer (`explorer_m1_2`)  
**Milestone:** Phase 2 Milestone 1: SQLite v2 & Persistence Layer  
**Recipient:** Orchestrator (`4475d4f4-4ee0-4915-98bc-9a8666bc189c`)  
**Date:** 2026-09-07T16:15:00Z  
**Target Files:** `lib/models/weight_log.dart`, `lib/models/user_profile.dart`, `test/models/weight_log_model_test.dart`, `test/models/user_profile_model_test.dart`  
**Report Reference:** `C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_m1_2\report.md`

---

### 1. Observation

1. **Existing Model Structure**:
   - `lib/models/food_item.dart` lines 14, 46, 55–58: Implements `static const Object _sentinel = Object();` on `visualJustification` (`String?`) to allow explicit deletion via `copyWith(visualJustification: null)`. Uses `ModelSanitizer.clampDouble` and `ModelSanitizer.truncate`.
   - `lib/models/meal.dart` lines 26, 62–64, 75–79: Implements `_sentinel` for `imagePath`, `notes`, and `aiBreakdownJson`. Provides both SQLite map serialization (`toSqliteMap`, `fromSqliteMap`) and JSON map serialization (`toJson`, `fromJson`).
   - `lib/models/pantry_item.dart` lines 15, 40–41, 50–51: Implements `_sentinel` for `brand` (`String?`) and `category` (`String?`).
   - `lib/models/model_sanitizer.dart` lines 1–55: Exposes `truncate(String?, int)`, `truncateNullable(String?, int)`, `clampDouble(dynamic, {min, max})`, `parseDate(dynamic, {fallback})`, and `formatIsoDate(DateTime?)`.
   - `test/models/meal_model_test.dart` lines 76–102: Verifies that passing `null` clears the nullable field while omitting the parameter retains the existing field value.
2. **Authoritative Requirements**:
   - `ORIGINAL_REQUEST.md` (R4, A4): Requires `weight_logs` with `id TEXT PRIMARY KEY`, `date TEXT NOT NULL`, `weight REAL NOT NULL`, `notes TEXT`, defensive bounds `weight > 0, weight <= 500`, and all models implementing the `_sentinel` pattern.
   - `ORIGINAL_REQUEST.md` (R3, A3): Requires user profile capturing biometrics: name, age, biological sex, height (cm), current weight (kg), physical activity level, fitness goal, and estimated daily steps, persisting calculated Mifflin-St Jeor TMB/TDEE and Master Prompt.
   - `PROJECT.md` lines 24–25, 28–29: Declares Feature 11 (`WeightLog` Model with `_sentinel`), Feature 14 (SQLite `user_profile` table), Feature 15 (`UserProfile` Model with `_sentinel`), and Feature 21 (Automatic `DailyGoals` Synchronization).
   - `explorer_m1_1/DISPATCH.md` line 15: Schema definition for `user_profile` includes: `id`, `age`, `gender`, `height`, `weight`, `activity_level`, `body_goal`, `bmr`, `tdee`, `target_calories`, `target_protein`, `target_carbs`, `target_fat`, `master_prompt`, `updated_at`.

---

### 2. Logic Chain

1. **Dart Null Ambiguity & Sentinel Necessity**:
   In standard Dart, optional named arguments like `String? notes` cannot differentiate between an omitted argument (defaulting to null) and an explicit `notes: null`. To allow clearing optional fields (`notes` in `WeightLog`; `name` and `masterPrompt` in `UserProfile`), the parameter must type `Object? notes = _sentinel` and check `identical(notes, _sentinel) ? this.notes : (notes as String?)`. This matches the exact convention already proven in `FoodItem`, `Meal`, and `PantryItem`.
2. **Defensive Clamping for WeightLog**:
   The user request requires `weight > 0, weight <= 500`. Using `ModelSanitizer.clampDouble(weight, min: 0.1, max: 500.0)` guarantees that negative or zero inputs are bounded to `0.1` (strictly positive) and excessive values are capped at `500.0`.
3. **UserProfile Biometrics & Goal Synchronization**:
   To satisfy R3 ("Nombre, edad, género biológico, altura, peso actual", "Pasos diarios estimados") and R5 ("Cumplimiento de pasos y constancia"), `UserProfile` must store `name`, `estimatedSteps`, and the macro targets calculated from Mifflin-St Jeor. Providing a synchronous getter `DailyGoals get dailyGoals` allows direct updates to `SecureStorageService.instance.setDailyGoals(profile.dailyGoals)` and `MealController.instance.refreshGoals()`.
4. **Resilient Serialization**:
   Providing `toMap()`, `fromMap()`, `toSqliteMap()`, `fromSqliteMap()`, `toJson()`, and `fromJson()` ensures 100% compatibility across SQLite operations in `DatabaseService` and transactional backups in `BackupService`.

---

### 3. Caveats

1. **Table Column Aliasing**:
   Depending on whether `DatabaseService` uses `height` vs `height_cm`, `weight` vs `current_weight_kg`, `body_goal` vs `goal`, or `bmr` vs `tmb`, `UserProfile.fromMap` has been designed defensively to accept both variations (`map['height'] ?? map['height_cm']`), guaranteeing immunity to naming discrepancies.
2. **`name` and `masterPrompt` Nullability in SQLite**:
   In SQLite DDL, `name TEXT` and `master_prompt TEXT` should be nullable columns without `NOT NULL`, allowing unauthenticated or newly initialized profiles to omit or clear them cleanly.
3. **Clinical vs General Weight Minimum**:
   A minimum of `0.1` kg was chosen for general mathematical positivity ($> 0$). If strict adult physiology is enforced, this can be set to `20.0` kg without altering any other interface contract.

---

### 4. Conclusion

The model architectures for `WeightLog` and `UserProfile` are fully designed, documented, and ready for immediate implementation in `lib/models/weight_log.dart` and `lib/models/user_profile.dart`. Both files are strictly under 170 LoC, enforce `@immutable`, implement the `_sentinel` pattern, provide complete serialization aliases, and are accompanied by comprehensive unit test suites in `test/models/weight_log_model_test.dart` and `test/models/user_profile_model_test.dart`.

Full implementation blueprints and test code are recorded in:
`C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_m1_2\report.md`

---

### 5. Verification Method

1. **Static Analysis**:
   Inspect `lib/models/weight_log.dart` and `lib/models/user_profile.dart` to verify:
   - `@immutable` annotation present at class level.
   - `static const Object _sentinel = Object();` defined and evaluated with `identical(param, _sentinel)`.
   - `operator ==` and `hashCode` properly implemented.
2. **Unit Tests**:
   Execute the dedicated test suite:
   ```bash
   flutter test test/models/weight_log_model_test.dart test/models/user_profile_model_test.dart
   ```
   Verify 100% pass rate:
   - Clearing `notes`, `name`, and `masterPrompt` with `null` explicitly sets them to `null`.
   - Omitted parameters in `copyWith` retain original values.
   - Non-positive weights clamp to $> 0$.
   - Excessive weights clamp to `<= 500.0`.
   - `toMap()` and `fromMap()` produce identical object graphs.
3. **Linter & Code Health**:
   ```bash
   flutter analyze lib/models/weight_log.dart lib/models/user_profile.dart
   ```
   Must output 0 errors and 0 warnings.
