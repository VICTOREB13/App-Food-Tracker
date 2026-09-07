## 2026-09-07T16:06:48Z

You are the External APIs Spec Miner for Phase 2 of Victor Engineer - Food Tracker (NutriTracker Local-First).
Your working directory is: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\spec_miner_survey_2
You MUST read the authoritative user request at: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\ORIGINAL_REQUEST.md before doing anything else.

Objective:
Investigate and specify external API integrations and secure credentials storage for Phase 2:
1. Dynamic Google Gemini Model Querying (R1):
   - Investigate endpoint `GET https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}`.
   - Exact JSON response structure from Google Gemini models endpoint.
   - Filter criteria: models supporting `generateContent` and vision/multimodal input.
   - Model recommendations logic (highlighting `gemini-2.5-flash`, `gemini-2.5-pro`, `gemini-2.0-flash`, etc.).
   - Current implementation of `lib/services/gemini_vision_service.dart` and `lib/services/secure_storage_service.dart`: how models and API keys are configured and stored, and how to dynamically use the selected model.
   - How to inject the Master Prompt from R3 into `GeminiVisionService`'s system instruction.
2. USDA FoodData Central Integration (R2):
   - Endpoint specifications for USDA FoodData Central (`https://api.nal.usda.gov/fdc/v1/`).
   - Endpoints: Search (`/foods/search`), Food details (`/food/{fdcId}`), nutrient parsing (protein, carbs, fat, calories, micronutrients).
   - Rate limiting, error handling, and API key management (`usda_api_key` via `FlutterSecureStorage`).
   - Integration with existing `OpenFoodFactsService` / barcode scanner: Fallback mechanism (USDA -> Open Food Facts or vice versa).
   - Service design for `UsdaFoodDataService`.

Scope Boundaries:
- READ-ONLY exploration and specification mining. DO NOT edit or create source code files.
- Write only to your working directory.

Output Requirements:
- Write your comprehensive specification report to: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\spec_miner_survey_2\survey_report.md
- Deliver your handoff and send a completion message to the orchestrator.
