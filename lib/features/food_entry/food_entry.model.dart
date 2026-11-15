import 'package:flutter/foundation.dart';
import 'package:food_tracker/features/food_entry/models/calibrated_dishware.dart';
import 'package:food_tracker/features/food_entry/models/food_item.dart';
import 'package:food_tracker/features/food_entry/models/meal.dart';
import 'package:food_tracker/features/food_entry/models/meal_analysis_result.dart';
import 'package:food_tracker/features/food_entry/models/meal_template.dart';

export 'package:food_tracker/features/food_entry/models/calibrated_dishware.dart';
export 'package:food_tracker/features/food_entry/models/food_item.dart';
export 'package:food_tracker/features/food_entry/models/meal.dart';
export 'package:food_tracker/features/food_entry/models/meal_analysis_result.dart';
export 'package:food_tracker/features/food_entry/models/meal_template.dart';
export 'package:food_tracker/features/food_entry/models/meal_decomposer.dart';
export 'package:food_tracker/features/food_entry/models/meal_image_file_info.dart';
export 'package:food_tracker/features/food_entry/models/food_search_suggestion.dart';

/// Semantic alias for food items within a meal slice.
typedef MealItem = FoodItem;

/// Operation status of the Food Entry vertical slice.
enum FoodEntryStatus {
  idle,
  loading,
  analyzing,
  saving,
  success,
  error;
}

/// Pure domain utility for macro and micronutrient computations and portion scaling.
class FoodNutritionCalculator {
  /// Aggregates nutritional macros and micros across a list of food items.
  static Map<String, double> calculateNutrientTotals(List<FoodItem> items) {
    double cal = 0.0, prot = 0.0, carbs = 0.0, fat = 0.0;
    double fib = 0.0, sod = 0.0, sug = 0.0;
    for (final item in items) {
      cal += item.calories;
      prot += item.protein;
      carbs += item.carbs;
      fat += item.fat;
      fib += item.fiber;
      sod += item.sodium;
      sug += item.sugar;
    }
    return {
      'calories': cal,
      'protein': prot,
      'carbs': carbs,
      'fat': fat,
      'fiber': fib,
      'sodium': sod,
      'sugar': sug,
    };
  }

  /// Linearly scales nutritional values of an item according to target gram portion.
  static FoodItem scaleItemPortion(FoodItem item, double newGrams) {
    final baseGrams = item.estimatedGrams > 0.0 ? item.estimatedGrams : 100.0;
    final ratio = newGrams > 0.0 ? (newGrams / baseGrams) : 0.0;
    return item.copyWith(
      estimatedGrams: newGrams,
      calories: (item.calories * ratio),
      protein: (item.protein * ratio),
      carbs: (item.carbs * ratio),
      fat: (item.fat * ratio),
      fiber: (item.fiber * ratio),
      sodium: (item.sodium * ratio),
      sugar: (item.sugar * ratio),
    );
  }

  /// Calculates percentage of total caloric energy provided by a macro.
  static double calculateMacroPercentage(double macroGrams, double totalCalories, {required bool isFat}) {
    if (totalCalories <= 0.0 || macroGrams <= 0.0) return 0.0;
    final calPerGram = isFat ? 9.0 : 4.0;
    final macroCalories = macroGrams * calPerGram;
    return ((macroCalories / totalCalories) * 100.0).clamp(0.0, 100.0);
  }
}

/// Immutable state container for Food Entry & Meal Management slice.
@immutable
class FoodEntryState {
  final FoodEntryStatus status;
  final DateTime selectedDate;
  final List<Meal> meals;
  final Meal? activeMeal;
  final List<CalibratedDishware> dishwareList;
  final CalibratedDishware? defaultDishware;
  final List<MealTemplate> templates;
  final MealAnalysisResult? lastAnalysis;
  final double? analysisProgress;
  final String? analysisStage;
  final String? errorMessage;

  static const Object _sentinel = Object();

