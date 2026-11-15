import 'package:flutter/foundation.dart';
import 'package:food_tracker/core/database/database_service.dart';
import 'package:food_tracker/core/di/service_locator.dart';
import 'package:food_tracker/core/interfaces/daos_interfaces.dart';
import 'package:food_tracker/core/interfaces/dishware_dao_interface.dart';
import 'package:food_tracker/core/interfaces/meal_template_dao_interface.dart';
import 'package:food_tracker/core/models/usda_food_item.dart';
import 'package:food_tracker/core/ports/ai_vision_port.dart';
import 'package:food_tracker/core/ports/database_port.dart';
import 'package:food_tracker/core/ports/nutrition_catalog_port.dart';
import 'package:food_tracker/core/services/platform/home_widget_service.dart';
import 'food_entry.model.dart';

/// State management controller for the Food Entry vertical slice (< 300 LoC budget).
class FoodEntryController extends ChangeNotifier {
  static FoodEntryController instance = FoodEntryController();

  final IDatabasePort? _dbPort;
  final IAiVisionPort? _aiVision;
  final INutritionCatalogPort? _nutrition;
  final IMealDao _mealDao;
  final IDishwareDao _dishwareDao;
  final IMealTemplateDao _templateDao;

  FoodEntryState _state = FoodEntryState.initial;

  FoodEntryController({
    IDatabasePort? databasePort,
    IAiVisionPort? aiVisionPort,
    INutritionCatalogPort? nutritionCatalogPort,
    IMealDao? mealDao,
    IDishwareDao? dishwareDao,
    IMealTemplateDao? mealTemplateDao,
  })  : _dbPort = databasePort ?? (getIt.isRegistered<IDatabasePort>() ? getIt<IDatabasePort>() : null),
        _aiVision = aiVisionPort ?? (getIt.isRegistered<IAiVisionPort>() ? getIt<IAiVisionPort>() : null),
        _nutrition = nutritionCatalogPort ??
            (getIt.isRegistered<INutritionCatalogPort>() ? getIt<INutritionCatalogPort>() : null),
        _mealDao = mealDao ??
            (databasePort?.mealDao ??
                (getIt.isRegistered<IMealDao>() ? getIt<IMealDao>() : DatabaseService.instance.mealDao)),
        _dishwareDao = dishwareDao ??
            (databasePort?.dishwareDao ??
                (getIt.isRegistered<IDishwareDao>()
                    ? getIt<IDishwareDao>()
                    : DatabaseService.instance.dishwareDao)),
        _templateDao = mealTemplateDao ??
            (databasePort?.mealTemplateDao ??
                (getIt.isRegistered<IMealTemplateDao>()
                    ? getIt<IMealTemplateDao>()
                    : DatabaseService.instance.mealTemplateDao));

  @visibleForTesting
  static void setMockInstance(FoodEntryController mock) => instance = mock;

  @visibleForTesting
  static void resetInstance() => instance = FoodEntryController();

  FoodEntryState get state => _state;
  DateTime get selectedDate => _state.selectedDate;
  List<Meal> get meals => _state.meals;
  bool get isLoading => _state.isLoading;
  bool get isAnalyzing => _state.isAnalyzing;
  List<CalibratedDishware> get dishwareList => _state.dishwareList;
  CalibratedDishware? get defaultDishware => _state.defaultDishware;
  List<MealTemplate> get templates => _state.templates;
  IDatabasePort? get dbPort => _dbPort;
  double get totalCalories => _state.totalCalories;
  double get totalProtein => _state.totalProtein;
  double get totalCarbs => _state.totalCarbs;
  double get totalFat => _state.totalFat;
  double get totalFiber => _state.totalFiber;
  double get totalSodium => _state.totalSodium;
  double get totalSugar => _state.totalSugar;
  Map<String, List<Meal>> get mealsByType => _state.mealsByType;

  Future<void> init({DateTime? date}) async {
    final target = date ?? DateTime.now();
    _state = _state.copyWith(selectedDate: DateTime(target.year, target.month, target.day));
    await Future.wait([loadMeals(), loadDishware(), loadTemplates()]);
  }

  Future<void> setSelectedDate(DateTime date) async {
    _state = _state.copyWith(selectedDate: DateTime(date.year, date.month, date.day));
    notifyListeners();
    await loadMeals();
  }

  Future<void> goToPreviousDay() => setSelectedDate(_state.selectedDate.subtract(const Duration(days: 1)));
  Future<void> goToNextDay() => setSelectedDate(_state.selectedDate.add(const Duration(days: 1)));
  Future<void> goToToday() => setSelectedDate(DateTime.now());

  Future<void> loadMeals({DateTime? date}) async {
    final targetDate = date ?? _state.selectedDate;
    _state = _state.copyWith(status: FoodEntryStatus.loading);
    notifyListeners();
    try {
      final loaded = await _mealDao.getMealsForDay(targetDate);
      _state = _state.copyWith(status: FoodEntryStatus.idle, meals: loaded, errorMessage: null);
    } catch (e) {
      _state = _state.copyWith(status: FoodEntryStatus.error, meals: const [], errorMessage: e.toString());
    } finally {
      notifyListeners();
      await syncNativeWidgets();
    }
  }

