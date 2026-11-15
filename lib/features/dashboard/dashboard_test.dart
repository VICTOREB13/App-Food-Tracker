import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/core/interfaces/database_service_interface.dart';
import 'package:food_tracker/core/ports/app_widget_sync_port.dart';
import 'package:food_tracker/core/ports/secure_storage_port.dart';
import 'package:food_tracker/core/models/daily_goals.dart';
import 'package:food_tracker/features/food_entry/models/meal.dart';
import 'dashboard.dart';

class _FakeDatabaseService implements IDatabaseService {
  final List<Meal> meals;
  final List<String> distinctDates;

  _FakeDatabaseService({
    List<Meal>? meals,
    List<String>? distinctDates,
  })  : meals = meals ?? [],
        distinctDates = distinctDates ?? [];

  @override
  Future<List<Meal>> getMealsForDay(DateTime day) async {
    return meals.where((m) =>
        m.date.year == day.year &&
        m.date.month == day.month &&
        m.date.day == day.day).toList();
  }

  @override
  Future<List<String>> getDistinctMealDates() async => distinctDates;

  @override
  Future<int> upsertMeal(Meal meal) async {
    meals.removeWhere((m) => m.id == meal.id);
    meals.add(meal);
    return 1;
  }

  @override
  Future<int> deleteMeal(String id) async {
    meals.removeWhere((m) => m.id == id);
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSecureStoragePort implements ISecureStoragePort {
  DailyGoals goals = const DailyGoals(calories: 2000, protein: 150, carbs: 200, fat: 65);

  @override
  Future<DailyGoals> getDailyGoals() async => goals;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAppWidgetSyncPort implements IAppWidgetSyncPort {
  int lastSavedCalories = 0;
  int lastSavedStreak = 0;
  bool updateWidgetsCalled = false;

  @override
  Future<void> saveSummaryData({
    required int caloriesConsumed,
    required int caloriesTarget,
    required int caloriesLeft,
    required int proteinConsumed,
    required int proteinLeft,
    required int carbsConsumed,
    required int carbsLeft,
    required int fatConsumed,
    required int fatLeft,
    int streakCount = 0,
  }) async {
    lastSavedCalories = caloriesConsumed;
    lastSavedStreak = streakCount;
  }

  @override
  Future<void> updateWidgets() async {
    updateWidgetsCalled = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyCaloricBudget Sentinel & Budget Calculations', () {
    test('initial empty budget defaults', () {
      const budget = DailyCaloricBudget.empty;
      expect(budget.consumedCalories, 0.0);
      expect(budget.targetCalories, 0.0);
      expect(budget.remainingCalories, 0.0);
      expect(budget.isOverBudget, isFalse);
      expect(budget.progressRatio, 0.0);
      expect(budget.percentage, 0);
    });

    test('calculates remaining calories and over budget accurately', () {
      const underBudget = DailyCaloricBudget(consumedCalories: 1400, targetCalories: 2000);
      expect(underBudget.remainingCalories, 600.0);
      expect(underBudget.isOverBudget, isFalse);
      expect(underBudget.progressRatio, closeTo(0.7, 0.001));
      expect(underBudget.percentage, 70);

      const overBudget = DailyCaloricBudget(consumedCalories: 2350, targetCalories: 2000);
      expect(overBudget.remainingCalories, -350.0);
      expect(overBudget.isOverBudget, isTrue);
      expect(overBudget.progressRatio, 1.0); // clamped at 1.0
      expect(overBudget.percentage, 100);
    });

    test('copyWith preserves sentinel defaults and updates specified fields', () {
      const original = DailyCaloricBudget(consumedCalories: 1200, targetCalories: 1800);
      final updated = original.copyWith(consumedCalories: 1500);
      expect(updated.consumedCalories, 1500);
      expect(updated.targetCalories, 1800);

      final unchanged = original.copyWith();
      expect(unchanged, equals(original));
      expect(unchanged.hashCode, equals(original.hashCode));
    });
  });

  group('MacroBreakdown Sentinel & Progression', () {
    test('initial empty breakdown defaults', () {
      const macros = MacroBreakdown.empty;
      expect(macros.protein, 0.0);
      expect(macros.proteinProgress, 0.0);
      expect(macros.proteinRemaining, 0.0);
    });

    test('calculates macro progress ratios and remaining amounts', () {
      const macros = MacroBreakdown(
        protein: 75, carbs: 100, fat: 30,
        proteinTarget: 150, carbsTarget: 200, fatTarget: 60,
      );
      expect(macros.proteinProgress, closeTo(0.5, 0.001));
      expect(macros.carbsProgress, closeTo(0.5, 0.001));
      expect(macros.fatProgress, closeTo(0.5, 0.001));
      expect(macros.proteinRemaining, 75.0);
      expect(macros.carbsRemaining, 100.0);
      expect(macros.fatRemaining, 30.0);
    });

    test('copyWith preserves sentinel values and equality', () {
      const original = MacroBreakdown(protein: 50, proteinTarget: 100);
      final updated = original.copyWith(protein: 80);
      expect(updated.protein, 80);
      expect(updated.proteinTarget, 100);
      expect(original.copyWith(), equals(original));
    });
  });

  group('DashboardState Sentinel & Categorization', () {
    test('initial state defaults', () {
      final state = DashboardState.initial;
      expect(state.isLoading, isFalse);
      expect(state.meals, isEmpty);
      expect(state.streakDays, 0);
      expect(state.totalMealsCount, 0);
      expect(state.isToday, isTrue);
    });

    test('mealsByType categorizes meals into four standard groups', () {
      final today = DateTime.now();
      final meals = [
        Meal(id: '1', name: 'Huevos', mealType: 'Desayuno', date: today, calories: 300, protein: 20, carbs: 5, fat: 15),
        Meal(id: '2', name: 'Pollo', mealType: 'Almuerzo', date: today, calories: 500, protein: 40, carbs: 40, fat: 10),
        Meal(id: '3', name: 'Atun', mealType: 'Cena', date: today, calories: 350, protein: 30, carbs: 10, fat: 8),
        Meal(id: '4', name: 'Nueces', mealType: 'Snack', date: today, calories: 200, protein: 5, carbs: 10, fat: 18),
      ];
      final state = DashboardState(selectedDate: today, meals: meals);
      final byType = state.mealsByType;
      expect(byType['Desayuno']!.length, 1);
      expect(byType['Almuerzo']!.length, 1);
      expect(byType['Cena']!.length, 1);
      expect(byType['Snack']!.length, 1);
      expect(state.totalMealsCount, 4);
    });

    test('copyWith preserves sentinel defaults', () {
      final state = DashboardState.initial;
      final copied = state.copyWith(streakDays: 5);
      expect(copied.streakDays, 5);
      expect(copied.isLoading, state.isLoading);
      expect(copied.selectedDate, state.selectedDate);
    });
  });

  group('DashboardController Orchestration', () {
    late _FakeDatabaseService fakeDb;
    late _FakeSecureStoragePort fakeStorage;
    late _FakeAppWidgetSyncPort fakeWidgetSync;
    late DashboardController controller;
    final testDate = DateTime(2026, 11, 15);

    setUp(() {
      final testMeals = [
        Meal(id: 'm1', name: 'Omelette', mealType: 'Desayuno', date: testDate, calories: 400, protein: 30, carbs: 10, fat: 20),
        Meal(id: 'm2', name: 'Ensalada Cesar', mealType: 'Almuerzo', date: testDate, calories: 600, protein: 45, carbs: 30, fat: 25),
      ];
      final distinctDates = ['2026-11-15', '2026-11-14', '2026-11-13'];

      fakeDb = _FakeDatabaseService(meals: testMeals, distinctDates: distinctDates);
      fakeStorage = _FakeSecureStoragePort();
      fakeWidgetSync = _FakeAppWidgetSyncPort();

      controller = DashboardController(
        databaseService: fakeDb,
        secureStoragePort: fakeStorage,
        appWidgetSyncPort: fakeWidgetSync,
        initialDate: testDate,
      );
    });

    test('init loads goals, meals, streak, and syncs widget', () async {
      await controller.init();

      expect(controller.meals.length, 2);
      expect(controller.totalCalories, 1000.0);
      expect(controller.totalProtein, 75.0);
      expect(controller.totalCarbs, 40.0);
      expect(controller.totalFat, 45.0);
      expect(controller.budget.remainingCalories, 1000.0); // 2000 - 1000
      expect(controller.streakDays, 3);
      expect(fakeWidgetSync.updateWidgetsCalled, isTrue);
    });

    test('date navigation updates selected date and reloads data', () async {
      await controller.init();
      final prevDate = testDate.subtract(const Duration(days: 1));

      await controller.goToPreviousDay();
      expect(controller.selectedDate.day, prevDate.day);
      expect(controller.meals, isEmpty);
      expect(controller.totalCalories, 0.0);

      await controller.goToNextDay();
      expect(controller.selectedDate.day, testDate.day);
      expect(controller.meals.length, 2);
    });

    test('saveMeal and deleteMeal recalculate totals correctly', () async {
      await controller.init();
      expect(controller.totalCalories, 1000.0);

      final newMeal = Meal(
        id: 'm3', name: 'Batido de Proteína', mealType: 'Snack',
        date: testDate, calories: 250, protein: 30, carbs: 10, fat: 3,
      );
      await controller.saveMeal(newMeal);
      expect(controller.meals.length, 3);
      expect(controller.totalCalories, 1250.0);

      await controller.deleteMeal(newMeal);
      expect(controller.meals.length, 2);
      expect(controller.totalCalories, 1000.0);
    });

    test('logWater saves 0-calorie hydration meal', () async {
      await controller.init();
      await controller.logWater(mealName: 'Agua (+250 ml)', notes: 'Hidratación rápida');

      expect(controller.meals.length, 3);
      final water = controller.meals.firstWhere((m) => m.name == 'Agua (+250 ml)');
      expect(water.calories, 0.0);
      expect(water.protein, 0.0);
      expect(water.mealType, 'Snack');
      expect(controller.totalCalories, 1000.0);
    });
  });
}
