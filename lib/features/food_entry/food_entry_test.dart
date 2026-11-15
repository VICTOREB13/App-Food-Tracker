import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/core/errors/failures.dart';
import 'package:food_tracker/core/errors/result.dart';
import 'package:food_tracker/core/interfaces/daos_interfaces.dart';
import 'package:food_tracker/core/interfaces/dishware_dao_interface.dart';
import 'package:food_tracker/core/interfaces/meal_template_dao_interface.dart';
import 'package:food_tracker/core/ports/ai_vision_port.dart';
import 'package:food_tracker/core/ports/nutrition_catalog_port.dart';
import 'package:food_tracker/features/pantry_inventory/models/pantry_item.dart';
import 'package:food_tracker/core/models/usda_food_item.dart';
import 'food_entry.dart';

class _FakeMealDao implements IMealDao {
  final List<Meal> _meals = [];

  @override Future<int> insertMeal(Meal m) async { _meals.add(m); return 1; }
  @override Future<int> upsertMeal(Meal m) async {
    _meals.removeWhere((e) => e.id == m.id);
    _meals.add(m);
    return 1;
  }
  @override Future<int> updateMeal(Meal m) async {
    final idx = _meals.indexWhere((e) => e.id == m.id);
    if (idx != -1) _meals[idx] = m;
    return 1;
  }
  @override Future<int> deleteMeal(String id) async { _meals.removeWhere((e) => e.id == id); return 1; }
  @override Future<Meal?> getMealById(String id) async => _meals.where((e) => e.id == id).firstOrNull;
  @override Future<List<Meal>> getMealsForDay(DateTime day) async => List.unmodifiable(_meals);
  @override Future<List<Meal>> getAllMeals() async => List.unmodifiable(_meals);
  @override Future<List<Meal>> getMealsByRange(DateTime s, DateTime e) async => List.unmodifiable(_meals);
  @override Future<Meal?> getMealByImagePath(String p) async => null;
  @override Future<List<String>> getDistinctMealDates() async => ['2026-11-15'];
  @override Future<int> clearMealImagePath(String id) async => 1;
  @override Future<List<Meal>> getMealsOlderThanWithImages(DateTime cutoff) async => [];
  @override Future<Result<int, DatabaseFailure>> upsertMealResult(Meal m) async => const Result.ok(1);
  @override Future<Result<Meal?, DatabaseFailure>> getMealByIdResult(String id) async => Result.ok(null);
  @override Future<Result<List<Meal>, DatabaseFailure>> getMealsForDayResult(DateTime d) async => Result.ok(_meals);
  @override Future<Result<List<Meal>, DatabaseFailure>> getMealsByRangeResult(DateTime s, DateTime e) async => Result.ok(_meals);
}

class _FakeDishwareDao implements IDishwareDao {
  final List<CalibratedDishware> _items = [];
  String? _defaultId;

  @override Future<int> insertDishware(CalibratedDishware d) async { _items.add(d); return 1; }
  @override Future<int> updateDishware(CalibratedDishware d) async {
    final idx = _items.indexWhere((e) => e.id == d.id);
    if (idx != -1) _items[idx] = d;
    return 1;
  }
  @override Future<int> deleteDishware(String id) async { _items.removeWhere((e) => e.id == id); return 1; }
  @override Future<CalibratedDishware?> getDishwareById(String id) async => _items.where((e) => e.id == id).firstOrNull;
  @override Future<List<CalibratedDishware>> getAllDishware() async => List.unmodifiable(_items);
  @override Future<CalibratedDishware?> getDefaultDishware() async => _items.where((e) => e.id == _defaultId).firstOrNull;
  @override Future<void> setDefaultDishware(String id) async { _defaultId = id; }
  @override Future<Result<int, DatabaseFailure>> insertDishwareResult(CalibratedDishware d) async => const Result.ok(1);
  @override Future<Result<List<CalibratedDishware>, DatabaseFailure>> getAllDishwareResult() async => Result.ok(_items);
  @override Future<Result<CalibratedDishware?, DatabaseFailure>> getDefaultDishwareResult() async => Result.ok(null);
}

