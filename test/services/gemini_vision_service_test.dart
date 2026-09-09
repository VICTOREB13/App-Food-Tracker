import 'dart:async';
import 'dart:io';
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
      const prompt = GeminiVisionService.systemInstruction;

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

    test('MealAnalysisResult maneja texto conversacional previo y posterior al bloque markdown', () {
      const conversationalJson = '''
      ¡Hola! He analizado la fotografía de tu comida y este es el desglose nutricional estimado:
      ```json
      {
        "plato": "Sancocho Criollo",
        "items": [
          {
            "alimento": "Caldo de res con verduras",
            "gramos_estimados": 350,
            "calorias": 280,
            "proteinas_g": 18.0,
            "carbohidratos_g": 35.0,
            "grasas_g": 8.0,
            "justificacion_visual": "Tazón mediano tradicional"
          }
        ],
        "totales": {
          "calorias": 280.0,
          "proteina_g": 18.0,
          "carbohidratos_g": 35.0,
          "grasas_g": 8.0
        }
      }
      ```
      Recuerda hidratarte bien durante el día. ¡Buen provecho!
      ''';

      final result = MealAnalysisResult.fromJsonString(conversationalJson);
      expect(result.dishName, equals('Sancocho Criollo'));
      expect(result.totalCalories, equals(280.0));
      expect(result.items.length, equals(1));
      expect(result.items.first.name, equals('Caldo de res con verduras'));
    });

    test('MealAnalysisResult acota defensivamente valores extremos astronómicos (ej: 99999999)', () {
      const extremeNumbersJson = '''
      {
        "plato": "Festín Desmedido",
        "items": [
          {
            "alimento": "Carne hipercalórica",
            "gramos_estimados": 99999999,
            "calorias": 99999999,
            "proteinas_g": 99999999,
            "carbohidratos_g": 99999999,
            "grasas_g": 99999999
          }
        ],
        "totales": {
          "calorias": 99999999,
          "proteina_g": 99999999,
          "carbohidratos_g": 99999999,
          "grasas_g": 99999999
        }
      }
      ''';

      final result = MealAnalysisResult.fromJsonString(extremeNumbersJson);
      expect(result.totalCalories, equals(9999.0));
      expect(result.totalProtein, equals(9999.0));
      expect(result.totalCarbs, equals(9999.0));
      expect(result.totalFat, equals(9999.0));
      expect(result.items.first.calories, equals(9999.0));
      expect(result.items.first.estimatedGrams, equals(50000.0));
    });

    test('MealAnalysisResult soporta nombres de claves alternativos (dish, totals, calories)', () {
      const alternateKeysJson = '''
      {
        "dish": "Ensalada César",
        "items": [
          {
            "name": "Pollo",
            "estimated_grams": 100,
            "calories": 160,
            "protein": 30,
            "carbs": 0,
            "fat": 3
          }
        ],
        "totals": {
          "calories": 160,
          "protein": 30,
          "carbs": 0,
          "fat": 3
        }
      }
      ''';

      final result = MealAnalysisResult.fromJsonString(alternateKeysJson);
      expect(result.dishName, equals('Ensalada César'));
      expect(result.totalCalories, equals(160.0));
      expect(result.totalProtein, equals(30.0));
      expect(result.items.first.name, equals('Pollo'));
    });

    test('buildSystemInstruction sin master prompt retorna baseSystemInstruction idéntica', () {
      final defaultInstruction = GeminiVisionService.buildSystemInstruction();
      expect(defaultInstruction, equals(GeminiVisionService.baseSystemInstruction));
      expect(defaultInstruction, equals(GeminiVisionService.systemInstruction));

      final emptyInstruction = GeminiVisionService.buildSystemInstruction('   ');
      expect(emptyInstruction, equals(GeminiVisionService.baseSystemInstruction));
    });

    test('buildSystemInstruction inyecta Master Prompt del usuario manteniendo reglas volumétricas', () {
      const masterPrompt = '''
      Usuario: Victor, 30 años, 80kg, 180cm
      Objetivo: Déficit calórico (-500 kcal)
      Meta diaria: 1950 kcal, 160g proteína
      ''';

      final prompt = GeminiVisionService.buildSystemInstruction(masterPrompt);

      // Preserves original clinical volumetric rules
      expect(prompt, contains('Puño cerrado'));
      expect(prompt, contains('Palma de la mano'));
      expect(prompt, contains('Pulgar'));
      expect(prompt, contains('Grasa Oculta'));

      // Injects Master Prompt section and user details
      expect(prompt, contains('--- CONTEXTO BIOLÓGICO Y METAS DEL COMENSAL (MASTER PROMPT) ---'));
      expect(prompt, contains('Victor, 30 años, 80kg'));
      expect(prompt, contains('Déficit calórico (-500 kcal)'));
      expect(prompt, contains('Ajusta tus estimaciones y observaciones'));
    });

    test('GeminiVisionService inicializa con modelo por defecto o custom y masterPrompt opcional', () {
      final serviceDefault = GeminiVisionService(apiKey: 'dummy-key');
      expect(serviceDefault.modelName, equals('gemini-2.5-flash'));
      expect(serviceDefault.masterPrompt, isNull);

      final serviceCustom = GeminiVisionService(
        apiKey: 'dummy-key',
        modelName: 'gemini-2.5-pro',
        masterPrompt: 'Contexto de usuario',
      );
      expect(serviceCustom.modelName, equals('gemini-2.5-pro'));
      expect(serviceCustom.masterPrompt, equals('Contexto de usuario'));
    });

    test('userFriendlyErrorMessage mapea errores de red, auth, cuota y seguridad correctamente', () {
      // 1. Network errors
      expect(
        GeminiVisionService.userFriendlyErrorMessage(const SocketException('Failed host lookup')),
        contains('Se perdió la conexión a internet'),
      );
      expect(
        GeminiVisionService.userFriendlyErrorMessage(TimeoutException('Request timed out')),
        contains('Se perdió la conexión a internet'),
      );
      expect(
        GeminiVisionService.userFriendlyErrorMessage('ClientException: Network is unreachable'),
        contains('Se perdió la conexión a internet'),
      );

      // 2. Auth / API Key errors
      expect(
        GeminiVisionService.userFriendlyErrorMessage('400 API key not valid'),
        contains('Tu API Key de Gemini no es válida'),
      );
      expect(
        GeminiVisionService.userFriendlyErrorMessage('PERMISSION_DENIED: 403 Forbidden'),
        contains('Tu API Key de Gemini no es válida'),
      );
      expect(
        GeminiVisionService.userFriendlyErrorMessage('401 Unauthorized: Invalid API Key'),
        contains('Tu API Key de Gemini no es válida'),
      );

      // 3. Quota errors
      expect(
        GeminiVisionService.userFriendlyErrorMessage('429 RESOURCE_EXHAUSTED: quota exceeded'),
        contains('Has alcanzado el límite de solicitudes de Gemini'),
      );
      expect(
        GeminiVisionService.userFriendlyErrorMessage('rate limit reached'),
        contains('Has alcanzado el límite de solicitudes de Gemini'),
      );

      // 4. Safety & detection failures
      expect(
        GeminiVisionService.userFriendlyErrorMessage('Candidate blocked due to SAFETY'),
        contains('La IA no logró identificar alimentos en la foto'),
      );
      expect(
        GeminiVisionService.userFriendlyErrorMessage('Gemini devolvió una respuesta vacía'),
        contains('La IA no logró identificar alimentos en la foto'),
      );

      // 5. Generic fallback
      expect(
        GeminiVisionService.userFriendlyErrorMessage(const FormatException('Unexpected token')),
        equals('Ocurrió un error al analizar la comida. Por favor, inténtalo nuevamente.'),
      );
    });
  });
}
