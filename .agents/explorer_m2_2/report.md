# Technical Architecture & Implementation Specification: USDA FoodData Central Client
**Project**: Victor Engineer - Food Tracker (NutriTracker Local-First) — Phase 2 Milestone 2
**Working Directory**: `C:\Users\vmesp\Documents\Cositas\App-Food-Tracker`
**Target Service**: `lib/services/usda_food_data_service.dart` & `lib/models/usda_food_item.dart`
**Target Test**: `test/services/usda_food_data_service_test.dart`
**Author**: Explorer 2 (`explorer_m2_2`)
**Status**: Recommendation / Pre-Implementation Architectural Blueprint

---

## 1. Executive Summary & Design Principles

This report details the exact Dart architecture, unified nutrient extraction logic, rate limiting defenses, domain conversions, and unit test strategy for the **USDA FoodData Central (FDC)** API client in Phase 2 Milestone 2.

### Core Architectural Principles
1. **Zero External Breakage / Local-First BYOK**: Operates under user-supplied API keys stored in encrypted hardware storage (`FlutterSecureStorage`). If the key is missing or invalid, the service gracefully degrades and delegates to `OpenFoodFactsService` without crashing.
2. **Unified Dual-Schema Parsing**: Seamlessly ingests both flattened search schemas (`/foods/search`) and nested full-detail schemas (`/food/{fdcId}`).
3. **Caloric & Micronutrient Integrity**: Fully extracts 4 macronutrients and 6 key micronutrients, automatically converting metric energy ($kJ \rightarrow kcal$ via $kcal = kJ / 4.184$) and clamping via `ModelSanitizer`.
4. **Hermetic Testability**: Built with constructor dependency injection (`http.Client` & `SecureStorageService`) enabling comprehensive in-memory unit tests using `MockClient` without real network calls.
5. **Clean Domain Conversion**: Maps directly to `PantryItem` for inventory/scanning and `FoodItem` for meal composition and AI logging.

---

## 2. Model Specification: `UsdaFoodItem`

We recommend placing `UsdaFoodItem` in `lib/models/usda_food_item.dart` (and exporting it from `lib/services/usda_food_data_service.dart`). It adheres strictly to the repository's immutable model conventions with the `_sentinel` pattern and `ModelSanitizer`.

