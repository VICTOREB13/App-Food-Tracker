# Handoff Report: Milestone 1 SQLite v2 Schema & Persistence Layer
**Author:** M1 SQLite & Schema Explorer (`explorer_m1_1`)  
**Working Directory:** `C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_m1_1`  
**Date:** 2026-09-07T16:17:00Z  
**Recipient:** Orchestrator (`parent`, id: `4475d4f4-4ee0-4915-98bc-9a8666bc189c`)

---

## 1. Observation
1. **Current SQLite Version & Upgrade Callback**:
   In `lib/services/database_service.dart:101-127`:
   ```dart
   return await openDatabase(
     dbPath,
     version: 1,
     onConfigure: (db) async { ... },
     onCreate: _onCreate,
   );
   ```
   `version` is hardcoded to `1` and there is no `onUpgrade` parameter passed to `openDatabase`.
2. **PRAGMA Execution Pattern**:
   In `lib/services/database_service.dart:107-123`:
   - `PRAGMA journal_mode = WAL;` is executed via `db.rawQuery()`.
   - `PRAGMA synchronous = NORMAL;` and `PRAGMA foreign_keys = ON;` are executed via `db.execute()`.
   - All pragmas are currently configured inside an anonymous callback.
3. **Existing Tables and Indices**:
   In `lib/services/database_service.dart:129-171`:
   - Tables created in `_onCreate`: `meals` and `pantry_items`.
   - Indices created: `idx_meals_date`, `idx_meals_meal_type`, `idx_meals_date_type`, `idx_pantry_name`, `idx_pantry_category`, `idx_pantry_favorite`.
   - No `weight_logs` or `user_profile` tables or indices exist.
4. **Existing Test Fixtures**:
   In `test/services/database_service_test.dart:16-68`:
   - In-memory test setup uses `databaseFactoryFfi.openDatabase(inMemoryDatabasePath, ...)` at `version: 1`, creating `meals` and `pantry_items`.
   - Injects mock database via `DatabaseService.instance.setDatabaseForTesting(db)`.
5. **Peer Explorer Alignment**:
   - `explorer_m1_2` (`report.md:62-145` and `193-256`): Specified `WeightLog` (`id`, `date`, `weight`, `notes`) and `UserProfile` (biometrics, Mifflin-St Jeor benchmarks, macro targets, master prompt, timestamps) with `_sentinel` pattern and `toSqliteMap()` / `fromSqliteMap()`.
   - `explorer_m1_3` (`report.md:28-153`): Specified `DatabaseService` date-range queries (`getWeightLogsByRange`, `getWeightLogsLastDays`, `getLatestWeightLog`), `MealController` integration, and `BackupService` JSON backup/restore pipeline.

---

## 2. Logic Chain
1. **Migration Safety**:
   - From Observation 1, because `version: 1` has no `onUpgrade`, an app upgrading from Phase 1 to Phase 2 with existing databases will fail to create the new tables (`weight_logs` and `user_profile`).
   - Adding `version: 2` and `onUpgrade: _onUpgrade` with check `if (oldVersion < 2)` guarantees that only the missing tables and indices are created, leaving existing `meals` and `pantry_items` records untouched.
2. **Fresh Install Consistency**:
   - From Observation 3, if `_onCreate` only creates version 1 tables, a fresh install would run `_onCreate` at version 2 but miss `weight_logs` and `user_profile`.
   - Unifying table creation into modular helpers (`_createWeightLogsTable`, `_createUserProfileTable`, `_createIndices`) invoked by both `_onCreate` and `_onUpgrade` guarantees schema parity between fresh installs and upgraded databases.
