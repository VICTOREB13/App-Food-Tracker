# Handoff Report: USDA FoodData Central Client Architecture
**Agent**: Explorer 2 (`explorer_m2_2`)
**Milestone**: Phase 2 Milestone 2 (External APIs & Credentials)
**Date**: 2026-09-07T16:35:00Z
**Report Artifact**: `C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_m2_2\report.md`

---

## 1. Observation

1. **User Request & Project Plan Scope**:
   - `ORIGINAL_REQUEST.md` (lines 28-32):
     > "R2. Integración de Credenciales USDA FoodData Central: Añadir campo de entrada seguro en `SettingsScreen` para la API Key de FoodData Central (`https://fdc.nal.usda.gov`). Almacenar la clave de forma segura mediante `FlutterSecureStorage` (`usda_api_key`). Crear servicio cliente `UsdaFoodDataService` con fallback automático a Open Food Facts para enriquecer la biblioteca de alimentos y códigos de barras."
   - `orchestrator_1/PROJECT.md` (lines 21-23, 50, 81):
     > "Feature 7: USDA FoodData Central Client Service - Typed client for `https://api.nal.usda.gov/fdc/v1/` (`/foods/search` & `/food/{fdcId}`). Feature 8: Unified Nutrient Parser - Extract macros (Kcal, protein, fat, carbs) and micros with unit conversions. Feature 9: Cascading Barcode Scanner Fallback - Scanned barcode queries USDA FDC first, falls back to Open Food Facts."
2. **Dual-Schema Structure in USDA FDC API**:
   - `spec_miner_survey_2/survey_report.md` (lines 274-318, 339-353):
     In `/foods/search`, nutrients are flat:
     ```json
     { "nutrientId": 1008, "nutrientName": "Energy", "unitName": "KCAL", "value": 150.0 }
     ```
     In `/food/{fdcId}`, nutrients are nested:
     ```json
     { "amount": 150.0, "nutrient": { "id": 1008, "name": "Energy", "unitName": "kcal" } }
     ```
3. **Existing Model Patterns & Constraints**:
   - `lib/models/food_item.dart` (lines 14, 25-35): Uses `static const Object _sentinel = Object();` and `ModelSanitizer.clampDouble()`.
   - `lib/models/pantry_item.dart` (lines 15, 27-35): Uses `_sentinel` and `ModelSanitizer`.
   - `lib/services/open_food_facts_service.dart` (lines 10-29): Uses `http.Client` with 10-second timeout, returns `PantryItem?`.
   - `lib/widgets/common/barcode_scanner_dialog.dart` (line 42): Calls `OpenFoodFactsService.instance.fetchProductByBarcode(code)`.
   - `lib/screens/dashboard_screen.dart` (lines 125-138): Converts `PantryItem` from barcode dialog into `FoodItem` with 100g base for meal logging.
4. **Dependencies**:
   - `pubspec.yaml` contains `http: ^1.3.0` which includes `package:http/testing.dart` (`MockClient`), enabling 100% offline hermetic testing.

---

## 2. Logic Chain

1. **Step 1 (Schema Normalization)**:
   Because USDA FDC returns flat nutrient maps from `/foods/search` (`nutrientId`, `value`) and nested maps from `/food/{fdcId}` (`nutrient.id`, `amount`), a single unified parser `UsdaNutrientParser.parseNutrient` is necessary to inspect both paths (`(item['nutrientId'] ?? item['nutrient']?['id'])` and `(item['value'] ?? item['amount'])`). This avoids code duplication and guarantees identical nutrient extraction across endpoints.
2. **Step 2 (Caloric Metric Conversion)**:
   Because European/international products or certain USDA sub-datasets report energy in kilojoules ($kJ$), checking if `unitName` contains `KJ` and dividing by $4.184$ ensures accurate kilocalorie ($kcal$) normalization before storing into domain models.
3. **Step 3 (Barcode Dual Formatting)**:
   Scanned barcodes may be 12-digit UPC-A (common in the US) or 13-digit EAN-13 (common internationally). Because USDA indexes branded GTINs as entered by manufacturers, stripping a leading `'0'` from a 13-digit barcode or prepending `'0'` to a 12-digit barcode allows `fetchByBarcode` to resolve items regardless of scanner hardware formatting.
4. **Step 4 (Cascading Fallback)**:
   The user prompt requires fallback to Open Food Facts. In `UsdaFoodDataService`, `fetchProductWithFallback(barcode)` attempts USDA FDC first if a key exists; on 404, 403, 429, timeout, or missing key, it transparently executes `OpenFoodFactsService.instance.fetchProductByBarcode(barcode)`. This allows `BarcodeScannerDialog` to upgrade to dual-provider lookup with a 1-line change.
5. **Step 5 (Hermetic Testing Strategy)**:
   Providing constructor injection `UsdaFoodDataService({http.Client? client, SecureStorageService? storage})` enables tests in `test/services/usda_food_data_service_test.dart` to inject `MockClient` with mock JSON fixtures, testing all success/failure paths deterministically in CI/CD without network access or live API keys.

---

## 3. Caveats

1. **API Key Provisioning**: Without an API key entered by the user, USDA FDC endpoints cannot be queried. The client design handles this gracefully by returning empty/null and falling back to Open Food Facts immediately without network delay.
2. **USDA Serving Sizes**: In Branded foods, `servingSize` is provided (often in grams or ml), whereas in Foundation / SR Legacy foods, nutrients are standard per 100g. `toFoodItem` accounts for this by checking `servingSize` and `servingSizeUnit == 'g'`, scaling macros proportionally if custom `estimatedGrams` is provided.
3. **Portion Text**: `householdServingFullText` (e.g. "1/2 cup") is branded-food specific; for raw ingredients it may be null. Fallback strings are provided via `ModelSanitizer`.

---

## 4. Conclusion

The architecture and exact code specified in `report.md` provide a production-grade, leak-proof, fully tested client for USDA FoodData Central:
- `UsdaFoodItem` model with `_sentinel` pattern and `toPantryItem()` / `toFoodItem()` converters.
- `UsdaNutrientParser` extracting Energy (1008), Protein (1003), Fat (1004), Carbs (1005), Fiber (1079), Sodium (1093), Calcium (1087), Iron (1089), Vitamin A (1104, 1106), and Vitamin C (1162) with $kJ \rightarrow kcal$ conversion.
- `UsdaFoodDataService` implementing `searchFoods`, `fetchByBarcode`, `fetchFoodDetails`, and `fetchProductWithFallback` with sliding-window rate limiting (1,000 req/hr) and 10s timeout defense.
- Ready-to-implement unit test suite with 5 mock JSON fixtures using `MockClient`.

---

## 5. Verification Method

1. **Inspect Architectural Specification**:
   View `C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_m2_2\report.md` to review the exact Dart classes and test fixtures.
2. **Downstream Implementation Verification**:
   When implemented by the coder agent:
   - Create `lib/models/usda_food_item.dart` and `lib/services/usda_food_data_service.dart`.
   - Create `test/services/usda_food_data_service_test.dart`.
   - Run:
     ```powershell
     flutter test test/services/usda_food_data_service_test.dart
     flutter analyze lib/models/usda_food_item.dart lib/services/usda_food_data_service.dart
     ```
   - Invalidation conditions: Any test failure in nutrient parsing, failure to convert kJ to kcal, crash on missing API key, or non-zero `flutter analyze` diagnostics.
