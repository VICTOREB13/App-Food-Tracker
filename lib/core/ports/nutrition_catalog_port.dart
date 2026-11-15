import 'package:food_tracker/features/pantry_inventory/models/pantry_item.dart';
import 'package:food_tracker/core/models/usda_food_item.dart';
import 'package:food_tracker/features/food_entry/services/barcode_lookup_service.dart' show BarcodeLookupResult, BarcodeSource;

export 'package:food_tracker/features/food_entry/services/barcode_lookup_service.dart' show BarcodeLookupResult, BarcodeSource;

/// Hexagonal port for external nutritional catalogs and barcode lookup providers.
abstract interface class INutritionCatalogPort {
  /// Looks up product information across cascading providers (e.g. USDA -> OpenFoodFacts).
  Future<BarcodeLookupResult?> lookupBarcode(
    String barcode, {
    String? apiKey,
  });

  /// Resolves barcode directly to a PantryItem with fallback across catalogs.
  Future<PantryItem?> fetchProductByBarcode(
    String barcode, {
    String? apiKey,
  });

  /// Searches USDA FoodData Central catalog by text query.
  Future<List<UsdaFoodItem>> searchUsdaFoods(
    String query, {
    int pageSize = 25,
    String? apiKey,
  });

  /// Fetches an item specifically from USDA FoodData Central by barcode.
  Future<UsdaFoodItem?> fetchUsdaItemByBarcode(
    String barcode, {
    String? apiKey,
  });

  /// Fetches an item specifically from Open Food Facts by barcode.
  Future<PantryItem?> fetchOpenFoodFactsProduct(
    String barcode,
  );

  /// Number of remaining API requests allowed under the current rate limit window, if available.
  int? get lastRemainingRequests;
}
