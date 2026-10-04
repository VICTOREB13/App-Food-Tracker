## 2026-10-04T21:57:56Z
You are Backend-Architect for Food Tracker v1.2.4.
Your working directory is:
C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\teamwork\backend_architect_1

Read the authoritative requirements and architecture:
1. C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\teamwork\ORIGINAL_REQUEST.md
2. C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\teamwork\explorer_backend\handoff.md
3. C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\teamwork\explorer_pantry\handoff.md
4. C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\artifacts\planning\task.md
5. C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\artifacts\architecture\abstractions.md
6. C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\artifacts\architecture\api_spec.md
7. Relevant skills: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\skills\backend-architect\SKILL.md and C:\Users\vmesp\.gemini\config\skills\sqlite-local-first-flutter\SKILL.md

Exclusive Write Boundaries (DO NOT touch frontend UI files):
- pubspec.yaml
- lib/services/backup_normalizer.dart (new file, < 250 LoC)
- lib/services/backup_service.dart (< 250 LoC)
- lib/models/pantry_item.dart (< 200 LoC)
- lib/database/database_connection_factory.dart
- lib/database/database_schema.dart
- test/services/backup_normalizer_test.dart (new file)
- test/models/pantry_item_portion_scaling_test.dart (new file)

Tasks to Implement:
1. Version & Dependencies:
   - In pubspec.yaml: bump version to 1.2.4+1.
   - In pubspec.yaml: add `file_picker: ^8.1.7` under dependencies.
   - Run `flutter pub get`.
2. BackupNormalizer (`lib/services/backup_normalizer.dart` < 250 LoC):
   - Adaptive normalization supporting legacy backups (v1.0.4 and prior):
     - If root is a raw JSON List `[...]`, wrap into `{"meals": [...]}`.
     - Translate legacy keys: `comidas` -> `meals`, `despensa` -> `pantry_items`, `perfil` -> `user_profile`, `pesos` -> `weight_logs`, `plantillas` -> `meal_templates`, `ayuno` -> `fasting_logs`, `vajilla` -> `calibrated_dishware`.
     - Null-safe fallback and structure validation without throwing FormatException on missing fields.
     - Expose `decodeAndNormalize` callable directly or via `Isolate.run`.
3. BackupService (`lib/services/backup_service.dart` < 250 LoC):
   - Execute JSON decoding and normalization using `Isolate.run(() => BackupNormalizer.decodeAndNormalize(jsonString))`.
   - Persist entities into SQLite using `db.transaction((txn) async { final batch = txn.batch(); ... await batch.commit(noResult: true); })` for 60 FPS smooth import without UI thread stutter.
4. SQLite Schema v4 & PantryItem Model:
   - Bump DB version from 3 to 4 in `DatabaseConnectionFactory.dart`.
   - In `DatabaseSchema.dart`: add `package_weight REAL` in `createPantryTable`, and in `onUpgrade` add `_safeAddColumn(db, 'pantry_items', 'package_weight REAL')` when `oldVersion < 4`.
   - In `PantryItem` (`lib/models/pantry_item.dart`):
     - Add `final double? packageWeight;` (e.g., 500.0g net weight).
     - Update constructor, `copyWith` (Sentinel pattern), `toSqliteMap`, `fromSqliteMap` with backwards compatibility (default null).
     - Add method `FoodItem toScaledFoodItem({required double gramsConsumed})`:
       `final factor = gramsConsumed / (servingSize > 0 ? servingSize : 100.0);`
       scaling calories, protein, carbs, fat, fiber, sodium, sugar proportionally.
5. Unit Tests:
   - Create `test/services/backup_normalizer_test.dart` testing: raw array wrapping, Spanish key translation, modern backup parsing, corrupt JSON handling, and Isolate decoding.
   - Create `test/models/pantry_item_portion_scaling_test.dart` testing: `packageWeight` serialization, `toScaledFoodItem` calculation accuracy, and SQLite migration v3 -> v4.
   - Run `flutter test test/services/backup_normalizer_test.dart` and `flutter test test/models/pantry_item_portion_scaling_test.dart` and existing backup tests.
   - Run `flutter analyze` to ensure 0 errors and 0 warnings.
6. Verify LoC:
   - All created and modified files must be strictly < 300 LoC.
