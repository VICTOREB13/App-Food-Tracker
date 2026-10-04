import 'dart:async';
import '../models/food_search_suggestion.dart';
import 'offline_food_estimator_service.dart';
import 'open_food_facts_service.dart';
import 'usda_food_data_service.dart';

/// Coordinator aggregating search results across embedded Local catalog, Open Food Facts, and USDA.
class FoodSearchCoordinator {
  static final FoodSearchCoordinator instance = FoodSearchCoordinator._();
  FoodSearchCoordinator._();

  /// Executes aggregated multi-source query with graceful fallback.
  Future<List<FoodSearchSuggestion>> search(String query) async {
    final clean = query.trim();
    if (clean.length < 2) return const [];

    final results = <FoodSearchSuggestion>[];

    // 1. Embedded Local Catalog (instant zero-tokens response)
    final localMatches = OfflineFoodEstimatorService.instance.searchCatalog(query: clean, limit: 3);
    for (final m in localMatches) {
      results.add(FoodSearchSuggestion(
        name: m.name,
        caloriesPer100g: m.calories,
        proteinPer100g: m.protein,
        carbsPer100g: m.carbs,
        fatPer100g: m.fat,
        fiberPer100g: m.fiber,
        sodiumPer100g: m.sodium,
        sugarPer100g: m.sugar,
        source: FoodSourceBadge.local,
      ));
    }

    // 2. Open Food Facts (public community database)
    try {
      final offMatches = await OpenFoodFactsService.instance
          .searchProductsByText(clean, pageSize: 4)
          .timeout(const Duration(seconds: 4));
      for (final p in offMatches) {
        results.add(FoodSearchSuggestion(
          name: p.name,
          brand: p.brand,
          caloriesPer100g: p.calories,
          proteinPer100g: p.protein,
          carbsPer100g: p.carbs,
          fatPer100g: p.fat,
          fiberPer100g: p.fiber,
          sodiumPer100g: p.sodium,
          sugarPer100g: p.sugar,
          source: FoodSourceBadge.openFoodFacts,
        ));
      }
    } catch (_) {}

    // 3. USDA FoodData Central (official database if API Key is configured)
    try {
      final usdaMatches = await UsdaFoodDataService.instance
          .searchFoods(clean, pageSize: 3)
          .timeout(const Duration(seconds: 4));
      for (final u in usdaMatches) {
        results.add(FoodSearchSuggestion(
          name: u.description,
          brand: u.brandName,
          caloriesPer100g: u.calories,
          proteinPer100g: u.protein,
          carbsPer100g: u.carbs,
          fatPer100g: u.fat,
          source: FoodSourceBadge.usda,
        ));
      }
    } catch (_) {}

    return results;
  }
}
