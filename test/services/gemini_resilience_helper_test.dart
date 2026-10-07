import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/meal_analysis_result.dart';
import 'package:food_tracker/services/gemini_resilience_helper.dart';

void main() {
  group('GeminiResilienceHelper Tests', () {
    test('isRetriableError identifies 429, 503, timeouts and socket errors', () {
      expect(GeminiResilienceHelper.isRetriableError('Exception: 429 ResourceExhausted'), isTrue);
      expect(GeminiResilienceHelper.isRetriableError('Exception: 503 Service Unavailable'), isTrue);
      expect(GeminiResilienceHelper.isRetriableError('SocketException: Connection timed out'), isTrue);
      expect(GeminiResilienceHelper.isRetriableError('Exception: 400 Bad Request'), isFalse);
      expect(GeminiResilienceHelper.isRetriableError('Exception: 401 Unauthorized'), isFalse);
    });

    test('executeWithRetry succeeds on first attempt without delay', () async {
      int attempts = 0;
      final result = await GeminiResilienceHelper.executeWithRetry<String>(
        primaryModel: 'gemini-3.8-flash',
        action: (attempt, currentModel) async {
          attempts++;
          return 'success';
        },
      );

      expect(result, equals('success'));
      expect(attempts, equals(1));
    });

    test('executeWithRetry retries transient 429 errors and succeeds', () async {
      int attempts = 0;
      final result = await GeminiResilienceHelper.executeWithRetry<String>(
        primaryModel: 'gemini-3.8-flash',
        customDelays: [const Duration(milliseconds: 10), const Duration(milliseconds: 20)],
        addJitter: false,
        action: (attempt, currentModel) async {
          attempts++;
          if (attempt == 0) {
            throw Exception('429 Quota Exceeded');
          }
          return 'recovered';
        },
      );

      expect(result, equals('recovered'));
      expect(attempts, equals(2));
    });

    test('executeWithRetry falls back to secondary model on repeated failures', () async {
      final modelsUsed = <String>[];
      final result = await GeminiResilienceHelper.executeWithRetry<String>(
        primaryModel: 'gemini-3.8-flash',
        secondaryModel: 'gemini-1.5-flash',
        customDelays: [const Duration(milliseconds: 10), const Duration(milliseconds: 20)],
        addJitter: false,
        action: (attempt, currentModel) async {
          modelsUsed.add(currentModel);
          if (attempt < 2) {
            throw Exception('503 Service Unavailable');
          }
          return 'ok_from_$currentModel';
        },
      );

      expect(result, equals('ok_from_gemini-1.5-flash'));
      expect(modelsUsed, contains('gemini-1.5-flash'));
    });

    test('buildUserPrompt appends dishware diameter metric scale when provided', () {
      final promptWithScale = GeminiResilienceHelper.buildUserPrompt(
        dishwareDiameterCm: 26.5,
        userContext: 'Cena ligera',
      );

      expect(promptWithScale, contains('Escala métrica de referencia del comensal'));
      expect(promptWithScale, contains('26.5 cm'));
      expect(promptWithScale, contains('Cena ligera'));
      expect(promptWithScale, contains('fibra_g, sodio_mg, azucar_g'));
      expect(promptWithScale, contains('ORDEN CAUSAL OBLIGATORIO'));

      final promptWithoutScale = GeminiResilienceHelper.buildUserPrompt(
        dishwareDiameterCm: null,
      );
      expect(promptWithoutScale.contains('Escala métrica de referencia'), isFalse);
    });

    test('mealAnalysisSchema and baseSystemInstruction enforce strict causal order', () {
      final schema = GeminiResilienceHelper.mealAnalysisSchema;
      expect(schema, isNotNull);

      // System instruction mandates the causal pipeline
      final instruction = GeminiResilienceHelper.baseSystemInstruction;
      expect(instruction, contains('PIPELINE CAUSAL ESTRICTO'));
      expect(instruction, contains('1. Identificación y Referencia Métrica'));
      expect(instruction, contains('2. Estimación Geométrica 3D'));
      expect(instruction, contains('3. Densidad Física y Factor de Cocción'));
      expect(instruction, contains('4. Detección Visual de Aceites y Grasa Oculta'));
      expect(instruction, contains('5. Gramos Calculados (Masa Derivada)'));
      expect(instruction, contains('6. Macronutrientes y Micronutrientes Deducidos'));
      expect(instruction, contains('7. Justificación Visual Explicativa'));
    });

    test('MealAnalysisResult deserializes JSON generated with causal 3D properties', () {
      const causalJson = '''
      {
        "plato": "Pechuga de Pollo con Arroz y Aguacate",
        "items": [
          {
            "alimento": "Pechuga de pollo a la plancha",
            "referencia_metrica": "Plato de 26 cm",
            "forma_geometrica_3d": "Prisma irregular elíptico",
            "dimensiones_estimadas_cm": "12 x 7 x 1.8 cm",
            "volumen_cm3": 115.0,
            "densidad_g_cm3": 1.25,
            "factor_coccion": 0.82,
            "grasa_visible_o_oculta": "Brillo ligero en superficie, ~3g aceite",
            "gramos_estimados": 120.0,
            "calorias": 195.0,
            "proteinas_g": 37.0,
            "carbohidratos_g": 0.0,
            "grasas_g": 4.5,
            "fibra_g": 0.0,
            "sodio_mg": 75.0,
            "azucar_g": 0.0,
            "justificacion_visual": "Masa de 120g calculada a partir de 115cm³ x 1.25g/cm³ x 0.82 cocción"
          },
          {
            "alimento": "Arroz blanco cocido",
            "referencia_metrica": "Plato de 26 cm",
            "forma_geometrica_3d": "Semiesfera / cúpula",
            "dimensiones_estimadas_cm": "9 x 9 x 3.5 cm",
            "volumen_cm3": 140.0,
            "densidad_g_cm3": 1.25,
            "factor_coccion": 1.0,
            "grasa_visible_o_oculta": "Sin aceite visible extra",
            "gramos_estimados": 175.0,
            "calorias": 228.0,
            "proteinas_g": 4.4,
            "carbohidratos_g": 49.0,
            "grasas_g": 0.5,
            "fibra_g": 1.2,
            "sodio_mg": 5.0,
            "azucar_g": 0.1,
            "justificacion_visual": "Masa de 175g derivada de volumen semiesférico de 140cm³"
          }
        ],
        "totales": {
          "calorias": 423.0,
          "proteina_g": 41.4,
          "carbohidratos_g": 49.0,
          "grasas_g": 5.0,
          "fibra_g": 1.2,
          "sodio_mg": 80.0,
          "azucar_g": 0.1
        }
      }
      ''';

      final result = MealAnalysisResult.fromJsonString(causalJson);
      expect(result.dishName, equals('Pechuga de Pollo con Arroz y Aguacate'));
      expect(result.items.length, equals(2));
      expect(result.items[0].name, equals('Pechuga de pollo a la plancha'));
      expect(result.items[0].estimatedGrams, equals(120.0));
      expect(result.items[0].visualJustification, contains('115cm³'));
      expect(result.items[1].name, equals('Arroz blanco cocido'));
      expect(result.items[1].estimatedGrams, equals(175.0));
      expect(result.totalCalories, equals(423.0));
    });
  });
}
