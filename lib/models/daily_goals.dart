import 'package:flutter/foundation.dart';
import 'model_sanitizer.dart';

@immutable
class DailyGoals {
  static const Object _sentinel = Object();

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const DailyGoals({
    this.calories = 2000.0,
    this.protein = 140.0,
    this.carbs = 220.0,
    this.fat = 65.0,
  });

  DailyGoals copyWith({
    Object? calories = _sentinel,
    Object? protein = _sentinel,
    Object? carbs = _sentinel,
    Object? fat = _sentinel,
  }) {
    return DailyGoals(
      calories: !identical(calories, _sentinel)
          ? ModelSanitizer.clampDouble(calories, min: 500, max: 10000)
          : this.calories,
      protein: !identical(protein, _sentinel)
          ? ModelSanitizer.clampDouble(protein, min: 10, max: 1000)
          : this.protein,
      carbs: !identical(carbs, _sentinel)
          ? ModelSanitizer.clampDouble(carbs, min: 10, max: 1000)
          : this.carbs,
      fat: !identical(fat, _sentinel)
          ? ModelSanitizer.clampDouble(fat, min: 10, max: 1000)
          : this.fat,
    );
  }

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

  factory DailyGoals.fromJson(Map<String, dynamic> json) {
    return DailyGoals(
      calories: ModelSanitizer.clampDouble(json['calories'], min: 500, max: 10000),
      protein: ModelSanitizer.clampDouble(json['protein'], min: 10, max: 1000),
      carbs: ModelSanitizer.clampDouble(json['carbs'], min: 10, max: 1000),
      fat: ModelSanitizer.clampDouble(json['fat'], min: 10, max: 1000),
    );
  }
}
