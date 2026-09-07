import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_tracker/models/daily_goals.dart';
import 'package:food_tracker/services/secure_storage_service.dart';

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};
  bool shouldThrow = false;

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
    if (shouldThrow) throw Exception('Simulated storage failure');
    return _data[key];
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
    if (shouldThrow) throw Exception('Simulated storage failure');
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
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
    if (shouldThrow) throw Exception('Simulated storage failure');
    _data.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (shouldThrow) throw Exception('Simulated storage failure');
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
      SecureStorageService.setMockInstance(service);
    });

    tearDown(() {
      SecureStorageService.resetInstance();
    });

    test('Gemini API Key get, set, delete', () async {
      expect(await service.getGeminiApiKey(), isNull);
      await service.setGeminiApiKey('AIzaSyD-mockKey123456');
      expect(await service.getGeminiApiKey(), equals('AIzaSyD-mockKey123456'));
      await service.deleteGeminiApiKey();
      expect(await service.getGeminiApiKey(), isNull);
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

    test('Onboarding status defaults to false, sets to true, and resets', () async {
      expect(await service.hasCompletedOnboarding(), isFalse);
      await service.setCompletedOnboarding(true);
      expect(await service.hasCompletedOnboarding(), isTrue);
      await service.setCompletedOnboarding(false);
      expect(await service.hasCompletedOnboarding(), isFalse);
      await service.setCompletedOnboarding(true);
      await service.resetCompletedOnboarding();
      expect(await service.hasCompletedOnboarding(), isFalse);
    });

    test('User Master Prompt get, set, delete', () async {
      expect(await service.getMasterPrompt(), isNull);
      const prompt = 'Hombre de 30 años, 80kg, déficit 500 kcal';
      await service.setMasterPrompt(prompt);
      expect(await service.getMasterPrompt(), equals(prompt));
      await service.deleteMasterPrompt();
      expect(await service.getMasterPrompt(), isNull);
    });

    test('DailyGoals serialization and default fallback', () async {
      final defaultGoals = await service.getDailyGoals();
      expect(defaultGoals.calories, equals(2000.0));

      const customGoals = DailyGoals(
        calories: 2400.0,
        protein: 180.0,
        carbs: 220.0,
        fat: 70.0,
      );
      await service.setDailyGoals(customGoals);
      final retrieved = await service.getDailyGoals();
      expect(retrieved.calories, equals(2400.0));
      expect(retrieved.protein, equals(180.0));
      expect(retrieved.carbs, equals(220.0));
      expect(retrieved.fat, equals(70.0));
    });

    test('Gracefully returns null/defaults when storage throws exception', () async {
      fakeStorage.shouldThrow = true;
      expect(await service.getGeminiApiKey(), isNull);
      expect(await service.getSelectedGeminiModel(), isNull);
      expect(await service.getUsdaApiKey(), isNull);
      expect(await service.hasCompletedOnboarding(), isFalse);
      expect(await service.getMasterPrompt(), isNull);
      final goals = await service.getDailyGoals();
      expect(goals.calories, equals(2000.0));
    });
  });
}
