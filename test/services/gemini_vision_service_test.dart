import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/services/gemini_vision_service.dart';

void main() {
  group('GeminiVisionService JSON Parsing & Volumetric Rules Tests', () {
    test('MealAnalysisResult deserializa JSON estructurado de Gemini fielmente', () {
      const jsonResponse = '''
      {
        "plato": "Pabellón Criollo",
        "items": [
          {
            "alimento": "Carne mechada",
            "gramos_estimados": 120,
            "calorias": 220,
            "proteinas_g": 32.0,
            "carbohidratos_g": 2.0,
            "grasas_g": 9.5,
            "justificacion_visual": "Porción equivalente a la palma de la mano, con sofrito"
          },
          {
            "alimento": "Arroz blanco cocido",
            "gramos_estimados": 180,
            "calorias": 234,
            "proteinas_g": 4.5,
            "carbohidratos_g": 50.4,
            "grasas_g": 0.6,
            "justificacion_visual": "Volumen de un puño cerrado (~1 taza)"
          },
          {
            "alimento": "Caraotas negras refritas",
            "gramos_estimados": 150,
            "calorias": 195,
            "proteinas_g": 12.0,
            "carbohidratos_g": 30.0,
            "grasas_g": 4.0,
            "justificacion_visual": "Legumbre cocida con sofrito casero"
          },
          {
            "alimento": "Grasa oculta de sofritos",
            "gramos_estimados": 8,
            "calorias": 72,
            "proteinas_g": 0.0,
            "carbohidratos_g": 0.0,
            "grasas_g": 8.0,
            "justificacion_visual": "Regla de 5-10g de aceite incorporado en sofritos"
          }
        ],
        "totales": {
          "calorias": 721.0,
          "proteina_g": 48.5,
          "carbohidratos_g": 82.4,
          "grasas_g": 22.1
        }
      }
      ''';

      final result = MealAnalysisResult.fromJsonString(jsonResponse);

      expect(result.dishName, equals('Pabellón Criollo'));
      expect(result.items.length, equals(4));
      expect(result.totalCalories, equals(721.0));
      expect(result.totalProtein, equals(48.5));
      expect(result.totalCarbs, equals(82.4));
      expect(result.totalFat, equals(22.1));
      expect(result.items.first.name, equals('Carne mechada'));
      expect(result.items.first.visualJustification, contains('palma de la mano'));
    });

    test('MealAnalysisResult suma automáticamente los items si totales no está presente', () {
      const jsonWithoutTotals = '''
      {
        "plato": "Pollo con Ensalada",
        "items": [
          {
            "alimento": "Pechuga a la plancha",
            "gramos_estimados": 100,
            "calorias": 165,
            "proteinas_g": 31.0,
            "carbohidratos_g": 0.0,
            "grasas_g": 3.6
          },
          {
            "alimento": "Ensalada verde con limón",
            "gramos_estimados": 120,
            "calorias": 30,
            "proteinas_g": 1.5,
            "carbohidratos_g": 5.0,
            "grasas_g": 0.5
          }
        ]
      }
      ''';

      final result = MealAnalysisResult.fromJsonString(jsonWithoutTotals);

      expect(result.dishName, equals('Pollo con Ensalada'));
      expect(result.items.length, equals(2));
      expect(result.totalCalories, equals(195.0));
      expect(result.totalProtein, equals(32.5));
      expect(result.totalCarbs, equals(5.0));
      expect(result.totalFat, equals(4.1));
    });

    test('Instrucciones del sistema contienen reglas de cubicaje casero latinoamericano', () {
      final prompt = GeminiVisionService.systemInstruction;

      expect(prompt, contains('Puño cerrado'));
      expect(prompt, contains('Palma de la mano'));
      expect(prompt, contains('Pulgar'));
      expect(prompt, contains('Conversión cocido vs crudo'));
      expect(prompt, contains('Grasa Oculta'));
      expect(prompt, contains('5g y 10g adicionales de grasa'));
      expect(prompt, contains('Porciones compartidas'));
    });

    test('MealAnalysisResult maneja markdown code fences y números como strings sin fallar', () {
      const markdownJson = '''```json
      {
        "plato": "Arepa Reina Pepiada",
        "items": [
          {
            "alimento": "Arepa de maíz",
            "gramos_estimados": "120",
            "calorias": "210",
            "proteinas_g": "4.0",
            "carbohidratos_g": "45.0",
            "grasas_g": "1.5"
          }
        ],
        "totales": {
          "calorias": "480",
          "proteinas_g": "24.0",
          "carbohidratos_g": "46.0",
          "grasas_g": "22.0"
        }
      }
      ```''';

      final result = MealAnalysisResult.fromJsonString(markdownJson);
      expect(result.dishName, equals('Arepa Reina Pepiada'));
      expect(result.totalCalories, equals(480.0));
      expect(result.totalProtein, equals(24.0));
      expect(result.totalCarbs, equals(46.0));
      expect(result.totalFat, equals(22.0));
      expect(result.items.first.name, equals('Arepa de maíz'));
      expect(result.items.first.calories, equals(210.0));
    });
  });
}
