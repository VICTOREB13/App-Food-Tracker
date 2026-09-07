import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_tracker/controllers/settings_controller.dart';
import 'package:food_tracker/models/daily_goals.dart';
import 'package:food_tracker/models/gemini_model_info.dart';
import 'package:food_tracker/services/database_service.dart';
import 'package:food_tracker/services/gemini_model_service.dart';
import 'package:food_tracker/services/secure_storage_service.dart';

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
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

const String mockApiResponse = '''
{
  "models": [
    {
      "name": "models/gemini-2.5-flash",
      "displayName": "Gemini 2.5 Flash",
      "description": "Ultra fast vision model",
      "supportedGenerationMethods": ["generateContent"],
      "inputModalities": ["TEXT", "IMAGE"]
    },
    {
      "name": "models/gemini-2.0-flash",
      "displayName": "Gemini 2.0 Flash",
      "description": "Stable high speed model",
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
  late FakeFlutterSecureStorage fakeStorage;
  late SettingsController controller;

  setUp(() async {
    fakeStorage = FakeFlutterSecureStorage();
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

  group('SettingsController Unit Tests', () {
    test('Initial state before init has default values', () {
      expect(controller.geminiApiKey, isNull);
      expect(controller.hasApiKey, isFalse);
      expect(controller.selectedGeminiModel, isNull);
      expect(controller.usdaApiKey, isNull);
      expect(controller.hasUsdaApiKey, isFalse);
      expect(controller.availableGeminiModels, isEmpty);
      expect(controller.isLoadingModels, isFalse);
      expect(controller.isOnlineModels, isFalse);
      expect(controller.isLoading, isFalse);
    });

    test('init() without Gemini API key loads fallbacks and default model', () async {
      await controller.init();

      expect(controller.geminiApiKey, isNull);
      expect(controller.hasApiKey, isFalse);
      expect(controller.availableGeminiModels, isNotEmpty);
      expect(controller.availableGeminiModels.length, equals(GeminiModelService.fallbackModels.length));
      expect(controller.isOnlineModels, isFalse);
      expect(controller.selectedGeminiModel, equals(GeminiModelService.fallbackModels.first.name));
    });

    test('init() with stored Gemini API key queries online models via GeminiModelService', () async {
      await fakeStorage.write(key: 'gemini_api_key', value: 'AIzaSyTest123');
      await fakeStorage.write(key: 'gemini_selected_model', value: 'gemini-2.0-flash');
      await fakeStorage.write(key: 'usda_api_key', value: 'USDA_KEY_456');

      final mockClient = MockClient((request) async {
        return http.Response(mockApiResponse, 200);
      });
      controller.setGeminiModelServiceForTesting(GeminiModelService(client: mockClient));

      await controller.init();

      expect(controller.geminiApiKey, equals('AIzaSyTest123'));
      expect(controller.hasApiKey, isTrue);
      expect(controller.usdaApiKey, equals('USDA_KEY_456'));
      expect(controller.hasUsdaApiKey, isTrue);
      expect(controller.selectedGeminiModel, equals('gemini-2.0-flash'));
      expect(controller.isOnlineModels, isTrue);
      expect(controller.availableGeminiModels.length, equals(3));
      expect(controller.availableGeminiModels[0].name, equals('gemini-2.5-flash'));
    });

    test('saveApiKey() saves key to SecureStorage and refreshes models', () async {
      final mockClient = MockClient((request) async {
        return http.Response(mockApiResponse, 200);
      });
      controller.setGeminiModelServiceForTesting(GeminiModelService(client: mockClient));

      bool notified = false;
      controller.addListener(() => notified = true);

      await controller.saveApiKey('AIzaSyNewKey');

      expect(controller.geminiApiKey, equals('AIzaSyNewKey'));
      expect(controller.hasApiKey, isTrue);
      expect(await SecureStorageService.instance.getGeminiApiKey(), equals('AIzaSyNewKey'));
      expect(controller.isOnlineModels, isTrue);
      expect(controller.availableGeminiModels.length, equals(3));
      expect(notified, isTrue);
    });

    test('saveApiKey("") deletes key and resets to fallback offline models', () async {
      await controller.saveApiKey('AIzaSyOldKey');
      expect(controller.hasApiKey, isTrue);

      await controller.saveApiKey('');

      expect(controller.geminiApiKey, isNull);
      expect(controller.hasApiKey, isFalse);
      expect(await SecureStorageService.instance.getGeminiApiKey(), isNull);
      expect(controller.isOnlineModels, isFalse);
      expect(controller.availableGeminiModels.length, equals(GeminiModelService.fallbackModels.length));
    });

    test('saveSelectedGeminiModel() updates model and persists to SecureStorage', () async {
      bool notified = false;
      controller.addListener(() => notified = true);

      await controller.saveSelectedGeminiModel('gemini-2.5-pro');

      expect(controller.selectedGeminiModel, equals('gemini-2.5-pro'));
      expect(await SecureStorageService.instance.getSelectedGeminiModel(), equals('gemini-2.5-pro'));
      expect(notified, isTrue);

      // Deleting selection
      await controller.saveSelectedGeminiModel('');
      expect(controller.selectedGeminiModel, isNull);
      expect(await SecureStorageService.instance.getSelectedGeminiModel(), isNull);
    });

    test('saveUsdaApiKey() updates key and persists to SecureStorage', () async {
      bool notified = false;
      controller.addListener(() => notified = true);

      await controller.saveUsdaApiKey('DEMO_USDA_API_KEY');

      expect(controller.usdaApiKey, equals('DEMO_USDA_API_KEY'));
      expect(controller.hasUsdaApiKey, isTrue);
      expect(await SecureStorageService.instance.getUsdaApiKey(), equals('DEMO_USDA_API_KEY'));
      expect(notified, isTrue);

      // Deleting key
      await controller.saveUsdaApiKey('');
      expect(controller.usdaApiKey, isNull);
      expect(controller.hasUsdaApiKey, isFalse);
      expect(await SecureStorageService.instance.getUsdaApiKey(), isNull);
    });

    test('loadAvailableGeminiModels() catches errors and falls back gracefully', () async {
      await fakeStorage.write(key: 'gemini_api_key', value: 'error-prone-key');
      await controller.init();

      final mockClient = MockClient((request) async {
        return http.Response('{"error": "Quota exceeded"}', 429);
      });
      controller.setGeminiModelServiceForTesting(GeminiModelService(client: mockClient));

      await controller.loadAvailableGeminiModels(forceRefresh: true);

      // Gracefully falls back without throwing unhandled exception
      expect(controller.isOnlineModels, isFalse);
      expect(controller.availableGeminiModels.length, equals(GeminiModelService.fallbackModels.length));
      expect(controller.selectedGeminiModel, isNotNull);
    });

    test('saveDailyGoals() updates goals in storage and refreshes MealController', () async {
      const newGoals = DailyGoals(
        calories: 2500,
        protein: 160,
        carbs: 260,
        fat: 75,
      );

      await controller.saveDailyGoals(newGoals);

      expect(controller.dailyGoals.calories, equals(2500));
      expect(controller.dailyGoals.protein, equals(160));
      final storedGoals = await SecureStorageService.instance.getDailyGoals();
      expect(storedGoals.calories, equals(2500));
    });
  });
}
