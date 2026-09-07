# External APIs Specification Report — Phase 2: Gemini & USDA FoodData Central
**Victor Engineer - Food Tracker (NutriTracker Local-First)**
*Document Version: 1.0.0 — Date: 2026-09-07*
*Author: External APIs Spec Miner (`spec_miner_survey_2`)*

---

## 1. Executive Summary & Architectural Scope

This report provides the authoritative technical specification for the external API integrations required in **Phase 2** of NutriTracker:
1. **Dynamic Google Gemini Model Querying & Selection (R1)**: Zero-hardcoding discovery of available Gemini models via Google's Generative Language REST API, vision/multimodal filtering, recommendation heuristics, secure model persistence, and contextual Master Prompt (R3) injection.
2. **USDA FoodData Central (FDC) Integration (R2)**: Full-text search and barcode resolution against the USDA REST API, comprehensive nutrient extraction (macros & micros), hardware-backed API key storage (`usda_api_key`), rate-limit resilience, and automatic fallback integration with `OpenFoodFactsService`.

All specifications align with the project's quality baselines: **100% Local-First BYOK (Bring Your Own Key)**, non-blocking asynchronous I/O, strict sanitization via `ModelSanitizer`, and modular separation of concerns.

---

## 2. Dynamic Google Gemini Model Querying (R1)

### 2.1 Authoritative Endpoint Specification

- **Endpoint**: `GET https://generativelanguage.googleapis.com/v1beta/models`
- **Authentication**: Query parameter `key={API_KEY}` (Google AI Studio BYOK)
- **HTTP Method**: `GET`
- **Request Headers**:
  - `Accept: application/json`
  - `Content-Type: application/json`
- **Query Parameters**:
  | Parameter | Type | Required | Default | Description |
  | :--- | :--- | :--- | :--- | :--- |
  | `key` | `string` | **Yes** | — | Google AI Studio API Key |
  | `pageSize` | `integer` | No | `50` | Number of models per page (max `1000`) |
  | `pageToken` | `string` | No | — | Token for pagination from previous response |

- **HTTP Status Codes & Error Behavior**:
  | HTTP Code | Condition | JSON Error Body Structure | Application Handling |
  | :--- | :--- | :--- | :--- |
  | `200 OK` | Success | Returns `{ "models": [ ... ] }` | Parse and filter active models |
  | `400 Bad Request` | Invalid key format or malformed parameter | `{"error": {"code": 400, "message": "API key not valid", "status": "INVALID_ARGUMENT"}}` | Notify user: "API Key de Gemini no válida" |
  | `403 Forbidden` | Key revoked, billing/quota block, IP restricted | `{"error": {"code": 403, "message": "Method doesn't allow...", "status": "PERMISSION_DENIED"}}` | Alert user to verify permissions in AI Studio |
  | `429 Too Many Requests` | Account quota or rate limit exceeded | `{"error": {"code": 429, "message": "Resource exhausted", "status": "RESOURCE_EXHAUSTED"}}` | Exponential backoff / alert user |
  | `500 / 503` | Google service temporary failure | `{"error": {"code": 503, "message": "Service Unavailable"}}` | Graceful fallback to default model (`gemini-2.5-flash`) |

### 2.2 Exact JSON Response Schema

Google Generative Language API returns the following JSON structure:

```json
{
  "models": [
    {
      "name": "models/gemini-2.5-flash",
      "version": "2.5",
      "displayName": "Gemini 2.5 Flash",
      "description": "Next-generation multimodal model offering fast speed, low latency, and highly accurate vision comprehension.",
      "inputTokenLimit": 1048576,
      "outputTokenLimit": 8192,
      "supportedGenerationMethods": [
        "generateContent",
        "countTokens"
      ],
      "inputModalities": [
        "TEXT",
        "IMAGE"
      ],
      "outputModalities": [
        "TEXT"
      ],
      "temperature": 1.0,
      "maxTemperature": 2.0,
      "topP": 0.95,
      "topK": 40
    },
    {
      "name": "models/gemini-2.5-pro",
      "version": "2.5",
      "displayName": "Gemini 2.5 Pro",
      "description": "State-of-the-art multimodal model with deep reasoning capabilities for complex visual analysis.",
      "inputTokenLimit": 2097152,
      "outputTokenLimit": 8192,
      "supportedGenerationMethods": [
        "generateContent",
        "countTokens"
      ],
      "inputModalities": [
        "TEXT",
        "IMAGE"
      ],
      "outputModalities": [
        "TEXT"
      ]
    },
    {
      "name": "models/gemini-2.0-flash",
      "version": "2.0",
      "displayName": "Gemini 2.0 Flash",
      "description": "Fast multimodal model for high-throughput tasks.",
      "inputTokenLimit": 1048576,
      "outputTokenLimit": 8192,
      "supportedGenerationMethods": [
        "generateContent",
        "countTokens"
      ],
      "inputModalities": [
        "TEXT",
        "IMAGE"
      ]
    },
    {
      "name": "models/text-embedding-004",
      "version": "004",
      "displayName": "Text Embedding 004",
      "description": "Generates high quality text embeddings.",
      "inputTokenLimit": 2048,
      "outputTokenLimit": 1,
      "supportedGenerationMethods": [
        "embedContent"
      ]
    }
  ],
  "nextPageToken": ""
}
```

