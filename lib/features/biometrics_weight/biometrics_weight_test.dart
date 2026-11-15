import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/core/errors/failures.dart';
import 'package:food_tracker/core/errors/result.dart';
import 'package:food_tracker/core/interfaces/daos_interfaces.dart';
import 'package:food_tracker/features/settings_profile/models/user_profile.dart';
import 'biometrics_weight.dart';

class _FakeWeightLogDao implements IWeightLogDao {
  final List<WeightLog> logs = [];

  @override
  Future<int> insertWeightLog(WeightLog log) async {
    logs.add(log);
    return 1;
  }

  @override
  Future<int> updateWeightLog(WeightLog log) async {
    final idx = logs.indexWhere((l) => l.id == log.id);
    if (idx != -1) logs[idx] = log;
    return 1;
  }

  @override
  Future<int> deleteWeightLog(String id) async {
    logs.removeWhere((l) => l.id == id);
    return 1;
  }

  @override
  Future<WeightLog?> getWeightLogById(String id) async =>
      logs.cast<WeightLog?>().firstWhere((l) => l?.id == id, orElse: () => null);

  @override
  Future<List<WeightLog>> getAllWeightLogs() async => List.unmodifiable(logs);

  @override
  Future<WeightLog?> getLatestWeightLog() async => logs.isEmpty ? null : logs.last;

  @override
  Future<List<WeightLog>> getWeightLogsByRange(DateTime startDate, DateTime endDate) async =>
      logs.where((l) => l.date.isAfter(startDate) && l.date.isBefore(endDate)).toList();

  @override
  Future<List<WeightLog>> getWeightLogsLastDays(int days) async {
    if (days <= 0) return getAllWeightLogs();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return logs.where((l) => l.date.isAfter(cutoff)).toList();
  }

  @override
  Future<void> batchUpsertWeightLogs(List<WeightLog> items) async {
    for (final item in items) {
      await insertWeightLog(item);
    }
  }

  @override
  Future<Result<int, DatabaseFailure>> insertWeightLogResult(WeightLog log) async {
    await insertWeightLog(log);
    return const Result.ok(1);
  }

  @override
  Future<Result<List<WeightLog>, DatabaseFailure>> getWeightLogsByRangeResult(
    DateTime startDate,
    DateTime endDate,
  ) async => Result.ok(await getWeightLogsByRange(startDate, endDate));

  @override
  Future<Result<WeightLog?, DatabaseFailure>> getLatestWeightLogResult() async =>
      Result.ok(await getLatestWeightLog());
}

class _FakeUserProfileDao implements IUserProfileDao {
  UserProfile? profile;

  @override
  Future<int> saveUserProfile(UserProfile p) async {
    profile = p;
    return 1;
  }

  @override
  Future<UserProfile?> getUserProfile() async => profile;

  @override
  Future<int> deleteUserProfile({String id = 'primary'}) async {
    profile = null;
    return 1;
  }

  @override
  Future<Result<int, DatabaseFailure>> saveUserProfileResult(UserProfile p) async {
    await saveUserProfile(p);
    return const Result.ok(1);
  }

  @override
  Future<Result<UserProfile?, DatabaseFailure>> getUserProfileResult() async =>
      Result.ok(profile);
}

