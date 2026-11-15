import 'package:flutter/foundation.dart';
import 'package:food_tracker/core/models/daily_goals.dart';
import 'package:food_tracker/features/food_entry/models/meal.dart';


/// Breakdown of macronutrient intake and targets.
@immutable
class MacroBreakdown {
  final double protein;
  final double carbs;
  final double fat;
  final double proteinTarget;
  final double carbsTarget;
  final double fatTarget;

  static const Object _sentinel = Object();

  const MacroBreakdown({
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.proteinTarget = 0.0,
    this.carbsTarget = 0.0,
    this.fatTarget = 0.0,
  });

  static const MacroBreakdown empty = MacroBreakdown();

  double get proteinProgress =>
      proteinTarget > 0 ? (protein / proteinTarget).clamp(0.0, 1.0) : 0.0;
  double get carbsProgress =>
      carbsTarget > 0 ? (carbs / carbsTarget).clamp(0.0, 1.0) : 0.0;
  double get fatProgress =>
      fatTarget > 0 ? (fat / fatTarget).clamp(0.0, 1.0) : 0.0;

  double get proteinRemaining => proteinTarget - protein;
  double get carbsRemaining => carbsTarget - carbs;
  double get fatRemaining => fatTarget - fat;

  MacroBreakdown copyWith({
    Object? protein = _sentinel,
    Object? carbs = _sentinel,
    Object? fat = _sentinel,
    Object? proteinTarget = _sentinel,
    Object? carbsTarget = _sentinel,
    Object? fatTarget = _sentinel,
  }) {
    return MacroBreakdown(
      protein: identical(protein, _sentinel) ? this.protein : (protein as double),
      carbs: identical(carbs, _sentinel) ? this.carbs : (carbs as double),
      fat: identical(fat, _sentinel) ? this.fat : (fat as double),
      proteinTarget: identical(proteinTarget, _sentinel)
          ? this.proteinTarget
          : (proteinTarget as double),
      carbsTarget: identical(carbsTarget, _sentinel)
          ? this.carbsTarget
          : (carbsTarget as double),
      fatTarget: identical(fatTarget, _sentinel)
          ? this.fatTarget
          : (fatTarget as double),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MacroBreakdown &&
          runtimeType == other.runtimeType &&
          protein == other.protein &&
          carbs == other.carbs &&
          fat == other.fat &&
          proteinTarget == other.proteinTarget &&
          carbsTarget == other.carbsTarget &&
          fatTarget == other.fatTarget;

  @override
  int get hashCode =>
      protein.hashCode ^
      carbs.hashCode ^
      fat.hashCode ^
      proteinTarget.hashCode ^
      carbsTarget.hashCode ^
      fatTarget.hashCode;
}

/// Representation of daily caloric intake vs goal.
@immutable
class DailyCaloricBudget {
  final double consumedCalories;
  final double targetCalories;

  static const Object _sentinel = Object();

  const DailyCaloricBudget({
    this.consumedCalories = 0.0,
    this.targetCalories = 0.0,
  });

  static const DailyCaloricBudget empty = DailyCaloricBudget();

  double get remainingCalories => targetCalories - consumedCalories;
  bool get isOverBudget => consumedCalories > targetCalories;
  double get progressRatio =>
      targetCalories > 0 ? (consumedCalories / targetCalories).clamp(0.0, 1.0) : 0.0;
  int get percentage => (progressRatio * 100).toInt();

  DailyCaloricBudget copyWith({
    Object? consumedCalories = _sentinel,
    Object? targetCalories = _sentinel,
  }) {
    return DailyCaloricBudget(
      consumedCalories: identical(consumedCalories, _sentinel)
          ? this.consumedCalories
          : (consumedCalories as double),
      targetCalories: identical(targetCalories, _sentinel)
          ? this.targetCalories
          : (targetCalories as double),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyCaloricBudget &&
          runtimeType == other.runtimeType &&
          consumedCalories == other.consumedCalories &&
          targetCalories == other.targetCalories;

  @override
  int get hashCode => consumedCalories.hashCode ^ targetCalories.hashCode;
}

/// Immutable state container for the Dashboard vertical slice.
@immutable
class DashboardState {
  final DateTime selectedDate;
  final DailyCaloricBudget budget;
  final MacroBreakdown macros;
  final List<Meal> meals;
  final int streakDays;
  final double? currentWeight;
  final bool isLoading;
  final DailyGoals goals;

  static const Object _sentinel = Object();

  const DashboardState({
    required this.selectedDate,
    this.budget = DailyCaloricBudget.empty,
    this.macros = MacroBreakdown.empty,
    this.meals = const [],
    this.streakDays = 0,
    this.currentWeight,
    this.isLoading = false,
    this.goals = const DailyGoals(),
  });

  static final DashboardState initial = DashboardState(
    selectedDate: DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ),
  );

  bool get isToday {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  Map<String, List<Meal>> get mealsByType {
    final map = <String, List<Meal>>{
      'Desayuno': [],
      'Almuerzo': [],
      'Cena': [],
      'Snack': [],
    };
    for (final m in meals) {
      map[map.containsKey(m.mealType) ? m.mealType : 'Snack']!.add(m);
    }
    return map;
  }

  int get totalMealsCount => meals.length;

  DashboardState copyWith({
    Object? selectedDate = _sentinel,
    Object? budget = _sentinel,
    Object? macros = _sentinel,
    Object? meals = _sentinel,
    Object? streakDays = _sentinel,
    Object? currentWeight = _sentinel,
    Object? isLoading = _sentinel,
    Object? goals = _sentinel,
  }) {
    return DashboardState(
      selectedDate: identical(selectedDate, _sentinel)
          ? this.selectedDate
          : (selectedDate as DateTime),
      budget: identical(budget, _sentinel)
          ? this.budget
          : (budget as DailyCaloricBudget),
      macros: identical(macros, _sentinel)
          ? this.macros
          : (macros as MacroBreakdown),
      meals: identical(meals, _sentinel)
          ? this.meals
          : (meals as List<Meal>),
      streakDays: identical(streakDays, _sentinel)
          ? this.streakDays
          : (streakDays as int),
      currentWeight: identical(currentWeight, _sentinel)
          ? this.currentWeight
          : (currentWeight as double?),
      isLoading: identical(isLoading, _sentinel)
          ? this.isLoading
          : (isLoading as bool),
      goals: identical(goals, _sentinel)
          ? this.goals
          : (goals as DailyGoals),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardState &&
          runtimeType == other.runtimeType &&
          selectedDate.year == other.selectedDate.year &&
          selectedDate.month == other.selectedDate.month &&
          selectedDate.day == other.selectedDate.day &&
          budget == other.budget &&
          macros == other.macros &&
          listEquals(meals, other.meals) &&
          streakDays == other.streakDays &&
          currentWeight == other.currentWeight &&
          isLoading == other.isLoading &&
          goals == other.goals;

  @override
  int get hashCode =>
      selectedDate.hashCode ^
      budget.hashCode ^
      macros.hashCode ^
      meals.hashCode ^
      streakDays.hashCode ^
      currentWeight.hashCode ^
      isLoading.hashCode ^
      goals.hashCode;
}
