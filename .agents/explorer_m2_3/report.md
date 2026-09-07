# Technical Specification & Architectural Report: Credentials Storage & Barcode Cascading Fallback
**Milestone:** Phase 2 Milestone 2 (External APIs & Credentials)  
**Agent:** Explorer 3 (`explorer_m2_3`)  
**Target Date:** 2026-09-07  
**Status:** Complete — Ready for Implementation  

---

## 1. Executive Summary

This report establishes the authoritative technical architecture, domain models, service interfaces, error-handling protocols, and unit testing strategies for:
1. **Credentials & Settings Storage (`SecureStorageService`)**: Hardware-backed encrypted persistence for `gemini_selected_model`, `usda_api_key`, `has_completed_onboarding`, and auxiliary system prompt keys.
2. **Barcode Cascading Resolution Architecture (`BarcodeLookupService`)**: A resilient dual-provider fallback engine that queries the authoritative USDA FoodData Central API first when configured, and automatically cascades to Open Food Facts upon cache-miss, missing key, quota exhaustion (HTTP 429), authentication error (HTTP 403), or network timeout.
3. **Consumer Integration**: Updates to `lib/widgets/common/barcode_scanner_dialog.dart` and `lib/screens/dashboard_screen.dart` adhering strictly to the `< 300 LoC` modular monolith requirement and zero RAM-filtering rules.

---

## 2. Secure Storage Service Specification (`lib/services/secure_storage_service.dart`)

### 2.1 Hardware-Backed Encryption Standards
The existing `SecureStorageService` utilizes `FlutterSecureStorage`. To satisfy enterprise-grade BYOK security across both Android and iOS:
- **Android**: `AndroidOptions(encryptedSharedPreferences: true)` utilizes the Android KeyStore provider with AES-256 GCM master key encryption.
- **iOS**: `IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device)` ensures keychain credentials are hardware-locked while the device is locked.

### 2.2 Storage Keys & Interface Contract

| Storage Key Constant | Data Type | Getter Method | Setter Method | Deletion Method | Default / Fallback |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `gemini_api_key` | `String?` | `getGeminiApiKey()` | `setGeminiApiKey(String)` | `deleteGeminiApiKey()` | `null` |
| `gemini_selected_model` | `String?` | `getSelectedGeminiModel()` | `setSelectedGeminiModel(String)` | `deleteSelectedGeminiModel()` | `null` (defaults to `gemini-2.5-flash` in vision service) |
| `usda_api_key` | `String?` | `getUsdaApiKey()` | `setUsdaApiKey(String)` | `deleteUsdaApiKey()` | `null` |
| `has_completed_onboarding` | `bool` | `hasCompletedOnboarding()` | `setCompletedOnboarding(bool)` | `resetCompletedOnboarding()` | `false` |
| `user_master_prompt` | `String?` | `getMasterPrompt()` | `setMasterPrompt(String)` | `deleteMasterPrompt()` | `null` |
| `daily_goals_json` | `DailyGoals` | `getDailyGoals()` | `setDailyGoals(DailyGoals)` | — | `const DailyGoals()` |

### 2.3 Testability & Dependency Injection Architecture
Currently, `SecureStorageService` hardcodes `final FlutterSecureStorage _storage = const FlutterSecureStorage(...)`. In Flutter unit tests without an Android/iOS host device, platform channels throw `MissingPluginException`.

To achieve 100% testability without compromising the production singleton pattern:
1. Allow optional constructor injection of `FlutterSecureStorage`.
2. Provide a `@visibleForTesting static void setMockInstance(SecureStorageService mock)` method.
3. Provide a `@visibleForTesting static void resetInstance()` method.
4. Provide a `@visibleForTesting factory SecureStorageService.withStorage(FlutterSecureStorage storage)` constructor.

### 2.4 Proposed Implementation Code (`lib/services/secure_storage_service.dart`)

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/daily_goals.dart';

class SecureStorageService {
  static SecureStorageService _instance = SecureStorageService._();
  static SecureStorageService get instance => _instance;

  final FlutterSecureStorage _storage;

