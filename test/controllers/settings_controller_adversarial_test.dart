import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_tracker/controllers/settings_controller.dart';
import 'package:food_tracker/models/gemini_model_info.dart';
import 'package:food_tracker/services/database_service.dart';
import 'package:food_tracker/services/gemini_model_service.dart';
import 'package:food_tracker/services/gemini_vision_service.dart';
import 'package:food_tracker/services/secure_storage_service.dart';

class AdversarialFakeStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> data = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return data[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      data[key] = value;
    } else {
      data.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    data.remove(key);
  }
}

const String fullApiResponse = '''
{
  "models": [
    {
      "name": "models/gemini-2.5-flash",
      "displayName": "Gemini 2.5 Flash",
      "description": "Ultra fast model",
      "supportedGenerationMethods": ["generateContent"],
      "inputModalities": ["TEXT", "IMAGE"]
    },
    {
      "name": "models/gemini-2.0-flash",
      "displayName": "Gemini 2.0 Flash",
      "description": "Stable model",
      "supportedGenerationMethods": ["generateContent"],
      "inputModalities": ["TEXT", "IMAGE"]
    },
    {
      "name": "models/gemini-2.5-pro",
      "displayName": "Gemini 2.5 Pro",
      "description": "Deep reasoning model",
      "supportedGenerationMethods": ["generateContent"],
      "inputModalities": ["TEXT", "IMAGE"]
    }
  ]
}
''';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late AdversarialFakeStorage fakeStorage;
  late SettingsController controller;

  setUp(() async {
    fakeStorage = AdversarialFakeStorage();
    SecureStorageService.setMockInstance(SecureStorageService.withStorage(fakeStorage));

    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE meals (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              meal_type TEXT NOT NULL,
              date TEXT NOT NULL,
              calories REAL NOT NULL,
              protein REAL NOT NULL,
              carbs REAL NOT NULL,
              fat REAL NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE pantry_items (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              category TEXT,
              calories REAL NOT NULL,
              protein REAL NOT NULL,
              carbs REAL NOT NULL,
              fat REAL NOT NULL,
              is_favorite INTEGER NOT NULL DEFAULT 0
            )
          ''');
        },
      ),
    );
    DatabaseService.instance.setDatabaseForTesting(db);

    SettingsController.resetInstance();
    controller = SettingsController.instance;
  });

  tearDown(() async {
    await DatabaseService.instance.closeForTesting();
    SecureStorageService.resetInstance();
    SettingsController.resetInstance();
  });

  group('Adversarial SettingsController & Model Selection Tests', () {
    test('1. Empty API Key generates ZERO spurious network calls and falls back cleanly', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response(fullApiResponse, 200);
      });
      controller.setGeminiModelServiceForTesting(GeminiModelService(client: mockClient));

      // Init without API key
      await controller.init();

      expect(requestCount, equals(0), reason: 'Zero network calls must be made without API key');
      expect(controller.hasApiKey, isFalse);
      expect(controller.isOnlineModels, isFalse);
      expect(controller.availableGeminiModels.length, equals(GeminiModelService.fallbackModels.length));
      expect(controller.selectedGeminiModel, equals(GeminiModelService.fallbackModels.first.name));

      // Explicit load call with null/empty key
      await controller.loadAvailableGeminiModels();
      expect(requestCount, equals(0), reason: 'Explicit loadAvailableGeminiModels with empty key must not fetch');
      expect(controller.isOnlineModels, isFalse);
    });

    test('2. Network Error Matrix: 400, 403, 429, 500, 503, Timeout, SocketException fallback gracefully', () async {
      final errorScenarios = [
        http.Response('{"error": "Invalid API Key"}', 400),
        http.Response('{"error": "Forbidden - Permission Denied"}', 403),
        http.Response('{"error": "Quota Exceeded"}', 429),
        http.Response('{"error": "Internal Server Error"}', 500),
        http.Response('Service Unavailable', 503),
      ];

      for (final errResponse in errorScenarios) {
        await fakeStorage.write(key: 'gemini_api_key', value: 'AIzaSyErrorKey');
        final mockClient = MockClient((request) async => errResponse);
        controller.setGeminiModelServiceForTesting(GeminiModelService(client: mockClient));

        // Must not throw uncaught exception
        await controller.loadAvailableGeminiModels(forceRefresh: true);

        expect(controller.isOnlineModels, isFalse);
        expect(controller.availableGeminiModels.length, equals(GeminiModelService.fallbackModels.length));
        expect(controller.selectedGeminiModel, isNotNull);
      }

      // Timeout scenario
      final timeoutClient = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return http.Response(fullApiResponse, 200);
      });
      controller.setGeminiModelServiceForTesting(
        GeminiModelService(client: timeoutClient),
      );
      await controller.loadAvailableGeminiModels(forceRefresh: true);
      expect(controller.isOnlineModels, isFalse);

      // SocketException scenario
      final socketErrorClient = MockClient((request) async {
        throw const SocketException('No Internet Connection');
      });
      controller.setGeminiModelServiceForTesting(
        GeminiModelService(client: socketErrorClient),
      );
      await controller.loadAvailableGeminiModels(forceRefresh: true);
      expect(controller.isOnlineModels, isFalse);
      expect(controller.availableGeminiModels.length, equals(GeminiModelService.fallbackModels.length));
    });

    test('3. Selection of each recommended model persists to SecureStorage and triggers notifyListeners', () async {
      const recommendedModels = [
        'gemini-2.5-flash',
        'gemini-2.0-flash',
        'gemini-2.5-pro',
      ];

      for (final model in recommendedModels) {
        int notificationCount = 0;
        void listener() => notificationCount++;
        controller.addListener(listener);

        await controller.saveSelectedGeminiModel(model);

        expect(controller.selectedGeminiModel, equals(model));
        expect(await SecureStorageService.instance.getSelectedGeminiModel(), equals(model));
        expect(notificationCount, greaterThan(0), reason: 'notifyListeners must be triggered for $model');

        controller.removeListener(listener);
      }
    });

    test('4. Dynamic Model Resolution: When stored model is null, defaults to GeminiVisionService.defaultModel', () async {
      await SecureStorageService.instance.deleteSelectedGeminiModel();
      final storedModel = await SecureStorageService.instance.getSelectedGeminiModel();
      expect(storedModel, isNull);

      final effectiveModel = storedModel ?? GeminiVisionService.defaultModel;
      expect(effectiveModel, equals('gemini-2.5-flash'));
      expect(effectiveModel, equals(GeminiVisionService.defaultModel));

      final visionService = GeminiVisionService(
        apiKey: 'dummy-key',
        modelName: effectiveModel,
      );
      expect(visionService.modelName, equals('gemini-2.5-flash'));
    });

    test('5. Dynamic Model Invocation: When user selects gemini-2.0-flash, effective model matches exactly', () async {
      await SecureStorageService.instance.setSelectedGeminiModel('gemini-2.0-flash');
      final storedModel = await SecureStorageService.instance.getSelectedGeminiModel();
      expect(storedModel, equals('gemini-2.0-flash'));

      final effectiveModel = storedModel ?? GeminiVisionService.defaultModel;
      expect(effectiveModel, equals('gemini-2.0-flash'));

      final visionService = GeminiVisionService(
        apiKey: 'dummy-key',
        modelName: effectiveModel,
      );
      expect(visionService.modelName, equals('gemini-2.0-flash'));
    });

    test('6. Unrecognized saved model resolves to first recommended model in available list', () {
      const models = [
        GeminiModelInfo(
          name: 'gemini-2.5-flash',
          displayName: 'Gemini 2.5 Flash',
          description: '',
          isRecommended: true,
        ),
        GeminiModelInfo(
          name: 'gemini-2.0-flash',
          displayName: 'Gemini 2.0 Flash',
          description: '',
          isRecommended: true,
        ),
      ];

      final resolved = GeminiModelService.resolveEffectiveModel(
        availableModels: models,
        savedSelection: 'gemini-obsolete-model-99',
      );
      expect(resolved, equals('gemini-2.5-flash'));
    });
  });
}
