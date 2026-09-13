import 'package:sqflite/sqflite.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/result.dart';
import '../../core/interfaces/daos_interfaces.dart';
import '../../models/weight_log.dart';

/// Data Access Object for weight logs and time-series progress tracking.
class WeightLogDao implements IWeightLogDao {
  final Future<Database> Function() _getDatabase;

  WeightLogDao(this._getDatabase);

  @override
  Future<int> insertWeightLog(WeightLog log) async {
    final db = await _getDatabase();
    return await db.insert(
      'weight_logs',
      log.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> updateWeightLog(WeightLog log) async {
    final db = await _getDatabase();
    return await db.update(
      'weight_logs',
      log.toSqliteMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  @override
  Future<int> deleteWeightLog(String id) async {
    final db = await _getDatabase();
    return await db.delete(
      'weight_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<WeightLog?> getWeightLogById(String id) async {
    final db = await _getDatabase();
    try {
      final results = await db.query(
        'weight_logs',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (results.isEmpty) return null;
      return WeightLog.fromSqliteMap(results.first);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<WeightLog>> getAllWeightLogs() async {
    final db = await _getDatabase();
    try {
      final results = await db.query(
        'weight_logs',
        orderBy: 'date ASC',
      );
      return results.map((m) => WeightLog.fromSqliteMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<WeightLog?> getLatestWeightLog() async {
    final db = await _getDatabase();
    try {
      final results = await db.query(
        'weight_logs',
        orderBy: 'date DESC',
        limit: 1,
      );
      if (results.isEmpty) return null;
      return WeightLog.fromSqliteMap(results.first);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<WeightLog>> getWeightLogsByRange(DateTime startDate, DateTime endDate) async {
    final db = await _getDatabase();
    try {
      final results = await db.query(
        'weight_logs',
        where: 'date >= ? AND date <= ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'date ASC',
      );
      return results.map((m) => WeightLog.fromSqliteMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<WeightLog>> getWeightLogsLastDays(int days) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    return await getWeightLogsByRange(startDate, now);
  }

  @override
  Future<void> batchUpsertWeightLogs(List<WeightLog> logs) async {
    if (logs.isEmpty) return;
    final db = await _getDatabase();
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final log in logs) {
        batch.insert(
          'weight_logs',
          log.toSqliteMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  // ==========================================
  // FUNCTIONAL RESULT APIS
  // ==========================================

  @override
  Future<Result<int, DatabaseFailure>> insertWeightLogResult(WeightLog log) async {
    try {
      final id = await insertWeightLog(log);
      return Result.ok(id);
    } catch (e, stack) {
      return Result.err(
        DatabaseFailure(
          message: 'Error al registrar peso: $e',
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<List<WeightLog>, DatabaseFailure>> getWeightLogsByRangeResult(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final logs = await getWeightLogsByRange(startDate, endDate);
      return Result.ok(logs);
    } catch (e, stack) {
      return Result.err(
        DatabaseFailure(
          message: 'Error al consultar logs de peso por rango: $e',
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<WeightLog?, DatabaseFailure>> getLatestWeightLogResult() async {
    try {
      final log = await getLatestWeightLog();
      return Result.ok(log);
    } catch (e, stack) {
      return Result.err(
        DatabaseFailure(
          message: 'Error al consultar último registro de peso: $e',
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }
}