### 2.3 Model Filtering Criteria for Vision & Multimodal Analysis

To ensure only models capable of photographic food analysis with structured JSON schema are offered in the UI:

1. **Generation Method**:
   - `model['supportedGenerationMethods']` must contain `"generateContent"`.
   - Discards embedding models (`embedContent`), token counters, or question-answering endpoints (`aqa`).
2. **Multimodal / Vision Capability**:
   - **Primary Check**: If `model['inputModalities']` is present, it must contain `"IMAGE"` (or `"image"`).
   - **Resilient Fallback Check** (for API versions/proxies omitting `inputModalities`):
     - The model name or ID must contain `'gemini'` (case-insensitive).
     - Discard explicit non-vision or non-generalist prefixes:
       - `embedding`, `text-embedding`
       - `imagen` (image generation, not visual analysis)
       - `tts` / `audio`
       - `text-bison`, `chat-bison` (legacy PaLM models)
       - `learnlm`
3. **Identifier Normalization**:
   - Google returns `models/gemini-2.5-flash`.
   - Normalized clean ID: `name.startsWith('models/') ? name.substring(7) : name`.
   - The Dart `google_generative_ai` SDK works with clean IDs (e.g. `'gemini-2.5-flash'`).

### 2.4 Model Recommendation Heuristics & Tier Hierarchy

In `SettingsScreen`, models should be sorted and annotated with semantic badges:

| Priority | Model ID Pattern | Semantic Label / Badge | Rationale |
| :--- | :--- | :--- | :--- |
| **Tier 1 (Top)** | `gemini-2.5-flash` / `gemini-3.*flash` | **RECOMENDADO (Ultrarrápido)** | Optimal tradeoff: ~1.2s latency, high volumetric accuracy, lowest token cost. |
| **Tier 2** | `gemini-2.5-pro` / `gemini-3.*pro` | **MÁXIMA PRECISIÓN (Razonamiento)** | Excels at complex, dense, multi-ingredient mixed dishes (stews, casseroles). |
| **Tier 3** | `gemini-2.0-flash` | **ESTABLE (Alta Velocidad)** | Mature production model; excellent reliability fallback. |
| **Tier 4** | `gemini-1.5-flash` / `gemini-1.5-pro` | **HEREDADO (Compatibilidad)** | Broad backward compatibility for legacy API accounts. |
| **Tier 5** | Other Gemini models | **DISPONIBLE** | Any user-tuned or experimental multimodal model available to the API key. |

**Dynamic Selection Fallback Logic**:
```dart
String resolveDefaultModel(List<String> availableModelIds, String? previouslySelected) {
  if (previouslySelected != null && availableModelIds.contains(previouslySelected)) {
    return previouslySelected;
  }
  const priorityOrder = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-2.5-pro',
    'gemini-1.5-flash',
    'gemini-1.5-pro',
  ];
  for (final candidate in priorityOrder) {
    if (availableModelIds.contains(candidate)) return candidate;
  }
  return availableModelIds.isNotEmpty ? availableModelIds.first : 'gemini-2.5-flash';
}
```

### 2.5 Current Services Audit & Phase 2 Integration

