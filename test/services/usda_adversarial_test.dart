import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:food_tracker/models/pantry_item.dart';
import 'package:food_tracker/models/usda_food_item.dart';
import 'package:food_tracker/services/barcode_lookup_service.dart';
import 'package:food_tracker/services/open_food_facts_service.dart';
import 'package:food_tracker/services/secure_storage_service.dart';
import 'package:food_tracker/services/usda_food_data_service.dart';

class MockSecureStorageService extends Fake implements SecureStorageService {
  String? usdaKey = 'VALID_TEST_KEY';
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
  group('UsdaNutrientParser Adversarial & Mathematical Precision Tests', () {
    test('Converts kJ to kcal with exact 4.184 factor and handles unit variants', () {
      // 1. 418.4 kJ / 4.184 = 100.00 kcal
      final raw1 = [
        {'nutrientId': 1008, 'value': 418.4, 'unitName': 'kJ'}
      ];
      final val1 = UsdaNutrientParser.parseNutrient(raw1, UsdaNutrientParser.energyIds);
      expect(val1, equals(100.0));

      // 2. 1000 kJ / 4.184 = 239.005736... -> rounded to 239.01
      final raw2 = [
        {'nutrientId': 1008, 'value': 1000.0, 'unitName': 'kJ'}
      ];
      final val2 = UsdaNutrientParser.parseNutrient(raw2, UsdaNutrientParser.energyIds);
      expect(val2, equals(239.01));

      // 3. 41.84 kJ -> 10.00 kcal
      final raw3 = [
        {'nutrientId': 1008, 'value': 41.84, 'unitName': 'KILOJOULES'}
      ];
      final val3 = UsdaNutrientParser.parseNutrient(raw3, UsdaNutrientParser.energyIds);
      expect(val3, equals(10.0));

      // 4. Case insensitivity: 'kj', 'KJ', 'Kilojoule', 'KILOJOULE'
      for (final unit in ['kj', 'KJ', 'Kilojoule', 'KILOJOULE']) {
        final parsed = UsdaNutrientParser.parseNutrient(
          [
            {'nutrientId': 1008, 'value': 418.4, 'unitName': unit}
          ],
          UsdaNutrientParser.energyIds,
        );
        expect(parsed, equals(100.0), reason: 'Failed for unit variation: $unit');
      }

      // 5. KCAL energy is NOT divided
      final rawKcal = [
        {'nutrientId': 1008, 'value': 150.0, 'unitName': 'KCAL'}
      ];
      final valKcal = UsdaNutrientParser.parseNutrient(rawKcal, UsdaNutrientParser.energyIds);
      expect(valKcal, equals(150.0));
    });

    test('Handles negative, extreme, NaN, and infinity values safely', () {
      // 1. Negative values clamped to 0.0
      final neg = [
        {'nutrientId': 1008, 'value': -50.0, 'unitName': 'KCAL'},
        {'nutrientId': 1003, 'value': -10.0, 'unitName': 'G'}
      ];
      expect(UsdaNutrientParser.parseNutrient(neg, UsdaNutrientParser.energyIds), equals(0.0));
      expect(UsdaNutrientParser.parseNutrient(neg, const [UsdaNutrientParser.idProtein]), equals(0.0));

      // 2. Extreme value clamped to 9999.0
      final extreme = [
        {'nutrientId': 1008, 'value': 100000.0, 'unitName': 'KCAL'}
      ];
      expect(UsdaNutrientParser.parseNutrient(extreme, UsdaNutrientParser.energyIds), equals(9999.0));

      // 3. NaN clamped to 0.0
      final nanVal = [
        {'nutrientId': 1008, 'value': double.nan, 'unitName': 'KCAL'}
      ];
      expect(UsdaNutrientParser.parseNutrient(nanVal, UsdaNutrientParser.energyIds), equals(0.0));

      // 4. Infinity clamped to 9999.0
      final infVal = [
        {'nutrientId': 1008, 'value': double.infinity, 'unitName': 'KCAL'}
      ];
      expect(UsdaNutrientParser.parseNutrient(infVal, UsdaNutrientParser.energyIds), equals(9999.0));

      // 5. Negative infinity clamped to 0.0
      final negInfVal = [
        {'nutrientId': 1008, 'value': double.negativeInfinity, 'unitName': 'KCAL'}
      ];
      expect(UsdaNutrientParser.parseNutrient(negInfVal, UsdaNutrientParser.energyIds), equals(0.0));
    });

    test('Handles null values and missing IDs gracefully across dual schemas', () {
      // 1. Null value skips to next item with valid value
      final nullItem = [
        {'nutrientId': 1008, 'value': null, 'unitName': 'KCAL'},
        {'nutrientId': 1008, 'value': 250.0, 'unitName': 'KCAL'}
      ];
      expect(UsdaNutrientParser.parseNutrient(nullItem, UsdaNutrientParser.energyIds), equals(250.0));

      // 2. Missing nutrientId resolved via nutrientNumber / number string
      final numberOnly = [
        {'nutrientNumber': '208', 'value': 320.0, 'unitName': 'KCAL'}
      ];
      expect(
        UsdaNutrientParser.parseNutrient(
          numberOnly,
          UsdaNutrientParser.energyIds,
          targetNumbers: const ['208'],
        ),
        equals(320.0),
      );

      // 3. Nested detail schema with amount and nested nutrient
      final nested = [
        {
          'nutrient': {'id': 1003, 'number': '203', 'name': 'Protein', 'unitName': 'g'},
          'amount': 24.5
        }
      ];
      expect(
        UsdaNutrientParser.parseNutrient(
          nested,
          const [UsdaNutrientParser.idProtein],
          targetNumbers: const ['203'],
        ),
        equals(24.5),
      );

      // 4. Completely unmatched IDs return 0.0
      final unmatched = [
        {'nutrientId': 9999, 'value': 100.0}
      ];
      expect(UsdaNutrientParser.parseNutrient(unmatched, UsdaNutrientParser.energyIds), equals(0.0));
    });

    test('Zero energy with positive macros persists correctly without crash or distortion', () {
      final json = {
        'fdcId': 77777,
        'description': 'Isolated Pure Protein Powder',
        'servingSize': 100.0,
        'servingSizeUnit': 'g',
        'foodNutrients': [
          {'nutrientId': 1008, 'value': 0.0, 'unitName': 'KCAL'},
          {'nutrientId': 1003, 'value': 25.0, 'unitName': 'G'},
          {'nutrientId': 1004, 'value': 10.0, 'unitName': 'G'},
          {'nutrientId': 1005, 'value': 30.0, 'unitName': 'G'},
        ]
      };

      final item = UsdaFoodItem.fromFdcJson(json);
      expect(item.calories, equals(0.0));
      expect(item.protein, equals(25.0));
      expect(item.fat, equals(10.0));
      expect(item.carbs, equals(30.0));

      final pantry = item.toPantryItem();
      expect(pantry.calories, equals(0.0));
      expect(pantry.protein, equals(25.0));

      final foodScaled = item.toFoodItem(estimatedGrams: 200.0);
      expect(foodScaled.calories, equals(0.0));
      expect(foodScaled.protein, equals(50.0));
      expect(foodScaled.fat, equals(20.0));
      expect(foodScaled.carbs, equals(60.0));
    });

    test('Decimal rounding and serving size scaling boundary conditions', () {
      final json = {
        'fdcId': 88888,
        'description': 'High Precision Granola',
        'servingSize': 40.0,
        'servingSizeUnit': 'g',
        'foodNutrients': [
          {'nutrientId': 1008, 'value': 150.0, 'unitName': 'KCAL'},
          {'nutrientId': 1003, 'value': 5.3333, 'unitName': 'G'},
          {'nutrientId': 1004, 'value': 2.6666, 'unitName': 'G'},
          {'nutrientId': 1005, 'value': 27.1234, 'unitName': 'G'},
        ]
      };

      final item = UsdaFoodItem.fromFdcJson(json);
      // Precision rounded to 2 decimals
      expect(item.protein, equals(5.33));
      expect(item.fat, equals(2.67));
      expect(item.carbs, equals(27.12));

      // Scaling: 40g base -> 100g scaled (ratio = 2.5)
      final scaled100g = item.toFoodItem(estimatedGrams: 100.0);
      expect(scaled100g.estimatedGrams, equals(100.0));
      expect(scaled100g.calories, equals(375.0));
      expect(scaled100g.protein, equals(13.33)); // 5.33 * 2.5 = 13.325 -> 13.33
      expect(scaled100g.fat, equals(6.68));     // 2.67 * 2.5 = 6.675 -> 6.68

      // Zero serving size defense: ratio defaults to 1.0, avoids div-by-zero
      const zeroServingItem = UsdaFoodItem(
        fdcId: 1,
        description: 'Zero Serving Food',
        servingSize: 0.0,
        servingSizeUnit: 'g',
        calories: 120.0,
      );
      final zeroScaled = zeroServingItem.toFoodItem(estimatedGrams: 50.0);
      expect(zeroScaled.calories, equals(120.0));

      // Negative serving size defense: ratio defaults to 1.0
      const negServingItem = UsdaFoodItem(
        fdcId: 2,
        description: 'Negative Serving Food',
        servingSize: -40.0,
        servingSizeUnit: 'g',
        calories: 100.0,
      );
      final negScaled = negServingItem.toFoodItem(estimatedGrams: 80.0);
      expect(negScaled.calories, equals(100.0));

      // Non-gram unit (e.g. ml): baseGrams defaults to 100.0
      const mlItem = UsdaFoodItem(
        fdcId: 3,
        description: 'Liquid Milk',
        servingSize: 240.0,
        servingSizeUnit: 'ml',
        calories: 150.0,
      );
      final mlScaled = mlItem.toFoodItem(estimatedGrams: 200.0);
      // ratio = 200 / 100 = 2.0
      expect(mlScaled.calories, equals(300.0));
    });
  });

