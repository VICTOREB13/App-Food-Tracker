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
              aOptions: AndroidOptions(resetOnError: true),
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

  static const Duration _timeout = Duration(seconds: 2);

  Future<String?> _safeRead(String key) async {
    try {
      return await _storage
          .read(key: key)
          .timeout(_timeout, onTimeout: () => null);
    } catch (e) {
      debugPrint('SecureStorageService: error reading $key: $e');
      return null;
    }
  }

  Future<void> _safeWrite(String key, String value) async {
    try {
      await _storage
          .write(key: key, value: value)
          .timeout(_timeout);
    } catch (e) {
      debugPrint('SecureStorageService: error writing $key: $e');
    }
  }

  Future<void> _safeDelete(String key) async {
    try {
      await _storage
          .delete(key: key)
          .timeout(_timeout);
    } catch (e) {
      debugPrint('SecureStorageService: error deleting $key: $e');
    }
  }

  // --- Gemini API Key ---
  Future<String?> getGeminiApiKey() => _safeRead(_geminiApiKeyKey);

  Future<void> setGeminiApiKey(String apiKey) =>
      _safeWrite(_geminiApiKeyKey, apiKey.trim());

  Future<void> deleteGeminiApiKey() => _safeDelete(_geminiApiKeyKey);

  // --- Gemini Selected Model (R1) ---
  Future<String?> getSelectedGeminiModel() => _safeRead(_geminiSelectedModelKey);

  Future<void> setSelectedGeminiModel(String model) =>
      _safeWrite(_geminiSelectedModelKey, model.trim());

  Future<void> deleteSelectedGeminiModel() => _safeDelete(_geminiSelectedModelKey);

  // --- USDA API Key (R2) ---
  Future<String?> getUsdaApiKey() => _safeRead(_usdaApiKeyKey);

  Future<void> setUsdaApiKey(String key) =>
      _safeWrite(_usdaApiKeyKey, key.trim());

  Future<void> deleteUsdaApiKey() => _safeDelete(_usdaApiKeyKey);

  // --- Onboarding Completion Status (R3) ---
  Future<bool> hasCompletedOnboarding() async {
    final value = await _safeRead(_hasCompletedOnboardingKey);
    return value == 'true';
  }

  Future<void> setCompletedOnboarding(bool completed) =>
      _safeWrite(_hasCompletedOnboardingKey, completed.toString());

  Future<void> resetCompletedOnboarding() =>
      _safeDelete(_hasCompletedOnboardingKey);

  // --- User Master Prompt (R3 Context) ---
  Future<String?> getMasterPrompt() => _safeRead(_masterPromptKey);

  Future<void> setMasterPrompt(String prompt) =>
      _safeWrite(_masterPromptKey, prompt.trim());

  Future<void> deleteMasterPrompt() => _safeDelete(_masterPromptKey);

  // --- Daily Goals ---
  Future<DailyGoals> getDailyGoals() async {
    try {
      final raw = await _safeRead(_dailyGoalsKey);
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
    await _safeWrite(_dailyGoalsKey, raw);
  }
}