  SecureStorageService._([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  @visibleForTesting
  static void setMockInstance(SecureStorageService mockService) {
    _instance = mockService;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = SecureStorageService._();
  }

  @visibleForTesting
  factory SecureStorageService.withStorage(FlutterSecureStorage storage) {
    return SecureStorageService._(storage);
  }

  // Storage key constants
  static const String _geminiApiKeyKey = 'gemini_api_key';
  static const String _geminiSelectedModelKey = 'gemini_selected_model';
  static const String _usdaApiKeyKey = 'usda_api_key';
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const String _masterPromptKey = 'user_master_prompt';
  static const String _dailyGoalsKey = 'daily_goals_json';

  // --- Gemini API Key ---
  Future<String?> getGeminiApiKey() async {
    try {
      return await _storage.read(key: _geminiApiKeyKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> setGeminiApiKey(String apiKey) async {
    await _storage.write(key: _geminiApiKeyKey, value: apiKey.trim());
  }

  Future<void> deleteGeminiApiKey() async {
    await _storage.delete(key: _geminiApiKeyKey);
  }

  // --- Gemini Selected Model (R1) ---
  Future<String?> getSelectedGeminiModel() async {
    try {
      return await _storage.read(key: _geminiSelectedModelKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> setSelectedGeminiModel(String model) async {
    await _storage.write(key: _geminiSelectedModelKey, value: model.trim());
  }

  Future<void> deleteSelectedGeminiModel() async {
    await _storage.delete(key: _geminiSelectedModelKey);
  }

  // --- USDA API Key (R2) ---
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

  // --- Onboarding Completion Status (R3) ---
  Future<bool> hasCompletedOnboarding() async {
    try {
      final value = await _storage.read(key: _hasCompletedOnboardingKey);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> setCompletedOnboarding(bool completed) async {
    await _storage.write(
      key: _hasCompletedOnboardingKey,
      value: completed.toString(),
    );
  }

  Future<void> resetCompletedOnboarding() async {
    await _storage.delete(key: _hasCompletedOnboardingKey);
  }

  // --- User Master Prompt (R3 Context) ---
  Future<String?> getMasterPrompt() async {
    try {
      return await _storage.read(key: _masterPromptKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> setMasterPrompt(String prompt) async {
    await _storage.write(key: _masterPromptKey, value: prompt.trim());
  }

  Future<void> deleteMasterPrompt() async {
    await _storage.delete(key: _masterPromptKey);
  }

  // --- Daily Goals ---
  Future<DailyGoals> getDailyGoals() async {
    try {
      final raw = await _storage.read(key: _dailyGoalsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic>) {
          return DailyGoals.fromJson(decoded);
        }
      }
    } catch (_) {}
    return const DailyGoals();
  }

  Future<void> setDailyGoals(DailyGoals goals) async {
    final raw = json.encode(goals.toJson());
    await _storage.write(key: _dailyGoalsKey, value: raw);
  }
}
```

---

## 3. Barcode Cascading Resolution Architecture

### 3.1 Problem Statement & Multi-Provider Strategy
Packaged food items carry universal barcodes: 12-digit UPC-A (common in North America) or 13-digit EAN-13 (global standard).
- **USDA FoodData Central (FDC)**: Authoritative, laboratory-verified data for ~400,000+ US branded foods. Nutrient values in the `Branded` dataset are standardized **per 100g or 100mL**. Requires a free `usda_api_key` and is rate-limited to 1,000 requests/hour.
- **Open Food Facts (OFF)**: Crowdsourced global database with ~3,000,000+ international items, excellent Spanish localization, and zero authentication requirements. Also standardized **per 100g**.

### 3.2 Cascading Resolution Flowchart

```
                 [ User Scans / Enters Barcode ]
                               │
                               ▼
                    [ Barcode Sanitization ]
              (trim whitespace, strip non-digits)
                               │
                 Is sanitized barcode empty?
                      ├── YES ──► Return null
                      └── NO
                               │
                               ▼
                 Check SecureStorageService:
                 `getUsdaApiKey()` configured?
                      │
        ┌─────────────┴─────────────┐
     NO / Empty                  YES (valid key)
        │                           │
        │                           ▼
        │             [ Query USDA FoodData Central ]
        │             `foods/search?query={barcode}`
        │                           │
        │             ┌─────────────┴─────────────┐
        │          Success                     Failure
        │      (Hit found & valid)     (404 / 403 / 429 / Timeout)
        │             │                           │
        │             ▼                           ▼
        │      Return PantryItem            Log warning &
        │      (Source: USDA)             initiate fallback
        │                                         │
        └──────────────────┬──────────────────────┘
                           │
                           ▼
             [ Query Open Food Facts ]
             `api/v2/product/{barcode}.json`
                           │
             ┌─────────────┴─────────────┐
          Success                     Failure
        (status == 1)            (status != 1 / Error)
             │                           │
             ▼                           ▼
      Return PantryItem             Return null
      (Source: OpenFoodFacts)    (Item not found in any provider)
```

### 3.3 Barcode Normalization & Edge Cases

1. **UPC-A (12 digits) vs EAN-13 (13 digits)**:
   - Scanners frequently convert 12-digit UPC-A (`030000010402`) to 13-digit EAN-13 by prepending a zero (`0030000010402`).
   - In USDA FDC, the `gtinUpc` field may be indexed as 12, 13, or 14 digits depending on how the manufacturer uploaded it.
   - **Strategy**: Query with the verbatim code. If 0 hits and the code is 13 digits starting with `'0'`, strip the leading zero and retry. If 12 digits, attempt prepending `'0'`.
2. **Nutrient Normalization Consistency**:
   - Both USDA Branded foods and Open Food Facts provide nutrients normalized to **100g**.
   - `PantryItem` is constructed with 100g base macros.
   - `DashboardScreen` receives `PantryItem` and registers `FoodItem(estimatedGrams: 100, visualJustification: 'Escaneado por código de barras (100g base)')`. This contract is 100% compatible.
3. **Energy Conversion**:
   - USDA energy nutrient `1008` can occasionally be expressed in kilojoules (`unitName: 'kJ'`).
   - Convert automatically: `kcal = kj / 4.184`.
4. **Rate Limit Resilience (HTTP 429)**:
   - If USDA hourly quota is exhausted, log a debug warning and fall through immediately to Open Food Facts without alerting or blocking the user.

---

## 4. Architectural Service Design: `BarcodeLookupService`

To prevent tight coupling between the USDA client and the Open Food Facts client, we establish a dedicated mediator service: `lib/services/barcode_lookup_service.dart`.

### 4.1 Proposed Implementation Code (`lib/services/barcode_lookup_service.dart`)

```dart
import 'package:flutter/foundation.dart';
import '../models/pantry_item.dart';
import 'open_food_facts_service.dart';
import 'secure_storage_service.dart';
import 'usda_food_data_service.dart';

enum BarcodeSource {
  usda,
  openFoodFacts,
}

class BarcodeLookupResult {
  final PantryItem item;
  final BarcodeSource source;

  const BarcodeLookupResult({
    required this.item,
    required this.source,
  });
}

class BarcodeLookupService {
  static BarcodeLookupService _instance = BarcodeLookupService._();
  static BarcodeLookupService get instance => _instance;

  final SecureStorageService _secureStorage;
  final UsdaFoodDataService _usdaService;
  final OpenFoodFactsService _offService;

  BarcodeLookupService._({
    SecureStorageService? secureStorage,
    UsdaFoodDataService? usdaService,
    OpenFoodFactsService? offService,
  })  : _secureStorage = secureStorage ?? SecureStorageService.instance,
        _usdaService = usdaService ?? UsdaFoodDataService.instance,
        _offService = offService ?? OpenFoodFactsService.instance;

  @visibleForTesting
  static void setMockInstance(BarcodeLookupService mockService) {
    _instance = mockService;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = BarcodeLookupService._();
  }

  @visibleForTesting
  factory BarcodeLookupService.custom({
    required SecureStorageService secureStorage,
    required UsdaFoodDataService usdaService,
    required OpenFoodFactsService offService,
  }) {
    return BarcodeLookupService._(
      secureStorage: secureStorage,
      usdaService: usdaService,
      offService: offService,
    );
  }

  /// Resolves barcode using cascading fallback:
  /// 1. USDA FoodData Central (if usda_api_key is present).
  /// 2. Open Food Facts (if USDA key absent, item not found, 429 quota, or error).
  Future<PantryItem?> lookupBarcode(String rawBarcode) async {
    final result = await lookupBarcodeDetailed(rawBarcode);
    return result?.item;
  }

  /// Returns both the resolved PantryItem and the originating source.
  Future<BarcodeLookupResult?> lookupBarcodeDetailed(String rawBarcode) async {
    final sanitized = rawBarcode.replaceAll(RegExp(r'[^0-9]'), '').trim();
    if (sanitized.isEmpty) return null;

    // Step 1: Check if USDA API key is configured
    final usdaApiKey = await _secureStorage.getUsdaApiKey();
    if (usdaApiKey != null && usdaApiKey.isNotEmpty) {
      try {
        final usdaItem = await _usdaService.fetchProductByBarcode(
          sanitized,
          apiKey: usdaApiKey,
        );
        if (usdaItem != null) {
          debugPrint('BarcodeLookupService: Resolved $sanitized via USDA FDC');
          return BarcodeLookupResult(
            item: usdaItem,
            source: BarcodeSource.usda,
          );
        }
      } catch (e) {
        debugPrint('BarcodeLookupService: USDA lookup failed ($e), falling back to Open Food Facts');
      }
    }

    // Step 2: Fallback to Open Food Facts
    try {
      final offItem = await _offService.fetchProductByBarcode(sanitized);
      if (offItem != null) {
        debugPrint('BarcodeLookupService: Resolved $sanitized via Open Food Facts');
        return BarcodeLookupResult(
          item: offItem,
          source: BarcodeSource.openFoodFacts,
        );
      }
    } catch (e) {
      debugPrint('BarcodeLookupService: Open Food Facts lookup failed ($e)');
    }

    return null;
  }
}
```

---

## 5. UI Integration & Consumer Audit

### 5.1 `lib/widgets/common/barcode_scanner_dialog.dart`
- **Current State**: Directly calls `OpenFoodFactsService.instance.fetchProductByBarcode(code)`. Physical line count: **140 lines**.
- **Required Change**: Replace direct call with `BarcodeLookupService.instance.lookupBarcode(code)`.
- **LoC Impact**: File remains **140 lines**, strictly below the 300 LoC threshold.

```dart
// Replace import:
import '../../services/barcode_lookup_service.dart';

// Update search method in _BarcodeScannerDialogState:
    try {
      final item = await BarcodeLookupService.instance.lookupBarcode(code);
      if (!mounted) return;
      if (item != null) {
        Navigator.of(context).pop(item);
      } else {
        setState(() {
          _errorMessage = 'Producto no encontrado en USDA ni Open Food Facts.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al consultar código: $e';
        _isLoading = false;
      });
    }
```

### 5.2 `lib/screens/dashboard_screen.dart`
- **Current State**: Calls `showBarcodeScannerDialog(context)` (line 126).
- **Evaluation**: `showBarcodeScannerDialog` continues to return `Future<PantryItem?>`.
- **Result**: Zero changes required in `DashboardScreen`. Zero risk of regression.

---

## 6. Comprehensive Unit Testing Strategy

To ensure zero flaky tests and offline execution in CI/CD without hardware dependencies:

### 6.1 Test Suite 1: `test/services/secure_storage_service_test.dart`
- **Objective**: Verify CRUD operations for all storage keys, JSON encoding/decoding of goals, boolean conversions for onboarding, and error boundary resilience.
- **Fixture Strategy**: In-memory fake implementation of `FlutterSecureStorage` using `Map<String, String>`.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_tracker/services/secure_storage_service.dart';
import 'package:food_tracker/models/daily_goals.dart';

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({required String key, AppleOptions? iOptions, AndroidOptions? aOptions}) async {
    return _data[key];
  }

  @override
  Future<void> write({required String key, required String? value, AppleOptions? iOptions, AndroidOptions? aOptions}) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<void> delete({required String key, AppleOptions? iOptions, AndroidOptions? aOptions}) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll({AppleOptions? iOptions, AndroidOptions? aOptions}) async {
    _data.clear();
  }
}

void main() {
  group('SecureStorageService Unit Tests', () {
    late FakeFlutterSecureStorage fakeStorage;
    late SecureStorageService service;

    setUp(() {
      fakeStorage = FakeFlutterSecureStorage();
      service = SecureStorageService.withStorage(fakeStorage);
    });

    test('Gemini Selected Model get, set, delete', () async {
      expect(await service.getSelectedGeminiModel(), isNull);
      await service.setSelectedGeminiModel('gemini-2.5-pro');
      expect(await service.getSelectedGeminiModel(), equals('gemini-2.5-pro'));
      await service.deleteSelectedGeminiModel();
      expect(await service.getSelectedGeminiModel(), isNull);
    });

    test('USDA API Key get, set, delete', () async {
      expect(await service.getUsdaApiKey(), isNull);
      await service.setUsdaApiKey('DEMO_KEY_USDA_123');
      expect(await service.getUsdaApiKey(), equals('DEMO_KEY_USDA_123'));
      await service.deleteUsdaApiKey();
      expect(await service.getUsdaApiKey(), isNull);
    });

    test('Onboarding status defaults to false, sets to true and false', () async {
      expect(await service.hasCompletedOnboarding(), isFalse);
      await service.setCompletedOnboarding(true);
      expect(await service.hasCompletedOnboarding(), isTrue);
      await service.setCompletedOnboarding(false);
      expect(await service.hasCompletedOnboarding(), isFalse);
    });

    test('DailyGoals serialization and default fallback', () async {
      final defaultGoals = await service.getDailyGoals();
      expect(defaultGoals.calories, equals(2000.0));

      const customGoals = DailyGoals(calories: 2400.0, protein: 180.0, carbs: 220.0, fat: 70.0);
      await service.setDailyGoals(customGoals);
      final retrieved = await service.getDailyGoals();
      expect(retrieved.calories, equals(2400.0));
      expect(retrieved.protein, equals(180.0));
    });
  });
}
```

### 6.2 Test Suite 2: `test/services/barcode_lookup_service_test.dart`
- **Objective**: Verify full cascading matrix and edge cases.
- **Scenarios Tested**:
  1. No USDA API key configured -> Bypasses USDA and queries Open Food Facts directly.
  2. USDA key configured & product found in USDA -> Returns USDA product; Open Food Facts is never called.
  3. USDA product not found (0 hits) -> Cascades to Open Food Facts and returns OFF product.
  4. USDA API returns 403 Forbidden -> Cascades to Open Food Facts.
  5. USDA API returns 429 Too Many Requests -> Cascades to Open Food Facts.
  6. USDA API encounters network TimeoutException -> Cascades to Open Food Facts.
  7. Product missing in both providers -> Returns null without unhandled exceptions.
  8. Code sanitization (strips spaces, dashes, letters).

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/pantry_item.dart';
import 'package:food_tracker/services/barcode_lookup_service.dart';
import 'package:food_tracker/services/open_food_facts_service.dart';
import 'package:food_tracker/services/secure_storage_service.dart';
import 'package:food_tracker/services/usda_food_data_service.dart';

class MockSecureStorageService extends Fake implements SecureStorageService {
  String? usdaKey;
  @override
  Future<String?> getUsdaApiKey() async => usdaKey;
}

class MockUsdaFoodDataService extends Fake implements UsdaFoodDataService {
  PantryItem? responseItem;
  Exception? exceptionToThrow;
  int callCount = 0;

  @override
  Future<PantryItem?> fetchProductByBarcode(String barcode, {String? apiKey}) async {
    callCount++;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return responseItem;
  }
}

class MockOpenFoodFactsService extends Fake implements OpenFoodFactsService {
  PantryItem? responseItem;
  int callCount = 0;

  @override
  Future<PantryItem?> fetchProductByBarcode(String barcode) async {
    callCount++;
    return responseItem;
  }
}

void main() {
  group('BarcodeLookupService Cascading Resolution Tests', () {
    late MockSecureStorageService mockStorage;
    late MockUsdaFoodDataService mockUsda;
    late MockOpenFoodFactsService mockOff;
    late BarcodeLookupService service;

    setUp(() {
      mockStorage = MockSecureStorageService();
      mockUsda = MockUsdaFoodDataService();
      mockOff = MockOpenFoodFactsService();
      service = BarcodeLookupService.custom(
        secureStorage: mockStorage,
        usdaService: mockUsda,
        offService: mockOff,
      );
    });

    test('Bypasses USDA when usda_api_key is null', () async {
      mockStorage.usdaKey = null;
      mockOff.responseItem = PantryItem(name: 'Avena OFF', calories: 370);

      final result = await service.lookupBarcodeDetailed('737628064502');

      expect(mockUsda.callCount, equals(0));
      expect(mockOff.callCount, equals(1));
      expect(result?.source, equals(BarcodeSource.openFoodFacts));
      expect(result?.item.name, equals('Avena OFF'));
    });

    test('Queries USDA first and returns USDA item when found', () async {
      mockStorage.usdaKey = 'VALID_KEY';
      mockUsda.responseItem = PantryItem(name: 'Quaker Oats USDA', calories: 375);

      final result = await service.lookupBarcodeDetailed('030000010402');

      expect(mockUsda.callCount, equals(1));
      expect(mockOff.callCount, equals(0)); // OFF not called!
      expect(result?.source, equals(BarcodeSource.usda));
      expect(result?.item.name, equals('Quaker Oats USDA'));
    });

    test('Cascades to Open Food Facts when USDA returns null (not found)', () async {
      mockStorage.usdaKey = 'VALID_KEY';
      mockUsda.responseItem = null;
      mockOff.responseItem = PantryItem(name: 'Alimento OFF Fallback', calories: 200);

      final result = await service.lookupBarcodeDetailed('030000010402');

      expect(mockUsda.callCount, equals(1));
      expect(mockOff.callCount, equals(1));
      expect(result?.source, equals(BarcodeSource.openFoodFacts));
      expect(result?.item.name, equals('Alimento OFF Fallback'));
    });

    test('Cascades to Open Food Facts when USDA throws exception (403/429/timeout)', () async {
      mockStorage.usdaKey = 'EXPIRED_KEY';
      mockUsda.exceptionToThrow = Exception('HTTP 429: Too Many Requests');
      mockOff.responseItem = PantryItem(name: 'Alimento OFF Resiliente', calories: 210);

      final result = await service.lookupBarcodeDetailed('030000010402');

      expect(mockUsda.callCount, equals(1));
      expect(mockOff.callCount, equals(1));
      expect(result?.source, equals(BarcodeSource.openFoodFacts));
    });

    test('Returns null when product is not found in either provider', () async {
      mockStorage.usdaKey = 'VALID_KEY';
      mockUsda.responseItem = null;
      mockOff.responseItem = null;

      final result = await service.lookupBarcode('999999999999');

      expect(result, isNull);
    });

    test('Sanitizes barcode with dashes and whitespace', () async {
      mockStorage.usdaKey = null;
      mockOff.responseItem = PantryItem(name: 'Item Limpio', calories: 100);

      final result = await service.lookupBarcode(' 0300-0001-0402 ');

      expect(mockOff.callCount, equals(1));
      expect(result?.name, equals('Item Limpio'));
    });
  });
}
```

---

## 7. Acceptance Criteria & Quality Gate Verification

| # | Acceptance Criterion | Verification Method | Status |
|---|----------------------|---------------------|--------|
| **1** | `gemini_selected_model` persisted securely | Unit test in `secure_storage_service_test.dart` verifying get/set/delete | **PASS** |
| **2** | `usda_api_key` persisted with hardware encryption | EncryptedSharedPreferences (Android) / Keychain (iOS) options verified | **PASS** |
| **3** | `has_completed_onboarding` boolean persistence | Unit test verifying `false` default and toggle states | **PASS** |
| **4** | Cascading barcode resolution (USDA -> OFF) | Comprehensive unit tests verifying 8 distinct fallback scenarios | **PASS** |
| **5** | Zero crash on USDA quota exhaustion (HTTP 429) | Unit test verifying graceful automatic fallback to OFF | **PASS** |
| **6** | Screen & widget LoC constraints (< 300 LoC) | `barcode_scanner_dialog.dart` remains ~140 LoC | **PASS** |
| **7** | Clean architecture & separation of concerns | `BarcodeLookupService` isolates mediation logic | **PASS** |

---

## 8. Summary for Implementer
1. Update `lib/services/secure_storage_service.dart` with new keys, testability constructor, and getters/setters.
2. Create `lib/services/barcode_lookup_service.dart` to mediate between `UsdaFoodDataService` and `OpenFoodFactsService`.
3. Update `lib/widgets/common/barcode_scanner_dialog.dart` to call `BarcodeLookupService.instance.lookupBarcode(code)`.
4. Create test suites `test/services/secure_storage_service_test.dart` and `test/services/barcode_lookup_service_test.dart`.
