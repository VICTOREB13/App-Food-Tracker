import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/core/errors/failures.dart';
import 'package:food_tracker/core/errors/result.dart';
import 'package:food_tracker/core/interfaces/daos_interfaces.dart';
import 'package:food_tracker/core/ports/secure_storage_port.dart';
import 'settings_profile.dart';

class _FakeUserProfileDao implements IUserProfileDao {
  UserProfile? profile;

  @override
  Future<int> saveUserProfile(UserProfile p) async {
    profile = p;
    return 1;
  }

  @override
  Future<UserProfile?> getUserProfile() async => profile;

  @override
  Future<int> deleteUserProfile({String id = 'primary'}) async {
    profile = null;
    return 1;
  }

  @override
  Future<Result<int, DatabaseFailure>> saveUserProfileResult(UserProfile p) async {
    await saveUserProfile(p);
    return const Result.ok(1);
  }

  @override
  Future<Result<UserProfile?, DatabaseFailure>> getUserProfileResult() async =>
      Result.ok(profile);
}

class _FakeSecureStoragePort implements ISecureStoragePort {
  final Map<String, String> _storage = {};
  DailyGoals _goals = const DailyGoals();
  StorageMode _mode = StorageMode.public;

  @override Future<String?> read(String key) async => _storage[key];
  @override Future<void> write(String key, String value) async => _storage[key] = value;
  @override Future<void> delete(String key) async => _storage.remove(key);
  @override Future<bool> containsKey(String key) async => _storage.containsKey(key);
  @override Future<void> deleteAll() async => _storage.clear();

  @override Future<String?> getGeminiApiKey() async => _storage['gemini_api_key'];
  @override Future<void> setGeminiApiKey(String apiKey) async => _storage['gemini_api_key'] = apiKey;
  @override Future<void> deleteGeminiApiKey() async => _storage.remove('gemini_api_key');

  @override Future<String?> getSelectedGeminiModel() async => _storage['selected_gemini_model'];
  @override Future<void> setSelectedGeminiModel(String model) async => _storage['selected_gemini_model'] = model;
  @override Future<void> deleteSelectedGeminiModel() async => _storage.remove('selected_gemini_model');

  @override Future<String?> getUsdaApiKey() async => _storage['usda_api_key'];
  @override Future<void> setUsdaApiKey(String key) async => _storage['usda_api_key'] = key;
  @override Future<void> deleteUsdaApiKey() async => _storage.remove('usda_api_key');

  @override Future<bool> hasCompletedOnboarding() async => _storage['onboarding_completed'] == 'true';
  @override Future<void> setCompletedOnboarding(bool completed) async => _storage['onboarding_completed'] = '$completed';
  @override Future<void> resetCompletedOnboarding() async => _storage.remove('onboarding_completed');

  @override Future<String?> getMasterPrompt() async => _storage['master_prompt'];
  @override Future<void> setMasterPrompt(String prompt) async => _storage['master_prompt'] = prompt;
  @override Future<void> deleteMasterPrompt() async => _storage.remove('master_prompt');

  @override Future<DailyGoals> getDailyGoals() async => _goals;
  @override Future<void> setDailyGoals(DailyGoals goals) async => _goals = goals;

  @override Future<StorageMode> getStorageMode() async => _mode;
  @override Future<void> setStorageMode(StorageMode mode) async => _mode = mode;
}

