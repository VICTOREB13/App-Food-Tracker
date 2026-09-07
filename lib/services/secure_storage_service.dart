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
