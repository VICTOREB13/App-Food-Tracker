import 'package:flutter/material.dart';
import 'package:food_tracker/core/utils/streak_calculator.dart';
import 'package:food_tracker/core/adapters/encrypted_storage_adapter.dart';
import 'package:food_tracker/core/adapters/home_widget_sync_adapter.dart';
import 'package:food_tracker/core/di/service_locator.dart';
import 'package:food_tracker/core/interfaces/database_service_interface.dart';
import 'package:food_tracker/core/ports/app_widget_sync_port.dart';
import 'package:food_tracker/core/ports/database_port.dart';
import 'package:food_tracker/core/ports/secure_storage_port.dart';
import 'package:food_tracker/features/biometrics_weight/biometrics_weight.dart';
import 'package:food_tracker/features/fasting_tracker/fasting_tracker.dart';
import 'package:food_tracker/core/models/daily_goals.dart';
import 'package:food_tracker/features/food_entry/models/meal.dart';
import 'package:food_tracker/core/database/database_service.dart';
import 'package:food_tracker/core/services/platform/home_widget_service.dart';
import 'package:food_tracker/core/services/storage/secure_storage_service.dart';
import 'dashboard.model.dart';

/// Micro-MVC controller for the Dashboard vertical slice.
/// Orchestrates daily intake, macro targets, streak tracking, native widget sync,
/// and integrations across biometrics and fasting slices.
class DashboardController extends ChangeNotifier {
  static DashboardController instance = DashboardController();

  @visibleForTesting
  static void setMockInstance(DashboardController mock) => instance = mock;

  @visibleForTesting
  static void resetInstance() => instance = DashboardController();

  final IDatabaseService _db;
  final IDatabasePort? _dbPort;
  final ISecureStoragePort _secureStorage;
  final IAppWidgetSyncPort _widgetSync;
  final BiometricsWeightController _biometrics;
  final FastingTrackerController _fasting;

  DashboardState _state;

  DashboardController({
    IDatabaseService? databaseService,
    IDatabasePort? databasePort,
    ISecureStoragePort? secureStoragePort,
    IAppWidgetSyncPort? appWidgetSyncPort,
    BiometricsWeightController? biometricsController,
    FastingTrackerController? fastingController,
    DateTime? initialDate,
  })  : _db = databaseService ?? DatabaseService.instance,
        _dbPort = databasePort ??
            (getIt.isRegistered<IDatabasePort>() ? getIt<IDatabasePort>() : null),
        _secureStorage = secureStoragePort ??
            (getIt.isRegistered<ISecureStoragePort>()
                ? getIt<ISecureStoragePort>()
                : EncryptedStorageAdapter(service: SecureStorageService.instance)),
        _widgetSync = appWidgetSyncPort ??
            (getIt.isRegistered<IAppWidgetSyncPort>()
                ? getIt<IAppWidgetSyncPort>()
                : HomeWidgetSyncAdapter(service: HomeWidgetService.instance)),
        _biometrics = biometricsController ?? BiometricsWeightController.instance,
        _fasting = fastingController ?? FastingTrackerController.instance,
        _state = initialDate != null
            ? DashboardState(selectedDate: initialDate)
            : DashboardState.initial;

  DashboardState get state => _state;
  DateTime get selectedDate => _state.selectedDate;
  DailyCaloricBudget get budget => _state.budget;
  MacroBreakdown get macros => _state.macros;
  List<Meal> get meals => _state.meals;
  int get streakDays => _state.streakDays;
  int get currentStreak => _state.streakDays;
  double? get currentWeight => _state.currentWeight;
  bool get isLoading => _state.isLoading;
  DailyGoals get dailyGoals => _state.goals;
  double get totalCalories => _state.budget.consumedCalories;
  double get totalProtein => _state.macros.protein;
  double get totalCarbs => _state.macros.carbs;
  double get totalFat => _state.macros.fat;
  double get calorieProgress => _state.budget.progressRatio;
  double get proteinProgress => _state.macros.proteinProgress;
  double get carbsProgress => _state.macros.carbsProgress;
  double get fatProgress => _state.macros.fatProgress;
  Map<String, List<Meal>> get mealsByType => _state.mealsByType;
  FastingTrackerController get fastingController => _fasting;
  BiometricsWeightController get biometricsController => _biometrics;

