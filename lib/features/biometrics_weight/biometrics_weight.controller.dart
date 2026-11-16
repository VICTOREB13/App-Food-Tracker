import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:food_tracker/core/di/service_locator.dart';
import 'package:food_tracker/core/interfaces/daos_interfaces.dart';
import 'package:food_tracker/core/ports/database_port.dart';
import 'package:food_tracker/core/database/database_service.dart';
import 'package:food_tracker/features/biometrics_weight/services/metabolic_calculator.dart';
import 'package:food_tracker/core/services/storage/secure_storage_service.dart';
import 'biometrics_weight.model.dart';

/// State management controller for the Biometrics & Weight vertical slice.
/// Handles weight entries, moving averages, Mifflin-St Jeor BMR, TDEE, ABW,
/// and local SQLite persistence via IDatabasePort or IWeightLogDao.
class BiometricsWeightController extends ChangeNotifier {
  static BiometricsWeightController instance = BiometricsWeightController();

  final IWeightLogDao _weightDao;
  final IUserProfileDao? _profileDao;
  BiometricsWeightState _state = BiometricsWeightState.initial;

  BiometricsWeightController({
    IDatabasePort? databasePort,
    IWeightLogDao? weightLogDao,
    IUserProfileDao? userProfileDao,
  })  : _weightDao = weightLogDao ??
            (databasePort?.weightLogDao ??
                (getIt.isRegistered<IDatabasePort>()
                    ? getIt<IDatabasePort>().weightLogDao
                    : (getIt.isRegistered<IWeightLogDao>()
                        ? getIt<IWeightLogDao>()
                        : DatabaseService.instance.weightLogDao))),
        _profileDao = userProfileDao ??
            (databasePort?.userProfileDao ??
                (getIt.isRegistered<IDatabasePort>()
                    ? getIt<IDatabasePort>().userProfileDao
                    : (getIt.isRegistered<IUserProfileDao>()
                        ? getIt<IUserProfileDao>()
                        : DatabaseService.instance.userProfileDao)));

  @visibleForTesting
  static void setMockInstance(BiometricsWeightController mock) {
    instance = mock;
  }

  @visibleForTesting
  static void resetInstance() {
    instance = BiometricsWeightController();
  }

  BiometricsWeightState get state => _state;
  List<WeightLog> get weightLogs => _state.logs;
  WeightLog? get latestWeightLog => _state.latestLog;
  double? get currentWeight => _state.currentWeight;
  WeightFilterRange get filterRange => _state.filterRange;
  int get selectedWeightDays => _state.filterRange.days;
  bool get isLoading => _state.isLoading;
  String? get errorMessage => _state.errorMessage;
  double get movingAverage7d => _state.movingAverage7d;
  double? get bmr => _state.bmr;
  double? get tdee => _state.tdee;
  double? get adjustedBodyWeight => _state.adjustedBodyWeight;
  double? get bmi => _state.bmi;
  BmiCategory? get bmiCategory => _state.bmiCategory;
  double? get weightDelta => _state.weightDelta;
  WeightTrendDirection get trendDirection => _state.trendDirection;

  Future<void> init() async {
    await loadWeightLogs();
  }

