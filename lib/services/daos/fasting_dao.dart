import 'package:sqflite/sqflite.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/result.dart';
import '../../core/interfaces/fasting_dao_interface.dart';
import '../../models/fasting_log.dart';

/// Data Access Object for intermittent fasting logs.
class FastingDao implements IFastingDao {
  final Future<Database> Function() _getDatabase;

  FastingDao(this._getDatabase);

  @override
  Future<int> insertFastingLog(FastingLog log) async {
    final db = await _getDatabase();
    return await db.insert(
      'fasting_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> updateFastingLog(FastingLog log) async {
    final db = await _getDatabase();
    return await db.update(
      'fasting_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  @override
  Future<int> deleteFastingLog(String id) async {
    final db = await _getDatabase();
    return await db.delete('fasting_logs', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<FastingLog?> getFastingLogById(String id) async {
    final db = await _getDatabase();
    final results = await db.query(
      'fasting_logs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return FastingLog.fromMap(results.first);
  }

  @override
  Future<FastingLog?> getActiveFastingLog() async {
    final db = await _getDatabase();
    final results = await db.query(
      'fasting_logs',
      where: 'is_active = 1',
      orderBy: 'start_time DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return FastingLog.fromMap(results.first);
  }

  @override
  Future<List<FastingLog>> getAllFastingLogs() async {
    final db = await _getDatabase();
    final results = await db.query('fasting_logs', orderBy: 'start_time DESC');
    return results.map((m) => FastingLog.fromMap(m)).toList();
  }

  @override
  Future<List<FastingLog>> getRecentFastingLogs({int limit = 10}) async {
    final db = await _getDatabase();
    final results = await db.query(
      'fasting_logs',
      orderBy: 'start_time DESC',
      limit: limit,
    );
    return results.map((m) => FastingLog.fromMap(m)).toList();
  }

  @override
  Future<Result<int, DatabaseFailure>> insertFastingLogResult(FastingLog log) async {
    try {
      final res = await insertFastingLog(log);
      return Result.ok(res);
    } catch (e, stack) {
      return Result.err(DatabaseFailure(message: 'Error al registrar ayuno: $e', cause: e, stackTrace: stack));
    }
  }

  @override
  Future<Result<FastingLog?, DatabaseFailure>> getActiveFastingLogResult() async {
    try {
      final log = await getActiveFastingLog();
      return Result.ok(log);
    } catch (e, stack) {
      return Result.err(DatabaseFailure(message: 'Error al consultar ayuno activo: $e', cause: e, stackTrace: stack));
    }
  }

  @override
  Future<Result<List<FastingLog>, DatabaseFailure>> getAllFastingLogsResult() async {
    try {
      final logs = await getAllFastingLogs();
      return Result.ok(logs);
    } catch (e, stack) {
      return Result.err(DatabaseFailure(message: 'Error al listar registros de ayuno: $e', cause: e, stackTrace: stack));
    }
  }
}
