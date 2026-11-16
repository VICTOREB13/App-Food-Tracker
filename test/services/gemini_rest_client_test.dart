import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:food_tracker/core/errors/gemini_api_exception.dart';
import 'package:food_tracker/core/services/ai/gemini_rest_client.dart';

void main() {
  group('GeminiRestClient Unit Tests', () {
    const testApiKey = '  test-secret-key-123  ';
    const cleanApiKey = 'test-secret-key-123';

    test('buildGenerationConfig injects thinkingConfig for Gemini 3.x and 4.x', () {
      final configG4 = GeminiRestClient.buildGenerationConfig(model: 'gemini-4-hydrogem');
      expect(configG4['temperature'], equals(1.0));
      expect(configG4['maxOutputTokens'], equals(16384));
      expect(configG4['thinkingConfig'], equals({'thinkingLevel': 'MEDIUM'}));

      final configG3 = GeminiRestClient.buildGenerationConfig(
        model: 'gemini-3.8-flash',
        thinkingLevel: 'HIGH',
      );
      expect(configG3['thinkingConfig'], equals({'thinkingLevel': 'HIGH'}));

      final configLite = GeminiRestClient.buildGenerationConfig(model: 'gemini-3.5-flash-lite');
      expect(configLite.containsKey('thinkingConfig'), isFalse);
    });

    test('generateContent sends valid headers and extracts candidate text', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['x-goog-api-key'], equals(cleanApiKey));
        expect(request.headers['Content-Type'], equals('application/json'));
        expect(request.url.toString(), contains('/models/gemini-3.8-flash:generateContent'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['contents'], isNotEmpty);

        final responsePayload = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': '{"plato": "Pollo al horno"}'}
                ]
              }
            }
          ]
        };
        return http.Response(jsonEncode(responsePayload), 200);
      });

      final client = GeminiRestClient(client: mockClient);
      final text = await client.generateContent(
        apiKey: testApiKey,
        model: 'gemini-3.8-flash',
        contents: [
          {
            'parts': [
              {'text': 'Analiza este plato'}
            ]
          }
        ],
      );

      expect(text, equals('{"plato": "Pollo al horno"}'));
    });

    test('generateContent throws GeminiApiException on HTTP error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": {"message": "Invalid API key"}}', 400);
      });

      final client = GeminiRestClient(client: mockClient);
      expect(
        () => client.generateContent(
          apiKey: testApiKey,
          model: 'gemini-3.8-flash',
          contents: [],
        ),
        throwsA(isA<GeminiApiException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('streamGenerateContent yields SSE chunks and ignores [DONE]', () async {
      final mockClient = MockClient.streaming((request, bodyStream) async {
        expect(request.headers['x-goog-api-key'], equals(cleanApiKey));
        expect(request.url.toString(), contains('streamGenerateContent?alt=sse'));

        final sseData = 'data: {"candidates":[{"content":{"parts":[{"text":"Parte 1"}]}}]}\n\n'
            'data: {"candidates":[{"content":{"parts":[{"text":" y Parte 2"}]}}]}\n\n'
            'data: [DONE]\n\n';

        final stream = Stream<List<int>>.fromIterable([utf8.encode(sseData)]);
        return http.StreamedResponse(stream, 200);
      });

      final client = GeminiRestClient(client: mockClient);
      final stream = client.streamGenerateContent(
        apiKey: testApiKey,
        model: 'gemini-3.8-flash',
        contents: [],
      );

      final chunks = await stream.toList();
      expect(chunks, equals(['Parte 1', ' y Parte 2']));
    });

    test('streamGenerateContent triggers silent unary fallback on SSE stream cut', () async {
      int requestCount = 0;
      final mockClient = MockClient.streaming((request, bodyStream) async {
        requestCount++;
        if (request.url.toString().contains('streamGenerateContent')) {
          // Socket cut / broken stream
          final controller = StreamController<List<int>>();
          controller.addError(const http.ClientException('SSE stream interrupted'));
          return http.StreamedResponse(controller.stream, 200);
        } else {
          // Unary fallback
          final responsePayload = {
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Resultado desde Unary Fallback'}
                  ]
                }
              }
            ]
          };
          final stream = Stream<List<int>>.fromIterable([utf8.encode(jsonEncode(responsePayload))]);
          return http.StreamedResponse(stream, 200);
        }
      });

      final client = GeminiRestClient(client: mockClient);
      final chunks = await client.streamGenerateContent(
        apiKey: testApiKey,
        model: 'gemini-3.8-flash',
        contents: [],
      ).toList();

      expect(chunks, equals(['Resultado desde Unary Fallback']));
      expect(requestCount, equals(2));
    });

    test('postDecision posts to /decisions and falls back to gemini-decision-1 on 404', () async {
      int postCount = 0;
      final mockClient = MockClient((request) async {
        postCount++;
        if (request.url.toString().endsWith('/decisions')) {
          return http.Response('{"error": "Endpoint not found"}', 404);
        }
        if (request.url.toString().contains('gemini-decision-1:generateContent')) {
          return http.Response(
            jsonEncode({
              'is_food': true,
              'image_quality': 'high',
              'dish_complexity': 'simple',
              'meal_category': 'lunch',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = GeminiRestClient(client: mockClient);
      final decision = await client.postDecision(
        apiKey: testApiKey,
        body: {'query': 'test'},
      );

      expect(decision['is_food'], isTrue);
      expect(decision['meal_category'], equals('lunch'));
      expect(postCount, equals(2));
    });

    test('createCachedContent, getCachedContent, and deleteCachedContent execute properly', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['x-goog-api-key'], equals(cleanApiKey));
        if (request.method == 'POST' && request.url.path.endsWith('/cachedContents')) {
          return http.Response(jsonEncode({'name': 'cachedContents/12345'}), 200);
        }
        if (request.method == 'GET' && request.url.path.endsWith('/cachedContents/12345')) {
          return http.Response(jsonEncode({'name': 'cachedContents/12345', 'model': 'gemini-3.8-flash'}), 200);
        }
        if (request.method == 'DELETE' && request.url.path.endsWith('/cachedContents/12345')) {
          return http.Response('', 200);
        }
        return http.Response('Not Found', 404);
      });

      final client = GeminiRestClient(client: mockClient);
      final created = await client.createCachedContent(apiKey: testApiKey, body: {'test': true});
      expect(created['name'], equals('cachedContents/12345'));

      final retrieved = await client.getCachedContent(apiKey: testApiKey, name: 'cachedContents/12345');
      expect(retrieved['model'], equals('gemini-3.8-flash'));

      await expectLater(
        client.deleteCachedContent(apiKey: testApiKey, name: 'cachedContents/12345'),
        completes,
      );
    });
  });
}
