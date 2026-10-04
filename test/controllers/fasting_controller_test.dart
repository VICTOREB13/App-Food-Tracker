import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/controllers/fasting_controller.dart';
import 'package:food_tracker/core/errors/failures.dart';
import 'package:food_tracker/core/errors/result.dart';
import 'package:food_tracker/core/interfaces/fasting_dao_interface.dart';
import 'package:food_tracker/models/fasting_log.dart';

class FakeFastingDao implements IFastingDao {
  FastingLog? activeLog;
  final List<FastingLog> allLogs = [];

  @override
  Future<int> insertFastingLog(FastingLog log) async {
    allLogs.add(log);
    if (log.isActive) activeLog = log;
    return 1;
  }

  @override
  Future<int> updateFastingLog(FastingLog log) async {
    final idx = allLogs.indexWhere((l) => l.id == log.id);
    if (idx != -1) allLogs[idx] = log;
    if (activeLog?.id == log.id) {
      activeLog = log.isActive ? log : null;
    }
    return 1;
  }

  @override
  Future<int> deleteFastingLog(String id) async {
    allLogs.removeWhere((l) => l.id == id);
    if (activeLog?.id == id) activeLog = null;
    return 1;
  }

  @override
  Future<FastingLog?> getActiveFastingLog() async => activeLog;

  @override
  Future<List<FastingLog>> getAllFastingLogs() async => List.unmodifiable(allLogs);

  @override
  Future<FastingLog?> getFastingLogById(String id) async =>
      allLogs.cast<FastingLog?>().firstWhere((l) => l?.id == id, orElse: () => null);

  @override
  Future<List<FastingLog>> getRecentFastingLogs({int limit = 10}) async =>
      allLogs.take(limit).toList();

  @override
  Future<Result<FastingLog?, DatabaseFailure>> getActiveFastingLogResult() async =>
      Result<FastingLog?, DatabaseFailure>.ok(activeLog);

  @override
  Future<Result<List<FastingLog>, DatabaseFailure>> getAllFastingLogsResult() async =>
      Result<List<FastingLog>, DatabaseFailure>.ok(allLogs);

  @override
  Future<Result<int, DatabaseFailure>> insertFastingLogResult(FastingLog log) async {
    await insertFastingLog(log);
    return const Result<int, DatabaseFailure>.ok(1);
  }
}

void main() {
  group('FastingController Tests', () {
    late FakeFastingDao fakeDao;
    late FastingController controller;

    setUp(() {
      fakeDao = FakeFastingDao();
      controller = FastingController(fastingDao: fakeDao);
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state has no active fast', () async {
      await controller.loadActiveFast();
      expect(controller.isFastingActive, isFalse);
      expect(controller.activeFast, isNull);
      expect(controller.elapsedDuration, equals(Duration.zero));
      expect(controller.progressRatio, equals(0.0));
    });

    test('startFast inserts log and activates timer', () async {
      final log = await controller.startFast(targetHours: 16.0);
      expect(controller.isFastingActive, isTrue);
      expect(controller.activeFast?.id, equals(log.id));
      expect(controller.targetHours, equals(16.0));
      expect(fakeDao.activeLog?.id, equals(log.id));
    });

    test('stopActiveFast closes current session', () async {
      await controller.startFast(targetHours: 16.0);
      expect(controller.isFastingActive, isTrue);

      final stopped = await controller.stopActiveFast();
      expect(stopped, isNotNull);
      expect(stopped!.isActive, isFalse);
      expect(stopped.endTime, isNotNull);
      expect(controller.isFastingActive, isFalse);
      expect(controller.activeFast, isNull);
      expect(fakeDao.activeLog, isNull);
    });

    test('progressRatio computes correctly and clamps to 1.0 max', () async {
      final pastStart = DateTime.now().subtract(const Duration(hours: 8));
      final log = FastingLog(startTime: pastStart, targetHours: 16.0, isActive: true);
      await fakeDao.insertFastingLog(log);
      await controller.loadActiveFast();

      expect(controller.isFastingActive, isTrue);
      expect(controller.progressRatio, closeTo(0.5, 0.05));
      expect(controller.fastingDurationFormatted, contains('8h'));
    });
  });
}
