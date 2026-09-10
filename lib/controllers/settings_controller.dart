import 'package:flutter/foundation.dart';
import '../models/daily_goals.dart';
import '../models/gemini_model_info.dart';
import '../services/backup_service.dart';
import '../services/database_service.dart';
import '../services/gemini_model_service.dart';
import '../services/metabolic_calculator.dart';
import '../services/secure_storage_service.dart';
import 'meal_controller.dart';

class SettingsController extends ChangeNotifier {
  static SettingsController _instance = SettingsController._();
  static SettingsController get instance => _instance;
  SettingsController._();

  @visibleForTesting
  static void setMockInstance(SettingsController mock) {
    _instance = mock;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = SettingsController._();
  }

  @visibleForTesting
  factory SettingsController.forTesting() => SettingsController._();

  GeminiModelService _geminiModelService = GeminiModelService.instance;

  @visibleForTesting
  void setGeminiModelServiceForTesting(GeminiModelService service) {
    _geminiModelService = service;
  }

  String? _geminiApiKey;
  String? _selectedGeminiModel;
  String? _usdaApiKey;
  List<GeminiModelInfo> _availableGeminiModels = [];
  bool _isLoadingModels = false;
  bool _isOnlineModels = false;

  DailyGoals _dailyGoals = const DailyGoals();
  Map<String, dynamic> _dbStats = {};
  bool _isLoading = false;

  String? get geminiApiKey => _geminiApiKey;
  bool get hasApiKey => _geminiApiKey != null && _geminiApiKey!.trim().isNotEmpty;

  String? get selectedGeminiModel => _selectedGeminiModel;
  String? get usdaApiKey => _usdaApiKey;
  bool get hasUsdaApiKey => _usdaApiKey != null && _usdaApiKey!.trim().isNotEmpty;
  List<GeminiModelInfo> get availableGeminiModels => List.unmodifiable(_availableGeminiModels);
  bool get isLoadingModels => _isLoadingModels;
  bool get isOnlineModels => _isOnlineModels;

  DailyGoals get dailyGoals => _dailyGoals;
  Map<String, dynamic> get dbStats => Map.unmodifiable(_dbStats);
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _geminiApiKey = await SecureStorageService.instance.getGeminiApiKey();
      _selectedGeminiModel = await SecureStorageService.instance.getSelectedGeminiModel();
      _usdaApiKey = await SecureStorageService.instance.getUsdaApiKey();
      _dailyGoals = await SecureStorageService.instance.getDailyGoals();
      _dbStats = await DatabaseService.instance.getDatabaseStats();

      if (_geminiApiKey != null && _geminiApiKey!.trim().isNotEmpty) {
        await loadAvailableGeminiModels();
      } else {
        _availableGeminiModels = GeminiModelService.fallbackModels;
        _isOnlineModels = false;
        _selectedGeminiModel ??= GeminiModelService.fallbackModels.first.name;
      }
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
      _availableGeminiModels = GeminiModelService.fallbackModels;
      _isOnlineModels = false;
    } else {
      await SecureStorageService.instance.setGeminiApiKey(trimmed);
      _geminiApiKey = trimmed;
      await loadAvailableGeminiModels(forceRefresh: true);
    }
    notifyListeners();
  }

  Future<void> loadSelectedGeminiModel() async {
    _selectedGeminiModel = await SecureStorageService.instance.getSelectedGeminiModel();
    notifyListeners();
  }

  Future<void> saveSelectedGeminiModel(String model) async {
    final trimmed = model.trim();
    if (trimmed.isEmpty) {
      await SecureStorageService.instance.deleteSelectedGeminiModel();
      _selectedGeminiModel = null;
    } else {
      await SecureStorageService.instance.setSelectedGeminiModel(trimmed);
      _selectedGeminiModel = trimmed;
    }
    notifyListeners();
  }

  Future<void> loadUsdaApiKey() async {
    _usdaApiKey = await SecureStorageService.instance.getUsdaApiKey();
    notifyListeners();
  }

  Future<void> saveUsdaApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await SecureStorageService.instance.deleteUsdaApiKey();
      _usdaApiKey = null;
    } else {
      await SecureStorageService.instance.setUsdaApiKey(trimmed);
      _usdaApiKey = trimmed;
    }
    notifyListeners();
  }

  Future<void> loadAvailableGeminiModels({bool forceRefresh = false}) async {
    final key = _geminiApiKey?.trim();
    if (key == null || key.isEmpty) {
      _availableGeminiModels = GeminiModelService.fallbackModels;
      _isOnlineModels = false;
      _isLoadingModels = false;
      _selectedGeminiModel ??= GeminiModelService.fallbackModels.first.name;
      notifyListeners();
      return;
    }

    _isLoadingModels = true;
    notifyListeners();

    try {
      final models = await _geminiModelService.fetchAvailableModels(key);
      if (models.isNotEmpty) {
        _availableGeminiModels = models;
        _isOnlineModels = true;
      } else {
        _availableGeminiModels = GeminiModelService.fallbackModels;
        _isOnlineModels = false;
      }
    } catch (_) {
      _availableGeminiModels = GeminiModelService.fallbackModels;
      _isOnlineModels = false;
    } finally {
      _isLoadingModels = false;
      final effective = GeminiModelService.resolveEffectiveModel(
        availableModels: _availableGeminiModels,
        savedSelection: _selectedGeminiModel,
      );
      if (_selectedGeminiModel == null || !_availableGeminiModels.any((m) => m.name == _selectedGeminiModel)) {
        _selectedGeminiModel = effective;
      }
      notifyListeners();
    }
  }

  Future<void> refreshDailyGoals([DailyGoals? goals]) async {
    _dailyGoals = goals ?? await SecureStorageService.instance.getDailyGoals();
    notifyListeners();
  }

  Future<void> saveDailyGoals(DailyGoals goals) async {
    await SecureStorageService.instance.setDailyGoals(goals);
    _dailyGoals = goals;

    try {
      var profile = await DatabaseService.instance.getUserProfile();
      profile ??= MetabolicCalculator.calculateProfile(
        age: 25,
        gender: 'male',
        height: 175,
        weight: 70,
        activityLevel: 'moderate',
        bodyGoal: 'maintenance',
      );
      final updated = profile.copyWith(
        targetCalories: goals.calories,
        targetProtein: goals.protein,
        targetCarbs: goals.carbs,
        targetFat: goals.fat,
        updatedAt: DateTime.now(),
      );
      final newPrompt = MetabolicCalculator.generateMasterPrompt(updated);
      final finalProfile = updated.copyWith(masterPrompt: newPrompt);
      await DatabaseService.instance.saveUserProfile(finalProfile);
      await SecureStorageService.instance.setMasterPrompt(newPrompt);
    } catch (_) {}

    await MealController.instance.refreshGoals();
    notifyListeners();
  }

  void notifyProfileUpdated() {
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
