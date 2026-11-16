import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:food_tracker/core/services/ai/decision_gate_service.dart';
import 'package:food_tracker/core/services/ai/gemini_rest_client.dart';
import 'package:food_tracker/core/services/storage/secure_storage_service.dart';
import 'package:food_tracker/features/food_entry/services/image_processing_service.dart';

class _FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> data = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      data[key] = value;
    } else {
      data.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => data.remove(key);
}

class _DummyImageProcessor extends Fake implements ImageProcessingService {
  @override
  Future<Uint8List> compressAndResizeAsync(
    Uint8List bytes, {
    int targetMaxDimension = 768,
    int quality = 85,
  }) async => bytes;
}

void main() {
  group('DecisionGateService Unit Tests', () {
    late _FakeSecureStorage fakeStorage;
    late SecureStorageService secureStorageService;
    late _DummyImageProcessor dummyImageProcessor;
    final dummyBytes = Uint8List.fromList([1, 2, 3, 4]);

    setUp(() {
      fakeStorage = _FakeSecureStorage();
      secureStorageService = SecureStorageService.withStorage(fakeStorage);
      dummyImageProcessor = _DummyImageProcessor();
    });

    test('Missing BYOK API Key triggers immediate fail-open', () async {
      final service = DecisionGateService(
        secureStorage: secureStorageService,
        imageProcessor: dummyImageProcessor,
      );

      final result = await service.evaluatePhoto(photoBytes: dummyBytes);

      expect(result.failOpen, isTrue);
      expect(result.isFood, isTrue);
      expect(result.reason, contains('API Key de Gemini no configurada'));
    });

    test('Valid photo evaluates 4 questions correctly (is_food, image_quality, dish_complexity, meal_category)', () async {
      await secureStorageService.setGeminiApiKey('AIzaSyValidKey');

      final mockClient = MockClient((request) async {
        final response = {
          'is_food': true,
          'image_quality': 'high',
          'dish_complexity': 'complex',
          'meal_category': 'lunch',
        };
        return http.Response(jsonEncode(response), 200);
      });

      final restClient = GeminiRestClient(client: mockClient);
      final service = DecisionGateService(
        restClient: restClient,
        secureStorage: secureStorageService,
        imageProcessor: dummyImageProcessor,
      );

      final result = await service.evaluatePhoto(photoBytes: dummyBytes, userNotes: 'Almuerzo completo');

      expect(result.failOpen, isFalse);
      expect(result.isFood, isTrue);
      expect(result.imageQuality, equals('high'));
      expect(result.dishComplexity, equals('complex'));
      expect(result.mealCategory, equals('lunch'));
      expect(result.isPass, isTrue);
      expect(result.shouldWarn, isFalse);
      expect(result.recommendedThinkingLevel, equals('HIGH'));
    });

    test('Non-food detection marks shouldWarn and isPass false', () async {
      await secureStorageService.setGeminiApiKey('AIzaSyValidKey');

      final mockClient = MockClient((request) async {
        final response = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': '```json\n{"is_food": false, "image_quality": "high", "dish_complexity": "simple", "meal_category": "snack"}\n```'
                  }
                ]
              }
            }
          ]
        };
        return http.Response(jsonEncode(response), 200);
      });

      final service = DecisionGateService(
        restClient: GeminiRestClient(client: mockClient),
        secureStorage: secureStorageService,
        imageProcessor: dummyImageProcessor,
      );

      final result = await service.evaluatePhoto(photoBytes: dummyBytes);

      expect(result.failOpen, isFalse);
      expect(result.isFood, isFalse);
      expect(result.isPass, isFalse);
      expect(result.shouldWarn, isTrue);
      expect(result.recommendedThinkingLevel, equals('MEDIUM'));
    });

    test('Low image quality triggers warning even when is_food is true', () async {
      await secureStorageService.setGeminiApiKey('AIzaSyValidKey');

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'is_food': true,
            'image_quality': 'low',
            'dish_complexity': 'simple',
            'meal_category': 'dinner',
          }),
          200,
        );
      });

      final service = DecisionGateService(
        restClient: GeminiRestClient(client: mockClient),
        secureStorage: secureStorageService,
        imageProcessor: dummyImageProcessor,
      );

      final result = await service.evaluatePhoto(photoBytes: dummyBytes);

      expect(result.isFood, isTrue);
      expect(result.imageQuality, equals('low'));
      expect(result.isPass, isFalse);
      expect(result.shouldWarn, isTrue);
    });

    test('Timeout exceeding 2500ms activates deterministic fail-open', () async {
      await secureStorageService.setGeminiApiKey('AIzaSyValidKey');

      final mockClient = MockClient((request) async {
        // Exceeds 2500ms
        await Future.delayed(const Duration(milliseconds: 2600));
        return http.Response('{}', 200);
      });

      final service = DecisionGateService(
        restClient: GeminiRestClient(client: mockClient),
        secureStorage: secureStorageService,
        imageProcessor: dummyImageProcessor,
      );

      final result = await service.evaluatePhoto(photoBytes: dummyBytes);

      expect(result.failOpen, isTrue);
      expect(result.isFood, isTrue);
      expect(result.isPass, isTrue);
      expect(result.reason, contains('excedido'));
    });
  });
}
