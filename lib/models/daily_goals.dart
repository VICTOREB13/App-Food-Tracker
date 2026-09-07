import 'model_sanitizer.dart';

class DailyGoals {
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
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) {
    return DailyGoals(
      calories: calories != null ? ModelSanitizer.clampDouble(calories) : this.calories,
      protein: protein != null ? ModelSanitizer.clampDouble(protein) : this.protein,
      carbs: carbs != null ? ModelSanitizer.clampDouble(carbs) : this.carbs,
      fat: fat != null ? ModelSanitizer.clampDouble(fat) : this.fat,
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
      calories: ModelSanitizer.clampDouble(json['calories'] as num?, min: 500, max: 10000),
      protein: ModelSanitizer.clampDouble(json['protein'] as num?, min: 10, max: 1000),
      carbs: ModelSanitizer.clampDouble(json['carbs'] as num?, min: 10, max: 1000),
      fat: ModelSanitizer.clampDouble(json['fat'] as num?, min: 10, max: 1000),
    );
  }
}
