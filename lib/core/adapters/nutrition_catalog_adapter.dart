import 'package:food_tracker/features/pantry_inventory/models/pantry_item.dart';
import 'package:food_tracker/core/models/usda_food_item.dart';
import 'package:food_tracker/features/food_entry/services/barcode_lookup_service.dart';
import 'package:food_tracker/core/services/nutrition/open_food_facts_service.dart';
import 'package:food_tracker/core/services/nutrition/usda_food_data_service.dart';
import '../ports/nutrition_catalog_port.dart';

/// Nutrition catalog and barcode cascade adapter for [INutritionCatalogPort].
class NutritionCatalogAdapter implements INutritionCatalogPort {
  final BarcodeLookupService _barcodeLookupService;
  final UsdaFoodDataService _usdaService;
  final OpenFoodFactsService _offService;

  NutritionCatalogAdapter({
    BarcodeLookupService? barcodeLookupService,
    UsdaFoodDataService? usdaService,
    OpenFoodFactsService? offService,
  })  : _barcodeLookupService =
            barcodeLookupService ?? BarcodeLookupService.instance,
        _usdaService = usdaService ?? UsdaFoodDataService.instance,
        _offService = offService ?? OpenFoodFactsService.instance;

  @override
  Future<BarcodeLookupResult?> lookupBarcode(
    String barcode, {
    String? apiKey,
  }) async {
    final sanitized = barcode.replaceAll(RegExp(r'[^0-9]'), '').trim();
    if (sanitized.isEmpty) return null;

    if (apiKey != null && apiKey.trim().isNotEmpty) {
      try {
        final usdaItem = await _usdaService.fetchProductByBarcode(
          sanitized,
          apiKey: apiKey.trim(),
        );
        if (usdaItem != null) {
          return BarcodeLookupResult(
            item: usdaItem,
            source: BarcodeSource.usda,
          );
        }
      } catch (_) {}

      try {
        final offItem = await _offService.fetchProductByBarcode(sanitized);
        if (offItem != null) {
          return BarcodeLookupResult(
            item: offItem,
            source: BarcodeSource.openFoodFacts,
          );
        }
      } catch (_) {}

      return null;
    }

    return await _barcodeLookupService.lookupBarcodeDetailed(sanitized);
  }

  @override
  Future<PantryItem?> fetchProductByBarcode(
    String barcode, {
    String? apiKey,
  }) async {
    final result = await lookupBarcode(barcode, apiKey: apiKey);
    return result?.item;
  }

  @override
  Future<List<UsdaFoodItem>> searchUsdaFoods(
    String query, {
    int pageSize = 25,
    String? apiKey,
  }) =>
      _usdaService.searchFoods(query, pageSize: pageSize, apiKey: apiKey);

  @override
  Future<UsdaFoodItem?> fetchUsdaItemByBarcode(
    String barcode, {
    String? apiKey,
  }) =>
      _usdaService.fetchByBarcode(barcode, apiKey: apiKey);

  @override
  Future<PantryItem?> fetchOpenFoodFactsProduct(String barcode) =>
      _offService.fetchProductByBarcode(barcode);

  @override
  int? get lastRemainingRequests => _usdaService.lastRemainingRequests;
}