```dart
import 'package:food_tracker/models/food_item.dart';
import 'package:food_tracker/models/model_sanitizer.dart';
import 'package:food_tracker/models/pantry_item.dart';

class UsdaFoodItem {
  final int fdcId;
  final String description;
  final String? brandOwner;
  final String? brandName;
  final String? gtinUpc;
  final String? dataType;
  final double? servingSize;
  final String? servingSizeUnit;
  final String? householdServingFullText;
  final String? category;

  // Macronutrients (Kcal, Grams)
  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  // Micronutrients (Fiber in g, Sodium/Calcium/Iron/VitC in mg, VitA in IU/mcg)
  final double fiber;
  final double sodium;
  final double calcium;
  final double iron;
  final double vitaminA;
  final double vitaminC;

  static const Object _sentinel = Object();

  const UsdaFoodItem({
    required this.fdcId,
    required this.description,
    this.brandOwner,
    this.brandName,
    this.gtinUpc,
    this.dataType,
    this.servingSize,
    this.servingSizeUnit,
    this.householdServingFullText,
    this.category,
    this.calories = 0.0,
    this.protein = 0.0,
    this.fat = 0.0,
    this.carbs = 0.0,
    this.fiber = 0.0,
    this.sodium = 0.0,
    this.calcium = 0.0,
    this.iron = 0.0,
    this.vitaminA = 0.0,
    this.vitaminC = 0.0,
  });

  UsdaFoodItem copyWith({
    int? fdcId,
    String? description,
    Object? brandOwner = _sentinel,
    Object? brandName = _sentinel,
    Object? gtinUpc = _sentinel,
    Object? dataType = _sentinel,
    Object? servingSize = _sentinel,
    Object? servingSizeUnit = _sentinel,
    Object? householdServingFullText = _sentinel,
    Object? category = _sentinel,
    double? calories,
    double? protein,
    double? fat,
    double? carbs,
    double? fiber,
    double? sodium,
    double? calcium,
    double? iron,
    double? vitaminA,
    double? vitaminC,
  }) {
    return UsdaFoodItem(
      fdcId: fdcId ?? this.fdcId,
      description: description ?? this.description,
      brandOwner: identical(brandOwner, _sentinel) ? this.brandOwner : (brandOwner as String?),
      brandName: identical(brandName, _sentinel) ? this.brandName : (brandName as String?),
      gtinUpc: identical(gtinUpc, _sentinel) ? this.gtinUpc : (gtinUpc as String?),
      dataType: identical(dataType, _sentinel) ? this.dataType : (dataType as String?),
      servingSize: identical(servingSize, _sentinel) ? this.servingSize : (servingSize as double?),
      servingSizeUnit: identical(servingSizeUnit, _sentinel) ? this.servingSizeUnit : (servingSizeUnit as String?),
      householdServingFullText: identical(householdServingFullText, _sentinel)
          ? this.householdServingFullText
          : (householdServingFullText as String?),
      category: identical(category, _sentinel) ? this.category : (category as String?),
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      fiber: fiber ?? this.fiber,
      sodium: sodium ?? this.sodium,
      calcium: calcium ?? this.calcium,
      iron: iron ?? this.iron,
      vitaminA: vitaminA ?? this.vitaminA,
      vitaminC: vitaminC ?? this.vitaminC,
    );
  }

  /// Parses both search items (/foods/search) and detail items (/food/{id})
  factory UsdaFoodItem.fromFdcJson(Map<String, dynamic> json) {
    final nutrients = json['foodNutrients'];

    final calories = UsdaNutrientParser.parseNutrient(
      nutrients,
      UsdaNutrientParser.energyIds,
      targetNumbers: const ['208'],
    );
    final protein = UsdaNutrientParser.parseNutrient(
      nutrients,
      const [UsdaNutrientParser.idProtein],
      targetNumbers: const ['203'],
    );
    final fat = UsdaNutrientParser.parseNutrient(
      nutrients,
      const [UsdaNutrientParser.idFat],
      targetNumbers: const ['204'],
    );
    final carbs = UsdaNutrientParser.parseNutrient(
      nutrients,
      const [UsdaNutrientParser.idCarbs],
      targetNumbers: const ['205'],
    );
    final fiber = UsdaNutrientParser.parseNutrient(
      nutrients,
      const [UsdaNutrientParser.idFiber],
      targetNumbers: const ['291'],
    );
    final sodium = UsdaNutrientParser.parseNutrient(
      nutrients,
      const [UsdaNutrientParser.idSodium],
      targetNumbers: const ['307'],
    );
    final calcium = UsdaNutrientParser.parseNutrient(
      nutrients,
      const [UsdaNutrientParser.idCalcium],
      targetNumbers: const ['301'],
    );
    final iron = UsdaNutrientParser.parseNutrient(
      nutrients,
      const [UsdaNutrientParser.idIron],
      targetNumbers: const ['303'],
    );
    final vitaminA = UsdaNutrientParser.parseNutrient(
      nutrients,
      const [UsdaNutrientParser.idVitaminA, 1106],
      targetNumbers: const ['318', '320'],
    );
    final vitaminC = UsdaNutrientParser.parseNutrient(
      nutrients,
      const [UsdaNutrientParser.idVitaminC],
      targetNumbers: const ['400'],
    );

    return UsdaFoodItem(
      fdcId: (json['fdcId'] as num?)?.toInt() ?? 0,
      description: ModelSanitizer.truncate(
        json['description']?.toString(),
        ModelSanitizer.maxNameLength,
        fallback: 'Alimento USDA',
      ),
      brandOwner: ModelSanitizer.truncateNullable(json['brandOwner']?.toString(), ModelSanitizer.maxNameLength),
      brandName: ModelSanitizer.truncateNullable(json['brandName']?.toString(), ModelSanitizer.maxNameLength),
      gtinUpc: ModelSanitizer.truncateNullable(json['gtinUpc']?.toString(), 32),
      dataType: ModelSanitizer.truncateNullable(json['dataType']?.toString(), 64),
      servingSize: (json['servingSize'] as num?)?.toDouble(),
      servingSizeUnit: ModelSanitizer.truncateNullable(json['servingSizeUnit']?.toString(), 32),
      householdServingFullText: ModelSanitizer.truncateNullable(json['householdServingFullText']?.toString(), 128),
      category: ModelSanitizer.truncateNullable(
        json['brandedFoodCategory']?.toString() ??
            json['foodCategory']?.toString() ??
            (json['wweiaFoodCategory'] is Map ? json['wweiaFoodCategory']['wweiaFoodCategoryDescription']?.toString() : null),
        100,
      ),
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
      fiber: fiber,
      sodium: sodium,
      calcium: calcium,
      iron: iron,
      vitaminA: vitaminA,
      vitaminC: vitaminC,
    );
  }

  /// Converts USDA food item to local PantryItem (for pantry storage or barcode scanning)
  PantryItem toPantryItem({bool isFavorite = false}) {
    final brand = ModelSanitizer.truncateNullable(
      brandOwner ?? brandName,
      ModelSanitizer.maxNameLength,
    );
    final cat = ModelSanitizer.truncateNullable(
      category ?? dataType,
      100,
    );

    return PantryItem(
      name: ModelSanitizer.truncate(
        description,
        ModelSanitizer.maxNameLength,
        fallback: 'Alimento USDA',
      ),
      brand: brand,
      category: cat,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      isFavorite: isFavorite,
    );
  }

  /// Converts USDA food item to FoodItem (for plate/meal logging)
  FoodItem toFoodItem({
    double? estimatedGrams,
    String? visualJustification,
  }) {
    final baseGrams = (servingSize != null && (servingSizeUnit?.toLowerCase() == 'g' || servingSizeUnit?.toLowerCase() == 'gr'))
        ? servingSize!
        : 100.0;
    final grams = estimatedGrams ?? baseGrams;
    final double ratio = (estimatedGrams != null && baseGrams > 0) ? (estimatedGrams / baseGrams) : 1.0;

    return FoodItem(
      name: ModelSanitizer.truncate(
        description,
        ModelSanitizer.maxNameLength,
        fallback: 'Alimento USDA',
      ),
      estimatedGrams: grams,
      calories: ModelSanitizer.clampDouble(calories * ratio),
      protein: ModelSanitizer.clampDouble(protein * ratio),
      carbs: ModelSanitizer.clampDouble(carbs * ratio),
      fat: ModelSanitizer.clampDouble(fat * ratio),
      visualJustification: ModelSanitizer.truncateNullable(
        visualJustification ??
            (householdServingFullText != null
                ? 'Porción USDA: $householdServingFullText ($grams g)'
                : 'Base USDA ($grams g)'),
        ModelSanitizer.maxJustificationLength,
      ),
    );
  }
}
```

