import 'package:flutter/foundation.dart';
import '../core/interfaces/database_service_interface.dart';
import '../core/interfaces/image_processing_service_interface.dart';
import '../models/daily_goals.dart';
import '../models/meal.dart';
import '../models/weight_log.dart';
import '../services/database_service.dart';
import '../services/image_processing_service.dart';
import '../services/metabolic_calculator.dart';
import '../services/secure_storage_service.dart';
import 'settings_controller.dart';
import 'streak_calculator.dart';

class MealController extends ChangeNotifier {
  static MealController _instance = MealController();
  static MealController get instance => _instance;

  @visibleForTesting
  static void setMockInstance(MealController mock) => _instance = mock;

  @visibleForTesting
  static void resetInstance() => _instance = MealController();

  final IDatabaseService _db;
  final IImageProcessingService _imageService;

  MealController({
    IDatabaseService? databaseService,
    IImageProcessingService? imageProcessingService,
  })  : _db = databaseService ?? DatabaseService.instance,
        _imageService = imageProcessingService ?? ImageProcessingService.instance;

  DateTime _selectedDate = DateTime.now();
  List<Meal> _meals = [];
  bool _isLoading = false;
  DailyGoals _dailyGoals = const DailyGoals();

  List<WeightLog> _weightLogs = [];
  WeightLog? _latestWeightLog;
  int _selectedWeightDays = 30;
  int _currentStreak = 0;

  DateTime get selectedDate => _selectedDate;
  List<Meal> get meals => List.unmodifiable(_meals);
  bool get isLoading => _isLoading;
  DailyGoals get dailyGoals => _dailyGoals;
  int get currentStreak => _currentStreak;

  List<WeightLog> get weightLogs => List.unmodifiable(_weightLogs);
  WeightLog? get latestWeightLog => _latestWeightLog;
  int get selectedWeightDays => _selectedWeightDays;
  double? get currentWeight => _latestWeightLog?.weight;

  double get totalCalories => _meals.fold(0.0, (acc, m) => acc + m.calories);
  double get totalProtein => _meals.fold(0.0, (acc, m) => acc + m.protein);
  double get totalCarbs => _meals.fold(0.0, (acc, m) => acc + m.carbs);
  double get totalFat => _meals.fold(0.0, (acc, m) => acc + m.fat);

  double get calorieProgress =>
      _dailyGoals.calories > 0 ? (totalCalories / _dailyGoals.calories).clamp(0.0, 1.0) : 0.0;
  double get proteinProgress =>
      _dailyGoals.protein > 0 ? (totalProtein / _dailyGoals.protein).clamp(0.0, 1.0) : 0.0;
  double get carbsProgress =>
      _dailyGoals.carbs > 0 ? (totalCarbs / _dailyGoals.carbs).clamp(0.0, 1.0) : 0.0;
  double get fatProgress =>
      _dailyGoals.fat > 0 ? (totalFat / _dailyGoals.fat).clamp(0.0, 1.0) : 0.0;

  Map<String, List<Meal>> get mealsByType {
    final map = <String, List<Meal>>{
      'Desayuno': [],
      'Almuerzo': [],
      'Cena': [],
      'Snack': [],
    };
    for (final m in _meals) {
      map[map.containsKey(m.mealType) ? m.mealType : 'Snack']!.add(m);
    }
    return map;
  }

  Future<void> init() async {
    await refreshGoals();
    await loadMeals();
    await refreshStreak();
    await loadWeightLogs();
  }

  Future<void> refreshStreak() async {
    try {
      final dates = await _db.getDistinctMealDates();
      _currentStreak = StreakCalculator.calculateStreakFromDates(dates);
    } catch (_) {
      _currentStreak = 0;
    }
  }

  static int calculateStreakFromDates(List<String> dates) =>
      StreakCalculator.calculateStreakFromDates(dates);

