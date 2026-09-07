import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:food_tracker/models/usda_food_item.dart';
import 'package:food_tracker/services/secure_storage_service.dart';
import 'package:food_tracker/services/usda_food_data_service.dart';

class MockSecureStorageService extends Fake implements SecureStorageService {
  String? usdaKey = 'VALID_MOCK_USDA_KEY';
  @override
  Future<String?> getUsdaApiKey() async => usdaKey;
}

const String mockSearchResponseJson = '''
{
  "totalHits": 1,
  "foods": [
    {
      "fdcId": 2117388,
      "description": "QUAKER, OLD FASHIONED ROLLED OATS",
      "dataType": "Branded",
      "brandOwner": "The Quaker Oats Company",
      "brandName": "QUAKER",
      "gtinUpc": "030000010402",
      "servingSize": 40.0,
      "servingSizeUnit": "g",
      "householdServingFullText": "1/2 cup",
      "brandedFoodCategory": "Cereal",
      "foodNutrients": [
        {
          "nutrientId": 1008,
          "nutrientName": "Energy",
          "nutrientNumber": "208",
          "unitName": "KCAL",
          "value": 150.0
        },
        {
          "nutrientId": 1003,
          "nutrientName": "Protein",
          "nutrientNumber": "203",
          "unitName": "G",
          "value": 5.0
        },
        {
          "nutrientId": 1004,
          "nutrientName": "Total lipid (fat)",
          "nutrientNumber": "204",
          "unitName": "G",
          "value": 2.5
        },
        {
          "nutrientId": 1005,
          "nutrientName": "Carbohydrate, by difference",
          "nutrientNumber": "205",
          "unitName": "G",
          "value": 27.0
        },
        {
          "nutrientId": 1079,
          "nutrientName": "Fiber, total dietary",
          "nutrientNumber": "291",
          "unitName": "G",
          "value": 4.0
        },
        {
          "nutrientId": 1093,
          "nutrientName": "Sodium, Na",
          "nutrientNumber": "307",
          "unitName": "MG",
          "value": 0.0
        },
        {
          "nutrientId": 1087,
          "nutrientName": "Calcium, Ca",
          "nutrientNumber": "301",
          "unitName": "MG",
          "value": 20.0
        },
        {
          "nutrientId": 1089,
          "nutrientName": "Iron, Fe",
          "nutrientNumber": "303",
          "unitName": "MG",
          "value": 1.5
        },
        {
          "nutrientId": 1104,
          "nutrientName": "Vitamin A, IU",
          "nutrientNumber": "318",
          "unitName": "IU",
          "value": 50.0
        },
        {
          "nutrientId": 1162,
          "nutrientName": "Vitamin C, total ascorbic acid",
          "nutrientNumber": "400",
          "unitName": "MG",
          "value": 2.0
        }
      ]
    }
  ]
}
''';

const String mockNestedDetailsResponseJson = '''
{
  "fdcId": 987654,
  "description": "European Yogurt Drink",
  "dataType": "Branded",
  "brandOwner": "EuroDairy Corp",
  "servingSize": 200.0,
  "servingSizeUnit": "g",
  "foodNutrients": [
    {
      "nutrient": {
        "id": 1008,
        "number": "208",
        "name": "Energy",
        "unitName": "kJ"
      },
      "amount": 418.4
    },
    {
      "nutrient": {
        "id": 1003,
        "number": "203",
        "name": "Protein",
        "unitName": "g"
      },
      "amount": 7.0
    },
    {
      "nutrient": {
        "id": 1004,
        "number": "204",
        "name": "Total lipid (fat)",
        "unitName": "g"
      },
      "amount": 3.0
    },
    {
      "nutrient": {
        "id": 1005,
        "number": "205",
        "name": "Carbohydrate, by difference",
        "unitName": "g"
      },
      "amount": 15.0
    }
  ]
}
''';

