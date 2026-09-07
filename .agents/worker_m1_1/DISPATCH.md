## 2026-09-07T16:16:46Z
You are the Lead Implementation Worker for Phase 2 Milestone 1: SQLite v2 & Persistence Layer.
Your working directory is: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\worker_m1_1

MANDATORY: You MUST read the authoritative user request at: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\ORIGINAL_REQUEST.md before doing anything else.

Read the detailed implementation blueprints from the 3 Explorer reports:
- Schema & Migration Blueprint: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_m1_1\report.md
- Models & Sentinel Blueprint: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_m1_2\report.md
- Integration & Backup Blueprint: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_m1_3\report.md
- Project Plan: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\orchestrator_1\PROJECT.md

Exclusive Write Ownership:
You own and may modify or create the following files exclusively:
- lib/models/weight_log.dart
- lib/models/user_profile.dart
- lib/services/database_service.dart
- lib/controllers/meal_controller.dart
- lib/services/backup_service.dart
- test/models/weight_log_model_test.dart
- test/models/user_profile_model_test.dart
- test/services/database_service_v2_test.dart
- test/controllers/meal_controller_weight_test.dart
- test/services/backup_service_v2_test.dart

Implementation Tasks:
1. `lib/models/weight_log.dart`:
   - `@immutable`, `id` (String), `date` (DateTime), `weight` (double), `notes` (String?).
   - `static const Object _sentinel = Object();` on `copyWith(notes: _sentinel)`.
   - `ModelSanitizer.clampDouble(weight, min: 0.1, max: 500.0)`.
   - `toMap()`, `fromMap()`, `toSqliteMap()`, `fromSqliteMap()`, `toJson()`, `fromJson()`, `operator ==`, `hashCode`.
2. `lib/models/user_profile.dart`:
   - `@immutable`, biometrics (name, age, gender, height, weight, activityLevel, bodyGoal, estimatedSteps), Mifflin-St Jeor fields (bmr, tdee, targetCalories, targetProtein, targetCarbs, targetFat), `masterPrompt` (String?), `updatedAt` (DateTime).
   - `_sentinel` on `name` and `masterPrompt` in `copyWith`.
   - `DailyGoals get dailyGoals`, `WeightLog toWeightLog()`, tolerance for column aliasing.
   - Serialization suites, `operator ==`, `hashCode`.
3. `lib/services/database_service.dart`:
   - Upgrade to `version: 2` with `onUpgrade: _onUpgrade`.
   - Tables: `weight_logs` with B-Tree index `idx_weight_logs_date ON weight_logs(date)`.
   - Tables: `user_profile` table.
   - Ensure fresh installs (`_onCreate`) also create `weight_logs`, `user_profile`, and their indices.
   - CRUD methods: `insertWeightLog`, `getWeightLogsByRange(DateTime start, DateTime end)`, `getWeightLogsLastDays(int days)`, `getLatestWeightLog()`, `deleteWeightLog(String id)`.
   - CRUD methods: `saveUserProfile(UserProfile profile)`, `getUserProfile()`.
4. `lib/controllers/meal_controller.dart`:
   - Keep file strictly < 300 LoC (currently 116, should reach ~154 LoC).
   - Add state: `List<WeightLog> _weightLogs`, `WeightLog? _latestWeightLog`.
   - Add methods: `loadWeightLogs({int days = 30})`, `recordWeight(double weight, {String? notes, DateTime? date})`, `deleteWeight(String id)`.
5. `lib/services/backup_service.dart`:
   - Include `weight_logs` and `user_profile` in JSON export.
   - Transactional import with `ConflictAlgorithm.replace` and 100% backward compatibility for Phase 1 backups.
6. Unit Tests:
   - Implement unit tests covering models, sentinel behavior, SQLite v2 migration, range queries, controller weight reactivity, and backup/restore.
   - Run the tests and ensure they pass with 0 errors.

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Output Requirements:
- Write your complete handoff report to: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\worker_m1_1\handoff.md
- Include passing test commands, results, and line counts.
- Send a completion message via send_message when finished.