#### `lib/services/secure_storage_service.dart`
- **Current State**: Stores `gemini_api_key` and `daily_goals_json` via `FlutterSecureStorage` (AES hardware encrypted via Android Keystore).
- **Phase 2 Required Additions**:
  ```dart
  static const String _geminiModelKey = 'gemini_selected_model';
  static const String _usdaApiKeyKey = 'usda_api_key';
  static const String _masterPromptKey = 'user_master_prompt';

  Future<String?> getGeminiModel() async => await _storage.read(key: _geminiModelKey);
  Future<void> setGeminiModel(String modelId) async => await _storage.write(key: _geminiModelKey, value: modelId.trim());

  Future<String?> getUsdaApiKey() async => await _storage.read(key: _usdaApiKeyKey);
  Future<void> setUsdaApiKey(String key) async => await _storage.write(key: _usdaApiKeyKey, value: key.trim());
  Future<void> deleteUsdaApiKey() async => await _storage.delete(key: _usdaApiKeyKey);

  Future<String?> getMasterPrompt() async => await _storage.read(key: _masterPromptKey);
  Future<void> setMasterPrompt(String prompt) async => await _storage.write(key: _masterPromptKey, value: prompt.trim());
  ```

#### `lib/services/gemini_vision_service.dart`
- **Current State**:
  - `modelName` is passed in constructor but defaults to static `defaultModel = 'gemini-2.5-flash'`.
  - In `dashboard_screen.dart`, it is instantiated with `GeminiVisionService(apiKey: apiKey)`, bypassing the stored model.
  - `systemInstruction` is a `static const String` containing volumetric rules, with no user profile context.
- **Phase 2 Required Additions**:
  1. Accept `String? masterPrompt` in `GeminiVisionService` constructor or `analyzeMealPhoto`.
  2. Implement `_buildSystemInstruction(String? masterPrompt)`:
     ```dart
     String _buildSystemInstruction([String? masterPrompt]) {
       final buffer = StringBuffer(baseSystemInstruction);
       if (masterPrompt != null && masterPrompt.trim().isNotEmpty) {
         buffer.writeln('\n--- CONTEXTO BIOLÓGICO Y METAS DEL COMENSAL (MASTER PROMPT) ---');
         buffer.writeln(masterPrompt.trim());
         buffer.writeln('Ajusta tus estimaciones y observaciones considerando las metas calóricas y macronutrientes del usuario.');
       }
       return buffer.toString();
     }
     ```
  3. In `DashboardScreen` (line 89):
     ```dart
     final selectedModel = await SecureStorageService.instance.getGeminiModel() ?? GeminiVisionService.defaultModel;
     final masterPrompt = await SecureStorageService.instance.getMasterPrompt();
     final gemini = GeminiVisionService(
       apiKey: apiKey,
       modelName: selectedModel,
       masterPrompt: masterPrompt,
     );
     ```

---

## 3. USDA FoodData Central Integration (R2)

### 3.1 Authoritative Endpoint Specifications

- **Base URL**: `https://api.nal.usda.gov/fdc/v1`
- **Official Documentation**: `https://fdc.nal.usda.gov/api-guide.html` & OpenAPI v3 spec (`app.swaggerhub.com/apis/fdcnal/food-data_central_api/1.0.1`)
- **Authentication**: Query parameter `api_key={USDA_API_KEY}` (or HTTP Header `X-Api-Key: {USDA_API_KEY}`). Keys are obtained free at `api.data.gov`.

#### Endpoint A: Food Search (`GET /foods/search`)
- **URL**: `https://api.nal.usda.gov/fdc/v1/foods/search`
- **Method**: `GET` (or `POST`)
- **Primary Use Cases**:
  1. **Barcode Lookup**: Searching by GTIN/UPC code (`query={barcode}&dataType=Branded`).
  2. **Text Food Search**: Searching raw/foundation ingredients (e.g. "Chicken breast", "Rolled oats", "Egg").
- **Query Parameters**:
  | Parameter | Type | Required | Description |
  | :--- | :--- | :--- | :--- |
  | `api_key` | `string` | **Yes** | USDA / Data.gov API Key |
  | `query` | `string` | **Yes** | Barcode number (UPC/GTIN) or food keyword query |
  | `dataType` | `string` | No | Comma-separated list: `Branded,Foundation,SR Legacy,Survey (FNDDS)` |
  | `pageSize` | `integer` | No | Default `50`, max `200` |
  | `pageNumber` | `integer` | No | Page index (1-based) |
  | `sortBy` | `string` | No | `dataType.keyword`, `lowercaseDescription.keyword`, `fdcId` |
  | `sortOrder` | `string` | No | `asc` or `desc` |

