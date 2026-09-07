# Handoff Report — Survey 2: External APIs (Gemini & USDA FoodData Central)

**Agent**: `spec_miner_survey_2` (External APIs Spec Miner)  
**Date**: 2026-09-07  
**Status**: Hard Handoff (Task Complete)  
**Deliverable**: `C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\spec_miner_survey_2\survey_report.md`

---

## 1. Observation

1. **`lib/services/gemini_vision_service.dart` (lines 87–117)**:
   - Line 91: `static const String defaultModel = 'gemini-2.5-flash';`
   - Lines 93–112: `static const String systemInstruction = '''...''';`
   - Line 114: `GeminiVisionService({required this.apiKey, this.modelName = defaultModel});`
   - Line 158: `final model = GenerativeModel(model: modelName, apiKey: apiKey, systemInstruction: Content.system(systemInstruction), ...);`
   - Observation: Currently, the service accepts `modelName` in its constructor, but defaults statically. In `lib/screens/dashboard_screen.dart` (line 89), it is invoked with `final gemini = GeminiVisionService(apiKey: apiKey);`, completely ignoring any selected model.
   - Observation: `systemInstruction` is a static constant with no dynamic injection of user profile, goals, or Master Prompt.

2. **`lib/services/secure_storage_service.dart` (lines 13–30)**:
   - Line 13: `static const String _geminiApiKeyKey = 'gemini_api_key';`
   - Line 14: `static const String _dailyGoalsKey = 'daily_goals_json';`
   - Observation: Only the Gemini API key and daily goals are currently stored. No storage keys exist for `gemini_selected_model`, `usda_api_key`, or `user_master_prompt`.

3. **`lib/services/open_food_facts_service.dart` (lines 12–86)**:
   - Lines 16–18: `https://world.openfoodfacts.org/api/v2/product/$sanitizedBarcode.json`
   - Observation: Currently the sole barcode provider. In `lib/widgets/common/barcode_scanner_dialog.dart` (line 42), the scanner only calls `OpenFoodFactsService.instance.fetchProductByBarcode(code);`.

4. **Google Gemini REST API (`v1beta/models`)**:
   - Endpoint: `GET https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}`
   - Observation: Returns `{ "models": [ ... ], "nextPageToken": "..." }`.
   - Each model contains: `name` (e.g. `"models/gemini-2.5-flash"`), `supportedGenerationMethods` (array), `inputModalities` (array, e.g. `["TEXT", "IMAGE"]`), `inputTokenLimit`, `outputTokenLimit`.

5. **USDA FoodData Central REST API (`https://api.nal.usda.gov/fdc/v1/`)**:
   - Endpoint `/foods/search`: Accepts `query={barcode}`, `dataType=Branded`, `api_key`. Returns `{ "foods": [ { "fdcId": ..., "description": ..., "foodNutrients": [ { "nutrientId": 1008, "value": 150.0, "unitName": "KCAL" } ] } ] }`.
   - Endpoint `/food/{fdcId}`: Full format returns nested nutrient objects `{ "amount": 150.0, "nutrient": { "id": 1008, "unitName": "kcal" } }`.
   - Observation: Nutrient IDs are standardized: `1008` (Energy/Kcal), `1003` (Protein), `1004` (Fat), `1005` (Carbohydrates).
   - Rate limit: 1,000 requests/hour per key on `api.data.gov`. Returns HTTP 429 when exhausted.

---

## 2. Logic Chain

1. **Dynamic Gemini Model Discovery**:
   - Because Google accounts have differing access to preview, experimental, and regional models, hardcoding model IDs risks breaking vision analysis when Google updates or deprecates endpoints.
   - Querying `v1beta/models` returns the live list for the specific API key.
   - By filtering models where `supportedGenerationMethods` contains `'generateContent'` AND `inputModalities` contains `'IMAGE'` (with a fallback regex for `'gemini'`), we isolate models that support multimodal food analysis.
   - Stripping the `'models/'` prefix produces clean IDs compatible with both UI display and `google_generative_ai` SDK constructor.

2. **Model Recommendation & Fallback Heuristics**:
   - Gemini models vary significantly in latency and reasoning depth. By ranking `gemini-2.5-flash` first (optimal speed/accuracy for vision volumetric parsing), followed by `gemini-2.0-flash` and `gemini-2.5-pro`, the UI guides the user to the best experience while leaving full control via the selector dropdown.
   - If a saved model is no longer available in the fetched list, the system falls back gracefully to the highest available recommendation tier rather than crashing.

3. **Master Prompt Injection**:
   - In `GeminiVisionService`, the volumetric cubic guidelines are necessary for portion estimation.
   - By creating a dynamic `_buildSystemInstruction([String? masterPrompt])` method, the user's biometric baseline (Mifflin-St Jeor TMB, TDEE, macronutrient distribution) is appended in a structured markdown block, preserving volumetric rules while providing personalization context.

4. **USDA FDC & Open Food Facts Dual-Provider Fallback**:
   - USDA FoodData Central provides deep US branded and raw ingredient data, while Open Food Facts provides comprehensive international and retail barcode coverage.
   - A cascading barcode resolution strategy (USDA -> fallback to Open Food Facts) maximizes product identification without forcing users without a USDA key to fail scanning.
   - Handling both flattened (`nutrientId`/`value`) and nested (`nutrient.id`/`amount`) USDA JSON structures prevents null crashes across search and detail endpoints.

---

## 3. Caveats

- **API Rate Limits**: The default free USDA key has a 1,000 requests/hour limit. For users without a key, the application seamlessly uses Open Food Facts without failure.
- **Energy Units in USDA**: While most USDA branded foods report energy in KCAL, some legacy entries report KJ. The nutrient extractor explicitly handles unit division (`val / 4.184`).
- **Offline Mode**: Both APIs are external. When offline, barcode scanning and Gemini vision will fail gracefully, and the local SQLite database continues normal operation (Local-First).

---

## 4. Conclusion

The technical architecture for Phase 2 External APIs is fully specified and documented in `survey_report.md`.
1. **Dynamic Gemini Querying**: Direct REST call to `v1beta/models`, vision filtering, clean model naming, tiered recommendations, and secure storage in `FlutterSecureStorage` (`gemini_selected_model`).
2. **Master Prompt Integration**: Structured injection into `GeminiVisionService`'s system instruction alongside existing volumetric cubic rules.
3. **USDA FoodData Central**: Complete client specification (`UsdaFoodDataService`) supporting barcode search, raw food search, unified nutrient extraction (macros & micros), and automatic cascading fallback to `OpenFoodFactsService`.
4. All acceptance criteria for A1 and A2 are directly actionable by the planning and implementation agents.

---

## 5. Verification Method

To independently verify the discoveries and specifications:
1. **Gemini Models Endpoint**:
   ```bash
   curl -s "https://generativelanguage.googleapis.com/v1beta/models?key=YOUR_KEY"
   ```
   Inspect the JSON response: verify presence of `models`, `supportedGenerationMethods`, and `inputModalities`.
2. **USDA FDC Search Endpoint**:
   ```bash
   curl -s "https://api.nal.usda.gov/fdc/v1/foods/search?api_key=DEMO_KEY&query=030000010402&dataType=Branded"
   ```
   Inspect the JSON response: verify `foods[0].foodNutrients` containing `nutrientId` `1008` (Energy), `1003` (Protein), `1004` (Fat), `1005` (Carbohydrates).
3. **Inspect Specification Report**:
   Inspect `C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\spec_miner_survey_2\survey_report.md` for complete API models, nutrient ID mapping tables, and code designs.