class _FakeMealTemplateDao implements IMealTemplateDao {
  final List<MealTemplate> _templates = [];

  @override Future<int> insertTemplate(MealTemplate t) async { _templates.add(t); return 1; }
  @override Future<int> updateTemplate(MealTemplate t) async {
    final idx = _templates.indexWhere((e) => e.id == t.id);
    if (idx != -1) _templates[idx] = t;
    return 1;
  }
  @override Future<int> deleteTemplate(String id) async { _templates.removeWhere((e) => e.id == id); return 1; }
  @override Future<MealTemplate?> getTemplateById(String id) async => _templates.where((e) => e.id == id).firstOrNull;
  @override Future<List<MealTemplate>> getAllTemplates() async => List.unmodifiable(_templates);
  @override Future<List<MealTemplate>> getTemplatesByMealType(String type) async =>
      _templates.where((e) => e.mealType == type).toList();
  @override Future<Result<int, DatabaseFailure>> insertTemplateResult(MealTemplate t) async => const Result.ok(1);
  @override Future<Result<List<MealTemplate>, DatabaseFailure>> getAllTemplatesResult() async => Result.ok(_templates);
  @override Future<Result<List<MealTemplate>, DatabaseFailure>> getTemplatesByMealTypeResult(String t) async => Result.ok(_templates);
}

