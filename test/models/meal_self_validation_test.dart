import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/food_item.dart';
import 'package:food_tracker/models/meal.dart';

void main() {
  group('Meal Self-Validation Metrics Tests', () {
    test('extracts confidencePercentage and calorieErrorMargin from aiBreakdownJson', () {
      final meal = Meal(
        name: 'Arepa Reina Pepiada',
        aiBreakdownJson: json.encode({
          'plato': 'Arepa Reina Pepiada',
          'porcentaje_certeza': 88,
          'margen_error_kcal': 55,
          'items': [
            {'alimento': 'Arepa', 'gramos_estimados': 120, 'calorias': 260, 'proteinas_g': 5, 'carbohidratos_g': 45, 'grasas_g': 2}
          ],
          'totales': {'calorias': 260, 'proteina_g': 5, 'carbohidratos_g': 45, 'grasas_g': 2}
        }),
      );

      expect(meal.confidencePercentage, equals(88));
      expect(meal.calorieErrorMargin, equals(55));
    });

    test('returns null when aiBreakdownJson is null or lacks metrics', () {
      final mealNoJson = Meal(name: 'Café solo');
      expect(mealNoJson.confidencePercentage, isNull);
      expect(mealNoJson.calorieErrorMargin, isNull);

      final mealEmptyJson = Meal(
        name: 'Café con leche',
        aiBreakdownJson: '{"plato": "Café", "items": []}',
      );
      expect(mealEmptyJson.confidencePercentage, isNull);
      expect(mealEmptyJson.calorieErrorMargin, isNull);
    });

    test('recalculateFromItems preserves confidencePercentage and calorieErrorMargin', () {
      final initialMeal = Meal(
        name: 'Tazón de Avena',
        aiBreakdownJson: json.encode({
          'plato': 'Tazón de Avena',
          'porcentaje_certeza': 94,
          'margen_error_kcal': 30,
          'items': [
            {'alimento': 'Avena en hojuelas', 'gramos_estimados': 50, 'calorias': 180, 'proteinas_g': 6, 'carbohidratos_g': 32, 'grasas_g': 3}
          ],
          'totales': {'calorias': 180, 'proteina_g': 6, 'carbohidratos_g': 32, 'grasas_g': 3}
        }),
      );

      expect(initialMeal.confidencePercentage, equals(94));
      expect(initialMeal.calorieErrorMargin, equals(30));

      final updatedItems = [
        FoodItem(name: 'Avena cocida', estimatedGrams: 150, calories: 150, protein: 5, carbs: 28, fat: 2),
        FoodItem(name: 'Plátano', estimatedGrams: 80, calories: 72, protein: 1, carbs: 18, fat: 0),
      ];

      final recalculated = initialMeal.recalculateFromItems(updatedItems);
      expect(recalculated.calories, equals(222.0));
      expect(recalculated.confidencePercentage, equals(94));
      expect(recalculated.calorieErrorMargin, equals(30));

      final decoded = json.decode(recalculated.aiBreakdownJson!);
      expect(decoded['porcentaje_certeza'], equals(94));
      expect(decoded['margen_error_kcal'], equals(30));
    });

    test('parses string numbers defensivamente in aiBreakdownJson', () {
      final meal = Meal(
        name: 'Plato Mixto',
        aiBreakdownJson: '{"porcentaje_certeza": "91", "margen_error_kcal": "±42"}',
      );
      expect(meal.confidencePercentage, equals(91));
      expect(meal.calorieErrorMargin, equals(42));
    });

    test('parses decimal strings accurately without digit concatenation', () {
      final meal = Meal(
        name: 'Plato Decimal',
        aiBreakdownJson: '{"porcentaje_certeza": "92.4%", "margen_error_kcal": "±45.5 kcal"}',
      );
      expect(meal.confidencePercentage, equals(92));
      expect(meal.calorieErrorMargin, equals(46));
    });

    test('extracts metrics and recalculateFromItems safely when aiBreakdownJson has markdown code fences', () {
      const fencedJson = '''
      ```json
      {
        "plato": "Pollo al Horno",
        "porcentaje_certeza": 89,
        "margen_error_kcal": 38,
        "items": [
          {"alimento": "Pechuga", "gramos_estimados": 150, "calorias": 240, "proteinas_g": 38, "carbohidratos_g": 0, "grasas_g": 5}
        ],
        "totales": {"calorias": 240, "proteina_g": 38, "carbohidratos_g": 0, "grasas_g": 5}
      }
      ```
      ''';

      final meal = Meal(name: 'Pollo al Horno', aiBreakdownJson: fencedJson);
      expect(meal.confidencePercentage, equals(89));
      expect(meal.calorieErrorMargin, equals(38));

      final updated = meal.recalculateFromItems([
        FoodItem(name: 'Pechuga', estimatedGrams: 200, calories: 320, protein: 50, carbs: 0, fat: 6),
      ]);
      expect(updated.confidencePercentage, equals(89));
      expect(updated.calorieErrorMargin, equals(38));
      final decoded = json.decode(updated.aiBreakdownJson!);
      expect(decoded['porcentaje_certeza'], equals(89));
      expect(decoded['margen_error_kcal'], equals(38));
    });
  });
}