  Future<void> loadWeightLogs({int? days}) async {
    final range = days != null ? WeightFilterRange.fromDays(days) : _state.filterRange;
    _state = _state.copyWith(isLoading: true, filterRange: range, errorMessage: null);
    notifyListeners();

    try {
      final logs = range.days <= 0
          ? await _weightDao.getAllWeightLogs()
          : await _weightDao.getWeightLogsLastDays(range.days);
      final latest = await _weightDao.getLatestWeightLog();

      final sorted = List<WeightLog>.from(logs)..sort((a, b) => a.date.compareTo(b.date));
      final effectiveLatest = latest ?? (sorted.isNotEmpty ? sorted.last : null);
      final ma7 = BiometricsCalculator.calculateMovingAverage(sorted, window: 7);

      _state = _state.copyWith(
        logs: sorted,
        latestLog: effectiveLatest,
        movingAverage7d: ma7,
      );

      await _recalculateBiometricsFromProfile();
    } catch (e) {
      debugPrint('BiometricsWeightController: Error loading logs: $e');
      _state = _state.copyWith(errorMessage: e.toString());
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<void> recordWeight(double weight, {String? notes, DateTime? date}) async {
    final log = WeightLog(weight: weight, notes: notes, date: date ?? DateTime.now());
    await _weightDao.insertWeightLog(log);
    await _syncWeightToProfile(weight);
    await loadWeightLogs(days: _state.filterRange.days);
  }

  Future<void> addWeightLog(double weight, {String? notes, DateTime? date}) =>
      recordWeight(weight, notes: notes, date: date);

  Future<void> deleteWeight(String id) async {
    await _weightDao.deleteWeightLog(id);
    await loadWeightLogs(days: _state.filterRange.days);
  }

  Future<void> setFilterRange(WeightFilterRange range) async {
    await loadWeightLogs(days: range.days);
  }

  Future<void> _recalculateBiometricsFromProfile() async {
    try {
      final profileDao = _profileDao;
      if (profileDao == null) return;
      final profile = await profileDao.getUserProfile();
      if (profile == null) return;

      final weightKg = _state.currentWeight ?? _state.latestLog?.weight ?? profile.weight;
      final heightCm = profile.height;
      if (weightKg <= 0.0 || heightCm <= 0.0) return;
      final isFemale = profile.gender.toLowerCase() == 'female';

      final bmr = BiometricsCalculator.calculateBmr(
        weightKg: weightKg,
        heightCm: heightCm,
        age: profile.age,
        isFemale: isFemale,
      );
      final mult = MetabolicCalculator.getActivityMultiplier(profile.activityLevel);
      final tdee = BiometricsCalculator.calculateTdee(bmr: bmr, activityMultiplier: mult);
      final bmi = BiometricsCalculator.calculateBmi(weightKg: weightKg, heightCm: heightCm);
      final bmiCat = BmiCategory.fromBmi(bmi);
      final abw = BiometricsCalculator.calculateAdjustedBodyWeight(
        actualWeightKg: weightKg,
        heightCm: heightCm,
        isFemale: isFemale,
      );

      _state = _state.copyWith(
        bmr: bmr,
        tdee: tdee,
        bmi: bmi,
        bmiCategory: bmiCat,
        adjustedBodyWeight: abw,
      );
    } catch (e) {
      debugPrint('BiometricsWeightController: Profile recalculation error: $e');
    }
  }

  Future<void> _syncWeightToProfile(double weight) async {
    try {
      final profileDao = _profileDao;
      if (profileDao == null) return;
      final profile = await profileDao.getUserProfile();
      if (profile == null) return;

      final isFemale = profile.gender.toLowerCase() == 'female';
      final newBmr = BiometricsCalculator.calculateBmr(
        weightKg: weight,
        heightCm: profile.height,
        age: profile.age,
        isFemale: isFemale,
      );
      final mult = MetabolicCalculator.getActivityMultiplier(profile.activityLevel);
      final newTdee = BiometricsCalculator.calculateTdee(bmr: newBmr, activityMultiplier: mult);

      final prevBmr = MetabolicCalculator.calculateBmr(
        gender: profile.gender,
        weightKg: profile.weight,
        heightCm: profile.height,
        age: profile.age,
      );
      final prevTdee = MetabolicCalculator.calculateTdee(bmr: prevBmr, activityLevel: profile.activityLevel);
      final prevAutoCals = MetabolicCalculator.calculateCaloricGoal(
        tdee: prevTdee,
        bmr: prevBmr,
        bodyGoal: profile.bodyGoal,
      );
      final prevMacros = MetabolicCalculator.calculateMacros(
        targetCalories: prevAutoCals,
        weightKg: profile.weight,
        bodyGoal: profile.bodyGoal,
        heightCm: profile.height,
        gender: profile.gender,
      );

      final isAuto = (profile.targetCalories - prevAutoCals).abs() <= 1.0 &&
          (profile.targetProtein - prevMacros.protein).abs() <= 1.0 &&
          (profile.targetFat - prevMacros.fat).abs() <= 1.0;

      double targetCal = profile.targetCalories, targetProt = profile.targetProtein;
      double targetCarb = profile.targetCarbs, targetFat = profile.targetFat;

      if (isAuto) {
        targetCal = MetabolicCalculator.calculateCaloricGoal(tdee: newTdee, bmr: newBmr, bodyGoal: profile.bodyGoal);
        final m = MetabolicCalculator.calculateMacros(
          targetCalories: targetCal,
          weightKg: weight,
          bodyGoal: profile.bodyGoal,
          heightCm: profile.height,
          gender: profile.gender,
        );
        targetProt = m.protein;
        targetCarb = m.carbs;
        targetFat = m.fat;
      }

      final updated = profile.copyWith(
        weight: weight,
        bmr: newBmr,
        tdee: newTdee,
        targetCalories: targetCal,
        targetProtein: targetProt,
        targetCarbs: targetCarb,
        targetFat: targetFat,
        updatedAt: DateTime.now(),
      );

      final newPrompt = MetabolicCalculator.generateMasterPrompt(updated);
      final finalProfile = updated.copyWith(masterPrompt: newPrompt);

      await profileDao.saveUserProfile(finalProfile);
      try {
        await SecureStorageService.instance.setMasterPrompt(newPrompt);
        await SecureStorageService.instance.setDailyGoals(finalProfile.dailyGoals);
      } catch (_) {}
    } catch (e) {
      debugPrint('BiometricsWeightController: _syncWeightToProfile error: $e');
    }
  }
}
