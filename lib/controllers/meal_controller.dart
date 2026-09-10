import 'package:flutter/foundation.dart';
import '../models/daily_goals.dart';
import '../models/meal.dart';
import '../models/weight_log.dart';
import '../services/database_service.dart';
import '../services/image_processing_service.dart';
import '../services/metabolic_calculator.dart';
import '../services/secure_storage_service.dart';
import 'settings_controller.dart';

class MealController extends ChangeNotifier {
  static final MealController instance = MealController._();
  MealController._();

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

  double get calorieProgress => _dailyGoals.calories > 0
      ? (totalCalories / _dailyGoals.calories).clamp(0.0, 1.0)
      : 0.0;
  double get proteinProgress => _dailyGoals.protein > 0
      ? (totalProtein / _dailyGoals.protein).clamp(0.0, 1.0)
      : 0.0;
  double get carbsProgress => _dailyGoals.carbs > 0
      ? (totalCarbs / _dailyGoals.carbs).clamp(0.0, 1.0)
      : 0.0;
  double get fatProgress => _dailyGoals.fat > 0
      ? (totalFat / _dailyGoals.fat).clamp(0.0, 1.0)
      : 0.0;

  Map<String, List<Meal>> get mealsByType {
    final map = <String, List<Meal>>{
      'Desayuno': [],
      'Almuerzo': [],
      'Cena': [],
      'Snack': [],
    };
    for (final m in _meals) {
      if (map.containsKey(m.mealType)) {
        map[m.mealType]!.add(m);
      } else {
        map['Snack']!.add(m);
      }
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
      final dates = await DatabaseService.instance.getDistinctMealDates();
      _currentStreak = calculateStreakFromDates(dates);
    } catch (_) {
      _currentStreak = 0;
    }
  }

  static int calculateStreakFromDates(List<String> dates) {
    if (dates.isEmpty) return 0;
    final dateSet = dates.toSet();

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    DateTime checkDate;
    if (dateSet.contains(todayStr)) {
      checkDate = now;
    } else if (dateSet.contains(yesterdayStr)) {
      checkDate = yesterday;
    } else {
      return 0;
    }

    int streak = 0;
    while (true) {
      final key = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (dateSet.contains(key)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> refreshGoals() async {
    _dailyGoals = await SecureStorageService.instance.getDailyGoals();
    notifyListeners();
  }

  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
    await loadMeals();
  }

  Future<void> goToPreviousDay() async {
    await setSelectedDate(_selectedDate.subtract(const Duration(days: 1)));
  }

  Future<void> goToNextDay() async {
    await setSelectedDate(_selectedDate.add(const Duration(days: 1)));
  }

  Future<void> goToToday() async {
    await setSelectedDate(DateTime.now());
  }

  Future<void> loadMeals() async {
    _isLoading = true;
    notifyListeners();
    try {
      _meals = await DatabaseService.instance.getMealsForDay(_selectedDate);
      await refreshStreak();
    } catch (_) {
      _meals = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveMeal(Meal meal) async {
    await DatabaseService.instance.insertMeal(meal);
    await loadMeals();
  }

  Future<void> upsertMeal(Meal meal) async {
    await DatabaseService.instance.upsertMeal(meal);
    await loadMeals();
  }

  Future<void> updateMeal(Meal meal) async {
    await DatabaseService.instance.updateMeal(meal);
    await loadMeals();
  }

  Future<void> deleteMeal(Meal meal) async {
    if (meal.imagePath != null) {
      await ImageProcessingService.instance.deleteMealImage(meal.imagePath);
    }
    await DatabaseService.instance.deleteMeal(meal.id);
    await loadMeals();
  }

  /// Prunes photos older than retentionDays while keeping meal entries intact
  Future<int> pruneOldPhotos(int retentionDays) async {
    final count = await ImageProcessingService.instance.pruneOldMealPhotos(
      retentionDays: retentionDays,
    );
    await loadMeals();
    return count;
  }

  Future<void> loadWeightLogs({int days = 30}) async {
    _selectedWeightDays = days;
    try {
      if (days <= 0) {
        _weightLogs = await DatabaseService.instance.getAllWeightLogs();
      } else {
        _weightLogs = await DatabaseService.instance.getWeightLogsLastDays(days);
      }
      _latestWeightLog = await DatabaseService.instance.getLatestWeightLog();
    } catch (e) {
      debugPrint('MealController: error loading weight logs: $e');
      _weightLogs = [];
      _latestWeightLog = null;
    }
    notifyListeners();
  }

  Future<void> recordWeight(double weight, {String? notes, DateTime? date}) async {
    final log = WeightLog(
      weight: weight,
      notes: notes,
      date: date ?? DateTime.now(),
    );
    await DatabaseService.instance.insertWeightLog(log);

    try {
      final profile = await DatabaseService.instance.getUserProfile();
      if (profile != null) {
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
        final updatedProfile = profile.copyWith(
          weight: weight,
          bmr: newBmr,
          tdee: newTdee,
          updatedAt: DateTime.now(),
        );
        final newPrompt = MetabolicCalculator.generateMasterPrompt(updatedProfile);
        final finalProfile = updatedProfile.copyWith(masterPrompt: newPrompt);
        await DatabaseService.instance.saveUserProfile(finalProfile);
        await SecureStorageService.instance.setMasterPrompt(newPrompt);
        SettingsController.instance.notifyProfileUpdated();
      }
    } catch (e) {
      debugPrint('MealController: error syncing weight to UserProfile: $e');
    }

    await loadWeightLogs(days: _selectedWeightDays);
  }

  Future<void> addWeightLog(double weight, {String? notes, DateTime? date}) =>
      recordWeight(weight, notes: notes, date: date);

  Future<void> deleteWeight(String id) async {
    await DatabaseService.instance.deleteWeightLog(id);
    await loadWeightLogs(days: _selectedWeightDays);
  }
}