void main() {
  group('BiometricsCalculator Formulas', () {
    test('calculates BMR using Mifflin-St Jeor equation accurately', () {
      final maleBmr = BiometricsCalculator.calculateBmr(
        weightKg: 70.0,
        heightCm: 175.0,
        age: 30,
        isFemale: false,
      );
      // (10 * 70) + (6.25 * 175) - (5 * 30) + 5 = 700 + 1093.75 - 150 + 5 = 1648.75 -> 1648.8
      expect(maleBmr, equals(1648.8));

      final femaleBmr = BiometricsCalculator.calculateBmr(
        weightKg: 60.0,
        heightCm: 165.0,
        age: 28,
        isFemale: true,
      );
      // (10 * 60) + (6.25 * 165) - (5 * 28) - 161 = 600 + 1031.25 - 140 - 161 = 1330.25 -> 1330.3
      expect(femaleBmr, equals(1330.3));
    });

    test('calculates TDEE and BMI categories correctly', () {
      final tdee = BiometricsCalculator.calculateTdee(bmr: 1600.0, activityMultiplier: 1.55);
      expect(tdee, equals(2480.0));

      final bmi = BiometricsCalculator.calculateBmi(weightKg: 70.0, heightCm: 175.0);
      expect(bmi, equals(22.9));
      expect(BmiCategory.fromBmi(17.5), equals(BmiCategory.underweight));
      expect(BmiCategory.fromBmi(22.9), equals(BmiCategory.normal));
      expect(BmiCategory.fromBmi(27.4), equals(BmiCategory.overweight));
      expect(BmiCategory.fromBmi(33.0), equals(BmiCategory.obeseClass1));
      expect(BmiCategory.fromBmi(38.0), equals(BmiCategory.obeseClass2));
      expect(BmiCategory.fromBmi(42.0), equals(BmiCategory.obeseClass3));
    });

    test('calculates Adjusted Body Weight (ABW) for obesity', () {
      // Height 180cm male, weight 110kg (BMI ~34.0, Obese Class 1)
      final abw = BiometricsCalculator.calculateAdjustedBodyWeight(
        actualWeightKg: 110.0,
        heightCm: 180.0,
        isFemale: false,
      );
      // IBW = 50 + 0.91 * (180 - 152.4) = 50 + 25.116 = 75.12
      // ABW = 75.12 + 0.4 * (110 - 75.12) = 75.12 + 13.95 = 89.07
      expect(abw, closeTo(89.07, 0.1));

      // Normal weight returns actual weight
      final normalAbw = BiometricsCalculator.calculateAdjustedBodyWeight(
        actualWeightKg: 70.0,
        heightCm: 180.0,
        isFemale: false,
      );
      expect(normalAbw, equals(70.0));
    });

    test('calculates moving average over a sliding window', () {
      expect(BiometricsCalculator.calculateMovingAverage([]), equals(0.0));

      final now = DateTime.now();
      final logs = [
        WeightLog(weight: 70.0, date: now.subtract(const Duration(days: 2))),
        WeightLog(weight: 71.0, date: now.subtract(const Duration(days: 1))),
        WeightLog(weight: 72.0, date: now),
      ];
      expect(BiometricsCalculator.calculateMovingAverage(logs, window: 7), equals(71.0));
    });
  });

  group('BiometricsWeightState Sentinel & Immutability', () {
    test('initial state contains safe sentinel defaults', () {
      const state = BiometricsWeightState.initial;
      expect(state.logs, isEmpty);
      expect(state.latestLog, isNull);
      expect(state.filterRange, equals(WeightFilterRange.thirtyDays));
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.bmr, isNull);
      expect(state.currentWeight, isNull);
      expect(state.weightDelta, isNull);
      expect(state.trendDirection, equals(WeightTrendDirection.stable));
    });

    test('copyWith preserves values when using sentinel and replaces when provided', () {
      const state = BiometricsWeightState(isLoading: false, errorMessage: 'Error');
      final updated = state.copyWith(isLoading: true, errorMessage: null);

      expect(updated.isLoading, isTrue);
      expect(updated.errorMessage, isNull);

      final same = updated.copyWith();
      expect(same.isLoading, isTrue);
      expect(same, equals(updated));
      expect(same.hashCode, equals(updated.hashCode));
    });

    test('weightDelta and trendDirection evaluate correctly', () {
      final now = DateTime.now();
      final stateInc = BiometricsWeightState(logs: [
        WeightLog(weight: 70.0, date: now.subtract(const Duration(days: 5))),
        WeightLog(weight: 72.0, date: now),
      ]);
      expect(stateInc.weightDelta, equals(2.0));
      expect(stateInc.trendDirection, equals(WeightTrendDirection.increasing));

      final stateDec = BiometricsWeightState(logs: [
        WeightLog(weight: 75.0, date: now.subtract(const Duration(days: 5))),
        WeightLog(weight: 73.0, date: now),
      ]);
      expect(stateDec.weightDelta, equals(-2.0));
      expect(stateDec.trendDirection, equals(WeightTrendDirection.decreasing));
    });
  });

  group('BiometricsWeightController State Transitions', () {
    late _FakeWeightLogDao fakeWeightDao;
    late _FakeUserProfileDao fakeProfileDao;
    late BiometricsWeightController controller;

    setUp(() {
      fakeWeightDao = _FakeWeightLogDao();
      fakeProfileDao = _FakeUserProfileDao();
      fakeProfileDao.profile = UserProfile(
        age: 30,
        height: 175.0,
        weight: 70.0,
        bmr: 1648.8,
        tdee: 2200.0,
        targetCalories: 2000.0,
        targetProtein: 140.0,
        targetCarbs: 220.0,
        targetFat: 60.0,
      );
      controller = BiometricsWeightController(
        weightLogDao: fakeWeightDao,
        userProfileDao: fakeProfileDao,
      );
    });

    test('recordWeight inserts log and updates state & profile', () async {
      await controller.recordWeight(74.5, notes: 'Morning weigh-in');

      expect(controller.state.logs.length, equals(1));
      expect(controller.currentWeight, equals(74.5));
      expect(controller.latestWeightLog?.notes, equals('Morning weigh-in'));
      expect(controller.state.bmr, isNotNull);
      expect(controller.state.bmi, isNotNull);
    });

    test('deleteWeight removes log and refreshes state', () async {
      final log = WeightLog(id: 'w-1', weight: 75.0);
      fakeWeightDao.logs.add(log);
      await controller.loadWeightLogs();
      expect(controller.state.logs.length, equals(1));

      await controller.deleteWeight('w-1');
      expect(controller.state.logs, isEmpty);
      expect(controller.currentWeight, isNull);
    });

    test('setFilterRange switches active time interval', () async {
      await controller.setFilterRange(WeightFilterRange.sevenDays);
      expect(controller.filterRange, equals(WeightFilterRange.sevenDays));
      expect(controller.selectedWeightDays, equals(7));
    });
  });
}