- **Exact JSON Response Schema (`/foods/search`)**:
```json
{
  "totalHits": 1,
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
        }
      ]
    }
  ]
}
```

#### Endpoint B: Food Details (`GET /food/{fdcId}`)
- **URL**: `https://api.nal.usda.gov/fdc/v1/food/{fdcId}`
- **Method**: `GET`
- **Query Parameters**:
  | Parameter | Type | Required | Description |
  | :--- | :--- | :--- | :--- |
  | `api_key` | `string` | **Yes** | Data.gov API Key |
  | `format` | `string` | No | `abridged` (concise) or `full` (detailed with portions) |
  | `nutrients` | `string` | No | Comma-separated list of nutrient IDs to return (e.g. `1008,1003,1004,1005`) |

- **Response Schema Difference Note**:
  In `/food/{fdcId}` with `format=full`, the nutrients array uses nested objects:
  ```json
  {
    "fdcId": 2117388,
    "description": "QUAKER, OLD FASHIONED ROLLED OATS",
    "foodNutrients": [
      {
        "type": "FoodNutrient",
        "id": 26829143,
        "amount": 150.0,
        "nutrient": {
          "id": 1008,
          "number": "208",
          "name": "Energy",
          "unitName": "kcal"
        }
      }
    ]
  }
  ```

### 3.2 Nutrient ID Mapping & Parsing Matrix

To ensure infallible nutrient extraction across both endpoints, the parser must read both flattened (`nutrientId` / `value`) and nested (`nutrient.id` / `amount`) formats:

| Target Nutrient | Primary USDA ID | Secondary / Legacy IDs | Unit Handling | Fallback Default |
| :--- | :--- | :--- | :--- | :--- |
| **Calories (Energy)** | **`1008`** ("Energy") | `2047`, `2048` (Atwater factors) | If `unitName == 'kJ'`, convert: `kcal = kj / 4.184`. If `kcal`, take value directly. | `0.0` |
| **Protein** | **`1003`** ("Protein") | `203` | Grams (`g`) | `0.0` |
| **Carbohydrates** | **`1005`** ("Carbohydrate, by diff.") | `205` | Grams (`g`) | `0.0` |
| **Fat (Total Lipids)** | **`1004`** ("Total lipid (fat)") | `204` | Grams (`g`) | `0.0` |
| **Fiber (Micronutrient)** | **`1079`** ("Fiber, total dietary") | `291` | Grams (`g`) | `0.0` |
| **Total Sugars** | **`2000`** ("Sugars, total") | `1063` | Grams (`g`) | `0.0` |
| **Sodium (Na)** | **`1093`** ("Sodium, Na") | `307` | Milligrams (`mg`) | `0.0` |
| **Potassium (K)** | **`1092`** ("Potassium, K") | `306` | Milligrams (`mg`) | `0.0` |
| **Calcium (Ca)** | **`1087`** ("Calcium, Ca") | `301` | Milligrams (`mg`) | `0.0` |
| **Iron (Fe)** | **`1089`** ("Iron, Fe") | `303` | Milligrams (`mg`) | `0.0` |
| **Cholesterol** | **`1258`** ("Cholesterol") | `601` | Milligrams (`mg`) | `0.0` |
| **Vitamin C** | **`1162`** ("Vitamin C") | `400` | Milligrams (`mg`) | `0.0` |
| **Vitamin D** | **`1114`** ("Vitamin D (D2+D3)") | `324` | Micrograms (`ug`) | `0.0` |

#### Resilient Dart Nutrient Extractor Algorithm:
```dart
double extractNutrient(List<dynamic> nutrients, List<int> targetIds) {
  for (final item in nutrients) {
    if (item is! Map<String, dynamic>) continue;
    
    // Support both flattened (/foods/search) and nested (/food/{id}) formats
    final int? id = (item['nutrientId'] as num?)?.toInt() ??
                    (item['nutrient']?['id'] as num?)?.toInt();
    
    if (id != null && targetIds.contains(id)) {
      final num? rawValue = (item['value'] as num?) ?? (item['amount'] as num?);
      final String unit = (item['unitName'] ?? item['nutrient']?['unitName'] ?? '').toString().toUpperCase();
      
      if (rawValue != null) {
        double val = rawValue.toDouble();
        // Convert kJ to kcal if necessary
        if (targetIds.contains(1008) && (unit == 'KJ' || unit == 'KILOJOULES')) {
          val = val / 4.184;
        }
        return ModelSanitizer.clampDouble(val);
      }
    }
  }
  return 0.0;
}
```

