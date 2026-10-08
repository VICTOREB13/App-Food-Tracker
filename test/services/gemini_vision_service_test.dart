import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/services/gemini_vision_service.dart';

void main() {
  group('GeminiVisionService Model, Timeout and System Instruction Tests', () {
    test('GeminiVisionService initializes with gemini-3.8-flash as defaultModel', () {
      final serviceDefault = GeminiVisionService(apiKey: 'dummy-key');
      expect(serviceDefault.modelName, equals('gemini-3.8-flash'));
      expect(GeminiVisionService.defaultModel, equals('gemini-3.8-flash'));
      expect(GeminiVisionService.clinicalModel, equals('gemini-3.1-pro'));
      expect(GeminiVisionService.fallbackModel, equals('gemini-2.5-flash'));
      expect(serviceDefault.masterPrompt, isNull);

      final serviceCustom = GeminiVisionService(
        apiKey: 'dummy-key',
        modelName: 'gemini-3.1-pro',
        masterPrompt: 'Contexto de usuario',
      );
      expect(serviceCustom.modelName, equals('gemini-3.1-pro'));
      expect(serviceCustom.masterPrompt, equals('Contexto de usuario'));
    });

    test('resolveTimeout scales network timeout between 90s and 120s based on model tier and thinking support', () {
      // 90s default for agile/flash legacy models without thinking
      expect(GeminiVisionService.resolveTimeout('gemini-2.5-flash'), equals(const Duration(seconds: 90)));
      expect(GeminiVisionService.resolveTimeout('gemini-1.5-flash'), equals(const Duration(seconds: 90)));

      // 120s for pro / deep reasoning / clinical models and gen-3 models with thinking
      expect(GeminiVisionService.resolveTimeout('gemini-3.8-flash'), equals(const Duration(seconds: 120)));
      expect(GeminiVisionService.resolveTimeout('gemini-3.1-pro'), equals(const Duration(seconds: 120)));
      expect(GeminiVisionService.resolveTimeout('gemini-2.5-pro'), equals(const Duration(seconds: 120)));
      expect(GeminiVisionService.resolveTimeout('gemini-3-pro-preview'), equals(const Duration(seconds: 120)));
    });

    test('userFriendlyErrorMessage provides descriptive timeout handling with retry/local fallback guidance', () {
      final timeoutMessage = GeminiVisionService.userFriendlyErrorMessage(TimeoutException('Request timed out'));
      expect(timeoutMessage, contains('El tiempo de espera de análisis se agotó'));
      expect(timeoutMessage, contains('Se perdió la conexión a internet'));
      expect(timeoutMessage, contains('reintenta o usa registro manual'));

      final strTimeout = GeminiVisionService.userFriendlyErrorMessage('timeoutexception after 90000ms');
      expect(strTimeout, contains('El tiempo de espera de análisis se agotó'));
    });

    test('userFriendlyErrorMessage maps network, auth, quota and safety errors', () {
      // 1. Network errors
      expect(
        GeminiVisionService.userFriendlyErrorMessage(const SocketException('Failed host lookup')),
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

      expect(prompt, contains('Puño cerrado'));
      expect(prompt, contains('Palma de la mano'));
      expect(prompt, contains('Pulgar'));
      expect(prompt, contains('Grasa Oculta'));
      expect(prompt, contains('--- CONTEXTO BIOLÓGICO Y METAS DEL COMENSAL (MASTER PROMPT) ---'));
      expect(prompt, contains('Victor, 30 años, 80kg'));
      expect(prompt, contains('Déficit calórico (-500 kcal)'));
    });

    test('System instruction preserves clinical volumetric rules and causal pipeline', () {
      const prompt = GeminiVisionService.systemInstruction;

      expect(prompt, contains('Puño cerrado'));
      expect(prompt, contains('Palma de la mano'));
      expect(prompt, contains('Pulgar'));
      expect(prompt, contains('Conversión cocido vs crudo'));
      expect(prompt, contains('Grasa Oculta'));
      expect(prompt, contains('5g y 10g adicionales de grasa'));
      expect(prompt, contains('Porciones compartidas'));
      expect(prompt, contains('PIPELINE CAUSAL ESTRICTO'));
      expect(prompt, contains('Desglose obligatorio de ingredientes en \'items\''));
      expect(prompt, contains('PROHIBIDO fijar 200g genéricos'));
    });

    test('GeminiVisionService exposes defaultThinkingLevel and resolves thinking levels correctly', () {
      expect(GeminiVisionService.defaultThinkingLevel, equals('MEDIUM'));
      expect(GeminiVisionService.resolveThinkingLevel('gemini-3.8-flash'), equals('MEDIUM'));
      expect(GeminiVisionService.resolveThinkingLevel('gemini-3.1-pro'), equals('MEDIUM'));
      expect(GeminiVisionService.resolveThinkingLevel('gemini-3.5-flash-lite'), isNull);
      expect(GeminiVisionService.resolveThinkingLevel('gemini-2.5-flash'), isNull);

      final config = GeminiVisionService.buildCallConfig(modelName: 'gemini-3.8-flash');
      expect(config['thinking_level'], equals('MEDIUM'));
      expect(config['thinking_config'], equals({'thinking_level': 'MEDIUM'}));

      final liteConfig = GeminiVisionService.buildCallConfig(modelName: 'gemini-3.5-flash-lite');
      expect(liteConfig.containsKey('thinking_level'), isFalse);
      expect(liteConfig.containsKey('thinking_config'), isFalse);
    });
  });
}