  Future<void> refreshGoals() async {
    _dailyGoals = await SecureStorageService.instance.getDailyGoals();
    notifyListeners();
  }

  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
    await loadMeals();
  }

  Future<void> goToPreviousDay() =>
      setSelectedDate(_selectedDate.subtract(const Duration(days: 1)));
  Future<void> goToNextDay() => setSelectedDate(_selectedDate.add(const Duration(days: 1)));
  Future<void> goToToday() => setSelectedDate(DateTime.now());

  Future<void> loadMeals() async {
    _isLoading = true;
    notifyListeners();
    try {
      _meals = await _db.getMealsForDay(_selectedDate);
      await refreshStreak();
    } catch (_) {
      _meals = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveMeal(Meal meal) async {
    await _db.insertMeal(meal);
    await loadMeals();
  }

  Future<void> upsertMeal(Meal meal) async {
    await _db.upsertMeal(meal);
    await loadMeals();
  }

  Future<void> updateMeal(Meal meal) async {
    await _db.updateMeal(meal);
    await loadMeals();
  }

  Future<void> deleteMeal(Meal meal) async {
    if (meal.imagePath != null) {
      await _imageService.deleteMealImage(meal.imagePath);
    }
    await _db.deleteMeal(meal.id);
    await loadMeals();
  }

  Future<int> pruneOldPhotos(int retentionDays) async {
    final count = await _imageService.pruneOldMealPhotos(retentionDays: retentionDays);
    await loadMeals();
    return count;
  }

  Future<void> loadWeightLogs({int days = 30}) async {
    _selectedWeightDays = days;
    try {
      _weightLogs = days <= 0
          ? await _db.getAllWeightLogs()
          : await _db.getWeightLogsLastDays(days);
      _latestWeightLog = await _db.getLatestWeightLog();
    } catch (e) {
      debugPrint('MealController: error loading weight logs: $e');
      _weightLogs = [];
      _latestWeightLog = null;
    }
    notifyListeners();
  }

  Future<void> recordWeight(double weight, {String? notes, DateTime? date}) async {
    final log = WeightLog(weight: weight, notes: notes, date: date ?? DateTime.now());
    await _db.insertWeightLog(log);
    await _syncWeightToProfile(weight);
    await loadWeightLogs(days: _selectedWeightDays);
  }

  Future<void> _syncWeightToProfile(double weight) async {
    try {
      final profile = await _db.getUserProfile();
      if (profile == null) return;

      final newBmr = MetabolicCalculator.calculateBmr(
        gender: profile.gender,
        weightKg: weight,
        heightCm: profile.height,
        age: profile.age,
      );
      final newTdee = MetabolicCalculator.calculateTdee(
        bmr: newBmr,
        activityLevel: profile.activityLevel,
      );

      final prevBmr = MetabolicCalculator.calculateBmr(
        gender: profile.gender,
        weightKg: profile.weight,
        heightCm: profile.height,
        age: profile.age,
      );
      final prevTdee =
          MetabolicCalculator.calculateTdee(bmr: prevBmr, activityLevel: profile.activityLevel);
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
        targetCal = MetabolicCalculator.calculateCaloricGoal(
          tdee: newTdee,
          bmr: newBmr,
          bodyGoal: profile.bodyGoal,
        );
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

      await _db.saveUserProfile(finalProfile);
      await SecureStorageService.instance.setMasterPrompt(newPrompt);
      await SecureStorageService.instance.setDailyGoals(finalProfile.dailyGoals);
      await refreshGoals();
      await SettingsController.instance.refreshDailyGoals(finalProfile.dailyGoals);
      SettingsController.instance.notifyProfileUpdated();
    } catch (e) {
      debugPrint('MealController: error syncing weight to UserProfile: $e');
    }
  }

  Future<void> addWeightLog(double weight, {String? notes, DateTime? date}) =>
      recordWeight(weight, notes: notes, date: date);

  Future<void> deleteWeight(String id) async {
    await _db.deleteWeightLog(id);
    await loadWeightLogs(days: _selectedWeightDays);
  }
}