### 3.3 Rate Limiting, HTTP Quotas & Error Handling

- **Rate Limits**:
  - Standard registered API key: **1,000 requests per hour** per IP/key.
  - Rate limit headers returned in response:
    - `X-RateLimit-Limit`: e.g. `1000`
    - `X-RateLimit-Remaining`: e.g. `984`
- **Error Status Codes & Behavior**:
  | Status Code | USDA Description | Handling in `UsdaFoodDataService` |
  | :--- | :--- | :--- |
  | `400 Bad Request` | Missing or invalid query parameter | Return `null` or empty list without crashing |
  | `403 Forbidden` | Invalid, expired, or deactivated API key | Log warning, throw `InvalidApiKeyException`, immediately trigger OpenFoodFacts fallback |
  | `404 Not Found` | Food item or FDC ID does not exist | Return `null`; trigger OpenFoodFacts fallback |
  | `429 Too Many Requests` | Hourly rate limit exceeded (`OVER_RATE_LIMIT`) | Log quota notice; immediately trigger OpenFoodFacts fallback |
  | `500 / 503` | USDA server down or in maintenance | Catch HTTP exception; immediately trigger OpenFoodFacts fallback |
  | `TimeoutException` | Request exceeded 10s | Cancel client request; immediately trigger OpenFoodFacts fallback |

### 3.4 Integration & Fallback Mechanism (USDA <-> Open Food Facts)

#### Dual-Provider Fallback Architecture

```
                       [ Barcode Scanner / Manual Code Input ]
                                         │
                                         ▼
                           Is 'usda_api_key' configured?
                                ├── No ───► Query Open Food Facts directly
                                │
                                └── Yes ──► Query USDA FDC (/foods/search?query={barcode}&dataType=Branded)
                                                  │
                                            Result Status
                                ┌─────────────────┴─────────────────┐
                                │                                   │
                             Found & Valid                   Not Found / Error / 429
                                │                                   │
                                ▼                                   ▼
                         Return PantryItem           Fallback: Query Open Food Facts
                                                                    │
                                                            Result Status
                                                     ┌──────────────┴──────────────┐
                                                     │                             │
                                                  Found                        Not Found
                                                     │                             │
                                                     ▼                             ▼
                                              Return PantryItem               Return null
```

#### Barcode Specific Edge Cases & Normalization
- **UPC-A (12 digits)** vs **EAN-13 (13 digits)**:
  - In the US, UPC-A barcodes are 12 digits (e.g. `030000010402`).
  - Many scanners prepend a leading `0` to produce EAN-13 (e.g. `0030000010402`).
  - In USDA FDC, `gtinUpc` is indexed as stored by the manufacturer (either 12 or 14 digits).
  - **Resolution**:
    1. Query with exact scanned code.
    2. If zero hits and length is 13 starting with `'0'`, strip leading zero to form 12-digit UPC and retry query if needed.

### 3.5 Service Design: `UsdaFoodDataService`

The service must follow the existing pattern in `lib/services/open_food_facts_service.dart`:
- Singleton pattern: `UsdaFoodDataService.instance`
- Reusable `http.Client` with standard 10-second timeout
- Clean mapping to `PantryItem`
- Fallback delegation helper `fetchProductWithFallback(String barcode)`