void main() {
  group('FoodEntryState Sentinel Defaults & Mutations', () {
    test('initial state has sentinel defaults', () {
      final state = FoodEntryState.initial;
      expect(state.status, equals(FoodEntryStatus.idle));
      expect(state.meals, isEmpty);
      expect(state.dishwareList, isEmpty);
      expect(state.templates, isEmpty);
      expect(state.activeMeal, isNull);
      expect(state.defaultDishware, isNull);
      expect(state.lastAnalysis, isNull);
      expect(state.analysisProgress, isNull);
      expect(state.errorMessage, isNull);
      expect(state.isIdle, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isAnalyzing, isFalse);
      expect(state.isSaving, isFalse);
      expect(state.hasError, isFalse);
      expect(state.totalCalories, equals(0.0));
    });

    test('copyWith updates state or clears nullable fields via sentinel', () {
      final state = FoodEntryState.initial.copyWith(
        status: FoodEntryStatus.saving,
        errorMessage: 'Database locked',
      );
      expect(state.status, equals(FoodEntryStatus.saving));
      expect(state.errorMessage, equals('Database locked'));
      expect(state.hasError, isTrue);

      final cleared = state.copyWith(errorMessage: null);
      expect(cleared.errorMessage, isNull);
      expect(cleared.status, equals(FoodEntryStatus.saving));
    });

    test('mealsByType organizes meals correctly into canonical slots', () {
      final meals = [
        Meal(id: '1', name: 'Huevos', calories: 250, mealType: 'Desayuno', date: DateTime(2026, 11, 15)),
        Meal(id: '2', name: 'Pollo', calories: 500, mealType: 'Almuerzo', date: DateTime(2026, 11, 15)),
        Meal(id: '3', name: 'Pescado', calories: 350, mealType: 'Cena', date: DateTime(2026, 11, 15)),
        Meal(id: '4', name: 'Manzana', calories: 80, mealType: 'Snack', date: DateTime(2026, 11, 15)),
        Meal(id: '5', name: 'Batido', calories: 180, mealType: 'Merienda', date: DateTime(2026, 11, 15)),
      ];
      final state = FoodEntryState.initial.copyWith(meals: meals);
      final byType = state.mealsByType;
      expect(byType['Desayuno']!.length, equals(1));
      expect(byType['Almuerzo']!.length, equals(1));
      expect(byType['Cena']!.length, equals(1));
      expect(byType['Snack']!.length, equals(2)); // Merienda falls into Snack
      expect(state.totalCalories, equals(1360.0));
    });
  });

  group('FoodNutritionCalculator Macros & Portion Scaling', () {
    test('calculateNutrientTotals aggregates all items accurately', () {
      final items = [
        FoodItem(name: 'Avena', estimatedGrams: 80, calories: 300, protein: 10, carbs: 54, fat: 5, fiber: 8, sodium: 5, sugar: 1),
        FoodItem(name: 'Leche', estimatedGrams: 200, calories: 120, protein: 8, carbs: 10, fat: 4, fiber: 0, sodium: 100, sugar: 9),
      ];
      final totals = FoodNutritionCalculator.calculateNutrientTotals(items);
      expect(totals['calories'], equals(420.0));
      expect(totals['protein'], equals(18.0));
      expect(totals['carbs'], equals(64.0));
      expect(totals['fat'], equals(9.0));
      expect(totals['fiber'], equals(8.0));
      expect(totals['sodium'], equals(105.0));
      expect(totals['sugar'], equals(10.0));
    });

    test('scaleItemPortion scales linearly by target gram weight', () {
      final item = FoodItem(
        name: 'Arroz',
        estimatedGrams: 100,
        calories: 130,
        protein: 2.7,
        carbs: 28.0,
        fat: 0.3,
        fiber: 0.4,
        sodium: 1.0,
        sugar: 0.1,
      );
      final scaled = FoodNutritionCalculator.scaleItemPortion(item, 250);
      expect(scaled.estimatedGrams, equals(250.0));
      expect(scaled.calories, closeTo(325.0, 0.01));
      expect(scaled.protein, closeTo(6.75, 0.01));
      expect(scaled.carbs, closeTo(70.0, 0.01));
      expect(scaled.fat, closeTo(0.75, 0.01));
    });

    test('calculateMacroPercentage computes caloric distribution', () {
      // 25g protein = 100 kcal. Total = 400 kcal -> 25.0%
      final proteinPct = FoodNutritionCalculator.calculateMacroPercentage(25, 400, isFat: false);
      expect(proteinPct, closeTo(25.0, 0.1));

      // 10g fat = 90 kcal. Total = 450 kcal -> 20.0%
      final fatPct = FoodNutritionCalculator.calculateMacroPercentage(10, 450, isFat: true);
      expect(fatPct, closeTo(20.0, 0.1));
    });
  });

  group('FoodEntryController Lifecycle & DAOs', () {
    late _FakeMealDao fakeMealDao;
    late _FakeDishwareDao fakeDishwareDao;
    late _FakeMealTemplateDao fakeTemplateDao;
    late FoodEntryController controller;

    setUp(() {
      fakeMealDao = _FakeMealDao();
      fakeDishwareDao = _FakeDishwareDao();
      fakeTemplateDao = _FakeMealTemplateDao();
      controller = FoodEntryController(
        mealDao: fakeMealDao,
        dishwareDao: fakeDishwareDao,
        mealTemplateDao: fakeTemplateDao,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('saveMeal and deleteMeal mutate state correctly', () async {
      final meal = Meal(id: 'm1', name: 'Salmón', calories: 400, mealType: 'Cena', date: DateTime.now());
      await controller.saveMeal(meal);
      expect(controller.meals.length, equals(1));
      expect(controller.totalCalories, equals(400.0));

      await controller.deleteMeal(meal);
      expect(controller.meals, isEmpty);
      expect(controller.totalCalories, equals(0.0));
    });

    test('calibrated dishware persistence and default reference', () async {
      final dish = CalibratedDishware(id: 'd1', name: 'Plato Hondo', diameterCm: 24.0, depthCm: 4.5, isDefault: true);
      await controller.saveDishware(dish);
      expect(controller.dishwareList.length, equals(1));
      expect(controller.defaultDishware?.id, equals('d1'));
      expect(controller.defaultDishware?.diameterCm, equals(24.0));
    });

    test('scaleItemPortion delegates to domain calculator', () {
      final item = FoodItem(name: 'Pan', estimatedGrams: 50, calories: 130);
      final scaled = controller.scaleItemPortion(item, 100);
      expect(scaled.estimatedGrams, equals(100.0));
      expect(scaled.calories, closeTo(260.0, 0.01));
    });
  });
}