---

## 3. Unified Nutrient Parser: `UsdaNutrientParser`

USDA FoodData Central uses two distinct structures for nutrients depending on the endpoint invoked:
1. **Search Endpoint (`/foods/search`)**: Flattened properties directly on nutrient item:
   `item['nutrientId']`, `item['value']`, `item['unitName']`.
2. **Detail Endpoint (`/food/{id}`)**: Nested object with metadata:
   `item['nutrient']['id']`, `item['amount']`, `item['nutrient']['unitName']`.
3. **Legacy / Abridged endpoints**: Alternative keys:
   `item['nutrientNumber']` or `item['number']`.

### 3.1 Nutrient ID & Number Mapping Reference

| Target Nutrient | Primary ID | Secondary IDs | Nutrient Numbers | Unit | Unit Conversion / Handling |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Calories (Energy)** | **`1008`** | `2047`, `2048` | `208` | `KCAL` | If `unitName` contains `KJ` $\rightarrow$ $kcal = kJ / 4.184$ |
| **Protein** | **`1003`** | — | `203` | `G` | Direct value clamped |
| **Total Fat** | **`1004`** | — | `204` | `G` | Direct value clamped |
| **Carbohydrates** | **`1005`** | — | `205` | `G` | Direct value clamped |
| **Dietary Fiber** | **`1079`** | — | `291` | `G` | Direct value clamped |
| **Sodium (Na)** | **`1093`** | — | `307` | `MG` | Direct value clamped |
| **Calcium (Ca)** | **`1087`** | — | `301` | `MG` | Direct value clamped |
| **Iron (Fe)** | **`1089`** | — | `303` | `MG` | Direct value clamped |
| **Vitamin A** | **`1104`** | `1106` | `318`, `320` | `IU` / `UG` | Direct value clamped |
| **Vitamin C** | **`1162`** | — | `400` | `MG` | Direct value clamped |

### 3.2 Exact Parser Algorithm