```dart
class UsdaFoodDataService {
  static final UsdaFoodDataService instance = UsdaFoodDataService._();
  UsdaFoodDataService._();

  final http.Client _client = http.Client();
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';

  Future<PantryItem?> fetchProductByBarcode(String barcode, {String? apiKey}) async {
    final key = apiKey ?? await SecureStorageService.instance.getUsdaApiKey();
    if (key == null || key.trim().isEmpty) return null;

    final sanitizedBarcode = barcode.trim();
    if (sanitizedBarcode.isEmpty) return null;

    final uri = Uri.parse('$_baseUrl/foods/search').replace(queryParameters: {
      'api_key': key.trim(),
      'query': sanitizedBarcode,
      'dataType': 'Branded',
      'pageSize': '5',
    });

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> foods = data['foods'] ?? [];
      if (foods.isEmpty) return null;

      // Find exact or closest GTIN match
      Map<String, dynamic>? matchedFood;
      for (final f in foods) {
        if (f is Map<String, dynamic> && f['gtinUpc'] == sanitizedBarcode) {
          matchedFood = f;
          break;
        }
      }
      matchedFood ??= (foods.first as Map<String, dynamic>);

      return _mapFoodToPantryItem(matchedFood);
    } catch (_) {
      return null;
    }
  }

  PantryItem _mapFoodToPantryItem(Map<String, dynamic> food) {
    final rawName = (food['description'] ?? 'Alimento USDA').toString();
    final brand = food['brandOwner']?.toString() ?? food['brandName']?.toString();
    final category = food['brandedFoodCategory']?.toString() ?? food['foodCategory']?.toString();
    final nutrients = (food['foodNutrients'] as List<dynamic>?) ?? [];

    final calories = extractNutrient(nutrients, [1008, 2047, 2048]);
    final protein = extractNutrient(nutrients, [1003]);
    final carbs = extractNutrient(nutrients, [1005]);
    final fat = extractNutrient(nutrients, [1004]);

    return PantryItem(
      name: ModelSanitizer.truncate(rawName, 255, fallback: 'Alimento USDA'),
      brand: brand,
      category: category,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }
}
```

---

## 4. Features Discovered

| # | Category | Feature | Description | Inputs | Outputs | Error Behavior | Discovered Via |
|---|----------|---------|-------------|--------|---------|----------------|----------------|
| 1 | Gemini API | `models.list` | Dynamic listing of all models available to the API key | `key` (API key), `pageSize`, `pageToken` | JSON array of `Model` objects | 400 (bad key), 403 (unauthorized), 429 (rate limit) | `v1beta/models` endpoint spec & docs |
| 2 | Gemini API | Modality Filtering | Identification of vision-capable models | `inputModalities`, `supportedGenerationMethods` | Filtered list containing `IMAGE` and `generateContent` | Ignores text-only & embedding models | `inputModalities` in Model metadata |
| 3 | Gemini API | Model Name Normalization | Removal of `models/` prefix for client SDK | String `models/{id}` | Clean string `{id}` | Fallback to original string if no prefix | Google Generative AI SDK standard |
| 4 | Gemini API | Tiered Model Recommendation | Semantic sorting & badging in settings UI | List of available models | Ranked models with badges (`RECOMENDADO`, `PRECISIÓN`, etc.) | Graceful fallback to `gemini-2.5-flash` | Prompt R1 & Gemini benchmark specs |
| 5 | Gemini API | Master Prompt System Instruction | Ingestion of user biometric & TDEE goals into AI vision prompt | `masterPrompt` string | Injected `Content.system` in `GenerativeModel` | Uses base instruction if master prompt is null/empty | `GeminiVisionService` architecture |
| 6 | USDA FDC | `foods/search` Barcode Lookup | Search branded foods by GTIN/UPC barcode | `query` (barcode), `dataType=Branded`, `api_key` | JSON with `foods` list and `foodNutrients` | Empty list if not found; 403 on invalid key | USDA FoodData Central OpenAPI spec |
| 7 | USDA FDC | Raw Food Text Search | Keyword search across USDA Foundation and SR Legacy datasets | `query` (food term), `dataType=Foundation,SR Legacy` | Search results with standard nutritional profiles | Returns 0 hits on typo | USDA `/foods/search` endpoint |
| 8 | USDA FDC | Resilient Nutrient Extraction | Unified extraction of calories, protein, carbs, fat from both flat and nested schemas | Array of nutrient objects (`value`/`amount`, `nutrientId`) | Normalized `double` for calories, protein, carbs, fat | Clamped to `0.0` via `ModelSanitizer` | Comparative analysis of `/foods/search` vs `/food/{id}` |
| 9 | USDA FDC | KJ to KCAL Conversion | Automatic conversion of metric energy units to kilocalories | Value in kJ where `unitName == 'KJ'` | Value divided by 4.184 | Clamped to non-negative double | USDA Nutrient 1008 unit guidelines |
| 10 | Security | `usda_api_key` Hardware Encryption | Secure persistence of USDA credentials via Keystore/Keyring | USDA API key string | Void (persisted in EncryptedSharedPreferences) | Catches exceptions, returns null on decryption error | `FlutterSecureStorage` implementation |
| 11 | Catalog | USDA -> OpenFoodFacts Fallback | Cascading lookup prioritizing USDA when key is present, falling back to Open Food Facts | Barcode string | `PantryItem` from first successful provider, or null | Safe fallback on 403, 404, 429, or network timeout | System requirement R2 & OFF service audit |

