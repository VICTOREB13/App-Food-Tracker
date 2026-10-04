import '../../models/fasting_log.dart';
import '../errors/failures.dart';
import '../errors/result.dart';

/// Contract for Fasting Log Data Access Object.
abstract interface class IFastingDao {
  Future<int> insertFastingLog(FastingLog log);
  Future<int> updateFastingLog(FastingLog log);
  Future<int> deleteFastingLog(String id);
  Future<FastingLog?> getFastingLogById(String id);
  Future<FastingLog?> getActiveFastingLog();
  Future<List<FastingLog>> getAllFastingLogs();
  Future<List<FastingLog>> getRecentFastingLogs({int limit = 10});

  // Functional Result APIs
  Future<Result<int, DatabaseFailure>> insertFastingLogResult(FastingLog log);
  Future<Result<FastingLog?, DatabaseFailure>> getActiveFastingLogResult();
  Future<Result<List<FastingLog>, DatabaseFailure>> getAllFastingLogsResult();
}
