import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/features/food_entry/models/meal_analysis_result.dart';

void main() {
  group('MealAnalysisResult Unit Tests', () {
    test('Default constructor initializes isPartial to false', () {
      const result = MealAnalysisResult(
        dishName: 'Ensalada César',
        items: [],
        totalCalories: 250,
        totalProtein: 15,
        totalCarbs: 10,
        totalFat: 12,
        rawJson: '{}',
      );

      expect(result.isPartial, isFalse);
      expect(result.dishName, equals('Ensalada César'));
      expect(result.totalFiber, equals(0.0));
      expect(result.totalSodium, equals(0.0));
      expect(result.totalSugar, equals(0.0));
    });

    test('isPartial flag can be explicitly passed in constructor', () {
      const result = MealAnalysisResult(
        dishName: 'Desayuno Parcial',
        items: [],
        totalCalories: 300,
        totalProtein: 20,
        totalCarbs: 30,
        totalFat: 10,
        rawJson: '{}',
        isPartial: true,
      );

      expect(result.isPartial, isTrue);
    });

    test('fromJsonString calculates macro totals deterministically from items without relying on totales object', () {
      const jsonStr = '''
      {
        "plato": "Pechuga de Pollo con Arroz y Aguacate",
        "items": [
          {
            "alimento": "Pechuga de pollo a la plancha",
            "gramos_estimados": 150,
            "calorias": 247.5,
            "proteinas_g": 46.5,
            "carbohidratos_g": 0.0,
            "grasas_g": 5.4,
            "fibra_g": 0.0,
            "sodio_mg": 110.0,
            "azucar_g": 0.0,
            "justificacion_visual": "Porción de 150g"
          },
          {
            "alimento": "Arroz integral cocido",
            "gramos_estimados": 100,
            "calorias": 111.0,
            "proteinas_g": 2.6,
            "carbohidratos_g": 23.0,
            "grasas_g": 0.9,
            "fibra_g": 1.8,
            "sodio_mg": 5.0,
            "azucar_g": 0.4,
            "justificacion_visual": "Media taza"
          },
          {
            "alimento": "Aguacate fresco",
            "gramos_estimados": 50,
            "calorias": 80.0,
            "proteinas_g": 1.0,
            "carbohidratos_g": 4.3,
            "grasas_g": 7.3,
            "fibra_g": 3.4,
            "sodio_mg": 3.5,
            "azucar_g": 0.3,
            "justificacion_visual": "Un cuarto de aguacate"
          }
        ],
        "porcentaje_certeza": 92,
        "margen_error_kcal": 25
      }
      ''';

      final result = MealAnalysisResult.fromJsonString(jsonStr);

      expect(result.dishName, equals('Pechuga de Pollo con Arroz y Aguacate'));
      expect(result.items.length, equals(3));
      expect(result.isPartial, isFalse);

      // Deterministic sums:
      // Calories: 247.5 + 111.0 + 80.0 = 438.5
      expect(result.totalCalories, equals(438.5));
      // Protein: 46.5 + 2.6 + 1.0 = 50.1
      expect(result.totalProtein, equals(50.1));
      // Carbs: 0.0 + 23.0 + 4.3 = 27.3
      expect(result.totalCarbs, equals(27.3));
      // Fat: 5.4 + 0.9 + 7.3 = 13.6
      expect(result.totalFat, equals(13.6));
      // Fiber: 0.0 + 1.8 + 3.4 = 5.2
      expect(result.totalFiber, equals(5.2));
      // Sodium: 110.0 + 5.0 + 3.5 = 118.5
      expect(result.totalSodium, equals(118.5));
      // Sugar: 0.0 + 0.4 + 0.3 = 0.7
      expect(result.totalSugar, equals(0.7));

      expect(result.confidencePercentage, equals(92));
      expect(result.calorieErrorMargin, equals(25));
    });

    test('fromJsonString detects is_partial or isPartial boolean in JSON payload', () {
      const jsonWithSnakeCase = '''
      {
        "plato": "Plato Incompleto",
        "items": [
          {
            "alimento": "Manzana",
            "calorias": 95,
            "proteinas_g": 0.5,
            "carbohidratos_g": 25,
            "grasas_g": 0.3
          }
        ],
        "is_partial": true
      }
      ''';

      final resultSnake = MealAnalysisResult.fromJsonString(jsonWithSnakeCase);
      expect(resultSnake.isPartial, isTrue);

      const jsonWithCamelCase = '''
      {
        "plato": "Plato Incompleto Camel",
        "items": [],
        "isPartial": true
      }
      ''';

      final resultCamel = MealAnalysisResult.fromJsonString(jsonWithCamelCase);
      expect(resultCamel.isPartial, isTrue);
    });

    test('fromJsonString respects isPartial parameter override', () {
      const jsonNormal = '''
      {
        "plato": "Sándwich de pavo",
        "items": [
          {
            "alimento": "Pan integral",
            "calorias": 140,
            "proteinas_g": 5,
            "carbohidratos_g": 26,
            "grasas_g": 2
          }
        ]
      }
      ''';

      final result = MealAnalysisResult.fromJsonString(jsonNormal, isPartial: true);
      expect(result.isPartial, isTrue);
    });

    test('Client-side item summation overrides diverging legacy totales object', () {
      const jsonWithWrongTotals = '''
      {
        "plato": "Batido de Proteína",
        "items": [
          {
            "alimento": "Proteína en polvo",
            "calorias": 120,
            "proteinas_g": 25,
            "carbohidratos_g": 2,
            "grasas_g": 1
          },
          {
            "alimento": "Leche de almendras",
            "calorias": 30,
            "proteinas_g": 1,
            "carbohidratos_g": 1,
            "grasas_g": 2.5
          }
        ],
        "totales": {
          "calorias": 999.0,
          "proteina_g": 99.0,
          "carbohidratos_g": 99.0,
          "grasas_g": 99.0
        }
      }
      ''';

      final result = MealAnalysisResult.fromJsonString(jsonWithWrongTotals);

      // Must be computed from items (120 + 30 = 150), ignoring 999.0 in totales
      expect(result.totalCalories, equals(150.0));
      expect(result.totalProtein, equals(26.0));
      expect(result.totalCarbs, equals(3.0));
      expect(result.totalFat, equals(3.5));
    });
  });
}
