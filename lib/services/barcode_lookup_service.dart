import 'package:flutter/foundation.dart';
import '../models/pantry_item.dart';
import 'open_food_facts_service.dart';
import 'secure_storage_service.dart';
import 'usda_food_data_service.dart';

enum BarcodeSource {
  usda,
  openFoodFacts,
}

class BarcodeLookupResult {
  final PantryItem item;
  final BarcodeSource source;

  const BarcodeLookupResult({
    required this.item,
    required this.source,
  });
}

class BarcodeLookupService {
  static BarcodeLookupService _instance = BarcodeLookupService._();
  static BarcodeLookupService get instance => _instance;

  final SecureStorageService _secureStorage;
  final UsdaFoodDataService _usdaService;
  final OpenFoodFactsService _offService;

  BarcodeLookupService._({
    SecureStorageService? secureStorage,
    UsdaFoodDataService? usdaService,
    OpenFoodFactsService? offService,
  })  : _secureStorage = secureStorage ?? SecureStorageService.instance,
        _usdaService = usdaService ?? UsdaFoodDataService.instance,
        _offService = offService ?? OpenFoodFactsService.instance;

  @visibleForTesting
  static void setMockInstance(BarcodeLookupService mockService) {
    _instance = mockService;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = BarcodeLookupService._();
  }

  @visibleForTesting
  factory BarcodeLookupService.custom({
    required SecureStorageService secureStorage,
    required UsdaFoodDataService usdaService,
    required OpenFoodFactsService offService,
  }) {
    return BarcodeLookupService._(
      secureStorage: secureStorage,
      usdaService: usdaService,
      offService: offService,
    );
  }

  /// Resolves barcode using cascading fallback:
  /// 1. USDA FoodData Central (if usda_api_key is present).
  /// 2. Open Food Facts (if USDA key absent, item not found, 429 quota, or error).
  Future<PantryItem?> lookupBarcode(String rawBarcode) async {
    final result = await lookupBarcodeDetailed(rawBarcode);
    return result?.item;
  }

  /// Returns both the resolved PantryItem and the originating source.
  Future<BarcodeLookupResult?> lookupBarcodeDetailed(String rawBarcode) async {
    final sanitized = rawBarcode.replaceAll(RegExp(r'[^0-9]'), '').trim();
    if (sanitized.isEmpty) return null;

    // Step 1: Check if USDA API key is configured
    final usdaApiKey = await _secureStorage.getUsdaApiKey();
    if (usdaApiKey != null && usdaApiKey.isNotEmpty) {
      try {
        final usdaItem = await _usdaService.fetchProductByBarcode(
          sanitized,
          apiKey: usdaApiKey,
        );
        if (usdaItem != null) {
          debugPrint('BarcodeLookupService: Resolved $sanitized via USDA FDC');
          return BarcodeLookupResult(
            item: usdaItem,
            source: BarcodeSource.usda,
          );
        }
      } catch (e) {
        debugPrint('BarcodeLookupService: USDA lookup failed ($e), falling back to Open Food Facts');
      }
    }

    // Step 2: Fallback to Open Food Facts
    try {
      final offItem = await _offService.fetchProductByBarcode(sanitized);
      if (offItem != null) {
        debugPrint('BarcodeLookupService: Resolved $sanitized via Open Food Facts');
        return BarcodeLookupResult(
          item: offItem,
          source: BarcodeSource.openFoodFacts,
        );
      }
    } catch (e) {
      debugPrint('BarcodeLookupService: Open Food Facts lookup failed ($e)');
    }

    return null;
  }
}
