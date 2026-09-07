## 2026-09-07T16:30:06Z
You are Explorer 3 for Phase 2 Milestone 2: External APIs & Credentials.
Your working directory is: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_m2_3
You MUST read the authoritative user request at: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\ORIGINAL_REQUEST.md before doing anything else.
Read the project plan at: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\orchestrator_1\PROJECT.md
Read the spec report at: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\spec_miner_survey_2\survey_report.md

Milestone 2 Scope (Credentials Storage & Barcode Cascading Fallback):
1. lib/services/secure_storage_service.dart:
   - Add storage keys:
     - gemini_selected_model: Future<String?> getSelectedGeminiModel(), Future<void> setSelectedGeminiModel(String model)
     - usda_api_key: Future<String?> getUsdaApiKey(), Future<void> setUsdaApiKey(String key), Future<void> deleteUsdaApiKey()
     - has_completed_onboarding: Future<bool> hasCompletedOnboarding(), Future<void> setCompletedOnboarding(bool completed)
   - Maintain hardware-backed encryption (FlutterSecureStorage).
2. Barcode Cascading Resolution:
   - Combine USDA FoodData Central and Open Food Facts:
     - When barcode scanned, check if USDA API key is set. If set, query USDA first (etchByBarcode).
     - If not found or no key or error, fall back automatically to OpenFoodFactsService.fetchProductByBarcode(code).
     - Provide unified result so scanning works globally and seamlessly.
   - Check where barcode scanning is called (lib/widgets/common/barcode_scanner_dialog.dart, etc.).

Task:
- Recommend exact implementation details, fallback architecture, and unit test strategies.
- DO NOT implement changes. Write your report to: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_m2_3\report.md.
- Write handoff.md and notify orchestrator via send_message.
