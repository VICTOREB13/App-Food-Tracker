import 'package:flutter/foundation.dart';
import '../models/daily_goals.dart';
import '../services/backup_service.dart';
import '../services/database_service.dart';
import '../services/secure_storage_service.dart';
import 'meal_controller.dart';

class SettingsController extends ChangeNotifier {
  static final SettingsController instance = SettingsController._();
  SettingsController._();

  String? _geminiApiKey;
  DailyGoals _dailyGoals = const DailyGoals();
  Map<String, dynamic> _dbStats = {};
  bool _isLoading = false;

  String? get geminiApiKey => _geminiApiKey;
  bool get hasApiKey => _geminiApiKey != null && _geminiApiKey!.trim().isNotEmpty;
  DailyGoals get dailyGoals => _dailyGoals;
  Map<String, dynamic> get dbStats => Map.unmodifiable(_dbStats);
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _geminiApiKey = await SecureStorageService.instance.getGeminiApiKey();
      _dailyGoals = await SecureStorageService.instance.getDailyGoals();
      _dbStats = await DatabaseService.instance.getDatabaseStats();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await SecureStorageService.instance.deleteGeminiApiKey();
      _geminiApiKey = null;
    } else {
      await SecureStorageService.instance.setGeminiApiKey(trimmed);
      _geminiApiKey = trimmed;
    }
    notifyListeners();
  }

  Future<void> saveDailyGoals(DailyGoals goals) async {
    await SecureStorageService.instance.setDailyGoals(goals);
    _dailyGoals = goals;
    await MealController.instance.refreshGoals();
    notifyListeners();
  }

  Future<void> optimizeDatabase() async {
    _isLoading = true;
    notifyListeners();
    try {
      await DatabaseService.instance.executeVacuum();
      _dbStats = await DatabaseService.instance.getDatabaseStats();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> exportBackup() async {
    return await BackupService.instance.exportToJsonString();
  }

  Future<Map<String, int>> importBackup(String jsonContent) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await BackupService.instance.importFromJsonString(jsonContent);
      _dbStats = await DatabaseService.instance.getDatabaseStats();
      await MealController.instance.loadMeals();
      return res;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
