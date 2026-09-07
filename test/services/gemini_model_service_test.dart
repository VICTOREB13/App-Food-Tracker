import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:food_tracker/models/gemini_model_info.dart';
import 'package:food_tracker/services/gemini_model_service.dart';

const String mockSuccessResponseJson = '''
{
  "models": [
    {
      "name": "models/gemini-2.5-flash",
      "version": "2.5",
      "displayName": "Gemini 2.5 Flash",
      "description": "Next-generation multimodal model.",
      "inputTokenLimit": 1048576,
      "outputTokenLimit": 8192,
      "supportedGenerationMethods": ["generateContent", "countTokens"],
      "inputModalities": ["TEXT", "IMAGE"]
    },
    {
      "name": "models/gemini-2.5-pro",
      "version": "2.5",
      "displayName": "Gemini 2.5 Pro",
      "description": "Deep reasoning multimodal model.",
      "inputTokenLimit": 2097152,
      "outputTokenLimit": 8192,
      "supportedGenerationMethods": ["generateContent", "countTokens"],
      "inputModalities": ["TEXT", "IMAGE"]
    },
    {
      "name": "models/gemini-2.0-flash",
      "version": "2.0",
      "displayName": "Gemini 2.0 Flash",
      "description": "Fast multimodal model.",
      "inputTokenLimit": 1048576,
      "outputTokenLimit": 8192,
      "supportedGenerationMethods": ["generateContent"],
      "inputModalities": ["TEXT", "IMAGE"]
    },
    {
      "name": "models/gemini-1.5-flash",
      "version": "1.5",
      "displayName": "Gemini 1.5 Flash",
      "description": "Legacy fast multimodal model.",
      "inputTokenLimit": 1048576,
      "outputTokenLimit": 8192,
      "supportedGenerationMethods": ["generateContent"],
      "inputModalities": ["TEXT", "IMAGE"]
    },
    {
      "name": "models/text-embedding-004",
      "version": "004",
      "displayName": "Text Embedding 004",
      "description": "Embeddings model.",
      "inputTokenLimit": 2048,
      "outputTokenLimit": 1,
      "supportedGenerationMethods": ["embedContent"],
      "inputModalities": ["TEXT"]
    },
    {
      "name": "models/imagen-3.0-generate-002",
      "version": "3.0",
      "displayName": "Imagen 3.0",
      "description": "Image generation model.",
      "supportedGenerationMethods": ["generateImage"]
    }
  ]
}
''';

const String mockMissingModalitiesJson = '''
{
  "models": [
    {
      "name": "models/gemini-2.5-flash",
      "displayName": "Gemini 2.5 Flash",
      "description": "Model with omitted modalities array.",
      "supportedGenerationMethods": ["generateContent"]
    },
    {
      "name": "models/text-embedding-004",
      "displayName": "Text Embedding",
      "supportedGenerationMethods": ["embedContent"]
    },
    {
      "name": "models/gemini-embedding-exp",
      "displayName": "Gemini Embedding",
      "supportedGenerationMethods": ["generateContent"]
    }
  ]
}
''';

