import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_tracker/core/adapters/encrypted_storage_adapter.dart';
import 'package:food_tracker/core/di/service_locator.dart';
import 'package:food_tracker/core/interfaces/daos_interfaces.dart';
import 'package:food_tracker/core/ports/database_port.dart';
import 'package:food_tracker/core/ports/secure_storage_port.dart';
import 'package:food_tracker/features/data_backup/services/backup_service.dart';
import 'package:food_tracker/core/database/database_service.dart';
import 'package:food_tracker/core/services/ai/gemini_model_service.dart';
import 'package:food_tracker/core/services/platform/home_widget_service.dart';
import 'package:food_tracker/features/biometrics_weight/services/metabolic_calculator.dart';
import 'package:food_tracker/core/services/storage/secure_storage_service.dart';
import 'package:food_tracker/core/services/theme/theme_manager.dart';
import 'settings_profile.model.dart';

/// State controller for Settings & User Profile managing BYOK, theme, locale,
/// metabolic goals, and database maintenance via hexagonal ports.
class SettingsProfileController extends ChangeNotifier {
  static SettingsProfileController instance = SettingsProfileController();

  final ISecureStoragePort _secureStorage;
  final IDatabasePort? _dbPort;
  final IUserProfileDao _userProfileDao;
  GeminiModelService _geminiModelService;
  final ThemeManager _themeManager;
  SettingsProfileState _state = SettingsProfileState.initial;

  SettingsProfileController({
    ISecureStoragePort? secureStoragePort,
    IDatabasePort? databasePort,
    IUserProfileDao? userProfileDao,
    GeminiModelService? geminiModelService,
    ThemeManager? themeManager,
  })  : _secureStorage = secureStoragePort ?? (getIt.isRegistered<ISecureStoragePort>() ? getIt<ISecureStoragePort>() : EncryptedStorageAdapter(service: SecureStorageService.instance)),
        _dbPort = databasePort ?? (getIt.isRegistered<IDatabasePort>() ? getIt<IDatabasePort>() : null),
        _userProfileDao = userProfileDao ?? (databasePort?.userProfileDao ?? (getIt.isRegistered<IUserProfileDao>() ? getIt<IUserProfileDao>() : DatabaseService.instance.userProfileDao)),
        _geminiModelService = geminiModelService ?? GeminiModelService.instance,
        _themeManager = themeManager ?? ThemeManager.instance;

  @visibleForTesting static void setMockInstance(SettingsProfileController mock) => instance = mock;
  @visibleForTesting static void resetInstance() => instance = SettingsProfileController();
  @visibleForTesting void setGeminiModelServiceForTesting(GeminiModelService s) => _geminiModelService = s;

  SettingsProfileState get state => _state;
  UserProfile? get profile => _state.profile; String? get geminiApiKey => _state.geminiApiKey;
  bool get hasApiKey => _state.hasApiKey; bool get hasUsdaApiKey => _state.hasUsdaApiKey;
  String? get selectedGeminiModel => _state.selectedGeminiModel;
  String? get usdaApiKey => _state.usdaApiKey;
  List<GeminiModelInfo> get availableGeminiModels => _state.availableGeminiModels;
  bool get isLoadingModels => _state.isLoadingModels; bool get isOnlineModels => _state.isOnlineModels;
  DailyGoals get dailyGoals => _state.dailyGoals;
  Map<String, dynamic> get dbStats => _state.dbStats;
  bool get isLoading => _state.isLoading; bool get isSaving => _state.isSaving;
  StorageMode get storageMode => _state.storageMode; Locale? get currentLocale => _state.locale; ThemeMode get themeMode => _state.themeMode;

