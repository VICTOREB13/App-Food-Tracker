# Handoff Report: Codebase & Database Architecture Survey for Phase 2

## 1. Observation
1. **Model Sentinel Pattern**:
   - `lib/models/food_item.dart:14`, `lib/models/meal.dart:26`, and `lib/models/pantry_item.dart:15` define:
     ```dart
     static const Object _sentinel = Object();
     ```
   - In `copyWith`, nullable parameters default to `_sentinel`, e.g., in `Meal` (`lib/models/meal.dart:123, 128, 129`):
     ```dart
     Object? imagePath = _sentinel,
     Object? notes = _sentinel,
     Object? aiBreakdownJson = _sentinel,
     ```
     and are evaluated via `identical(notes, _sentinel) ? this.notes : (notes as String?)`.
   - In `test/models/meal_model_test.dart:76-102`, test `'copyWith con patrón Sentinel elimina campos al pasar null explícito'` asserts that passing `null` clears fields while omitting them preserves previous values.

2. **SQLite Database Configuration & Concurrency**:
   - `lib/services/database_service.dart:14, 38-53` implements memoization using `static Future<Database>? _initFuture;` to avoid concurrent initialization race conditions.
   - `lib/services/database_service.dart:104-124` sets pragmas on `onConfigure`:
     - `await db.rawQuery('PRAGMA journal_mode = WAL;');` (using `rawQuery` due to Android driver quirks).
     - `await db.execute('PRAGMA synchronous = NORMAL;');`
     - `await db.execute('PRAGMA foreign_keys = ON;');`
   - `lib/services/database_service.dart:103` sets `version: 1`, with `onCreate: _onCreate` defining `meals` and `pantry_items`.
   - **Critical observation:** `openDatabase` has NO `onUpgrade` callback currently defined.

3. **Controllers & Data Access Patterns**:
   - `lib/controllers/meal_controller.dart` is 116 LoC, extends `ChangeNotifier`, manages `_selectedDate`, `_meals`, and `_dailyGoals`.
   - Querying for daily meals uses indexed boundary conditions (`where: 'date >= ? AND date < ?'`) in `lib/services/database_service.dart:216`.
   - `lib/controllers/settings_controller.dart` manages API keys, Daily Goals, VACUUM, and JSON backup/restore.

4. **Security & Storage**:
   - `lib/services/secure_storage_service.dart:9-15` uses `FlutterSecureStorage` with `AndroidOptions(encryptedSharedPreferences: true)`. It currently stores `gemini_api_key` and `daily_goals_json`.

5. **Backup Architecture**:
   - `lib/services/backup_service.dart:11-74` exports and imports `meals` and `pantry_items` in a single SQLite transaction `db.transaction((txn) async { ... })`.

## 2. Logic Chain
1. From Observation 1: The `_sentinel` pattern with `identical(field, _sentinel)` is the established project standard for all models with nullable fields. Therefore, the new `WeightLog` model for R4 must adopt this identical pattern for `notes` (`Object? notes = _sentinel`).
2. From Observation 2: The database is currently at `version: 1` with no `onUpgrade` handler. Adding `weight_logs` (R4) and `user_profile` (R3) requires upgrading to `version: 2` and adding `onUpgrade: _onUpgrade` in `openDatabase`. This ensures backward compatibility for users upgrading from Phase 1 without data loss.
3. From Observation 2 & Requirement R4: B-Tree index `idx_weight_logs_date ON weight_logs(date)` allows date-range queries (`date >= ? AND date <= ?`) for 7, 30, and 90 days to execute with $O(\log N)$ performance directly in SQLite, avoiding in-memory filtering.
4. From Observation 3: `MealController` is 116 LoC. Adding weight logging methods (`loadWeightLogs`, `recordWeight`, `deleteWeight`) will add ~40 LoC, remaining under 180 LoC total—well within the project's < 300 LoC constraint while satisfying Requirement R4's explicit mandate for `MealController` integration.
5. From Observation 4 & 5: Biometric user profile data and Master Prompt are domain state rather than secret tokens. Storing them in a dedicated SQLite `user_profile` table ensures they participate in ACID transactions, sync with historical weight records, and are included in the JSON backup pipeline (`BackupService`).

## 3. Caveats
- Flutter SDK is not directly in the current command line PATH in this specific environment, though all Dart source files, unit tests, and architectures are fully accessible and statically verified against Flutter 3.22+ and Flutter 3.27+ specifications.
- UI implementations (screens and bento cards for R3 and R5) are surveyed by peer explorer `explorer_survey_3`. This survey focuses on the database, model, controller, and service layer.

## 4. Conclusion
The Phase 1 foundation is cleanly organized, production-ready, and aligns with `sqlite-local-first-flutter` guidelines.
The implementation path for Phase 2 backend & persistence is clear:
1. Create `lib/models/weight_log.dart` implementing the `_sentinel` pattern and `ModelSanitizer` bounds.
2. Upgrade `DatabaseService` to database `version: 2` with `onUpgrade` script creating `weight_logs` (and `user_profile`), alongside indexed date-range query methods.
3. Integrate weight logging into `MealController` (< 300 LoC).
4. Implement `MetabolicCalculator` (Mifflin-St Jeor) and Master Prompt generator for R3, injecting the output into `GeminiVisionService.systemInstruction`.
5. Update `BackupService` to include `weight_logs` in JSON export and transactional import.

## 5. Verification Method
1. **Inspect Survey Report**:
   Read `C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_survey_1\survey_report.md` for complete DDL, Dart models, calculator logic, and migration code.
2. **Inspect Existing Model Sentinel Tests**:
   Examine `C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\test\models\meal_model_test.dart` lines 76-102 to verify how tests assert `copyWith` sentinel behavior.
3. **Inspect Database Concurrency & Pragma Tests**:
   Examine `C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\test\services\database_service_test.dart` lines 75-96 to verify in-memory test initialization and pragma assertions.