void main() {
  group('GeminiModelService Unit Tests', () {
    test('fetchAvailableModels successfully parses and ranks vision models', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['key'], equals('test-api-key'));
        expect(request.url.queryParameters['pageSize'], equals('100'));
        return http.Response(mockSuccessResponseJson, 200);
      });

      final service = GeminiModelService(client: mockClient);
      final models = await service.fetchAvailableModels('test-api-key');

      // Should contain 4 vision models (excluding text-embedding-004 and imagen)
      expect(models.length, equals(4));

      // 1. gemini-2.5-flash (rank 1)
      expect(models[0].name, equals('gemini-2.5-flash'));
      expect(models[0].isRecommended, isTrue);
      expect(models[0].recommendationLabel, equals('RECOMENDADO (Ultrarrápido)'));

      // 2. gemini-2.0-flash (rank 2)
      expect(models[1].name, equals('gemini-2.0-flash'));
      expect(models[1].isRecommended, isTrue);
      expect(models[1].recommendationLabel, equals('ESTABLE (Alta Velocidad)'));

      // 3. gemini-2.5-pro (rank 3)
      expect(models[2].name, equals('gemini-2.5-pro'));
      expect(models[2].isRecommended, isTrue);
      expect(models[2].recommendationLabel, equals('MÁXIMA PRECISIÓN (Razonamiento)'));

      // 4. gemini-1.5-flash (rank 5)
      expect(models[3].name, equals('gemini-1.5-flash'));
      expect(models[3].isRecommended, isFalse);
      expect(models[3].recommendationLabel, equals('HEREDADO (Compatibilidad)'));
    });

    test('isVisionCapableModel fallback heuristic filters non-vision when inputModalities is absent', () {
      final service = GeminiModelService();
      final models = service.parseModelsResponse(mockMissingModalitiesJson);

      expect(models.length, equals(1));
      expect(models.first.name, equals('gemini-2.5-flash'));
    });

    test('Throws GeminiApiException with 400 when API key is empty', () async {
      final service = GeminiModelService();
      expect(
        () => service.fetchAvailableModels('   '),
        throwsA(isA<GeminiApiException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('Throws GeminiApiException with 403 on forbidden response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"error": {"code": 403, "message": "Method not allowed for key"}}',
          403,
        );
      });

      final service = GeminiModelService(client: mockClient);
      expect(
        () => service.fetchAvailableModels('invalid-key'),
        throwsA(
          isA<GeminiApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.details, 'details', contains('Method not allowed')),
        ),
      );
    });

    test('Throws GeminiApiException with 429 on quota limit reached', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"error": {"code": 429, "message": "Resource has been exhausted"}}',
          429,
        );
      });

      final service = GeminiModelService(client: mockClient);
      expect(
        () => service.fetchAvailableModels('rate-limited-key'),
        throwsA(isA<GeminiApiException>().having((e) => e.statusCode, 'statusCode', 429)),
      );
    });

    test('Throws GeminiApiException with 408 on timeout', () async {
      final mockClient = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return http.Response('{}', 200);
      });

      final service = GeminiModelService(client: mockClient);
      expect(
        () => service.fetchAvailableModels(
          'key',
          timeout: const Duration(milliseconds: 10),
        ),
        throwsA(isA<GeminiApiException>().having((e) => e.statusCode, 'statusCode', 408)),
      );
    });

    test('resolveEffectiveModel returns saved selection if valid in list', () {
      final available = [
        const GeminiModelInfo(
          name: 'gemini-2.5-flash',
          displayName: 'Gemini 2.5 Flash',
          description: '',
          isRecommended: true,
        ),
        const GeminiModelInfo(
          name: 'gemini-2.5-pro',
          displayName: 'Gemini 2.5 Pro',
          description: '',
          isRecommended: true,
        ),
      ];

      final resolved = GeminiModelService.resolveEffectiveModel(
        availableModels: available,
        savedSelection: 'gemini-2.5-pro',
      );
      expect(resolved, equals('gemini-2.5-pro'));
    });

    test('resolveEffectiveModel falls back to recommended model if saved is invalid or null', () {
      final available = [
        const GeminiModelInfo(
          name: 'gemini-2.5-flash',
          displayName: 'Gemini 2.5 Flash',
          description: '',
          isRecommended: true,
        ),
      ];

      final resolvedNull = GeminiModelService.resolveEffectiveModel(
        availableModels: available,
        savedSelection: null,
      );
      expect(resolvedNull, equals('gemini-2.5-flash'));

      final resolvedMissing = GeminiModelService.resolveEffectiveModel(
        availableModels: available,
        savedSelection: 'deprecated-model-xyz',
      );
      expect(resolvedMissing, equals('gemini-2.5-flash'));
    });

    test('Fallback models list is populated and contains standard models', () {
      final fallbacks = GeminiModelService.fallbackModels;
      expect(fallbacks.length, greaterThanOrEqualTo(3));
      expect(fallbacks.any((m) => m.name == 'gemini-2.5-flash'), isTrue);
      expect(fallbacks.any((m) => m.name == 'gemini-2.0-flash'), isTrue);
      expect(fallbacks.any((m) => m.name == 'gemini-2.5-pro'), isTrue);
    });

    test('GeminiModelInfo serialization and sentinel copyWith', () {
      const model = GeminiModelInfo(
        name: 'gemini-2.5-flash',
        displayName: 'Gemini 2.5 Flash',
        description: 'Test description',
        isRecommended: true,
        recommendationLabel: 'RECOMENDADO',
        inputTokenLimit: 1000,
        outputTokenLimit: 500,
      );

      final json = model.toJson();
      final fromJson = GeminiModelInfo.fromJson(json);

      expect(fromJson, equals(model));
      expect(fromJson.name, equals('gemini-2.5-flash'));
      expect(fromJson.recommendationLabel, equals('RECOMENDADO'));

      final copied = model.copyWith(recommendationLabel: null);
      expect(copied.recommendationLabel, isNull);
      expect(copied.name, equals(model.name));
    });
  });
}