```dart
class UsdaNutrientParser {
  static const int idEnergy = 1008;
  static const int idProtein = 1003;
  static const int idFat = 1004;
  static const int idCarbs = 1005;
  static const int idFiber = 1079;
  static const int idSodium = 1093;
  static const int idCalcium = 1087;
  static const int idIron = 1089;
  static const int idVitaminA = 1104;
  static const int idVitaminC = 1162;

  static const List<int> energyIds = [idEnergy, 2047, 2048];

  /// Parses a nutrient value by searching target IDs and fallback numbers.
  /// Handles both flattened (`nutrientId`, `value`) and nested (`nutrient.id`, `amount`) schemas.
  /// Automatically converts kJ to kcal for Energy (1008).
  static double parseNutrient(
    dynamic foodNutrientsRaw,
    List<int> targetIds, {
    List<String> targetNumbers = const [],
  }) {
    if (foodNutrientsRaw is! List) return 0.0;

    for (final item in foodNutrientsRaw) {
      if (item is! Map<String, dynamic>) continue;

      // 1. Resolve nutrient ID (flat or nested)
      final int? id = (item['nutrientId'] as num?)?.toInt() ??
          (item['nutrient'] is Map ? (item['nutrient']['id'] as num?)?.toInt() : null);

      // 2. Resolve nutrient number (flat or nested)
      final String? number = item['nutrientNumber']?.toString() ??
          item['number']?.toString() ??
          (item['nutrient'] is Map ? item['nutrient']['number']?.toString() : null);

      final bool idMatches = id != null && targetIds.contains(id);
      final bool numberMatches = number != null && targetNumbers.contains(number);

      if (idMatches || numberMatches) {
        // 3. Resolve numeric value (value or amount)
        final num? rawVal = (item['value'] as num?) ?? (item['amount'] as num?);
        if (rawVal == null) continue;

        // 4. Resolve unit
        final String unit = (item['unitName'] ??
                (item['nutrient'] is Map ? item['nutrient']['unitName'] : null) ??
                '')
            .toString()
            .trim()
            .toUpperCase();

        double val = rawVal.toDouble();

        // 5. Energy conversion if kJ
        final bool isEnergy = targetIds.contains(idEnergy) || targetNumbers.contains('208');
        if (isEnergy && (unit == 'KJ' || unit.contains('KILOJOULE'))) {
          val = val / 4.184;
        }

        return ModelSanitizer.clampDouble(val);
      }
    }

    return 0.0;
  }
}
```

---

## 4. Service Architecture: `UsdaFoodDataService`

### 4.1 Architectural Specifications
- **Base URL**: `https://api.nal.usda.gov/fdc/v1`
- **Rate Limit Resilience**:
  - Max quota: 1,000 req/hour.
  - Active tracking of `x-ratelimit-remaining` and local rolling window of request timestamps.
  - If rate limit is exhausted (HTTP 429) or fewer than 2 requests remain, throws `UsdaRateLimitException` or returns fallback immediately.
- **Timeout**:
  - Non-blocking 10-second timeout on all network calls.
- **Graceful Error Codes**:
  - `400`: Invalid query / parameter $\rightarrow$ returns empty list / null gracefully.
  - `403`: Invalid / missing API key $\rightarrow$ catches `UsdaAuthenticationException`, logs, triggers OpenFoodFacts fallback.
  - `429`: Quota exhausted $\rightarrow$ catches `UsdaRateLimitException`, logs, triggers OpenFoodFacts fallback.
  - Missing key: If no API key configured in storage or arguments, aborts immediately without network overhead.
- **Barcode Resolution**:
  - Handles US UPC-A (12 digits) vs European EAN-13 (13 digits) with automatic zero-trimming/prepending.

### 4.2 Complete Service Implementation

```dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:food_tracker/models/pantry_item.dart';
import 'package:food_tracker/models/usda_food_item.dart';
import 'package:food_tracker/services/open_food_facts_service.dart';
import 'package:food_tracker/services/secure_storage_service.dart';

class UsdaApiException implements Exception {
  final String message;
  final int? statusCode;
  const UsdaApiException(this.message, {this.statusCode});
  @override
  String toString() => 'UsdaApiException($statusCode): $message';
}

class UsdaRateLimitException extends UsdaApiException {
  const UsdaRateLimitException([String message = 'Límite de solicitudes USDA excedido (1,000 req/hora).'])
      : super(message, statusCode: 429);
}

class UsdaAuthenticationException extends UsdaApiException {
  const UsdaAuthenticationException([String message = 'API Key de USDA no válida o no autorizada (HTTP 403).'])
      : super(message, statusCode: 403);
}

class UsdaFoodDataService {
  static final UsdaFoodDataService instance = UsdaFoodDataService();

  final http.Client _client;
  final SecureStorageService _storage;
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';

  // Rate Limiting (1,000 requests per hour limit)
  static const int maxRequestsPerHour = 1000;
  final List<DateTime> _requestLog = [];
  int? _lastRemainingHeader;

  UsdaFoodDataService({
    http.Client? client,
    SecureStorageService? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? SecureStorageService.instance;

  int? get lastRemainingRequests => _lastRemainingHeader;

  /// Validates whether a request can be dispatched according to local sliding-window rate limits
  bool _canDispatchRequest() {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    _requestLog.removeWhere((timestamp) => timestamp.isBefore(oneHourAgo));
    if (_requestLog.length >= maxRequestsPerHour) return false;
    if (_lastRemainingHeader != null && _lastRemainingHeader! <= 0) return false;
    return true;
  }

  void _recordRequest() {
    _requestLog.add(DateTime.now());
  }

  void _updateRateLimitHeaders(Map<String, String> headers) {
    final remaining = headers['x-ratelimit-remaining'];
    if (remaining != null) {
      _lastRemainingHeader = int.tryParse(remaining);
    }
  }

  Future<String?> _resolveApiKey(String? explicitKey) async {
    if (explicitKey != null && explicitKey.trim().isNotEmpty) {
      return explicitKey.trim();
    }
    return await _storage.getUsdaApiKey();
  }

  /// Searches foods by keyword with pagination
  Future<List<UsdaFoodItem>> searchFoods(
    String query, {
    int pageSize = 10,
    String? apiKey,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];

    final key = await _resolveApiKey(apiKey);
    if (key == null || key.isEmpty) return const [];

    if (!_canDispatchRequest()) {
      throw const UsdaRateLimitException();
    }

    final uri = Uri.parse('$_baseUrl/foods/search').replace(queryParameters: {
      'api_key': key,
      'query': trimmedQuery,
      'pageSize': pageSize.clamp(1, 100).toString(),
      'dataType': 'Branded,Foundation,SR Legacy',
    });

    try {
      _recordRequest();
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      _updateRateLimitHeaders(response.headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> foods = data['foods'] ?? [];
        return foods
            .whereType<Map<String, dynamic>>()
            .map((f) => UsdaFoodItem.fromFdcJson(f))
            .toList();
      } else if (response.statusCode == 403) {
        throw const UsdaAuthenticationException();
      } else if (response.statusCode == 429) {
        throw const UsdaRateLimitException();
      } else {
        return const [];
      }
    } on TimeoutException {
      return const [];
    } catch (e) {
      if (e is UsdaApiException) rethrow;
      return const [];
    }
  }

  /// Fetches a food item by UPC/GTIN barcode with auto-fallback for 12/13 digit formatting
  Future<UsdaFoodItem?> fetchByBarcode(
    String barcode, {
    String? apiKey,
  }) async {
    final sanitizedBarcode = barcode.trim();
    if (sanitizedBarcode.isEmpty) return null;

    final key = await _resolveApiKey(apiKey);
    if (key == null || key.isEmpty) return null;

    // 1. Direct query with scanned barcode
    var item = await _queryBarcodeOnce(sanitizedBarcode, key);
    if (item != null) return item;

    // 2. EAN-13 (13 digits starting with 0) -> Retry as UPC-A (12 digits)
    if (sanitizedBarcode.length == 13 && sanitizedBarcode.startsWith('0')) {
      item = await _queryBarcodeOnce(sanitizedBarcode.substring(1), key);
      if (item != null) return item;
    }

    // 3. UPC-A (12 digits) -> Retry as EAN-13 (13 digits prepended with 0)
    if (sanitizedBarcode.length == 12) {
      item = await _queryBarcodeOnce('0$sanitizedBarcode', key);
      if (item != null) return item;
    }

    return null;
  }

  Future<UsdaFoodItem?> _queryBarcodeOnce(String code, String key) async {
    if (!_canDispatchRequest()) return null;

    final uri = Uri.parse('$_baseUrl/foods/search').replace(queryParameters: {
      'api_key': key,
      'query': code,
      'dataType': 'Branded',
      'pageSize': '5',
    });

    try {
      _recordRequest();
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      _updateRateLimitHeaders(response.headers);

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> foods = data['foods'] ?? [];
      if (foods.isEmpty) return null;

      // Find exact GTIN match or best hit
      Map<String, dynamic>? matched;
      for (final f in foods) {
        if (f is Map<String, dynamic>) {
          final gtin = f['gtinUpc']?.toString();
          if (gtin == code || (gtin != null && (gtin.endsWith(code) || code.endsWith(gtin)))) {
            matched = f;
            break;
          }
        }
      }
      matched ??= (foods.first as Map<String, dynamic>);
      return UsdaFoodItem.fromFdcJson(matched);
    } catch (_) {
      return null;
    }
  }

  /// Fetches complete food details by FDC ID (/food/{fdcId})
  Future<UsdaFoodItem?> fetchFoodDetails(
    int fdcId, {
    String? apiKey,
  }) async {
    if (fdcId <= 0) return null;

    final key = await _resolveApiKey(apiKey);
    if (key == null || key.isEmpty) return null;

    if (!_canDispatchRequest()) {
      throw const UsdaRateLimitException();
    }

    final uri = Uri.parse('$_baseUrl/food/$fdcId').replace(queryParameters: {
      'api_key': key,
      'format': 'full',
    });

    try {
      _recordRequest();
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      _updateRateLimitHeaders(response.headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UsdaFoodItem.fromFdcJson(data);
      } else if (response.statusCode == 403) {
        throw const UsdaAuthenticationException();
      } else if (response.statusCode == 429) {
        throw const UsdaRateLimitException();
      } else {
        return null;
      }
    } on TimeoutException {
      return null;
    } catch (e) {
      if (e is UsdaApiException) rethrow;
      return null;
    }
  }

  /// Cascading Barcode Resolution: Queries USDA first, falls back to Open Food Facts
  Future<PantryItem?> fetchProductWithFallback(
    String barcode, {
    String? apiKey,
  }) async {
    final sanitized = barcode.trim();
    if (sanitized.isEmpty) return null;

    try {
      final usdaItem = await fetchByBarcode(sanitized, apiKey: apiKey);
      if (usdaItem != null) {
        return usdaItem.toPantryItem();
      }
    } catch (_) {
      // Gracefully continue to fallback
    }

    // Fallback: Open Food Facts
    return await OpenFoodFactsService.instance.fetchProductByBarcode(sanitized);
  }
}
```

