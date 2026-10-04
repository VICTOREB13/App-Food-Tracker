# SQLite Local-First Persistence in Flutter
Core Principles:
- Memoized initialization (_initFuture)
- Desktop FFI adaptation
- Performance pragmas: WAL mode, synchronous = NORMAL, foreign_keys = ON
- B-Tree Composite Indexing & native SQL filtering
- Immutable Sentinel Pattern for models
- Atomic transactions & batch upserts (db.transaction + batch.commit(noResult: true))
- Scoped storage & dynamic paths via path_provider / file_picker
- Atomic JSON backup pipelines & in-memory deterministic testing
