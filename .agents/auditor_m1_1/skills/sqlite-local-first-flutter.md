# sqlite-local-first-flutter (Local Copy)
Source: C:\Users\vmesp\.gemini\config\skills\sqlite-local-first-flutter\SKILL.md

Complete architectural and implementation guide for high-performance, local-first, offline-deterministic Flutter apps powered by SQLite (sqflite and sqflite_common_ffi). Covers race-condition defense (memoized init), WAL mode & integrity pragmas, B-Tree composite indexing, the Immutable Sentinel Pattern in Dart models, transactional batch upserts, 2-phase external sync with concurrency pools, scoped storage, and atomic JSON backup pipelines.

## Key Checkpoints:
1. `_initFuture` memoization in `DatabaseService`
2. Pragmas in `onConfigure`: WAL, synchronous = NORMAL, foreign_keys = ON
3. B-Tree indexes created in `_onCreate` / `_onUpgrade` (e.g., `idx_weight_logs_date ON weight_logs(date)`)
4. Native SQL WHERE / ORDER BY / LIMIT — NO in-memory RAM filtering with Dart `.where()`
5. Sentinel pattern in immutable models: `identical(param, _sentinel)`
6. Transactional batch operations: `db.transaction((txn) async { ... batch.commit(noResult: true); })`
7. Scoped storage & atomic JSON backup / restore
