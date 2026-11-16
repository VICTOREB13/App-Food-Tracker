import 'package:flutter/foundation.dart';
import 'package:food_tracker/core/interfaces/database_service_interface.dart';
import 'package:food_tracker/core/interfaces/image_processing_service_interface.dart';
import '../biometrics_weight/biometrics_weight.dart';
import 'food_entry.controller.dart';
import 'food_entry.model.dart';
import 'package:food_tracker/core/database/database_service.dart';
import 'package:food_tracker/core/services/platform/home_widget_service.dart';
import 'package:food_tracker/features/food_entry/services/image_processing_service.dart';
import 'package:food_tracker/core/services/storage/secure_storage_service.dart';
import '../settings_profile/settings_profile.dart';
import 'package:food_tracker/core/utils/streak_calculator.dart';

/// Backward-compatible facade delegating meal operations to [FoodEntryController]
/// and biometrics to [BiometricsWeightController] under Vertical Slice Architecture (<300 LoC).
class MealController extends ChangeNotifier {
  static MealController _instance = MealController();
  static MealController get instance => _instance;

  @visibleForTesting
  static void setMockInstance(MealController mock) => _instance = mock;

  @visibleForTesting
  static void resetInstance() => _instance = MealController();

  final IDatabaseService _db;
  final IImageProcessingService _imageService;
  final FoodEntryController _foodEntry;
  final BiometricsWeightController _biometrics;

  DailyGoals _dailyGoals = const DailyGoals();
  int _currentStreak = 0;
  int _selectedWeightDays = 30;

  MealController({
    IDatabaseService? databaseService,
    IImageProcessingService? imageProcessingService,
    FoodEntryController? foodEntryController,
    BiometricsWeightController? biometricsController,
  })  : _db = databaseService ?? DatabaseService.instance,
        _imageService = imageProcessingService ?? ImageProcessingService.instance,
        _foodEntry = foodEntryController ?? FoodEntryController.instance,
        _biometrics = biometricsController ?? BiometricsWeightController.instance {
    _foodEntry.addListener(notifyListeners);
    _biometrics.addListener(notifyListeners);
  }

  DateTime get selectedDate => _foodEntry.selectedDate;
  List<Meal> get meals => _foodEntry.meals;
  bool get isLoading => _foodEntry.isLoading;
  DailyGoals get dailyGoals => _dailyGoals;
  int get currentStreak => _currentStreak;

  List<WeightLog> get weightLogs => _biometrics.weightLogs;
  WeightLog? get latestWeightLog => _biometrics.latestWeightLog;
  int get selectedWeightDays => _selectedWeightDays;
  double? get currentWeight => _biometrics.latestWeightLog?.weight;

  double get totalCalories => _foodEntry.totalCalories;
  double get totalProtein => _foodEntry.totalProtein;
  double get totalCarbs => _foodEntry.totalCarbs;
  double get totalFat => _foodEntry.totalFat;

  double get calorieProgress =>
      _dailyGoals.calories > 0 ? (totalCalories / _dailyGoals.calories).clamp(0.0, 1.0) : 0.0;
  double get proteinProgress =>
      _dailyGoals.protein > 0 ? (totalProtein / _dailyGoals.protein).clamp(0.0, 1.0) : 0.0;
  double get carbsProgress =>
      _dailyGoals.carbs > 0 ? (totalCarbs / _dailyGoals.carbs).clamp(0.0, 1.0) : 0.0;
  double get fatProgress =>
      _dailyGoals.fat > 0 ? (totalFat / _dailyGoals.fat).clamp(0.0, 1.0) : 0.0;

  Map<String, List<Meal>> get mealsByType => _foodEntry.mealsByType;

  Future<void> init() async {
    try {
      await refreshGoals();
    } catch (e) {
      debugPrint('MealController: error refreshing goals: $e');
    }
    await Future.wait([
      _foodEntry.init(),
      refreshStreak(),
      loadWeightLogs(),
    ]);
  }