  Future<void> init() async {
    await refreshGoals();
    await Future.wait([
      loadMeals(),
      refreshStreak(),
      refreshWeight(),
    ]);
  }

  Future<void> refreshGoals() async {
    try {
      final goals = await _secureStorage.getDailyGoals();
      _state = _state.copyWith(goals: goals);
      _recalculateNutrition();
    } catch (_) {
      _state = _state.copyWith(goals: const DailyGoals());
    }
    notifyListeners();
    await _syncNativeWidgets();
  }

  Future<void> setSelectedDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    if (_state.selectedDate == normalized) return;
    _state = _state.copyWith(selectedDate: normalized);
    notifyListeners();
    await loadMeals();
  }

  Future<void> goToPreviousDay() =>
      setSelectedDate(_state.selectedDate.subtract(const Duration(days: 1)));

  Future<void> goToNextDay() =>
      setSelectedDate(_state.selectedDate.add(const Duration(days: 1)));

  Future<void> goToToday() => setSelectedDate(DateTime.now());

  Future<void> loadMeals() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    try {
      final fetchedMeals = await _db.getMealsForDay(_state.selectedDate);
      _state = _state.copyWith(meals: fetchedMeals);
      _recalculateNutrition();
      await refreshStreak();
    } catch (_) {
      _state = _state.copyWith(meals: const []);
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      await _syncNativeWidgets();
    }
  }

  void _recalculateNutrition() {
    double cal = 0.0, p = 0.0, c = 0.0, f = 0.0;
    for (final m in _state.meals) {
      cal += m.calories;
      p += m.protein;
      c += m.carbs;
      f += m.fat;
    }
    final budget = DailyCaloricBudget(
      consumedCalories: cal,
      targetCalories: _state.goals.calories,
    );
    final macros = MacroBreakdown(
      protein: p,
      carbs: c,
      fat: f,
      proteinTarget: _state.goals.protein,
      carbsTarget: _state.goals.carbs,
      fatTarget: _state.goals.fat,
    );
    _state = _state.copyWith(budget: budget, macros: macros);
  }

  Future<void> refreshStreak() async {
    try {
      final dates = await _db.getDistinctMealDates();
      final streak = StreakCalculator.calculateStreakFromDates(dates);
      _state = _state.copyWith(streakDays: streak);
    } catch (_) {
      _state = _state.copyWith(streakDays: 0);
    }
    notifyListeners();
  }

  Future<void> refreshWeight() async {
    try {
      final weight = _biometrics.latestWeightLog?.weight ?? _biometrics.currentWeight;
      _state = _state.copyWith(currentWeight: weight);
    } catch (_) {
      _state = _state.copyWith(currentWeight: null);
    }
    notifyListeners();
  }

  Future<void> saveMeal(Meal meal) async {
    await _db.upsertMeal(meal);
    await loadMeals();
  }

  Future<void> addMeal(Meal meal) => saveMeal(meal);

  Future<void> deleteMeal(Meal meal) async {
    await _db.deleteMeal(meal.id);
    await loadMeals();
  }

  Future<void> logWater({
    required String mealName,
    required String notes,
  }) async {
    final waterMeal = Meal(
      name: mealName,
      mealType: 'Snack',
      date: _state.selectedDate,
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      notes: notes,
    );
    await saveMeal(waterMeal);
  }

  Future<void> _syncNativeWidgets() async {
    try {
      final now = DateTime.now();
      final isToday = _state.isToday;
      final todayMeals = isToday ? _state.meals : await _db.getMealsForDay(now);
      double cal = 0, p = 0, c = 0, f = 0;
      for (final m in todayMeals) {
        cal += m.calories;
        p += m.protein;
        c += m.carbs;
        f += m.fat;
      }
      await _widgetSync.saveSummaryData(
        caloriesConsumed: cal.round(),
        caloriesTarget: _state.goals.calories.round(),
        caloriesLeft: (_state.goals.calories - cal).round(),
        proteinConsumed: p.round(),
        proteinLeft: (_state.goals.protein - p).round(),
        carbsConsumed: c.round(),
        carbsLeft: (_state.goals.carbs - c).round(),
        fatConsumed: f.round(),
        fatLeft: (_state.goals.fat - f).round(),
        streakCount: _state.streakDays,
      );
      await _widgetSync.updateWidgets();
    } catch (_) {}
  }
}
