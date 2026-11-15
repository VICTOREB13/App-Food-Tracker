import 'package:food_tracker/core/models/daily_goals.dart';
import 'package:food_tracker/core/models/storage_mode.dart';

/// Hexagonal port for encrypted hardware storage and sensitive credential custody.
abstract interface class ISecureStoragePort {
  // --- Generic Key-Value Operations ---
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<bool> containsKey(String key);
  Future<void> deleteAll();

  // --- Gemini API Key ---
  Future<String?> getGeminiApiKey();
  Future<void> setGeminiApiKey(String apiKey);
  Future<void> deleteGeminiApiKey();

  // --- Gemini Selected Model ---
  Future<String?> getSelectedGeminiModel();
  Future<void> setSelectedGeminiModel(String model);
  Future<void> deleteSelectedGeminiModel();

  // --- USDA API Key ---
  Future<String?> getUsdaApiKey();
  Future<void> setUsdaApiKey(String key);
  Future<void> deleteUsdaApiKey();

  // --- Onboarding Completion Status ---
  Future<bool> hasCompletedOnboarding();
  Future<void> setCompletedOnboarding(bool completed);
  Future<void> resetCompletedOnboarding();

  // --- User Master Prompt ---
  Future<String?> getMasterPrompt();
  Future<void> setMasterPrompt(String prompt);
  Future<void> deleteMasterPrompt();

  // --- Daily Goals ---
  Future<DailyGoals> getDailyGoals();
  Future<void> setDailyGoals(DailyGoals goals);

  // --- Storage Mode (Public vs Private) ---
  Future<StorageMode> getStorageMode();
  Future<void> setStorageMode(StorageMode mode);
}