  static final FoodEntryState initial = FoodEntryState(
    status: FoodEntryStatus.idle,
    selectedDate: DateTime.now(),
    meals: const [],
    dishwareList: const [],
    templates: const [],
  );

  const FoodEntryState({
    required this.status,
    required this.selectedDate,
    this.meals = const [],
    this.activeMeal,
    this.dishwareList = const [],
    this.defaultDishware,
    this.templates = const [],
    this.lastAnalysis,
    this.analysisProgress,
    this.analysisStage,
    this.errorMessage,
  });

  bool get isIdle => status == FoodEntryStatus.idle;
  bool get isLoading => status == FoodEntryStatus.loading;
  bool get isAnalyzing => status == FoodEntryStatus.analyzing;
  bool get isSaving => status == FoodEntryStatus.saving;
  bool get hasError => status == FoodEntryStatus.error || errorMessage != null;

  double get totalCalories => meals.fold(0.0, (acc, m) => acc + m.calories);
  double get totalProtein => meals.fold(0.0, (acc, m) => acc + m.protein);
  double get totalCarbs => meals.fold(0.0, (acc, m) => acc + m.carbs);
  double get totalFat => meals.fold(0.0, (acc, m) => acc + m.fat);
  double get totalFiber => meals.fold(0.0, (acc, m) => acc + m.fiber);
  double get totalSodium => meals.fold(0.0, (acc, m) => acc + m.sodium);
  double get totalSugar => meals.fold(0.0, (acc, m) => acc + m.sugar);

  Map<String, List<Meal>> get mealsByType {
    final map = <String, List<Meal>>{
      'Desayuno': [],
      'Almuerzo': [],
      'Cena': [],
      'Snack': [],
    };
    for (final m in meals) {
      final key = map.containsKey(m.mealType) ? m.mealType : 'Snack';
      map[key]!.add(m);
    }
    return map;
  }

  FoodEntryState copyWith({
    FoodEntryStatus? status,
    DateTime? selectedDate,
    List<Meal>? meals,
    Object? activeMeal = _sentinel,
    List<CalibratedDishware>? dishwareList,
    Object? defaultDishware = _sentinel,
    List<MealTemplate>? templates,
    Object? lastAnalysis = _sentinel,
    Object? analysisProgress = _sentinel,
    Object? analysisStage = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return FoodEntryState(
      status: status ?? this.status,
      selectedDate: selectedDate ?? this.selectedDate,
      meals: meals ?? this.meals,
      activeMeal: identical(activeMeal, _sentinel) ? this.activeMeal : (activeMeal as Meal?),
      dishwareList: dishwareList ?? this.dishwareList,
      defaultDishware: identical(defaultDishware, _sentinel)
          ? this.defaultDishware
          : (defaultDishware as CalibratedDishware?),
      templates: templates ?? this.templates,
      lastAnalysis: identical(lastAnalysis, _sentinel)
          ? this.lastAnalysis
          : (lastAnalysis as MealAnalysisResult?),
      analysisProgress: identical(analysisProgress, _sentinel)
          ? this.analysisProgress
          : (analysisProgress as double?),
      analysisStage: identical(analysisStage, _sentinel)
          ? this.analysisStage
          : (analysisStage as String?),
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : (errorMessage as String?),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodEntryState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          selectedDate == other.selectedDate &&
          listEquals(meals, other.meals) &&
          activeMeal == other.activeMeal &&
          listEquals(dishwareList, other.dishwareList) &&
          defaultDishware == other.defaultDishware &&
          listEquals(templates, other.templates) &&
          lastAnalysis == other.lastAnalysis &&
          analysisProgress == other.analysisProgress &&
          analysisStage == other.analysisStage &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        status,
        selectedDate,
        Object.hashAll(meals),
        activeMeal,
        Object.hashAll(dishwareList),
        defaultDishware,
        Object.hashAll(templates),
        lastAnalysis,
        analysisProgress,
        analysisStage,
        errorMessage,
      );
}