3. **Query Performance & Indexing**:
   - In `weight_logs`, `date` is stored as an ISO-8601 string (`YYYY-MM-DDTHH:MM:SS.mmmZ`).
   - Because ISO-8601 strings sort lexicographically in exact chronological order, creating a B-Tree index `idx_weight_logs_date` on `weight_logs(date)` allows SQLite to execute range queries (`date >= ? AND date <= ?`) in $O(\log N + K)$ time and latest-entry lookups (`ORDER BY date DESC LIMIT 1`) in $O(1)$ time.
   - This eliminates in-memory RAM filtering with Dart `.where(...)`, adhering strictly to `sqlite-local-first-flutter`.
4. **Referential Integrity & WAL Durability**:
   - From Observation 2, maintaining WAL mode, `synchronous = NORMAL`, and `foreign_keys = ON` in a dedicated `_onConfigure` helper guarantees non-blocking concurrent reads during writes and ACID transaction safety.
5. **Contract Parity**:
   - From Observation 5, aligning column names, types, and serialization aliases (`toSqliteMap()`, `fromSqliteMap()`) ensures that `DatabaseService`, `WeightLog`, `UserProfile`, `MealController`, and `BackupService` communicate without conversion errors or runtime column mismatches.

---

## 3. Caveats
- `user_profile` Table Optional Columns: The prompt specifies 15 columns for `user_profile` (`id`, `age`, `gender`, `height`, `weight`, `activity_level`, `body_goal`, `bmr`, `tdee`, `target_calories`, `target_protein`, `target_carbs`, `target_fat`, `master_prompt`, `updated_at`). Adding nullable `name TEXT` and `estimated_steps INTEGER NOT NULL DEFAULT 8000` is recommended to support `UserProfile` model properties defined in R3 and R5. If strictly 15 columns are used, `UserProfile.toSqliteMap()` must omit `name` and `estimated_steps`. Both options are documented in `report.md`.
- Concurrency during Migrations: SQLite handles `onUpgrade` inside an exclusive lock. Background queries initiated while `onUpgrade` runs will pause until the migration commits. The memoized `_initFuture` ensures callers await the initialization promise rather than opening duplicate database connections.

---

## 4. Conclusion
Milestone 1 SQLite v2 migration is fully designed and ready for implementation.
1. `lib/services/database_service.dart` must be upgraded to `version: 2` with `onUpgrade: _onUpgrade` and modular table creation helpers (`_createMealsTable`, `_createPantryTable`, `_createWeightLogsTable`, `_createUserProfileTable`, `_createIndices`).
2. Schema for `weight_logs` (`id`, `date`, `weight`, `notes`) with index `idx_weight_logs_date` provides $O(\log N + K)$ range queries and $O(1)$ latest lookup.
3. Schema for `user_profile` stores the user's metabolic profile, Mifflin-St Jeor targets, and Gemini Master Prompt with singleton replacement semantics.
4. All method signatures for single mutations, range queries, batch upserts, and telemetry stats are finalized.
5. Comprehensive test specifications for `test/services/database_service_v2_test.dart` are defined.

Full details and ready-to-implement code snippets are documented at:
`C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_m1_1\report.md`

---

## 5. Verification Method
1. **File Inspection**:
   - Inspect `lib/services/database_service.dart` to verify `openDatabase` specifies `version: 2`, `onConfigure: _onConfigure`, `onCreate: _onCreate`, and `onUpgrade: _onUpgrade`.
   - Inspect DDL statements to verify `idx_weight_logs_date` is created on `weight_logs(date)`.
2. **Automated Unit & Migration Tests**:
   - Run existing database tests:
     `flutter test test/services/database_service_test.dart`
   - Run new migration and v2 tests:
     `flutter test test/services/database_service_v2_test.dart`
3. **Invalidation Conditions**:
   - If an in-memory database upgraded from v1 to v2 loses existing `meals` records, the migration logic is invalid.
   - If `sqlite_master` does not contain `idx_weight_logs_date` after migration, the indexing strategy is invalid.
   - If `getWeightLogsByRange` performs in-memory filtering rather than SQL `WHERE date >= ? AND date <= ?`, the local-first standard is violated.
