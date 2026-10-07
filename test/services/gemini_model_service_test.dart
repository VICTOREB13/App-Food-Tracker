import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:food_tracker/models/gemini_model_info.dart';
import 'package:food_tracker/services/gemini_model_service.dart';

const String mockSuccessResponseJson = '''
{
  "models": [
    {
      "name": "models/gemini-3.8-flash",
      "version": "3.8",
      "displayName": "Gemini 3.8 Flash",
      "description": "Daily fast and cost-effective vision model.",
      "inputTokenLimit": 1048576,
      "outputTokenLimit": 8192,
      "supportedGenerationMethods": ["generateContent", "countTokens"],
      "inputModalities": ["TEXT", "IMAGE"]
    },
    {
      "name": "models/gemini-3.1-pro",
      "version": "3.1",
      "displayName": "Gemini 3.1 Pro",
      "description": "Clinical deep reasoning high-precision model.",
      "inputTokenLimit": 2097152,
      "outputTokenLimit": 8192,
      "supportedGenerationMethods": ["generateContent", "countTokens"],
      "inputModalities": ["TEXT", "IMAGE"]
    },
    {
      "name": "models/gemini-2.5-flash",
      "version": "2.5",
      "displayName": "Gemini 2.5 Flash",
      "description": "Multimodal model.",
      "inputTokenLimit": 1048576,
      "outputTokenLimit": 8192,
      "supportedGenerationMethods": ["generateContent", "countTokens"],
      "inputModalities": ["TEXT", "IMAGE"]
    },
    {
      "name": "models/gemini-2.0-flash",
      "version": "2.0",
      "displayName": "Gemini 2.0 Flash",
      "description": "Retired legacy model.",
      "inputTokenLimit": 1048576,
      "outputTokenLimit": 8192,
      "supportedGenerationMethods": ["generateContent"],
      "inputModalities": ["TEXT", "IMAGE"]
    },
    {
      "name": "models/gemini-1.5-flash",
      "version": "1.5",
      "displayName": "Gemini 1.5 Flash",
      "description": "Legacy fast model.",
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
    }
  ]
}
''';

const String mockMissingModalitiesJson = '''
{
  "models": [
    {
      "name": "models/gemini-3.8-flash",
      "displayName": "Gemini 3.8 Flash",
      "description": "Model with omitted modalities array.",
      "supportedGenerationMethods": ["generateContent"]
    },
    {
      "name": "models/text-embedding-004",
      "displayName": "Text Embedding",
      "supportedGenerationMethods": ["embedContent"]
    }
  ]
}
''';