---

## 5. Mock JSON Fixtures Specification

To guarantee hermetic, zero-network unit tests, we define 5 JSON fixture files in `test/fixtures/`:

### 5.1 `test/fixtures/usda_search_response_fixture.json` (Flattened Search Schema)
```json
{
  "totalHits": 2,
  "currentPage": 1,
  "totalPages": 1,
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
          "value": 0.0
        },
        {
          "nutrientId": 1162,
          "nutrientName": "Vitamin C, total ascorbic acid",
          "nutrientNumber": "400",
          "unitName": "MG",
          "value": 0.0
        }
      ]
    },
    {
      "fdcId": 171688,
      "description": "Chicken breast, rotisserie",
      "dataType": "Foundation",
      "foodNutrients": [
        {
          "nutrientId": 1008,
          "nutrientName": "Energy",
          "unitName": "KCAL",
          "value": 165.0
        },
        {
          "nutrientId": 1003,
          "nutrientName": "Protein",
          "unitName": "G",
          "value": 31.02
        },
        {
          "nutrientId": 1004,
          "nutrientName": "Total lipid (fat)",
          "unitName": "G",
          "value": 3.57
        },
        {
          "nutrientId": 1005,
          "nutrientName": "Carbohydrate, by difference",
          "unitName": "G",
          "value": 0.0
        }
      ]
    }
  ]
}
```

### 5.2 `test/fixtures/usda_food_details_nested_fixture.json` (Nested Schema with kJ Energy)
```json
{
  "fdcId": 987654,
  "description": "European Yogurt Drink",
  "dataType": "Branded",
  "brandOwner": "EuroDairy Corp",
  "servingSize": 200.0,
  "servingSizeUnit": "g",
  "householdServingFullText": "1 bottle",
  "foodNutrients": [
    {
      "type": "FoodNutrient",
      "id": 10001,
      "amount": 1046.0,
      "nutrient": {
        "id": 1008,
        "number": "208",
        "name": "Energy",
        "unitName": "kJ"
      }
    },
    {
      "type": "FoodNutrient",
      "id": 10002,
      "amount": 8.0,
      "nutrient": {
        "id": 1003,
        "number": "203",
        "name": "Protein",
        "unitName": "g"
      }
    },
    {
      "type": "FoodNutrient",
      "id": 10003,
      "amount": 4.0,
      "nutrient": {
        "id": 1004,
        "number": "204",
        "name": "Total lipid (fat)",
        "unitName": "g"
      }
    },
    {
      "type": "FoodNutrient",
      "id": 10004,
      "amount": 22.0,
      "nutrient": {
        "id": 1005,
        "number": "205",
        "name": "Carbohydrate, by difference",
        "unitName": "g"
      }
    },
    {
      "type": "FoodNutrient",
      "id": 10005,
      "amount": 250.0,
      "nutrient": {
        "id": 1087,
        "number": "301",
        "name": "Calcium, Ca",
        "unitName": "mg"
      }
    },
    {
      "type": "FoodNutrient",
      "id": 10006,
      "amount": 12.0,
      "nutrient": {
        "id": 1162,
        "number": "400",
        "name": "Vitamin C, total ascorbic acid",
        "unitName": "mg"
      }
    }
  ]
}
```

### 5.3 `test/fixtures/usda_error_429_fixture.json`
```json
{
  "error": {
    "code": 429,
    "message": "OVER_RATE_LIMIT",
    "details": "You have exceeded your rate limit of 1000 requests per hour."
  }
}
```

### 5.4 `test/fixtures/usda_error_403_fixture.json`
```json
{
  "error": {
    "code": 403,
    "message": "API_KEY_INVALID",
    "details": "An invalid api_key was provided."
  }
}
```

---

## 6. Unit Test Strategy: `test/services/usda_food_data_service_test.dart`

The unit test strategy uses `MockClient` from `package:http/testing.dart` to verify all behaviors in isolation:

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:food_tracker/models/usda_food_item.dart';
import 'package:food_tracker/services/usda_food_data_service.dart';

