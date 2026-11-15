/// Badge indicating the origin repository of a food item suggestion.
enum FoodSourceBadge { local, usda, openFoodFacts }

/// Unified lightweight model representing nutritional suggestions from Local catalog or Online APIs.
class FoodSearchSuggestion {
  final String name;
  final String? brand;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double fiberPer100g;
  final double sodiumPer100g;
  final double sugarPer100g;
  final FoodSourceBadge source;

  const FoodSearchSuggestion({
    required this.name,
    this.brand,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g = 0.0,
    this.sodiumPer100g = 0.0,
    this.sugarPer100g = 0.0,
    required this.source,
  });

  String get sourceBadgeLabel {
    switch (source) {
      case FoodSourceBadge.local:
        return 'Local';
      case FoodSourceBadge.usda:
        return 'USDA';
      case FoodSourceBadge.openFoodFacts:
        return 'OpenFood';
    }
  }
}
