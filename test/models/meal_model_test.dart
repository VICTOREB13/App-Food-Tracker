import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/controllers/meal_controller.dart';
import 'package:food_tracker/models/food_item.dart';
import 'package:food_tracker/models/meal.dart';

void main() {
  group('Meal Model Tests', () {
    test('toSqliteMap y fromSqliteMap preservan todos los campos fielmente', () {
      final now = DateTime(2026, 9, 6, 14, 30);
      final meal = Meal(
        id: 'test-meal-uuid-1',
        name: 'Arroz con Pollo y Ensalada',
        mealType: 'Almuerzo',
        date: now,
        imagePath: '/data/user/0/com.victorengineer.foodtracker/meals/meal_1.jpg',
        calories: 650.5,
        protein: 42.0,
        carbs: 75.2,
        fat: 18.5,
        notes: 'Pechuga a la plancha, arroz blanco y ensalada mixta',
        aiBreakdownJson: json.encode({
          'plato': 'Arroz con Pollo',
          'items': [],
          'totales': {'calorias': 650.5, 'proteina_g': 42.0, 'carbohidratos_g': 75.2, 'grasas_g': 18.5}
        }),
      );

      final map = meal.toSqliteMap();
      expect(map['id'], equals('test-meal-uuid-1'));
      expect(map['name'], equals('Arroz con Pollo y Ensalada'));
      expect(map['meal_type'], equals('Almuerzo'));
      expect(map['date'], equals(now.toIso8601String()));
      expect(map['calories'], equals(650.5));
      expect(map['protein'], equals(42.0));
      expect(map['carbs'], equals(75.2));
      expect(map['fat'], equals(18.5));

      final restored = Meal.fromSqliteMap(map);
      expect(restored.id, equals(meal.id));
      expect(restored.name, equals(meal.name));
      expect(restored.mealType, equals(meal.mealType));
      expect(restored.date, equals(meal.date));
      expect(restored.imagePath, equals(meal.imagePath));
      expect(restored.calories, equals(meal.calories));
      expect(restored.protein, equals(meal.protein));
      expect(restored.carbs, equals(meal.carbs));
      expect(restored.fat, equals(meal.fat));
      expect(restored.notes, equals(meal.notes));
      expect(restored.aiBreakdownJson, equals(meal.aiBreakdownJson));
    });

    test('Límites defensivos se aplican a entradas desmedidas', () {
      final superLongName = 'A' * 400;
      final superLongNotes = 'B' * 3000;
      final superLongPath = 'C' * 2000;

      final meal = Meal(
        name: superLongName,
        notes: superLongNotes,
        imagePath: superLongPath,
        calories: -50.0,
        protein: 15000.0,
        carbs: -10.0,
        fat: 999999.0,
      );

      expect(meal.name.length, equals(255));
      expect(meal.notes!.length, equals(2000));
      expect(meal.imagePath!.length, equals(1024));
      expect(meal.calories, equals(0.0));
      expect(meal.protein, equals(9999.0));
      expect(meal.carbs, equals(0.0));
      expect(meal.fat, equals(9999.0));
    });

    test('copyWith con patrón Sentinel elimina campos al pasar null explícito', () {
      final meal = Meal(
        id: 'uuid-101',
        name: 'Cena Liviana',
        imagePath: '/path/to/img.jpg',
        notes: 'Sin aderezos',
        aiBreakdownJson: '{"test": true}',
      );

      // Borrar notas e imagen pasando null explícito
      final cleared = meal.copyWith(
        imagePath: null,
        notes: null,
        aiBreakdownJson: null,
      );

      expect(cleared.imagePath, isNull);
      expect(cleared.notes, isNull);
      expect(cleared.aiBreakdownJson, isNull);
      expect(cleared.name, equals('Cena Liviana'));

      // Modificar solo el nombre conservando imagen y notas
      final renamed = meal.copyWith(name: 'Cena Fuerte');
      expect(renamed.name, equals('Cena Fuerte'));
      expect(renamed.imagePath, equals('/path/to/img.jpg'));
      expect(renamed.notes, equals('Sin aderezos'));
    });

    test('recalculateFromItems recalcula totales y actualiza aiBreakdownJson', () {
      final meal = Meal(name: 'Bandeja');
      final items = [
        FoodItem(name: 'Arroz blanco', estimatedGrams: 150, calories: 195, protein: 4.0, carbs: 42.0, fat: 0.5),
        FoodItem(name: 'Pechuga asada', estimatedGrams: 120, calories: 198, protein: 37.0, carbs: 0.0, fat: 4.5),
        FoodItem(name: 'Aceite sofrito', estimatedGrams: 10, calories: 90, protein: 0.0, carbs: 0.0, fat: 10.0),
      ];

      final updated = meal.recalculateFromItems(items);
      expect(updated.calories, equals(483.0));
      expect(updated.protein, equals(41.0));
      expect(updated.carbs, equals(42.0));
      expect(updated.fat, equals(15.0));
      expect(updated.items.length, equals(3));
      expect(updated.items.first.name, equals('Arroz blanco'));
    });

    test('recalculateFromItems con lista vacía conserva macros existentes y no los resetea a cero', () {
      final meal = Meal(name: 'Comida rápida', calories: 450, protein: 20, carbs: 50, fat: 12);
      final updated = meal.recalculateFromItems([]);
      expect(updated.calories, equals(450.0));
      expect(updated.protein, equals(20.0));
      expect(updated.carbs, equals(50.0));
      expect(updated.fat, equals(12.0));
    });

    test('Meal constructor con items inicializa aiBreakdownJson y expone items correctamente', () {
      final items = [
        FoodItem(name: 'Huevos revueltos', estimatedGrams: 100, calories: 150, protein: 12.0, carbs: 1.0, fat: 10.0),
        FoodItem(name: 'Pan tostado', estimatedGrams: 50, calories: 130, protein: 4.0, carbs: 24.0, fat: 1.5),
      ];
      final meal = Meal(
        name: 'Desayuno Proteico',
        items: items,
        calories: 280,
        protein: 16.0,
        carbs: 25.0,
        fat: 11.5,
      );
      expect(meal.items.length, equals(2));
      expect(meal.items[0].name, equals('Huevos revueltos'));
      expect(meal.items[1].name, equals('Pan tostado'));
      expect(meal.aiBreakdownJson, isNotNull);
    });

    test('copyWith pasando aiBreakdownJson null limpia items completamente sin resurrección', () {
      final items = [
        FoodItem(name: 'Ensalada César', estimatedGrams: 150, calories: 200, protein: 5.0, carbs: 10.0, fat: 12.0),
      ];
      final mealWithItems = Meal(name: 'Almuerzo', items: items);
      expect(mealWithItems.items.length, equals(1));

      final cleared = mealWithItems.copyWith(aiBreakdownJson: null);
      expect(cleared.items, isEmpty);
      expect(cleared.aiBreakdownJson, isNull);
    });

    test('recalculateFromItems no resetea calorias existentes si los items tienen 0 calorias', () {
      final meal = Meal(name: 'Almuerzo Proteico', calories: 500, protein: 40, carbs: 50, fat: 15);
      final itemsWithZeroMacros = [
        FoodItem(name: 'Arroz blanco', estimatedGrams: 150, calories: 0, protein: 0, carbs: 0, fat: 0),
        FoodItem(name: 'Pollo', estimatedGrams: 120, calories: 0, protein: 0, carbs: 0, fat: 0),
      ];

      final updated = meal.recalculateFromItems(itemsWithZeroMacros);
      expect(updated.calories, equals(500.0));
      expect(updated.protein, equals(40.0));
      expect(updated.carbs, equals(50.0));
      expect(updated.fat, equals(15.0));
      expect(updated.items.length, equals(2));
    });

    test('Meal.items parsea fielmente listas de strings y objetos map en aiBreakdownJson', () {
      final mealWithStringList = Meal(
        name: 'Comida simple',
        aiBreakdownJson: '{"items": ["Arroz", "Lentejas"]}',
      );
      expect(mealWithStringList.items.length, equals(2));
      expect(mealWithStringList.items[0].name, equals('Arroz'));
      expect(mealWithStringList.items[1].name, equals('Lentejas'));

      final mealWithMap = Meal(
        name: 'Comida map',
        aiBreakdownJson: '{"items": {"Pollo": {"calorias": 150}}}',
      );
      expect(mealWithMap.items.length, equals(1));
      expect(mealWithMap.items.first.name, equals('Pollo'));
    });
  });

  group('MealController calculateStreakFromDates Tests', () {
    final now = DateTime.now();
    String formatDate(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final todayStr = formatDate(now);
    final yesterdayStr = formatDate(now.subtract(const Duration(days: 1)));
    final dayBeforeYesterdayStr = formatDate(now.subtract(const Duration(days: 2)));
    final threeDaysAgoStr = formatDate(now.subtract(const Duration(days: 3)));
    final fourDaysAgoStr = formatDate(now.subtract(const Duration(days: 4)));

    test('returns 0 for empty dates list', () {
      expect(MealController.calculateStreakFromDates([]), equals(0));
    });

    test('returns 1 when only today has a meal', () {
      expect(MealController.calculateStreakFromDates([todayStr]), equals(1));
    });

    test('returns 1 when only yesterday has a meal (today not logged yet)', () {
      expect(MealController.calculateStreakFromDates([yesterdayStr]), equals(1));
    });

    test('returns 2 when today and yesterday have meals', () {
      expect(
        MealController.calculateStreakFromDates([todayStr, yesterdayStr]),
        equals(2),
      );
    });

    test('returns 4 for consecutive days ending today', () {
      expect(
        MealController.calculateStreakFromDates([
          todayStr,
          yesterdayStr,
          dayBeforeYesterdayStr,
          threeDaysAgoStr,
        ]),
        equals(4),
      );
    });

    test('returns 4 for consecutive days ending yesterday', () {
      expect(
        MealController.calculateStreakFromDates([
          yesterdayStr,
          dayBeforeYesterdayStr,
          threeDaysAgoStr,
          fourDaysAgoStr,
        ]),
        equals(4),
      );
    });

    test('returns 0 when streak was broken (neither today nor yesterday logged)', () {
      expect(
        MealController.calculateStreakFromDates([
          dayBeforeYesterdayStr,
          threeDaysAgoStr,
          fourDaysAgoStr,
        ]),
        equals(0),
      );
    });

    test('stops counting at the first gap in dates', () {
      expect(
        MealController.calculateStreakFromDates([
          todayStr,
          yesterdayStr,
          threeDaysAgoStr,
          fourDaysAgoStr,
        ]),
        equals(2),
      );
    });

    test('handles duplicate dates and unsorted input', () {
      expect(
        MealController.calculateStreakFromDates([
          yesterdayStr,
          todayStr,
          yesterdayStr,
          todayStr,
          dayBeforeYesterdayStr,
        ]),
        equals(3),
      );
    });
  });
}