void main() {
  group('UsdaNutrientParser Tests', () {
    test('Parsea esquema aplanado (/foods/search) de macros y micros', () {
      final flatJson = json.decode(usdaSearchFixtureJson)['foods'][0];
      final item = UsdaFoodItem.fromFdcJson(flatJson);

      expect(item.fdcId, equals(2117388));
      expect(item.description, equals('QUAKER, OLD FASHIONED ROLLED OATS'));
      expect(item.calories, equals(150.0));
      expect(item.protein, equals(5.0));
      expect(item.fat, equals(2.5));
      expect(item.carbs, equals(27.0));
      expect(item.fiber, equals(4.0));
      expect(item.sodium, equals(0.0));
      expect(item.calcium, equals(20.0));
      expect(item.iron, equals(1.5));
    });

    test('Parsea esquema anidado (/food/{id}) y convierte kJ a kcal fielmente', () {
      final nestedJson = json.decode(usdaDetailFixtureJson);
      final item = UsdaFoodItem.fromFdcJson(nestedJson);

      expect(item.fdcId, equals(987654));
      // 1046 kJ / 4.184 = 250.0 kcal
      expect(item.calories, closeTo(250.0, 0.1));
      expect(item.protein, equals(8.0));
      expect(item.fat, equals(4.0));
      expect(item.carbs, equals(22.0));
      expect(item.calcium, equals(250.0));
      expect(item.vitaminC, equals(12.0));
    });

    test('Nutrientes no presentes devuelven 0.0 de manera segura sin crashear', () {
      final partialJson = {
        'fdcId': 12345,
        'description': 'Aceite de Oliva Puro',
        'foodNutrients': [
          {'nutrientId': 1004, 'value': 14.0, 'unitName': 'G'},
        ]
      };
      final item = UsdaFoodItem.fromFdcJson(partialJson);

      expect(item.fat, equals(14.0));
      expect(item.protein, equals(0.0));
      expect(item.carbs, equals(0.0));
      expect(item.fiber, equals(0.0));
    });
  });

  group('Domain Model Conversions', () {
    test('UsdaFoodItem.toPantryItem convierte correctamente campos sanitizados', () {
      final flatJson = json.decode(usdaSearchFixtureJson)['foods'][0];
      final usdaItem = UsdaFoodItem.fromFdcJson(flatJson);
      final pantryItem = usdaItem.toPantryItem(isFavorite: true);

      expect(pantryItem.name, equals('QUAKER, OLD FASHIONED ROLLED OATS'));
      expect(pantryItem.brand, equals('The Quaker Oats Company'));
      expect(pantryItem.calories, equals(150.0));
      expect(pantryItem.protein, equals(5.0));
      expect(pantryItem.isFavorite, isTrue);
    });

    test('UsdaFoodItem.toFoodItem escala macros según gramos estimados', () {
      final flatJson = json.decode(usdaSearchFixtureJson)['foods'][0];
      final usdaItem = UsdaFoodItem.fromFdcJson(flatJson); // servingSize: 40g, 150 kcal
      // Solicitamos 80g (el doble)
      final foodItem = usdaItem.toFoodItem(estimatedGrams: 80.0);

      expect(foodItem.estimatedGrams, equals(80.0));
      expect(foodItem.calories, equals(300.0)); // 150 * 2
      expect(foodItem.protein, equals(10.0));   // 5 * 2
      expect(foodItem.fat, equals(5.0));       // 2.5 * 2
    });
  });

  group('UsdaFoodDataService Client Operations', () {
    test('searchFoods consulta endpoint y deserializa lista de alimentos', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/fdc/v1/foods/search'));
        expect(request.url.queryParameters['query'], equals('oats'));
        return http.Response(
          usdaSearchFixtureJson,
          200,
          headers: {'x-ratelimit-remaining': '995'},
        );
      });

      final service = UsdaFoodDataService(client: mockClient);
      final results = await service.searchFoods('oats', apiKey: 'test_key');

      expect(results.length, equals(2));
      expect(results.first.description, contains('QUAKER'));
      expect(service.lastRemainingRequests, equals(995));
    });

    test('fetchFoodDetails consulta /food/{fdcId} con format=full', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/fdc/v1/food/987654'));
        return http.Response(usdaDetailFixtureJson, 200);
      });

      final service = UsdaFoodDataService(client: mockClient);
      final result = await service.fetchFoodDetails(987654, apiKey: 'test_key');

      expect(result, isNotNull);
      expect(result!.description, equals('European Yogurt Drink'));
      expect(result.calories, closeTo(250.0, 0.1));
    });

    test('fetchByBarcode reintenta con 12 dígitos si código EAN-13 comienza con 0', () async {
      int queryCount = 0;
      final mockClient = MockClient((request) async {
        queryCount++;
        final query = request.url.queryParameters['query'];
        if (query == '0030000010402') {
          return http.Response('{"foods": []}', 200); // 13 dígitos sin resultados
        }
        if (query == '030000010402') {
          return http.Response(usdaSearchFixtureJson, 200); // 12 dígitos exitoso
        }
        return http.Response('{"foods": []}', 200);
      });

      final service = UsdaFoodDataService(client: mockClient);
      final item = await service.fetchByBarcode('0030000010402', apiKey: 'test_key');

      expect(item, isNotNull);
      expect(item!.gtinUpc, equals('030000010402'));
      expect(queryCount, equals(2));
    });

    test('searchFoods lanza UsdaRateLimitException en HTTP 429', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          usdaError429Json,
          429,
          headers: {'x-ratelimit-remaining': '0'},
        );
      });

      final service = UsdaFoodDataService(client: mockClient);
      expect(
        () => service.searchFoods('apple', apiKey: 'test_key'),
        throwsA(isA<UsdaRateLimitException>()),
      );
    });

    test('searchFoods lanza UsdaAuthenticationException en HTTP 403', () async {
      final mockClient = MockClient((request) async {
        return http.Response(usdaError403Json, 403);
      });

      final service = UsdaFoodDataService(client: mockClient);
      expect(
        () => service.searchFoods('apple', apiKey: 'invalid_key'),
        throwsA(isA<UsdaAuthenticationException>()),
      );
    });

    test('Si no hay API key ni explícita ni en storage, devuelve vacío sin llamadas HTTP', () async {
      int callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        return http.Response('{"foods": []}', 200);
      });

      final service = UsdaFoodDataService(client: mockClient);
      final results = await service.searchFoods('apple', apiKey: null);

      expect(results, isEmpty);
      expect(callCount, equals(0));
    });
  });
}

