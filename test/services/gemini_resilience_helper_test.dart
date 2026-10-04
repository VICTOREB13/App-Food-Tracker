import 'package:flutter_test/flutter_test.dart';
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
        primaryModel: 'gemini-2.5-flash',
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
        primaryModel: 'gemini-2.5-flash',
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
        primaryModel: 'gemini-2.5-flash',
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

      final promptWithoutScale = GeminiResilienceHelper.buildUserPrompt(
        dishwareDiameterCm: null,
      );
      expect(promptWithoutScale.contains('Escala métrica de referencia'), isFalse);
    });
  });
}
