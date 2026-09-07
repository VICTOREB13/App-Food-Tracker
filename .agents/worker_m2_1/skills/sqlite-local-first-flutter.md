---
name: sqlite-local-first-flutter
description: Complete architectural and implementation guide for high-performance, local-first, offline-deterministic Flutter apps powered by SQLite (sqflite and sqflite_common_ffi). Covers race-condition defense (memoized init), WAL mode & integrity pragmas, B-Tree composite indexing, the Immutable Sentinel Pattern in Dart models, transactional batch upserts, 2-phase external sync with concurrency pools, scoped storage, and atomic JSON backup pipelines.
license: MIT
metadata:
  author: Victor Engineer
  version: "1.0.0"
  tags: [sqlite, local-first, flutter, database, indexing, concurrency, transactions, offline-first, sentinel-pattern, sqflite]
---

# SQLite Local-First Persistence in Flutter

Guía canónica para el diseño, implementación y optimización de aplicaciones **100% Local-First** en Flutter con **SQLite**. Proporciona cero latencia perceptible, privacidad integral del usuario, funcionamiento offline ininterrumpido y consistencia ACID estricta en plataformas móviles (Android/iOS) y de escritorio (Windows/macOS/Linux).

---

## 1. Concurrencia y Protección contra Condiciones de Carrera

### 1.1 El Patrón de Inicialización Memoizada (`_initFuture`)
En arquitecturas reactivas, múltiples widgets o servicios concurrentes pueden solicitar la base de datos simultáneamente al iniciar la aplicación. Si cada llamada intenta abrir o migrar la base de datos de forma independiente, SQLite arrojará `DatabaseException: database is locked`.

* **Patrón Obligatorio en `DatabaseService`:**
  ```dart
  class DatabaseService {
    DatabaseService._();
    static final DatabaseService instance = DatabaseService._();

    Database? _database;
    Future<Database>? _initFuture;

    Future<Database> get database async {
      if (_database != null) return _database!;
      // Memoización: Todas las llamadas concurrentes comparten la misma promesa
      return _initFuture ??= _initDatabase();
    }

    Future<Database> _initDatabase() async {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'app_database.db');
      final db = await openDatabase(
        path,
        version: 2,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      _database = db;
      return db;
    }
  }
  ```

### 1.2 Adaptación Multiplataforma (Móvil vs Escritorio FFI)
* **Móvil (Android / iOS):** Utiliza los bindings nativos del paquete `sqflite`.
* **Escritorio (Windows / Linux / macOS):** Debe inicializarse el motor FFI mediante `sqflite_common_ffi` en el `main()` antes de cualquier llamada a la base de datos:
  ```dart
  import 'dart:io';
  import 'package:sqflite_common_ffi/sqflite_ffi.dart';

  void main() {
    WidgetsFlutterBinding.ensureInitialized();
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    runApp(const MyApp());
  }
  ```

---

## 2. Pragmas de Rendimiento e Integridad Referencial

Configura siempre estos pragmas dentro del callback `onConfigure` de `openDatabase`:

```dart
Future<void> _onConfigure(Database db) async {
  // 1. Write-Ahead Logging: Permite lecturas concurrentes sin bloquear escrituras
  await db.execute('PRAGMA journal_mode = WAL;');

  // 2. Sincronización NORMAL: Reduce sustancialmente I/O a disco con alta durabilidad en WAL
  await db.execute('PRAGMA synchronous = NORMAL;');

  // 3. Claves Foráneas: Obligatorio para preservar integridad referencial y cascading
  await db.execute('PRAGMA foreign_keys = ON;');
}
```

* **Beneficios de WAL + NORMAL:**
  - Las operaciones de lectura (`SELECT`) nunca esperan a que terminen las transacciones de escritura (`INSERT/UPDATE`).
  - La UI nunca sufre congelamientos ni caídas de frames al persistir datos en segundo plano.
  - Multiplica el throughput de inserciones por lotes de 10x a 50x frente a `DELETE` journal mode.

---

## 3. Estrategia de Índices B-Tree y Filtrado SQL Nativo

### 3.1 Índices B-Tree Especializados
Nunca realices búsquedas o filtros de estado sin un índice B-Tree de soporte. En `_onCreate` o `onUpgrade`:

```sql
-- 1. Búsqueda por texto insensible a mayúsculas/minúsculas
CREATE INDEX IF NOT EXISTS idx_games_title_nocase ON games(title COLLATE NOCASE);

-- 2. Índice compuesto para vistas filtradas por estado y orden cronológico (Dashboard)
CREATE INDEX IF NOT EXISTS idx_games_status_updated ON games(status, updated_at DESC);

-- 3. Métricas y rankings por horas y valoración
CREATE INDEX IF NOT EXISTS idx_games_hours_played ON games(hours_played DESC);
CREATE INDEX IF NOT EXISTS idx_games_rating ON games(rating DESC, hours_played DESC);

-- 4. Búsqueda por ID externo para sincronización rápida
CREATE INDEX IF NOT EXISTS idx_games_steam_id ON games(steam_id);
```

### 3.2 Prohibido Filtrar en Memoria RAM con Dart
* ❌ **Antipatrón:** Leer `db.query('games')` (miles de registros) y hacer `games.where((g) => g.status == filter).toList()` en Dart.
* ✅ **Estándar:** Construir cláusulas dinámicas `WHERE`, `ORDER BY`, `LIMIT` y `OFFSET` directamente en SQL:
  ```dart
  Future<List<Game>> getGames({
    String? status,
    String? query,
    String? platform,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (status != null && status != 'Todos') {
      whereClauses.add('status = ?');
      whereArgs.add(status);
    }
    if (query != null && query.trim().isNotEmpty) {
      whereClauses.add('title LIKE ?');
      whereArgs.add('%${query.trim()}%');
    }
    if (platform != null && platform != 'Todas') {
      whereClauses.add('platform = ?');
      whereArgs.add(platform);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final results = await db.query(
      'games',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'updated_at DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((m) => Game.fromSqlite(m)).toList();
  }
  ```