  Future<void> refreshStreak() async {
    try {
      final dates = await _db.getDistinctMealDates();
      _currentStreak = StreakCalculator.calculateStreakFromDates(dates);
    } catch (_) {
      _currentStreak = 0;
    }
    notifyListeners();
  }

  static int calculateStreakFromDates(List<String> dates) =>
      StreakCalculator.calculateStreakFromDates(dates);

  Future<void> refreshGoals() async {
    try {
      _dailyGoals = await SecureStorageService.instance.getDailyGoals();
    } catch (_) {
      _dailyGoals = const DailyGoals();
    }
    notifyListeners();
    _syncNativeWidgets();
  }

  Future<void> setSelectedDate(DateTime date) async {
    await _foodEntry.setSelectedDate(date);
    await refreshStreak();
    _syncNativeWidgets();
  }

  Future<void> goToPreviousDay() => setSelectedDate(selectedDate.subtract(const Duration(days: 1)));
  Future<void> goToNextDay() => setSelectedDate(selectedDate.add(const Duration(days: 1)));
  Future<void> goToToday() => setSelectedDate(DateTime.now());

  Future<void> loadMeals() async {
    await _foodEntry.loadMeals();
    await refreshStreak();
    _syncNativeWidgets();
  }

  Future<void> saveMeal(Meal meal) async { await _foodEntry.saveMeal(meal); await refreshStreak(); }
  Future<void> upsertMeal(Meal meal) async { await _foodEntry.upsertMeal(meal); await refreshStreak(); }
  Future<void> addMeal(Meal meal) => upsertMeal(meal);
  Future<void> updateMeal(Meal meal) async { await _foodEntry.updateMeal(meal); await refreshStreak(); }

  Future<void> deleteMeal(Meal meal) async {
    if (meal.imagePath != null) {
      await _imageService.deleteMealImage(meal.imagePath);
    }
    await _foodEntry.deleteMeal(meal);
    await refreshStreak();
  }

  Future<int> pruneOldPhotos(int retentionDays) async {
    final count = await _imageService.pruneOldMealPhotos(retentionDays: retentionDays);
    await loadMeals();
    return count;
  }

  Future<void> loadWeightLogs({int days = 30}) async {
    _selectedWeightDays = days;
    await _biometrics.loadWeightLogs(days: days);
    notifyListeners();
  }

  Future<void> recordWeight(double weight, {String? notes, DateTime? date}) async {
    await _biometrics.recordWeight(weight, notes: notes, date: date);
    await refreshGoals();
    try {
      final profile = await _db.getUserProfile();
      if (profile != null) {
        await SettingsController.instance.refreshDailyGoals(profile.dailyGoals);
        SettingsController.instance.notifyProfileUpdated();
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> addWeightLog(double weight, {String? notes, DateTime? date}) =>
      recordWeight(weight, notes: notes, date: date);

  Future<void> deleteWeight(String id) async {
    await _biometrics.deleteWeight(id);
    notifyListeners();
  }

  Future<void> _syncNativeWidgets() async {
    try {
      final now = DateTime.now();
      final isToday = selectedDate.year == now.year &&
          selectedDate.month == now.month &&
          selectedDate.day == now.day;
      final todayMeals = isToday ? meals : await _db.getMealsForDay(now);
      double cal = 0, p = 0, c = 0, f = 0;
      for (final m in todayMeals) {
        cal += m.calories; p += m.protein; c += m.carbs; f += m.fat;
      }
      await HomeWidgetService.instance.updateFromDailyTotals(
        consumedCalories: cal, targetCalories: _dailyGoals.calories,
        consumedProtein: p, targetProtein: _dailyGoals.protein,
        consumedCarbs: c, targetCarbs: _dailyGoals.carbs,
        consumedFat: f, targetFat: _dailyGoals.fat,
        streakCount: _currentStreak,
      );
    } catch (_) {}
  }
}
