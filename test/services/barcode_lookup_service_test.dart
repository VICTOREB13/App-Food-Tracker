import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/pantry_item.dart';
import 'package:food_tracker/services/barcode_lookup_service.dart';
import 'package:food_tracker/services/open_food_facts_service.dart';
import 'package:food_tracker/services/secure_storage_service.dart';
import 'package:food_tracker/services/usda_food_data_service.dart';

class MockSecureStorageService extends Fake implements SecureStorageService {
  String? usdaKey;
  @override
  Future<String?> getUsdaApiKey() async => usdaKey;
}

class MockUsdaFoodDataService extends Fake implements UsdaFoodDataService {
  PantryItem? responseItem;
  Exception? exceptionToThrow;
  int callCount = 0;
  String? lastBarcode;
  String? lastApiKey;

  @override
  Future<PantryItem?> fetchProductByBarcode(String barcode, {String? apiKey}) async {
    callCount++;
    lastBarcode = barcode;
    lastApiKey = apiKey;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return responseItem;
  }
}

class MockOpenFoodFactsService extends Fake implements OpenFoodFactsService {
  PantryItem? responseItem;
  Exception? exceptionToThrow;
  int callCount = 0;
  String? lastBarcode;

  @override
  Future<PantryItem?> fetchProductByBarcode(String barcode) async {
    callCount++;
    lastBarcode = barcode;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return responseItem;
  }
}

void main() {
  group('BarcodeLookupService Cascading Resolution Tests', () {
    late MockSecureStorageService mockStorage;
    late MockUsdaFoodDataService mockUsda;
    late MockOpenFoodFactsService mockOff;
    late BarcodeLookupService service;

    setUp(() {
      mockStorage = MockSecureStorageService();
      mockUsda = MockUsdaFoodDataService();
      mockOff = MockOpenFoodFactsService();
      service = BarcodeLookupService.custom(
        secureStorage: mockStorage,
        usdaService: mockUsda,
        offService: mockOff,
      );
      BarcodeLookupService.setMockInstance(service);
    });

    tearDown(() {
      BarcodeLookupService.resetInstance();
    });

    test('Bypasses USDA when usda_api_key is null', () async {
      mockStorage.usdaKey = null;
      mockOff.responseItem = PantryItem(name: 'Avena OFF', calories: 370);

      final result = await service.lookupBarcodeDetailed('737628064502');

      expect(mockUsda.callCount, equals(0));
      expect(mockOff.callCount, equals(1));
      expect(result?.source, equals(BarcodeSource.openFoodFacts));
      expect(result?.item.name, equals('Avena OFF'));
    });

    test('Bypasses USDA when usda_api_key is empty string', () async {
      mockStorage.usdaKey = '   ';
      mockOff.responseItem = PantryItem(name: 'Yogurt OFF', calories: 120);

      final result = await service.lookupBarcode('737628064502');

      expect(mockUsda.callCount, equals(0));
      expect(mockOff.callCount, equals(1));
      expect(result?.name, equals('Yogurt OFF'));
    });

    test('Queries USDA first and returns USDA item when found', () async {
      mockStorage.usdaKey = 'VALID_KEY';
      mockUsda.responseItem = PantryItem(name: 'Quaker Oats USDA', calories: 375);

      final result = await service.lookupBarcodeDetailed('030000010402');

      expect(mockUsda.callCount, equals(1));
      expect(mockOff.callCount, equals(0)); // OFF not called
      expect(result?.source, equals(BarcodeSource.usda));
      expect(result?.item.name, equals('Quaker Oats USDA'));
      expect(mockUsda.lastApiKey, equals('VALID_KEY'));
    });

    test('Cascades to Open Food Facts when USDA returns null (not found)', () async {
      mockStorage.usdaKey = 'VALID_KEY';
      mockUsda.responseItem = null;
      mockOff.responseItem = PantryItem(name: 'Alimento OFF Fallback', calories: 200);

      final result = await service.lookupBarcodeDetailed('030000010402');

      expect(mockUsda.callCount, equals(1));
      expect(mockOff.callCount, equals(1));
      expect(result?.source, equals(BarcodeSource.openFoodFacts));
      expect(result?.item.name, equals('Alimento OFF Fallback'));
    });

    test('Cascades to Open Food Facts when USDA throws exception (403/429/timeout)', () async {
      mockStorage.usdaKey = 'EXPIRED_KEY';
      mockUsda.exceptionToThrow = Exception('HTTP 429: Too Many Requests');
      mockOff.responseItem = PantryItem(name: 'Alimento OFF Resiliente', calories: 210);

      final result = await service.lookupBarcodeDetailed('030000010402');

      expect(mockUsda.callCount, equals(1));
      expect(mockOff.callCount, equals(1));
      expect(result?.source, equals(BarcodeSource.openFoodFacts));
      expect(result?.item.name, equals('Alimento OFF Resiliente'));
    });

    test('Returns null when product is not found in either provider', () async {
      mockStorage.usdaKey = 'VALID_KEY';
      mockUsda.responseItem = null;
      mockOff.responseItem = null;

      final result = await service.lookupBarcode('999999999999');

      expect(result, isNull);
    });

    test('Sanitizes barcode with dashes, spaces, and non-numeric characters', () async {
      mockStorage.usdaKey = null;
      mockOff.responseItem = PantryItem(name: 'Item Limpio', calories: 100);

      final result = await service.lookupBarcode(' 0300-0001-0402#A ');

      expect(mockOff.callCount, equals(1));
      expect(mockOff.lastBarcode, equals('030000010402'));
      expect(result?.name, equals('Item Limpio'));
    });

    test('Returns null immediately for empty or non-digit barcode', () async {
      mockStorage.usdaKey = 'VALID_KEY';

      final result1 = await service.lookupBarcode('');
      final result2 = await service.lookupBarcode('   ');
      final result3 = await service.lookupBarcode('abc-xyz');

      expect(result1, isNull);
      expect(result2, isNull);
      expect(result3, isNull);
      expect(mockUsda.callCount, equals(0));
      expect(mockOff.callCount, equals(0));
    });

    test('Handles Open Food Facts exception without crashing', () async {
      mockStorage.usdaKey = null;
      mockOff.exceptionToThrow = Exception('Network connection reset');

      final result = await service.lookupBarcode('123456789012');

      expect(result, isNull);
      expect(mockOff.callCount, equals(1));
    });
  });
}