---

## 4. Modelado Inmutable y el Patrón Sentinel

### 4.1 La Ambigüedad del `null` en Dart
Al implementar `copyWith` en modelos inmutables, pasar `null` como argumento normalmente significa "no cambies este valor". Sin embargo, si el usuario desea **borrar explícitamente** un campo opcional (ej. remover la portada local o desasignar una fecha), `field: null` es ignorado.

### 4.2 El Patrón Sentinel Completo
Crea un objeto centinela privado e inmutable para distinguir entre "no modificar" y "asignar null explícitamente":

```dart
const Object _sentinel = Object();

class Game {
  final String id;
  final String title;
  final String? coverPath;
  final num? rating;
  final DateTime? completedDate;
  final DateTime? updatedAt;

  const Game({
    required this.id,
    required this.title,
    this.coverPath,
    this.rating,
    this.completedDate,
    this.updatedAt,
  });

  Game copyWith({
    String? id,
    String? title,
    Object? coverPath = _sentinel,
    Object? rating = _sentinel,
    Object? completedDate = _sentinel,
    Object? updatedAt = _sentinel,
  }) {
    return Game(
      id: id ?? this.id,
      title: title ?? this.title,
      coverPath: identical(coverPath, _sentinel) ? this.coverPath : coverPath as String?,
      rating: identical(rating, _sentinel) ? this.rating : rating as num?,
      completedDate: identical(completedDate, _sentinel) ? this.completedDate : completedDate as DateTime?,
      updatedAt: identical(updatedAt, _sentinel) ? this.updatedAt : updatedAt as DateTime?,
    );
  }

  /// Preservar marcas de tiempo preexistentes en lugar de destruirlas
  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'title': title,
      'cover_path': coverPath,
      'rating': rating,
      'completed_date': completedDate?.toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
```

---

## 5. Transacciones Atómicas y Sincronización en 2 Fases

### 5.1 Inserciones y Actualizaciones Masivas en Lote (`batchUpsertGames`)
Nunca ejecutes un `for` de llamadas `db.insert()` o `db.update()` individuales. Encapsula siempre en una transacción por lotes:

```dart
Future<void> batchUpsertGames(List<Game> games) async {
  if (games.isEmpty) return;
  final db = await database;
  await db.transaction((txn) async {
    final batch = txn.batch();
    for (final game in games) {
      batch.insert(
        'games',
        game.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  });
}
```

### 5.2 Sincronización en Dos Fases (Resiliencia ante APIs Externas)
Al sincronizar con APIs lentas o con rate limits (Steam, RAWG, HLTB):
1. **Fase 1 (Ingesta Atómica Inmediata < 1s):**
   * Descarga la lista básica de juegos.
   * Ejecuta `batchUpsertGames` en SQLite inmediatamente.
   * La UI actualiza la biblioteca del usuario en menos de un segundo.
2. **Fase 2 (Cola de Enriquecimiento en Segundo Plano):**
   * Procesa en background metadatos pesados (portadas HD, sinopsis, horas de duración).
   * Controla la concurrencia con un pool de workers restringido (ej. 2 workers concurrentes y retardo de 300 ms entre llamadas).
   * Emite progreso en tiempo real mediante callbacks o Streams tipados (`SyncProgress`).
   * Maneja errores por elemento sin cancelar toda la transacción.

---

## 6. Scoped Storage, Rutas Dinámicas y Backups JSON

### 6.1 Prohibidas las Rutas Absolutas Hardcodeadas
* ❌ Nunca uses rutas como `/storage/emulated/0/Download` o `C:\Users\...`. En Android 10+ (Scoped Storage) fallarán por violaciones de permisos (`Permission Denied`).
* ✅ Resuelve rutas dinámicamente con `path_provider`:
  - **Base de Datos y Caché Interna de Portadas:** `getApplicationDocumentsDirectory()`.
  - **Importación / Exportación Elegida por el Usuario:** Usa `file_picker` (`FilePicker.platform.pickFiles` y `FilePicker.platform.saveFile` o `getDirectoryPath`).

### 6.2 Resiliencia de Respaldos JSON (Exportación / Importación)
* **Exportación Atómica:** Genera un JSON estructurado con metadatos del esquema (`schema_version: 1`, `exported_at`, `count`, `games: [...]`).
* **Importación Transaccional:**
  1. Valida estrictamente la estructura del JSON y tipos numéricos (`num` parseado a `double`).
  2. Ejecuta la restauración dentro de un `db.transaction(...)`. Si un registro está corrupto, la transacción realiza rollback automático, protegiendo la base de datos del usuario de inconsistencias.

---

## 7. Checklist de Calidad para Persistencia SQLite
- [ ] Inicialización protegida por `_initFuture` para prevenir bloqueos por concurrencia.
- [ ] Pragmas `WAL`, `synchronous = NORMAL` y `foreign_keys = ON` configurados en `onConfigure`.
- [ ] Índices B-Tree creados para ordenamientos frecuentes, estados y búsquedas `COLLATE NOCASE`.
- [ ] Modelo inmutable con patrón Sentinel en `copyWith` para limpieza explícita de campos nulos.
- [ ] Ingestas masivas implementadas con `db.transaction` y `batch.commit(noResult: true)`.
- [ ] Rutas locales resueltas dinámicamente mediante `path_provider` (Scoped Storage safe).
- [ ] Pruebas unitarias de persistencia 100% deterministas con base de datos en memoria (`inMemoryDatabasePath`).
