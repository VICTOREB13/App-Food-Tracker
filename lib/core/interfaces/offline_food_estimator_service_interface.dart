import '../../models/food_item.dart';

/// Contract for the Zero-Tokens local food estimator service.
abstract interface class IOfflineFoodEstimatorService {
  /// Estimates nutritional values and returns a FoodItem scaled to the requested grams.
  FoodItem? estimateNutrients({required String query, required double grams});

  /// Searches the offline food catalog for matching ingredients.
  List<FoodItem> searchCatalog({required String query, int limit = 10});
}
