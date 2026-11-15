import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_tracker/core/models/daily_goals.dart';
import 'package:food_tracker/core/models/storage_mode.dart';
import 'package:food_tracker/core/services/storage/secure_storage_service.dart';
import '../ports/secure_storage_port.dart';

/// Hardware-backed encrypted storage adapter for [ISecureStoragePort].
class EncryptedStorageAdapter implements ISecureStoragePort {
  final SecureStorageService _service;
  final FlutterSecureStorage _storage;

  EncryptedStorageAdapter({
    SecureStorageService? service,
    FlutterSecureStorage? storage,
  })  : _service = service ?? SecureStorageService.instance,
        _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  // --- Generic Key-Value Operations ---
  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key).timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value).timeout(
            const Duration(seconds: 2),
          );
    } catch (_) {}
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key).timeout(
            const Duration(seconds: 2),
          );
    } catch (_) {}
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key).timeout(
            const Duration(seconds: 2),
            onTimeout: () => false,
          );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll().timeout(
            const Duration(seconds: 2),
          );
    } catch (_) {}
  }

  // --- Gemini API Key ---
  @override
  Future<String?> getGeminiApiKey() => _service.getGeminiApiKey();

  @override
  Future<void> setGeminiApiKey(String apiKey) =>
      _service.setGeminiApiKey(apiKey);

  @override
  Future<void> deleteGeminiApiKey() => _service.deleteGeminiApiKey();

  // --- Gemini Selected Model ---
  @override
  Future<String?> getSelectedGeminiModel() => _service.getSelectedGeminiModel();

  @override
  Future<void> setSelectedGeminiModel(String model) =>
      _service.setSelectedGeminiModel(model);

  @override
  Future<void> deleteSelectedGeminiModel() =>
      _service.deleteSelectedGeminiModel();

  // --- USDA API Key ---
  @override
  Future<String?> getUsdaApiKey() => _service.getUsdaApiKey();

  @override
  Future<void> setUsdaApiKey(String key) => _service.setUsdaApiKey(key);

  @override
  Future<void> deleteUsdaApiKey() => _service.deleteUsdaApiKey();

  // --- Onboarding Completion Status ---
  @override
  Future<bool> hasCompletedOnboarding() => _service.hasCompletedOnboarding();

  @override
  Future<void> setCompletedOnboarding(bool completed) =>
      _service.setCompletedOnboarding(completed);

  @override
  Future<void> resetCompletedOnboarding() =>
      _service.resetCompletedOnboarding();

  // --- User Master Prompt ---
  @override
  Future<String?> getMasterPrompt() => _service.getMasterPrompt();

  @override
  Future<void> setMasterPrompt(String prompt) =>
      _service.setMasterPrompt(prompt);

  @override
  Future<void> deleteMasterPrompt() => _service.deleteMasterPrompt();

  // --- Daily Goals ---
  @override
  Future<DailyGoals> getDailyGoals() => _service.getDailyGoals();

  @override
  Future<void> setDailyGoals(DailyGoals goals) =>
      _service.setDailyGoals(goals);

  // --- Storage Mode (Public vs Private) ---
  @override
  Future<StorageMode> getStorageMode() => _service.getStorageMode();

  @override
  Future<void> setStorageMode(StorageMode mode) =>
      _service.setStorageMode(mode);
}
