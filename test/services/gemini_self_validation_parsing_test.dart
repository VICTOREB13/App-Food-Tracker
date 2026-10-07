import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/meal_analysis_result.dart';

void main() {
  group('Gemini Vision Self-Validation Parsing Tests', () {
    test('MealAnalysisResult deserializa porcentaje_certeza y margen_error_kcal correctamente', () {
      const selfValidationJson = '''
      {
        "plato": "Pollo a la plancha con arroz",
        "porcentaje_certeza": 90,
        "margen_error_kcal": 45,
        "items": [
          {"alimento": "Pollo", "gramos_estimados": 150, "calorias": 220, "proteinas_g": 35, "carbohidratos_g": 0, "grasas_g": 4}
        ],
        "totales": {"calorias": 220, "proteina_g": 35, "carbohidratos_g": 0, "grasas_g": 4}
      }
      ''';

      final result = MealAnalysisResult.fromJsonString(selfValidationJson);
      expect(result.confidencePercentage, equals(90));
      expect(result.calorieErrorMargin, equals(45));

      final map = result.toMap();
      expect(map['porcentaje_certeza'], equals(90));
      expect(map['margen_error_kcal'], equals(45));

      final copied = result.copyWith(confidencePercentage: 95, calorieErrorMargin: 30);
      expect(copied.confidencePercentage, equals(95));
      expect(copied.calorieErrorMargin, equals(30));
    });

    test('MealAnalysisResult deserializa claves alternativas en inglés para métricas de certeza', () {
      const englishMetricsJson = '''
      {
        "plato": "Salmón con espárragos",
        "confidence_percentage": 85,
        "calorie_error_margin": 40,
        "items": [
          {"alimento": "Salmón", "gramos_estimados": 180, "calorias": 360, "proteinas_g": 34, "carbohidratos_g": 0, "grasas_g": 22}
        ],
        "totales": {"calorias": 360, "proteina_g": 34, "carbohidratos_g": 0, "grasas_g": 22}
      }
      ''';

      final result = MealAnalysisResult.fromJsonString(englishMetricsJson);
      expect(result.confidencePercentage, equals(85));
      expect(result.calorieErrorMargin, equals(40));
    });

    test('MealAnalysisResult sanitiza bloques markdown ```json y parsea strings decimales', () {
      const markdownJson = '''
      ```json
      {
        "plato": "Ensalada César",
        "porcentaje_certeza": "88.6%",
        "margen_error_kcal": "±42.5 kcal",
        "items": [
          {"alimento": "Lechuga y pollo", "gramos_estimados": 200, "calorias": 280, "proteinas_g": 25, "carbohidratos_g": 8, "grasas_g": 16}
        ],
        "totales": {"calorias": 280, "proteina_g": 25, "carbohidratos_g": 8, "grasas_g": 16}
      }
      ```
      ''';

      final result = MealAnalysisResult.fromJsonString(markdownJson);
      expect(result.confidencePercentage, equals(89));
      expect(result.calorieErrorMargin, equals(43));
      expect(result.rawJson, isNot(contains('```')));
    });

    test('MealAnalysisResult acota valores fuera de rango defensivamente', () {
      const extremeJson = '''
      {
        "plato": "Plato Extremo",
        "porcentaje_certeza": 150,
        "margen_error_kcal": 5000,
        "items": [],
        "totales": {"calorias": 0, "proteina_g": 0, "carbohidratos_g": 0, "grasas_g": 0}
      }
      ''';

      final result = MealAnalysisResult.fromJsonString(extremeJson);
      expect(result.confidencePercentage, equals(100));
      expect(result.calorieErrorMargin, equals(2000));
    });
  });
}