---

## 5. Edge Cases & Failure Recovery

| # | Feature | Input / Scenario | Observed / Specified Behavior | Recovery Strategy |
|---|---------|------------------|-------------------------------|-------------------|
| 1 | Gemini Models | User enters invalid/revoked Gemini API Key | `models.list` returns HTTP 400/403 with `INVALID_ARGUMENT` or `PERMISSION_DENIED` | Catch HTTP error, display clear snackbar error in `SettingsScreen`, do not overwrite model list |
| 2 | Gemini Models | Google deprecates or blocks `gemini-2.5-flash` for an account | Filtered list does not contain `gemini-2.5-flash` | Heuristic falls back to `gemini-2.0-flash` or `gemini-1.5-flash` without app crash |
| 3 | Gemini Vision | `masterPrompt` contains special characters or markdown | User profile with custom goals, emojis, quotes | Safe string interpolation inside separate markdown header block in `systemInstruction` |
| 4 | USDA FDC | No USDA API Key configured by user | `usda_api_key` is null in `FlutterSecureStorage` | Bypass USDA directly, execute `OpenFoodFactsService.fetchProductByBarcode` instantly |
| 5 | USDA FDC | USDA hourly quota exceeded (HTTP 429) | USDA API returns 429 `OVER_RATE_LIMIT` | Log warning, silently fall back to `OpenFoodFactsService` to complete barcode scan |
| 6 | USDA FDC | Barcode scanned has leading zero (EAN-13 vs UPC-A) | Scanned code `0030000010402` has 13 digits | Primary search with full code; if 0 hits, strip leading '0' (`030000010402`) and retry search |
| 7 | USDA FDC | Energy nutrient reported in kJ instead of kcal | `nutrientId: 1008`, `unitName: 'kJ'`, `value: 628` | Detect unit `'kJ'` / `'KILOJOULES'`, divide by `4.184` -> `150.1 kcal` |
| 8 | USDA FDC | Product has missing macronutrient (e.g. pure oil has 0g protein) | Nutrient 1003 not in `foodNutrients` list | `extractNutrient` returns `0.0`, safely clamped by `ModelSanitizer.clampDouble` |
| 9 | Network | Slow network / USDA server outage | HTTP connection hangs | 10-second timeout triggers, catches `TimeoutException`, cascades to Open Food Facts |

---

## 6. Implementation Checklist & Recommendations

1. **Storage Updates (`lib/services/secure_storage_service.dart`)**:
   - Add getters/setters for `gemini_selected_model`, `usda_api_key`, and `user_master_prompt`.
2. **Dynamic Models (`lib/controllers/settings_controller.dart`)**:
   - Add `fetchAvailableGeminiModels(String apiKey)`.
   - Add `saveSelectedGeminiModel(String modelId)`.
   - Add `saveUsdaApiKey(String key)`.
3. **Settings UI (`lib/screens/settings_screen.dart` & `lib/widgets/settings/`)**:
   - Create `GeminiModelSelectorCard` with Dropdown/Bento selection and recommendation badges.
   - Create `UsdaApiKeyInputCard` modeled after `ApiKeyInputCard`.
4. **USDA Client (`lib/services/usda_food_data_service.dart`)**:
   - Implement `fetchProductByBarcode` and `searchFoods`.
   - Implement `extractNutrient` supporting flat and nested USDA formats.
5. **Unified Barcode Resolution (`lib/widgets/common/barcode_scanner_dialog.dart`)**:
   - Update barcode lookup to call USDA with fallback to Open Food Facts.
6. **Gemini Vision (`lib/services/gemini_vision_service.dart`)**:
   - Accept dynamic `modelName` and `masterPrompt` in constructor.
   - Inject `masterPrompt` into `_buildSystemInstruction()`.
