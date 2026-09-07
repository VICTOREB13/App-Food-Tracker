# 5-Component Handoff Report: Phase 2 Milestone 2 - Credentials Storage & Barcode Cascading Fallback

**Agent:** Explorer 3 (`explorer_m2_3`)  
**Target Milestone:** Phase 2 Milestone 2 (M2: External APIs & Credentials)  
**Deliverable Path:** `C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_m2_3\report.md`  
**Handoff Type:** Hard (Investigation complete)  

---

## 1. Observation

### 1.1 Existing Implementations Observed
- **`lib/services/secure_storage_service.dart` (50 lines)**:
  - Uses `FlutterSecureStorage` with `AndroidOptions(encryptedSharedPreferences: true)` (`line 9-11`).
  - Only stores `gemini_api_key` (`lines 13, 16-30`) and `daily_goals_json` (`lines 14, 32-48`).
  - Lacks `gemini_selected_model`, `usda_api_key`, `has_completed_onboarding`, and `user_master_prompt`.
  - Directly instantiates `const FlutterSecureStorage(...)` as a private field (`line 9`), making unit testing impossible without platform channels unless dependency injection is added.
- **`lib/services/open_food_facts_service.dart` (88 lines)**:
  - Exposes `Future<PantryItem?> fetchProductByBarcode(String barcode)` (`line 12`).
  - Queries `https://world.openfoodfacts.org/api/v2/product/$sanitizedBarcode.json` with a 10s timeout (`line 17, 28`).
  - Extracts 100g base nutrients (`energy-kcal_100g`, `proteins_100g`, `carbohydrates_100g`, `fat_100g`) and constructs `PantryItem` (`lines 50-82`).
- **`lib/widgets/common/barcode_scanner_dialog.dart` (140 lines)**:
  - Calls `OpenFoodFactsService.instance.fetchProductByBarcode(code)` directly at line 42.
  - Displays error message: `'Producto no encontrado en Open Food Facts.'` (`line 48`).
  - Physical LoC is 140 lines, well below the 300 LoC threshold.
- **`lib/screens/dashboard_screen.dart` (287 lines)**:
  - Consumes barcode scan at line 126: `final PantryItem? item = await showBarcodeScannerDialog(context);`.
  - Maps `PantryItem` to `FoodItem(estimatedGrams: 100, visualJustification: 'Escaneado por código de barras (100g base)')` (`lines 129-137`).
- **Test Baseline**:
  - Zero existing tests for `SecureStorageService` or barcode lookup in `test/`.
  - Machine environment does not have `flutter` or `dart` in system PATH (`auditor_m1_1/handoff.md:147`). All unit tests run in CI/CD and must be 100% mocked without external hardware channels or network calls.

---

## 2. Logic Chain

1. **Credentials Storage (`SecureStorageService`)**:
   - `ORIGINAL_REQUEST.md` (R1, R2, R3) requires persisting `gemini_selected_model`, `usda_api_key`, and onboarding status under hardware encryption.
   - Adding getters, setters, and deletion methods with `AndroidOptions(encryptedSharedPreferences: true)` and `IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device)` guarantees security across mobile platforms.
   - Refactoring `SecureStorageService` to accept optional `FlutterSecureStorage` and providing `@visibleForTesting static void setMockInstance()` / `SecureStorageService.withStorage()` allows 100% in-memory unit testing in `test/services/secure_storage_service_test.dart` using a fake storage class.