// Inlined fixtures for test simplicity
const String usdaSearchFixtureJson = '''{ ... }''';
const String usdaDetailFixtureJson = '''{ ... }''';
const String usdaError429Json = '''{"error": {"code": 429, "message": "OVER_RATE_LIMIT"}}''';
const String usdaError403Json = '''{"error": {"code": 403, "message": "API_KEY_INVALID"}}''';
```

---

## 7. Integration Blueprint with NutriTracker Ecosystem

### 7.1 Integration with `BarcodeScannerDialog` (`lib/widgets/common/barcode_scanner_dialog.dart`)
In `_searchBarcode`:
```dart
// Before:
final item = await OpenFoodFactsService.instance.fetchProductByBarcode(code);

// Recommended Phase 2 Replacement:
final item = await UsdaFoodDataService.instance.fetchProductWithFallback(code);
```
This single line change preserves 100% of the UI behavior while elevating barcode scanning into a high-tier dual-provider fallback engine.

### 7.2 Integration with `SecureStorageService` (`lib/services/secure_storage_service.dart`)
The following methods must be added to `SecureStorageService`:
```dart
static const String _usdaApiKeyKey = 'usda_api_key';

Future<String?> getUsdaApiKey() async {
  try {
    return await _storage.read(key: _usdaApiKeyKey);
  } catch (_) {
    return null;
  }
}

Future<void> setUsdaApiKey(String key) async {
  await _storage.write(key: _usdaApiKeyKey, value: key.trim());
}

Future<void> deleteUsdaApiKey() async {
  await _storage.delete(key: _usdaApiKeyKey);
}
```

---

## 8. Summary of Files to Create / Modify in Milestone 2 Implementation

| Target Path | Action | Description |
| :--- | :--- | :--- |
| `lib/models/usda_food_item.dart` | **Create** | Implements `UsdaFoodItem` and `UsdaNutrientParser` with Sentinel pattern, nutrient clamping, and `toPantryItem()` / `toFoodItem()`. |
| `lib/services/usda_food_data_service.dart` | **Create** | Typed USDA FDC client with `searchFoods`, `fetchByBarcode`, `fetchFoodDetails`, rate-limit tracking, and cascading fallback. |
| `lib/services/secure_storage_service.dart` | **Modify** | Adds `getUsdaApiKey()`, `setUsdaApiKey()`, `deleteUsdaApiKey()`. |
| `lib/widgets/common/barcode_scanner_dialog.dart` | **Modify** | Switches barcode resolution to `UsdaFoodDataService.instance.fetchProductWithFallback()`. |
| `test/services/usda_food_data_service_test.dart` | **Create** | Comprehensive unit test suite covering dual-schema parsing, kJ conversion, rate limits, and fallback. |
| `test/fixtures/usda_*.json` | **Create** | Standalone fixture files (or inlined in test). |