  Future<void> init() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    try {
      await loadLocale();
      final mode = await _secureStorage.getStorageMode();
      final gemKey = await _secureStorage.getGeminiApiKey();
      final model = await _secureStorage.getSelectedGeminiModel();
      final usdaKey = await _secureStorage.getUsdaApiKey();
      final goals = await _secureStorage.getDailyGoals();
      final userProf = await _userProfileDao.getUserProfile();
      final stats = await (_dbPort?.getDatabaseStats() ?? DatabaseService.instance.getDatabaseStats());
      _state = _state.copyWith(
        storageMode: mode, geminiApiKey: gemKey, selectedGeminiModel: model,
        usdaApiKey: usdaKey, dailyGoals: goals, profile: userProf,
        dbStats: stats, themeMode: _themeManager.themeMode,
      );
      if (gemKey != null && gemKey.trim().isNotEmpty) {
        await loadAvailableGeminiModels();
      } else {
        _state = _state.copyWith(
          availableGeminiModels: GeminiModelService.fallbackModels,
          isOnlineModels: false,
          selectedGeminiModel: model ?? GeminiModelService.fallbackModels.first.name,
        );
      }
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<void> loadProfile() async {
    try {
      final saved = await _userProfileDao.getUserProfile();
      _state = _state.copyWith(profile: saved);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> saveProfile(UserProfile userProfile) async {
    _state = _state.copyWith(isSaving: true);
    notifyListeners();
    try {
      await _userProfileDao.saveUserProfile(userProfile);
      _state = _state.copyWith(profile: userProfile);
    } finally {
      _state = _state.copyWith(isSaving: false);
      notifyListeners();
    }
  }

  Future<void> loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('app_locale_code');
      final loc = (code != null && code.isNotEmpty) ? Locale(code) : null;
      _state = _state.copyWith(locale: loc);
      await HomeWidgetService.instance.syncAllWidgetsWithLocale(loc ?? const Locale('es'));
    } catch (_) {}
  }

  Future<void> setLocale(Locale locale) async {
    _state = _state.copyWith(locale: locale);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_locale_code', locale.languageCode);
      await HomeWidgetService.instance.syncAllWidgetsWithLocale(locale);
    } catch (_) {}
  }

  Future<void> saveStorageMode(StorageMode mode) async {
    _state = _state.copyWith(storageMode: mode);
    notifyListeners();
    await _secureStorage.setStorageMode(mode);
  }

