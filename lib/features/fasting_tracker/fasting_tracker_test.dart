import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/core/errors/failures.dart';
import 'package:food_tracker/core/errors/result.dart';
import 'package:food_tracker/core/interfaces/fasting_dao_interface.dart';
import 'fasting_tracker.dart';

class _FakeFastingDao implements IFastingDao {
  FastingLog? activeLog;
  final List<FastingLog> logs = [];

  @override
  Future<int> insertFastingLog(FastingLog log) async {
    logs.add(log);
    if (log.isActive) activeLog = log;
    return 1;
  }

  @override
  Future<int> updateFastingLog(FastingLog log) async {
    final idx = logs.indexWhere((l) => l.id == log.id);
    if (idx != -1) logs[idx] = log;
    if (activeLog?.id == log.id) {
      activeLog = log.isActive ? log : null;
    }
    return 1;
  }

  @override
  Future<int> deleteFastingLog(String id) async {
    logs.removeWhere((l) => l.id == id);
    if (activeLog?.id == id) activeLog = null;
    return 1;
  }

  @override
  Future<FastingLog?> getActiveFastingLog() async => activeLog;

  @override
  Future<List<FastingLog>> getAllFastingLogs() async => List.unmodifiable(logs);

  @override
  Future<FastingLog?> getFastingLogById(String id) async =>
      logs.cast<FastingLog?>().firstWhere((l) => l?.id == id, orElse: () => null);

  @override
  Future<List<FastingLog>> getRecentFastingLogs({int limit = 10}) async =>
      logs.take(limit).toList();

  @override
  Future<Result<FastingLog?, DatabaseFailure>> getActiveFastingLogResult() async =>
      Result<FastingLog?, DatabaseFailure>.ok(activeLog);

  @override
  Future<Result<List<FastingLog>, DatabaseFailure>> getAllFastingLogsResult() async =>
      Result<List<FastingLog>, DatabaseFailure>.ok(logs);

  @override
  Future<Result<int, DatabaseFailure>> insertFastingLogResult(FastingLog log) async {
    await insertFastingLog(log);
    return const Result<int, DatabaseFailure>.ok(1);
  }
}

void main() {
  group('FastingProtocol & KetosisPhase Domain Calculations', () {
    test('verifies protocol targets and 24-hour total window', () {
      for (final p in FastingProtocol.values) {
        if (p != FastingProtocol.custom) {
          expect(p.fastHours + p.eatHours, equals(24));
        }
      }
      expect(FastingProtocol.fromHours(13.0), equals(FastingProtocol.circadian));
      expect(FastingProtocol.fromHours(14.0), equals(FastingProtocol.fourteenTen));
      expect(FastingProtocol.fromHours(16.0), equals(FastingProtocol.sixteenEight));
      expect(FastingProtocol.fromHours(18.0), equals(FastingProtocol.eighteenSix));
      expect(FastingProtocol.fromHours(20.0), equals(FastingProtocol.twentyFour));
      expect(FastingProtocol.fromHours(23.5), equals(FastingProtocol.custom));
    });

    test('verifies physiological ketosis phases by elapsed duration', () {
      expect(KetosisPhase.fromElapsed(const Duration(hours: 2)), equals(KetosisPhase.anabolic));
      expect(KetosisPhase.fromElapsed(const Duration(hours: 8)), equals(KetosisPhase.glycogenDepletion));
      expect(KetosisPhase.fromElapsed(const Duration(hours: 15)), equals(KetosisPhase.ketosis));
      expect(KetosisPhase.fromElapsed(const Duration(hours: 24)), equals(KetosisPhase.deepKetosis));
    });
  });

  group('FastingState Sentinel & Immutability', () {
    test('initial state contains safe sentinel defaults', () {
      const state = FastingState.initial;
      expect(state.isFastingActive, isFalse);
      expect(state.activeFast, isNull);
      expect(state.elapsed, equals(Duration.zero));
      expect(state.remaining, equals(Duration.zero));
      expect(state.progressRatio, equals(0.0));
      expect(state.ketosisPhase, equals(KetosisPhase.anabolic));
      expect(state.protocol, equals(FastingProtocol.sixteenEight));
      expect(state.formattedElapsed, equals('0h 0m'));
    });

    test('copyWith updates and resets fields using sentinel pattern', () {
      final log = FastingLog(startTime: DateTime.now(), targetHours: 16.0);
      final state1 = FastingState.initial.copyWith(
        activeFast: log,
        protocol: FastingProtocol.eighteenSix,
        progressRatio: 0.5,
      );
      expect(state1.isFastingActive, isTrue);
      expect(state1.protocol, equals(FastingProtocol.eighteenSix));
      expect(state1.progressRatio, equals(0.5));

      final state2 = state1.copyWith(activeFast: null);
      expect(state2.activeFast, isNull);
      expect(state2.isFastingActive, isFalse);
      expect(state2.protocol, equals(FastingProtocol.eighteenSix));
    });
  });

  group('FastingTrackerController State Transitions', () {
    late _FakeFastingDao fakeDao;
    late FastingTrackerController controller;

    setUp(() {
      fakeDao = _FakeFastingDao();
      controller = FastingTrackerController(fastingDao: fakeDao);
    });

    tearDown(() {
      controller.dispose();
    });

    test('starts with inactive state and loads empty active log', () async {
      await controller.loadActiveFast();
      expect(controller.isFastingActive, isFalse);
      expect(controller.activeFast, isNull);
      expect(controller.elapsedDuration, equals(Duration.zero));
      expect(controller.progressRatio, equals(0.0));
    });

    test('startFast inserts log and activates protocol calculation', () async {
      final log = await controller.startFast(protocol: FastingProtocol.eighteenSix);
      expect(controller.isFastingActive, isTrue);
      expect(controller.activeFast?.id, equals(log.id));
      expect(controller.targetHours, equals(18.0));
      expect(controller.currentProtocol, equals(FastingProtocol.eighteenSix));
      expect(fakeDao.activeLog?.id, equals(log.id));
    });

    test('stopActiveFast closes session and updates state', () async {
      await controller.startFast(protocol: FastingProtocol.sixteenEight);
      expect(controller.isFastingActive, isTrue);

      final stopped = await controller.stopActiveFast();
      expect(stopped, isNotNull);
      expect(stopped!.isActive, isFalse);
      expect(stopped.endTime, isNotNull);
      expect(controller.isFastingActive, isFalse);
      expect(controller.activeFast, isNull);
      expect(fakeDao.activeLog, isNull);
    });

    test('progress ratio and ketosis phase compute correctly for elapsed time', () async {
      final pastStart = DateTime.now().subtract(const Duration(hours: 14));
      final log = FastingLog(startTime: pastStart, targetHours: 16.0, isActive: true);
      await fakeDao.insertFastingLog(log);
      await controller.loadActiveFast();

      expect(controller.isFastingActive, isTrue);
      expect(controller.progressRatio, closeTo(0.875, 0.05));
      expect(controller.ketosisPhase, equals(KetosisPhase.ketosis));
      expect(controller.fastingDurationFormatted, contains('14h'));
    });

    test('setProtocol updates protocol when inactive', () {
      controller.setProtocol(FastingProtocol.twentyFour);
      expect(controller.currentProtocol, equals(FastingProtocol.twentyFour));
      expect(controller.targetHours, equals(20.0));
    });
  });
}