void main() {
  group('UsdaFoodDataService & UsdaFoodItem Tests', () {
    late MockSecureStorageService mockStorage;

    setUp(() {
      mockStorage = MockSecureStorageService();
    });

    test('searchFoods successfully queries API and parses flattened food nutrients', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/foods/search'));
        expect(request.url.queryParameters['query'], equals('oats'));
        expect(request.url.queryParameters['api_key'], equals('VALID_MOCK_USDA_KEY'));
        return http.Response(mockSearchResponseJson, 200, headers: {
          'x-ratelimit-remaining': '995',
        });
      });

      final service = UsdaFoodDataService(client: mockClient, storage: mockStorage);
      final results = await service.searchFoods('oats');

      expect(results.length, equals(1));
      final item = results.first;
      expect(item.fdcId, equals(2117388));
      expect(item.description, equals('QUAKER, OLD FASHIONED ROLLED OATS'));
      expect(item.calories, equals(150.0));
      expect(item.protein, equals(5.0));
      expect(item.fat, equals(2.5));
      expect(item.carbs, equals(27.0));
      expect(item.fiber, equals(4.0));
      expect(item.calcium, equals(20.0));
      expect(item.iron, equals(1.5));
      expect(item.vitaminA, equals(50.0));
      expect(item.vitaminC, equals(2.0));
      expect(service.lastRemainingRequests, equals(995));
    });

    test('fetchFoodDetails parses nested schema and converts kJ to kcal accurately', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/food/987654'));
        return http.Response(mockNestedDetailsResponseJson, 200);
      });

      final service = UsdaFoodDataService(client: mockClient, storage: mockStorage);
      final item = await service.fetchFoodDetails(987654);

      expect(item, isNotNull);
      expect(item!.description, equals('European Yogurt Drink'));
      // 418.4 kJ / 4.184 = 100.0 kcal
      expect(item.calories, equals(100.0));
      expect(item.protein, equals(7.0));
      expect(item.fat, equals(3.0));
      expect(item.carbs, equals(15.0));
    });

    test('fetchByBarcode finds product and normalizes 13-digit EAN to 12-digit UPC', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        final query = request.url.queryParameters['query'];
        if (query == '0030000010402') {
          // First try with 13 digits returns empty
          return http.Response('{"foods": []}', 200);
        } else if (query == '030000010402') {
          // Second try with stripped leading zero returns item
          return http.Response(mockSearchResponseJson, 200);
        }
        return http.Response('{"foods": []}', 200);
      });

      final service = UsdaFoodDataService(client: mockClient, storage: mockStorage);
      final item = await service.fetchByBarcode('0030000010402');

      expect(item, isNotNull);
      expect(item!.gtinUpc, equals('030000010402'));
      expect(requestCount, equals(2));
    });

    test('fetchProductByBarcode returns PantryItem representation', () async {
      final mockClient = MockClient((request) async {
        return http.Response(mockSearchResponseJson, 200);
      });

      final service = UsdaFoodDataService(client: mockClient, storage: mockStorage);
      final pantryItem = await service.fetchProductByBarcode('030000010402');

      expect(pantryItem, isNotNull);
      expect(pantryItem!.name, equals('QUAKER, OLD FASHIONED ROLLED OATS'));
      expect(pantryItem.calories, equals(150.0));
      expect(pantryItem.protein, equals(5.0));
      expect(pantryItem.brand, equals('The Quaker Oats Company'));
    });

    test('Throws UsdaAuthenticationException on HTTP 403', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Forbidden', 403);
      });

      final service = UsdaFoodDataService(client: mockClient, storage: mockStorage);
      expect(
        () => service.searchFoods('apple'),
        throwsA(isA<UsdaAuthenticationException>()),
      );
    });

    test('Throws UsdaRateLimitException on HTTP 429', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Rate limit exceeded', 429);
      });

      final service = UsdaFoodDataService(client: mockClient, storage: mockStorage);
      expect(
        () => service.searchFoods('apple'),
        throwsA(isA<UsdaRateLimitException>()),
      );
    });

    test('Returns empty when USDA API key is not configured', () async {
      mockStorage.usdaKey = null;
      final service = UsdaFoodDataService(storage: mockStorage);

      final searchResults = await service.searchFoods('rice');
      expect(searchResults, isEmpty);

      final barcodeResult = await service.fetchByBarcode('123456789012');
      expect(barcodeResult, isNull);
    });

    test('UsdaFoodItem conversions to PantryItem and FoodItem with scaling', () {
      const usda = UsdaFoodItem(
        fdcId: 1001,
        description: 'Pechuga de Pollo Asada',
        brandOwner: 'Granja Real',
        servingSize: 100.0,
        servingSizeUnit: 'g',
        householdServingFullText: '1 filete',
        calories: 165.0,
        protein: 31.0,
        fat: 3.6,
        carbs: 0.0,
      );

      // 1. To PantryItem
      final pantry = usda.toPantryItem(isFavorite: true);
      expect(pantry.name, equals('Pechuga de Pollo Asada'));
      expect(pantry.brand, equals('Granja Real'));
      expect(pantry.calories, equals(165.0));
      expect(pantry.protein, equals(31.0));
      expect(pantry.isFavorite, isTrue);

      // 2. To FoodItem scaled to 200g (ratio = 2.0)
      final food200g = usda.toFoodItem(estimatedGrams: 200.0);
      expect(food200g.estimatedGrams, equals(200.0));
      expect(food200g.calories, equals(330.0));
      expect(food200g.protein, equals(62.0));
      expect(food200g.fat, equals(7.2));

      // 3. copyWith with Sentinel
      final copied = usda.copyWith(brandOwner: null, calories: 170.0);
      expect(copied.brandOwner, isNull);
      expect(copied.calories, equals(170.0));
      expect(copied.protein, equals(31.0));
    });
  });
}
