import 'package:flutter/foundation.dart';

/// Represents a specific meal or plate suggested by the recommendation engine.
@immutable
class RecommendedDish {
  final String id;
  final String name;
  final String mealType;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String description;
  final List<String> ingredients;
  final String whyRecommended;
  final int fitScore; // Match percentage (0-100%)

  const RecommendedDish({
    required this.id,
    required this.name,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.description,
    required this.ingredients,
    required this.whyRecommended,
    this.fitScore = 95,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mealType': mealType,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'description': description,
        'ingredients': ingredients,
        'whyRecommended': whyRecommended,
        'fitScore': fitScore,
      };

  factory RecommendedDish.fromJson(Map<String, dynamic> json) => RecommendedDish(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        mealType: json['mealType'] as String? ?? 'Almuerzo',
        calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
        description: json['description'] as String? ?? '',
        ingredients: (json['ingredients'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        whyRecommended: json['whyRecommended'] as String? ?? '',
        fitScore: (json['fitScore'] as num?)?.toInt() ?? 95,
      );
}

/// Represents an actionable food swap to reduce fat or increase protein.
@immutable
class FoodSwapSuggestion {
  final String originalFood;
  final String substituteFood;
  final String rationale;
  final double fatSavedGrams;
  final double proteinGainedGrams;

  const FoodSwapSuggestion({
    required this.originalFood,
    required this.substituteFood,
    required this.rationale,
    this.fatSavedGrams = 0.0,
    this.proteinGainedGrams = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'originalFood': originalFood,
        'substituteFood': substituteFood,
        'rationale': rationale,
        'fatSavedGrams': fatSavedGrams,
        'proteinGainedGrams': proteinGainedGrams,
      };

  factory FoodSwapSuggestion.fromJson(Map<String, dynamic> json) => FoodSwapSuggestion(
        originalFood: json['originalFood'] as String? ?? '',
        substituteFood: json['substituteFood'] as String? ?? '',
        rationale: json['rationale'] as String? ?? '',
        fatSavedGrams: (json['fatSavedGrams'] as num?)?.toDouble() ?? 0.0,
        proteinGainedGrams: (json['proteinGainedGrams'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Comprehensive nutritional diagnostic report across 7, 15, or 30 days.
@immutable
class NutritionalAnalysisReport {
  final int daysAnalyzed;
  final int mealsLogged;
  final double averageDailyCalories;
  final double averageDailyProtein;
  final double averageDailyCarbs;
  final double averageDailyFat;

  final double targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;

  final String fatDiagnosis;
  final String proteinDiagnosis;
  final String carbsDiagnosis;
  final String calorieDiagnosis;

  final List<FoodSwapSuggestion> fatReductionSwaps;
  final List<FoodSwapSuggestion> proteinIncreaseSuggestions;
  final List<RecommendedDish> suggestedPlates;

  const NutritionalAnalysisReport({
    required this.daysAnalyzed,
    required this.mealsLogged,
    required this.averageDailyCalories,
    required this.averageDailyProtein,
    required this.averageDailyCarbs,
    required this.averageDailyFat,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    required this.fatDiagnosis,
    required this.proteinDiagnosis,
    required this.carbsDiagnosis,
    required this.calorieDiagnosis,
    required this.fatReductionSwaps,
    required this.proteinIncreaseSuggestions,
    required this.suggestedPlates,
  });

  double get calorieDelta => averageDailyCalories - targetCalories;
  double get proteinDelta => averageDailyProtein - targetProtein;
  double get carbsDelta => averageDailyCarbs - targetCarbs;
  double get fatDelta => averageDailyFat - targetFat;
}

/// Instant plan for "¿Qué debería comer hoy?" based on remaining macros.
@immutable
class TodayRecommendationPlan {
  final double remainingCalories;
  final double remainingProtein;
  final double remainingCarbs;
  final double remainingFat;
  final String nextMealType;
  final String generalAdvice;
  final List<RecommendedDish> recommendedOptions;

  const TodayRecommendationPlan({
    required this.remainingCalories,
    required this.remainingProtein,
    required this.remainingCarbs,
    required this.remainingFat,
    required this.nextMealType,
    required this.generalAdvice,
    required this.recommendedOptions,
  });
}