2. **Barcode Cascading Fallback Architecture**:
   - USDA FoodData Central offers official, lab-analyzed data for US branded products, while Open Food Facts provides broad global and international coverage.
   - A mediator service `BarcodeLookupService` (`lib/services/barcode_lookup_service.dart`) decouples `UsdaFoodDataService` from `OpenFoodFactsService`, respecting the Single Responsibility Principle.
   - When a barcode is scanned:
     1. It normalizes digits (stripping whitespace and non-digits).
     2. It checks `SecureStorageService.instance.getUsdaApiKey()`. If missing, it immediately delegates to Open Food Facts.
     3. If a USDA key is present, it queries USDA FDC (`/foods/search?query={barcode}&dataType=Branded`).
     4. If USDA returns a match, it constructs `PantryItem` (which is already per 100g in USDA Branded dataset) and returns immediately.
     5. If USDA returns 0 hits, 403 (invalid key), 429 (rate limit exceeded), or encounters a timeout (>10s), it catches the error and silently cascades to `OpenFoodFactsService.fetchProductByBarcode(code)`.
     6. If Open Food Facts returns a match, it returns `PantryItem`. If not found, it returns `null`.
3. **Consumer Layer Integration**:
   - `barcode_scanner_dialog.dart` only needs to replace line 42 with `BarcodeLookupService.instance.lookupBarcode(code)` and update the error text. Its LoC remains ~140 lines (< 300 LoC threshold).
   - `dashboard_screen.dart` requires 0 modifications because `showBarcodeScannerDialog` continues to return `Future<PantryItem?>`.
4. **Conclusion Derivation**:
   - This design achieves 100% coverage of Milestone 2 requirements without bloat, provides zero breaking changes, and enables offline deterministic testing.

---

## 3. Caveats

- **USDA FoodData Central Client Dependency**: `BarcodeLookupService` relies on `UsdaFoodDataService`, which is being specified by peer `explorer_m2_2`. The contract is simple: `Future<PantryItem?> fetchProductByBarcode(String barcode, {String? apiKey})`.
- **EAN-13 vs UPC-A**: Scanners prepending a leading zero to 12-digit UPCs must be handled during query retries (both in `UsdaFoodDataService` and `BarcodeLookupService`).
- **Offline Mode**: If the device has no internet connection at all, both USDA and OFF will time out and return `null`, allowing the user to enter food manually.

---

## 4. Conclusion

The recommended architecture establishes:
1. An expanded, hardware-encrypted, and test-injectable `SecureStorageService` storing `gemini_selected_model`, `usda_api_key`, `has_completed_onboarding`, and `user_master_prompt`.
2. A lightweight, decoupled `BarcodeLookupService` coordinating the cascading fallback from USDA FDC to Open Food Facts.
3. Drop-in integration into `barcode_scanner_dialog.dart` keeping screen/dialog LoC well under the 300-line limit.
4. Two comprehensive test suites (`secure_storage_service_test.dart` and `barcode_lookup_service_test.dart`) covering 12 distinct unit test scenarios with fake in-memory fixtures.

---

## 5. Verification Method

### 5.1 Inspection Checklist
1. Inspect `lib/services/secure_storage_service.dart` for:
   - `getSelectedGeminiModel()` / `setSelectedGeminiModel(String)`
   - `getUsdaApiKey()` / `setUsdaApiKey(String)` / `deleteUsdaApiKey()`
   - `hasCompletedOnboarding()` / `setCompletedOnboarding(bool)`
   - Testability constructor: `SecureStorageService.withStorage(storage)`.
2. Inspect `lib/services/barcode_lookup_service.dart` for:
   - `lookupBarcode(String)` and `lookupBarcodeDetailed(String)`
   - Cascade logic: USDA (if key) -> Open Food Facts.
3. Inspect `lib/widgets/common/barcode_scanner_dialog.dart` for call to `BarcodeLookupService.instance.lookupBarcode(code)`.

### 5.2 Test Execution Commands (CI / Local Flutter)
```bash
flutter test test/services/secure_storage_service_test.dart
flutter test test/services/barcode_lookup_service_test.dart
flutter test
flutter analyze
```

### 5.3 Invalidation Conditions
- Any hardcoded API keys in source code.
- Any crash or user-facing exception when USDA API key is invalid or rate limit is reached (HTTP 429).
- Any increase of `barcode_scanner_dialog.dart` exceeding 300 LoC.