  Future<void> saveApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await _secureStorage.deleteGeminiApiKey();
      _state = _state.copyWith(
        geminiApiKey: null,
        availableGeminiModels: GeminiModelService.fallbackModels,
        isOnlineModels: false,
      );
    } else {
      await _secureStorage.setGeminiApiKey(trimmed);
      _state = _state.copyWith(geminiApiKey: trimmed);
      await loadAvailableGeminiModels(forceRefresh: true);
    }
    notifyListeners();
  }

  Future<void> saveSelectedGeminiModel(String modelName) async {
    final trimmed = modelName.trim();
    if (trimmed.isEmpty) {
      await _secureStorage.deleteSelectedGeminiModel();
      _state = _state.copyWith(selectedGeminiModel: null);
    } else {
      await _secureStorage.setSelectedGeminiModel(trimmed);
      _state = _state.copyWith(selectedGeminiModel: trimmed);
    }
    notifyListeners();
  }

  Future<void> saveUsdaApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await _secureStorage.deleteUsdaApiKey();
      _state = _state.copyWith(usdaApiKey: null);
    } else {
      await _secureStorage.setUsdaApiKey(trimmed);
      _state = _state.copyWith(usdaApiKey: trimmed);
    }
    notifyListeners();
  }

  Future<void> loadAvailableGeminiModels({bool forceRefresh = false}) async {
    final key = _state.geminiApiKey?.trim();
    if (key == null || key.isEmpty) {
      _state = _state.copyWith(
        availableGeminiModels: GeminiModelService.fallbackModels,
        isOnlineModels: false,
        isLoadingModels: false,
        selectedGeminiModel: _state.selectedGeminiModel ?? GeminiModelService.fallbackModels.first.name,
      );
      notifyListeners();
      return;
    }
    _state = _state.copyWith(isLoadingModels: true);
    notifyListeners();
    try {
      final models = await _geminiModelService.fetchAvailableModels(key);
      _state = _state.copyWith(
        availableGeminiModels: models.isNotEmpty ? models : GeminiModelService.fallbackModels,
        isOnlineModels: models.isNotEmpty,
      );
    } catch (_) {
      _state = _state.copyWith(availableGeminiModels: GeminiModelService.fallbackModels, isOnlineModels: false);
    } finally {
      final eff = GeminiModelService.resolveEffectiveModel(
        availableModels: _state.availableGeminiModels,
        savedSelection: _state.selectedGeminiModel,
      );
      String? sel = _state.selectedGeminiModel;
      if (sel == null || !_state.availableGeminiModels.any((m) => m.name == sel)) sel = eff;
      _state = _state.copyWith(isLoadingModels: false, selectedGeminiModel: sel);
      notifyListeners();
    }
  }

  Future<void> refreshDailyGoals([DailyGoals? goals]) async {
    final effective = goals ?? await _secureStorage.getDailyGoals();
    _state = _state.copyWith(dailyGoals: effective);
    notifyListeners();
  }

  Future<void> saveDailyGoals(DailyGoals goals) async {
    await _secureStorage.setDailyGoals(goals);
    _state = _state.copyWith(dailyGoals: goals);
    try {
      final prof = (await _userProfileDao.getUserProfile()) ?? MetabolicCalculator.calculateProfile(
        age: 25, gender: 'male', height: 175, weight: 70, activityLevel: 'moderate', bodyGoal: 'maintenance',
      );
      final updated = prof.copyWith(
        targetCalories: goals.calories, targetProtein: goals.protein,
        targetCarbs: goals.carbs, targetFat: goals.fat, updatedAt: DateTime.now(),
      );
      final newPrompt = MetabolicCalculator.generateMasterPrompt(updated);
      final finalProfile = updated.copyWith(masterPrompt: newPrompt);
      await _userProfileDao.saveUserProfile(finalProfile);
      await _secureStorage.setMasterPrompt(newPrompt);
      _state = _state.copyWith(profile: finalProfile);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _state = _state.copyWith(themeMode: mode);
    notifyListeners();
    await _themeManager.setThemeMode(mode);
  }

  Future<void> toggleTheme() async {
    await _themeManager.toggleTheme();
    _state = _state.copyWith(themeMode: _themeManager.themeMode);
    notifyListeners();
  }

  Future<void> optimizeDatabase() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    try {
      if (_dbPort != null) {
        await _dbPort.executeVacuum();
        _state = _state.copyWith(dbStats: await _dbPort.getDatabaseStats());
      } else {
        await DatabaseService.instance.executeVacuum();
        _state = _state.copyWith(dbStats: await DatabaseService.instance.getDatabaseStats());
      }
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<String> exportBackup() async => BackupService.instance.exportToJsonString();
  Future<File> exportBackupToFile({String? customDirectoryPath}) => BackupService.instance.exportToJsonFile(customDirectoryPath: customDirectoryPath);

  Future<T> _runWithBackupSync<T>(Future<T> Function() action) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    try {
      final res = await action();
      final stats = await (_dbPort?.getDatabaseStats() ?? DatabaseService.instance.getDatabaseStats());
      _state = _state.copyWith(dbStats: stats);
      return res;
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<List<File>> listBackups({String? customDirectoryPath}) async =>
      BackupService.instance.listAvailableBackups(customDirectoryPath: customDirectoryPath);

  Future<Map<String, int>> importBackup(String jsonContent) =>
      _runWithBackupSync(() => BackupService.instance.importFromJsonString(jsonContent));

  Future<Map<String, int>> importBackupFromFile(File file) =>
      _runWithBackupSync(() => BackupService.instance.importFromFile(file));

  void notifyProfileUpdated() {
    loadProfile();
    notifyListeners();
  }
}
