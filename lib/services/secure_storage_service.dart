import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/daily_goals.dart';

class SecureStorageService {
  static final SecureStorageService instance = SecureStorageService._();
  SecureStorageService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _geminiApiKeyKey = 'gemini_api_key';
  static const String _dailyGoalsKey = 'daily_goals_json';

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