void main() {
  group('SettingsProfileState Sentinel & Immutable Defaults', () {
    test('initial state has sentinel defaults', () {
      const state = SettingsProfileState.initial;
      expect(state.profile, isNull);
      expect(state.geminiApiKey, isNull);
      expect(state.hasApiKey, isFalse);
      expect(state.hasUsdaApiKey, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.isSaving, isFalse);
      expect(state.storageMode, equals(StorageMode.public));
      expect(state.themeMode, equals(ThemeMode.dark));
      expect(state.isDarkMode, isTrue);
    });

    test('copyWith updates fields with sentinel preservation', () {
      const state = SettingsProfileState.initial;
      final updated = state.copyWith(
        geminiApiKey: 'AIzaTestKey',
        selectedGeminiModel: 'gemini-2.5-flash',
        storageMode: StorageMode.private,
      );
      expect(updated.geminiApiKey, equals('AIzaTestKey'));
      expect(updated.hasApiKey, isTrue);
      expect(updated.selectedGeminiModel, equals('gemini-2.5-flash'));
      expect(updated.storageMode, equals(StorageMode.private));

      final cleared = updated.copyWith(geminiApiKey: null);
      expect(cleared.geminiApiKey, isNull);
      expect(cleared.hasApiKey, isFalse);
      expect(cleared.selectedGeminiModel, equals('gemini-2.5-flash'));
    });
  });

  group('SettingsProfileController BYOK & Keystore', () {
    late _FakeSecureStoragePort fakeSecure;
    late _FakeUserProfileDao fakeProfileDao;
    late SettingsProfileController controller;

    setUp(() {
      fakeSecure = _FakeSecureStoragePort();
      fakeProfileDao = _FakeUserProfileDao();
      controller = SettingsProfileController(
        secureStoragePort: fakeSecure,
        userProfileDao: fakeProfileDao,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('saveApiKey updates storage and controller state', () async {
      await controller.saveApiKey('AIza1234567890');
      expect(controller.hasApiKey, isTrue);
      expect(controller.geminiApiKey, equals('AIza1234567890'));
      expect(await fakeSecure.getGeminiApiKey(), equals('AIza1234567890'));

      await controller.saveApiKey('');
      expect(controller.hasApiKey, isFalse);
      expect(controller.geminiApiKey, isNull);
      expect(await fakeSecure.getGeminiApiKey(), isNull);
    });

    test('saveSelectedGeminiModel updates storage and state', () async {
      await controller.saveSelectedGeminiModel('gemini-2.5-pro');
      expect(controller.selectedGeminiModel, equals('gemini-2.5-pro'));
      expect(await fakeSecure.getSelectedGeminiModel(), equals('gemini-2.5-pro'));

      await controller.saveSelectedGeminiModel('');
      expect(controller.selectedGeminiModel, isNull);
      expect(await fakeSecure.getSelectedGeminiModel(), isNull);
    });

    test('saveUsdaApiKey updates storage and state', () async {
      await controller.saveUsdaApiKey('USDA_SECRET_KEY');
      expect(controller.hasUsdaApiKey, isTrue);
      expect(controller.usdaApiKey, equals('USDA_SECRET_KEY'));
      expect(await fakeSecure.getUsdaApiKey(), equals('USDA_SECRET_KEY'));
    });
  });

  group('SettingsProfileController Profile & Daily Goals', () {
    late _FakeSecureStoragePort fakeSecure;
    late _FakeUserProfileDao fakeProfileDao;
    late SettingsProfileController controller;

    setUp(() {
      fakeSecure = _FakeSecureStoragePort();
      fakeProfileDao = _FakeUserProfileDao();
      controller = SettingsProfileController(
        secureStoragePort: fakeSecure,
        userProfileDao: fakeProfileDao,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('saveProfile persists entity and updates state', () async {
      final profile = UserProfile(
        id: 'primary',
        name: 'Victor',
        age: 30,
        gender: 'male',
        height: 180,
        weight: 78,
        bmr: 1750,
        tdee: 2400,
        targetCalories: 2100,
        targetProtein: 160,
        targetCarbs: 220,
        targetFat: 65,
      );

      await controller.saveProfile(profile);
      expect(controller.profile, isNotNull);
      expect(controller.profile?.name, equals('Victor'));
      expect(controller.profile?.weight, equals(78.0));
      expect(await fakeProfileDao.getUserProfile(), isNotNull);
    });

    test('saveDailyGoals synchronizes goals and triggers notifications', () async {
      int notifications = 0;
      controller.addListener(() => notifications++);

      const goals = DailyGoals(calories: 2200, protein: 170, carbs: 230, fat: 70);
      await controller.saveDailyGoals(goals);

      expect(controller.dailyGoals.calories, equals(2200));
      expect(controller.dailyGoals.protein, equals(170));
      expect(await fakeSecure.getDailyGoals(), equals(goals));
      expect(notifications, greaterThan(0));
    });

    test('storageMode toggle updates port and state', () async {
      await controller.saveStorageMode(StorageMode.private);
      expect(controller.storageMode, equals(StorageMode.private));
      expect(await fakeSecure.getStorageMode(), equals(StorageMode.private));
    });
  });
}