  group('UsdaFoodDataService & BarcodeLookupService Adversarial Tests', () {
    late MockSecureStorageService mockStorage;
    late MockUsdaFoodDataService mockUsda;
    late MockOpenFoodFactsService mockOff;
    late BarcodeLookupService lookupService;

    setUp(() {
      mockStorage = MockSecureStorageService();
      mockUsda = MockUsdaFoodDataService();
      mockOff = MockOpenFoodFactsService();
      lookupService = BarcodeLookupService.custom(
        secureStorage: mockStorage,
        usdaService: mockUsda,
        offService: mockOff,
      );
      BarcodeLookupService.setMockInstance(lookupService);
    });

    tearDown(() {
      BarcodeLookupService.resetInstance();
    });

    test('Barcode variations: 8-digit, 12-digit, 13-digit, and alphanumeric garbage', () async {
      mockStorage.usdaKey = 'VALID_KEY';
      mockUsda.responseItem = PantryItem(name: 'Item USDA', calories: 200);

      // 1. 8-digit EAN-8
      mockUsda.responseItem = null;
      mockOff.responseItem = PantryItem(name: 'EAN8 OFF', calories: 150);
      final res8 = await lookupService.lookupBarcode(' 12345678 ');
      expect(mockUsda.lastBarcode, equals('12345678'));
      expect(res8?.name, equals('EAN8 OFF'));

      // 2. 12-digit UPC-A
      mockUsda.responseItem = PantryItem(name: 'UPC-A USDA', calories: 250);
      final res12 = await lookupService.lookupBarcode('030000010402');
      expect(mockUsda.lastBarcode, equals('030000010402'));
      expect(res12?.name, equals('UPC-A USDA'));

      // 3. 13-digit EAN-13 with leading zero
      final res13 = await lookupService.lookupBarcode('0030000010402');
      expect(mockUsda.lastBarcode, equals('0030000010402'));
      expect(res13?.name, equals('UPC-A USDA'));

      // 4. 13-digit European without leading zero (starts with 84...)
      mockUsda.responseItem = null;
      mockOff.responseItem = PantryItem(name: 'Spanish Olive Oil', calories: 884);
      final resEuro = await lookupService.lookupBarcode('8410100010015');
      expect(resEuro?.name, equals('Spanish Olive Oil'));

      // 5. Alphanumeric garbage without digits returns null immediately without querying
      mockUsda.callCount = 0;
      mockOff.callCount = 0;
      final resGarbage = await lookupService.lookupBarcode('ABC-XYZ!@#');
      expect(resGarbage, isNull);
      expect(mockUsda.callCount, equals(0));
      expect(mockOff.callCount, equals(0));

      // 6. Alphanumeric with embedded digits strips non-digits
      mockUsda.responseItem = PantryItem(name: 'Cleaned Product', calories: 100);
      final resCleaned = await lookupService.lookupBarcode('UPC: 737628064502 (BOX)');
      expect(mockUsda.lastBarcode, equals('737628064502'));
      expect(resCleaned?.name, equals('Cleaned Product'));
    });

    test('Missing USDA API key triggers immediate fallback to Open Food Facts', () async {
      mockStorage.usdaKey = null;
      mockOff.responseItem = PantryItem(name: 'Instant OFF', calories: 99);

      final result = await lookupService.lookupBarcodeDetailed('737628064502');

      expect(mockUsda.callCount, equals(0), reason: 'USDA must not be called when key is null');
      expect(mockOff.callCount, equals(1));
      expect(result?.source, equals(BarcodeSource.openFoodFacts));
      expect(result?.item.name, equals('Instant OFF'));
    });

    test('Cascades to Open Food Facts on USDA HTTP 403, 404, 429, and SocketExceptions', () async {
      mockStorage.usdaKey = 'EXPIRED_KEY';
      mockOff.responseItem = PantryItem(name: 'Resilient OFF', calories: 300);

      // 1. USDA 403 Authentication Exception
      mockUsda.exceptionToThrow = const UsdaAuthenticationException();
      final res403 = await lookupService.lookupBarcodeDetailed('737628064502');
      expect(res403?.source, equals(BarcodeSource.openFoodFacts));
      expect(res403?.item.name, equals('Resilient OFF'));

      // 2. USDA 429 Rate Limit Exception
      mockUsda.exceptionToThrow = const UsdaRateLimitException();
      final res429 = await lookupService.lookupBarcodeDetailed('737628064502');
      expect(res429?.source, equals(BarcodeSource.openFoodFacts));

      // 3. USDA 404 (returns null)
      mockUsda.exceptionToThrow = null;
      mockUsda.responseItem = null;
      final res404 = await lookupService.lookupBarcodeDetailed('737628064502');
      expect(res404?.source, equals(BarcodeSource.openFoodFacts));

      // 4. SocketException (Network offline)
      mockUsda.exceptionToThrow = const SocketException('Failed host lookup: api.nal.usda.gov');
      final resSocket = await lookupService.lookupBarcodeDetailed('737628064502');
      expect(resSocket?.source, equals(BarcodeSource.openFoodFacts));
    });

    test('Both USDA and OFF failing returns null cleanly without uncaught exceptions', () async {
      mockStorage.usdaKey = 'VALID_KEY';
      mockUsda.exceptionToThrow = const SocketException('No Internet');
      mockOff.exceptionToThrow = const SocketException('No Internet');

      final result = await lookupService.lookupBarcode('737628064502');

      expect(result, isNull);
      expect(mockUsda.callCount, equals(1));
      expect(mockOff.callCount, equals(1));
    });

    test('Rate limiting sliding window: enforces 1000 requests/hour limit', () async {
      int serverCalls = 0;
      final mockClient = MockClient((request) async {
        serverCalls++;
        return http.Response('{"foods": []}', 200);
      });

      final service = UsdaFoodDataService(
        client: mockClient,
        storage: mockStorage,
      );

      // Dispatch 1000 requests
      for (int i = 0; i < UsdaFoodDataService.maxRequestsPerHour; i++) {
        await service.searchFoods('apple');
      }
      expect(serverCalls, equals(1000));

      // The 1001st request within the sliding hour MUST throw UsdaRateLimitException
      expect(
        () => service.searchFoods('apple'),
        throwsA(isA<UsdaRateLimitException>()),
      );
      // Ensure no further HTTP request reached the server
      expect(serverCalls, equals(1000));
    });

    test('Vulnerability Analysis: Permanent lockout when x-ratelimit-remaining is 0', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"foods": []}',
          200,
          headers: {'x-ratelimit-remaining': '0'},
        );
      });

      final service = UsdaFoodDataService(
        client: mockClient,
        storage: mockStorage,
      );

      // First call executes and receives x-ratelimit-remaining: 0
      await service.searchFoods('bread');
      expect(service.lastRemainingRequests, equals(0));

      // Subsequent call is immediately blocked by local header check
      expect(
        () => service.searchFoods('bread'),
        throwsA(isA<UsdaRateLimitException>()),
      );
    });
  });
}