void main() {
  group('GeminiModelService Unit Tests', () {
    test('fetchAvailableModels successfully parses, ranks, and prioritizes vision models', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['key'], equals('test-api-key'));
        expect(request.url.queryParameters['pageSize'], equals('100'));
        return http.Response(mockSuccessResponseJson, 200);
      });

      final service = GeminiModelService(client: mockClient);
      final models = await service.fetchAvailableModels('test-api-key');

      expect(models.length, equals(5));

      // 1. gemini-3.8-flash (rank 1, recommended default)
      expect(models[0].name, equals('gemini-3.8-flash'));
      expect(models[0].isRecommended, isTrue);
      expect(models[0].recommendationLabel, equals('Fast'));

      // 2. gemini-3.1-pro (rank 2, recommended clinical)
      expect(models[1].name, equals('gemini-3.1-pro'));
      expect(models[1].isRecommended, isTrue);
      expect(models[1].recommendationLabel, equals('Think'));

      // 3. gemini-2.5-flash (rank 3, not recommended)
      expect(models[2].name, equals('gemini-2.5-flash'));
      expect(models[2].isRecommended, isFalse);

      // 4. gemini-1.5-flash (rank 5)
      expect(models[3].name, equals('gemini-1.5-flash'));
      expect(models[3].isRecommended, isFalse);

      // 5. gemini-2.0-flash (rank 10, obsolete)
      expect(models[4].name, equals('gemini-2.0-flash'));
      expect(models[4].isRecommended, isFalse);
      expect(models[4].recommendationLabel, equals('Obsoleto'));
    });

    test('supportsThinking and resolveThinkingBudget assign 1024 to pro and thinking models', () {
      expect(GeminiModelService.supportsThinking('gemini-3.1-pro'), isTrue);
      expect(GeminiModelService.resolveThinkingBudget('gemini-3.1-pro'), equals(1024));

      expect(GeminiModelService.supportsThinking('gemini-3.8-flash'), isFalse);
      expect(GeminiModelService.resolveThinkingBudget('gemini-3.8-flash'), isNull);

      final proConfig = GeminiModelService.buildCallConfig(modelName: 'gemini-3.1-pro');
      expect(proConfig['thinking_budget'], equals(1024));
      expect(proConfig['thinking_config'], equals({'thinking_budget': 1024}));

      final flashConfig = GeminiModelService.buildCallConfig(modelName: 'gemini-3.8-flash');
      expect(flashConfig.containsKey('thinking_budget'), isFalse);
    });

    test('isVisionCapableModel fallback heuristic filters non-vision when inputModalities is absent', () {
      final service = GeminiModelService();
      final models = service.parseModelsResponse(mockMissingModalitiesJson);

      expect(models.length, equals(1));
      expect(models.first.name, equals('gemini-3.8-flash'));
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
        return http.Response('{"error": {"code": 403, "message": "Method not allowed for key"}}', 403);
      });

      final service = GeminiModelService(client: mockClient);
      expect(
        () => service.fetchAvailableModels('invalid-key'),
        throwsA(isA<GeminiApiException>().having((e) => e.statusCode, 'statusCode', 403)),
      );
    });

    test('Throws GeminiApiException with 429 on quota limit reached', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": {"code": 429, "message": "Resource has been exhausted"}}', 429);
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
        () => service.fetchAvailableModels('key', timeout: const Duration(milliseconds: 10)),
        throwsA(isA<GeminiApiException>().having((e) => e.statusCode, 'statusCode', 408)),
      );
    });

    test('resolveEffectiveModel returns saved selection if valid in list', () {
      final available = [
        const GeminiModelInfo(name: 'gemini-3.8-flash', displayName: 'Gemini 3.8 Flash', description: '', isRecommended: true),
        const GeminiModelInfo(name: 'gemini-3.1-pro', displayName: 'Gemini 3.1 Pro', description: '', isRecommended: true),
      ];

      final resolved = GeminiModelService.resolveEffectiveModel(
        availableModels: available,
        savedSelection: 'gemini-3.1-pro',
      );
      expect(resolved, equals('gemini-3.1-pro'));
    });

    test('resolveEffectiveModel falls back to recommended model if saved is invalid or null', () {
      final available = [
        const GeminiModelInfo(name: 'gemini-3.8-flash', displayName: 'Gemini 3.8 Flash', description: '', isRecommended: true),
      ];

      final resolvedNull = GeminiModelService.resolveEffectiveModel(availableModels: available, savedSelection: null);
      expect(resolvedNull, equals('gemini-3.8-flash'));

      final resolvedMissing = GeminiModelService.resolveEffectiveModel(availableModels: available, savedSelection: 'deprecated-model-xyz');
      expect(resolvedMissing, equals('gemini-3.8-flash'));
    });

    test('GeminiModelInfo serialization and sentinel copyWith', () {
      const model = GeminiModelInfo(
        name: 'gemini-3.8-flash',
        displayName: 'Gemini 3.8 Flash',
        description: 'Test description',
        isRecommended: true,
        recommendationLabel: 'Fast',
        inputTokenLimit: 1000,
        outputTokenLimit: 500,
      );

      final json = model.toJson();
      final fromJson = GeminiModelInfo.fromJson(json);

      expect(fromJson, equals(model));
      expect(fromJson.name, equals('gemini-3.8-flash'));

      final copied = model.copyWith(recommendationLabel: null);
      expect(copied.recommendationLabel, isNull);
    });
  });
}
