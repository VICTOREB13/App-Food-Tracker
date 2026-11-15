/// Class representing the macronutrient split distribution in grams
class MacroDistribution {
  final double protein;
  final double carbs;
  final double fat;

  const MacroDistribution({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  double get proteinCalories => protein * 4.0;
  double get carbsCalories => carbs * 4.0;
  double get fatCalories => fat * 9.0;
  double get totalCalories => proteinCalories + carbsCalories + fatCalories;

  @override
  String toString() =>
      'MacroDistribution(protein: ${protein}g, carbs: ${carbs}g, fat: ${fat}g, total: ${totalCalories}kcal)';
}
