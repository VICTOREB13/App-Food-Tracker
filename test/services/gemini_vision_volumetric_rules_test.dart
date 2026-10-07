import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/meal_analysis_result.dart';

void main() {
  group('Gemini Vision Volumetric Rules and Safeguards Tests', () {
    test('MealAnalysisResult desglosa componentes individuales si la IA devuelve items vacíos', () {
      const jsonWithoutItems = '''
      {
        "plato": "Arroz blanco con pollo asado y aguacate",
        "items": [],
        "totales": {
          "calorias": 585.0,
          "proteina_g": 38.0,
          "carbohidratos_g": 62.0,
          "grasas_g": 19.0
        }
      }
      ''';

      final result = MealAnalysisResult.fromJsonString(jsonWithoutItems);
      expect(result.dishName, equals('Arroz blanco con pollo asado y aguacate'));
      expect(result.items.isNotEmpty, isTrue);
      expect(result.items.length, equals(3));
      expect(result.items.any((e) => e.name.contains('Arroz')), isTrue);
      expect(result.items.any((e) => e.name.contains('pollo asado')), isTrue);
      expect(result.items.any((e) => e.name.contains('aguacate')), isTrue);
      expect(result.totalCalories, equals(585.0));
    });

    test('MealAnalysisResult genera item de respaldo cuando el plato es simple y no contiene separadores', () {
      const jsonSimpleDish = '''
      {
        "plato": "Sopa de res",
        "items": [],
        "totales": {
          "calorias": 320.0,
          "proteina_g": 24.0,
          "carbohidratos_g": 18.0,
          "grasas_g": 12.0
        }
      }
      ''';

      final result = MealAnalysisResult.fromJsonString(jsonSimpleDish);
      expect(result.dishName, equals('Sopa de res'));
      expect(result.items.length, equals(1));
      expect(result.items.first.name, equals('Sopa de res'));
      expect(result.items.first.estimatedGrams, isNot(equals(200.0)));
    });

    test('MealAnalysisResult desglosa ingrediente único que contiene lista agrupada', () {
      const jsonScreenshotCase = '''
      {
        "plato": "Arroz blanco, frijoles negros y carne molida",
        "items": [
          {
            "alimento": "Arroz blanco, frijoles negros y carne molida",
            "gramos_estimados": 200,
            "calorias": 758,
            "proteinas_g": 32,
            "carbohidratos_g": 79,
            "grasas_g": 36
          }
        ],
        "totales": {
          "calorias": 758,
          "proteina_g": 32,
          "carbohidratos_g": 79,
          "grasas_g": 36
        }
      }
      ''';

      final result = MealAnalysisResult.fromJsonString(jsonScreenshotCase);
      expect(result.dishName, equals('Arroz blanco, frijoles negros y carne molida'));
      expect(result.items.length, equals(3));
      for (final item in result.items) {
        expect(item.estimatedGrams, isNot(equals(200.0)));
      }
      expect(result.items.any((e) => e.name.toLowerCase().contains('arroz')), isTrue);
      expect(result.items.any((e) => e.name.toLowerCase().contains('frijol')), isTrue);
      expect(result.items.any((e) => e.name.toLowerCase().contains('carne')), isTrue);
    });

    test('MealAnalysisResult deserializa múltiples ingredientes individuales sin 200g genérico', () {
      const detailedMealJson = '''
      {
        "plato": "Arroz blanco con frijoles negros, carne molida y aguacate",
        "items": [
          {
            "alimento": "Arroz blanco cocido",
            "gramos_estimados": 160,
            "calorias": 208,
            "proteinas_g": 4.0,
            "carbohidratos_g": 45.0,
            "grasas_g": 0.5,
            "justificacion_visual": "Porción aproximada de 1 taza"
          },
          {
            "alimento": "Frijoles negros guisados",
            "gramos_estimados": 130,
            "calorias": 170,
            "proteinas_g": 10.5,
            "carbohidratos_g": 26.0,
            "grasas_g": 3.0,
            "justificacion_visual": "Porción lateral con caldo"
          },
          {
            "alimento": "Carne molida guisada",
            "gramos_estimados": 125,
            "calorias": 240,
            "proteinas_g": 24.0,
            "carbohidratos_g": 2.0,
            "grasas_g": 15.0,
            "justificacion_visual": "Carne sazonada en el centro"
          },
          {
            "alimento": "Aguacate fresco en tajadas",
            "gramos_estimados": 70,
            "calorias": 112,
            "proteinas_g": 1.4,
            "carbohidratos_g": 6.0,
            "grasas_g": 10.0,
            "justificacion_visual": "Dos tajadas visibles"
          }
        ],
        "totales": {
          "calorias": 730,
          "proteina_g": 39.9,
          "carbohidratos_g": 79.0,
          "grasas_g": 28.5
        }
      }
      ''';

      final result = MealAnalysisResult.fromJsonString(detailedMealJson);
      expect(result.dishName, equals('Arroz blanco con frijoles negros, carne molida y aguacate'));
      expect(result.items.length, equals(4));

      for (final item in result.items) {
        expect(item.estimatedGrams, isNot(equals(200.0)));
        expect(item.calories, greaterThan(0));
      }
      expect(result.items[0].estimatedGrams, equals(160.0));
      expect(result.items[1].estimatedGrams, equals(130.0));
      expect(result.items[2].estimatedGrams, equals(125.0));
      expect(result.items[3].estimatedGrams, equals(70.0));
    });

    test('MealAnalysisResult repara JSON truncado por corte de tokens de Gemini', () {
      const truncatedJson = '''
      {
        "plato": "Pollo al Horno con Romero",
        "items": [
          {
            "alimento": "Pechuga de pollo",
            "gramos_estimados": 150,
            "calorias": 240,
            "proteinas_g": 40.0,
            "carbohidratos_g": 0.0,
            "grasas_g": 5.0
          },
          {
            "alimento": "Papas rústicas",
            "gramos_estimados": 120,
            "calorias": 110
      ''';

      final result = MealAnalysisResult.fromJsonString(truncatedJson);
      expect(result.dishName, equals('Pollo al Horno con Romero'));
      expect(result.items.isNotEmpty, isTrue);
      expect(result.items.first.name, equals('Pechuga de pollo'));
    });

    test('MealAnalysisResult protege hierbas y condimentos de absorber macros mayores', () {
      final items = MealAnalysisResult.decomposeCompositeFood(
        ['Pechuga de pollo', 'Romero fresco'],
        300.0,
        40.0,
        0.0,
        10.0,
      );

      expect(items.length, equals(2));
      final pollo = items.firstWhere((i) => i.name.toLowerCase().contains('pollo'));
      final romero = items.firstWhere((i) => i.name.toLowerCase().contains('romero'));

      expect(pollo.calories, greaterThan(250.0));
      expect(pollo.protein, greaterThan(35.0));
      expect(romero.calories, lessThan(15.0));
      expect(romero.protein, lessThan(2.0));
      expect(romero.estimatedGrams, lessThanOrEqualTo(15.0));
    });

    test('MealAnalysisResult no confunde salmón o salchichas con condimentos', () {
      final items = MealAnalysisResult.decomposeCompositeFood(
        ['Filete de salmón a la plancha', 'Arroz blanco', 'Romero fresco'],
        500.0,
        45.0,
        50.0,
        15.0,
      );

      final salmon = items.firstWhere((i) => i.name.contains('salmón'));
      expect(salmon.calories, greaterThan(100.0));
      expect(salmon.protein, greaterThan(20.0));
      expect(salmon.estimatedGrams, greaterThan(50.0));
    });

    test('MealAnalysisResult repara JSON cortado a mitad de clave y con escape colgante', () {
      const truncatedMidKey = '{"plato": "Pollo al Curry", "items": [{"alimento": "Pechuga", "calor';
      final result1 = MealAnalysisResult.fromJsonString(truncatedMidKey);
      expect(result1.dishName, equals('Pollo al Curry'));
      expect(result1.items.length, equals(1));

      const truncatedEscape = '{"plato": "Pollo al Romero con \\';
      final result2 = MealAnalysisResult.fromJsonString(truncatedEscape);
      expect(result2.dishName, contains('Pollo al Romero'));
    });
  });
}