  Future<void> saveMeal(Meal meal) async { await _mealDao.insertMeal(meal); await loadMeals(); }
  Future<void> addMeal(Meal meal) => saveMeal(meal);
  Future<void> upsertMeal(Meal meal) async { await _mealDao.upsertMeal(meal); await loadMeals(); }
  Future<void> updateMeal(Meal meal) async { await _mealDao.updateMeal(meal); await loadMeals(); }
  Future<void> deleteMeal(Meal meal) async { await _mealDao.deleteMeal(meal.id); await loadMeals(); }

  Future<MealAnalysisResult?> analyzeMealPhoto(
    Uint8List imageBytes, {
    String? notes,
    double? dishwareDiameterCm,
    String? pantryContext,
  }) async {
    if (_aiVision == null) {
      _state = _state.copyWith(status: FoodEntryStatus.error, errorMessage: 'AI Vision not available');
      notifyListeners();
      return null;
    }
    _state = _state.copyWith(status: FoodEntryStatus.analyzing, analysisProgress: 0.2);
    notifyListeners();
    try {
      final diameter = dishwareDiameterCm ?? _state.defaultDishware?.diameterCm;
      final result = await _aiVision.analyzeMealPhoto(
        rawImageBytes: imageBytes,
        userContext: notes,
        dishwareDiameterCm: diameter,
        pantryContext: pantryContext,
      );
      _state = _state.copyWith(status: FoodEntryStatus.success, lastAnalysis: result, analysisProgress: 1.0);
      notifyListeners();
      return result;
    } catch (e) {
      final msg = _aiVision.formatUserFriendlyError(e);
      _state = _state.copyWith(status: FoodEntryStatus.error, errorMessage: msg);
      notifyListeners();
      return null;
    }
  }

  Future<MealAnalysisResult?> reanalyzeMealPhoto({
    required Uint8List rawImageBytes,
    required List<FoodItem> currentItems,
    required String oldIngredient,
    required String newIngredient,
    String? userNotes,
    double? dishwareDiameterCm,
  }) async {
    if (_aiVision == null) return null;
    _state = _state.copyWith(status: FoodEntryStatus.analyzing);
    notifyListeners();
    try {
      final res = await _aiVision.reanalyzeWithIngredientSubstitution(
        rawImageBytes: rawImageBytes, currentItems: currentItems,
        oldIngredient: oldIngredient, newIngredient: newIngredient,
        userNotes: userNotes, dishwareDiameterCm: dishwareDiameterCm ?? _state.defaultDishware?.diameterCm,
      );
      _state = _state.copyWith(status: FoodEntryStatus.success, lastAnalysis: res);
      notifyListeners();
      return res;
    } catch (e) {
      _state = _state.copyWith(status: FoodEntryStatus.error, errorMessage: e.toString());
      notifyListeners();
      return null;
    }
  }

  Future<BarcodeLookupResult?> lookupBarcode(String barcode) async => _nutrition?.lookupBarcode(barcode);
  Future<List<UsdaFoodItem>> searchUsdaFoods(String query) async => _nutrition?.searchUsdaFoods(query) ?? Future.value(const []);

  Future<void> loadDishware() async {
    try {
      final list = await _dishwareDao.getAllDishware();
      final def = await _dishwareDao.getDefaultDishware();
      _state = _state.copyWith(dishwareList: list, defaultDishware: def);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> saveDishware(CalibratedDishware dishware) async {
    final existing = await _dishwareDao.getDishwareById(dishware.id);
    if (existing == null) {
      await _dishwareDao.insertDishware(dishware);
    } else {
      await _dishwareDao.updateDishware(dishware);
    }
    if (dishware.isDefault) await _dishwareDao.setDefaultDishware(dishware.id);
    await loadDishware();
  }

  Future<void> deleteDishware(String id) async { await _dishwareDao.deleteDishware(id); await loadDishware(); }
  Future<void> setDefaultDishware(String id) async { await _dishwareDao.setDefaultDishware(id); await loadDishware(); }

  Future<void> loadTemplates({String? mealType}) async {
    try {
      final list = mealType != null ? await _templateDao.getTemplatesByMealType(mealType) : await _templateDao.getAllTemplates();
      _state = _state.copyWith(templates: list);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> saveTemplate(MealTemplate template) async {
    final existing = await _templateDao.getTemplateById(template.id);
    if (existing == null) {
      await _templateDao.insertTemplate(template);
    } else {
      await _templateDao.updateTemplate(template);
    }
    await loadTemplates();
  }

  Future<void> deleteTemplate(String id) async { await _templateDao.deleteTemplate(id); await loadTemplates(); }

  FoodItem scaleItemPortion(FoodItem item, double newGrams) => FoodNutritionCalculator.scaleItemPortion(item, newGrams);

  Future<void> syncNativeWidgets() async {
    try {
      final now = DateTime.now();
      final isToday = _state.selectedDate.year == now.year &&
          _state.selectedDate.month == now.month &&
          _state.selectedDate.day == now.day;
      final todayMeals = isToday ? _state.meals : await _mealDao.getMealsForDay(now);
      double cal = 0, p = 0, c = 0, f = 0;
      for (final m in todayMeals) { cal += m.calories; p += m.protein; c += m.carbs; f += m.fat; }
      await HomeWidgetService.instance.updateFromDailyTotals(
        consumedCalories: cal, targetCalories: 2000.0,
        consumedProtein: p, targetProtein: 150.0,
        consumedCarbs: c, targetCarbs: 200.0,
        consumedFat: f, targetFat: 65.0,
        streakCount: 0,
      );
    } catch (_) {}
  }
}
