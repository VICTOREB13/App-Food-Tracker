## 2026-09-07T16:30:06Z
You are Explorer 2 for Phase 2 Milestone 2: External APIs & Credentials.
Your working directory is: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_m2_2
You MUST read the authoritative user request at: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\ORIGINAL_REQUEST.md before doing anything else.
Read the project plan at: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\orchestrator_1\PROJECT.md
Read the spec report at: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\spec_miner_survey_2\survey_report.md

Milestone 2 Scope (USDA FoodData Central Client):
1. `lib/services/usda_food_data_service.dart`:
   - Typed client for `https://api.nal.usda.gov/fdc/v1/`.
   - Methods:
     - `Future<List<UsdaFoodItem>> searchFoods(String query, {int pageSize = 10, String? apiKey})`
     - `Future<UsdaFoodItem?> fetchByBarcode(String barcode, {String? apiKey})`
     - `Future<UsdaFoodItem?> fetchFoodDetails(int fdcId, {String? apiKey})`
   - Unified Nutrient Parser:
     - Handle both flattened search schemas (`nutrientId`/`value`) and nested detail schemas (`nutrient.id`/`amount`).
     - IDs: 1008 (Calories/Energy, convert KJ to Kcal if unitName is KJ), 1003 (Protein), 1004 (Fat), 1005 (Carbohydrates).
     - Micros: 1079 (Fiber), 1093 (Sodium), 1087 (Calcium), 1089 (Iron), 1104 (Vitamin A), 1162 (Vitamin C).
   - Rate limiting & error handling:
     - 1,000 req/hour limit, 10-second timeout, graceful error codes (400, 403, 429).
     - If API key is missing or empty, handle gracefully.
   - Conversion to domain model: `PantryItem toPantryItem()` and `FoodItem toFoodItem()`.

Task:
- Recommend exact Dart code structure, nutrient extraction logic, and unit test strategy with mock JSON fixtures.
- DO NOT implement changes. Write your report to: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_m2_2\report.md.
- Write handoff.md and notify orchestrator via send_message.
