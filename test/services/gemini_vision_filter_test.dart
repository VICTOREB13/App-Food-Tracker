import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/services/gemini_vision_filter.dart';

void main() {
  group('GeminiVisionFilter Unit Tests', () {
    test('Fallback models list is populated and excludes deprecated gemini-2.0-flash', () {
      const fallbacks = GeminiVisionFilter.fallbackModels;
      expect(fallbacks.length, equals(4));
      expect(fallbacks.any((m) => m.name == 'gemini-3.8-flash'), isTrue);
      expect(fallbacks.any((m) => m.name == 'gemini-3.1-pro'), isTrue);
      expect(fallbacks.any((m) => m.name == 'gemini-2.5-flash'), isTrue);
      expect(fallbacks.any((m) => m.name == 'gemini-1.5-flash'), isTrue);
      expect(fallbacks.any((m) => m.name == 'gemini-2.0-flash'), isFalse);
    });

    test('calculateTierRank prioritizes 3.8-flash and 3.1-pro, and demotes 2.0-flash as obsolete', () {
      expect(GeminiVisionFilter.calculateTierRank('gemini-3.8-flash'), equals(1));
      expect(GeminiVisionFilter.calculateTierRank('gemini-3.1-pro'), equals(2));
      expect(GeminiVisionFilter.calculateTierRank('gemini-2.5-flash'), equals(3));
      expect(GeminiVisionFilter.calculateTierRank('gemini-2.5-pro'), equals(4));
      expect(GeminiVisionFilter.calculateTierRank('gemini-1.5-flash'), equals(5));
      expect(GeminiVisionFilter.calculateTierRank('gemini-2.0-flash'), equals(10));
    });

    test('calculateRecommendationLabel flags 2.0 models as Obsoleto and pro as Think', () {
      expect(GeminiVisionFilter.calculateRecommendationLabel('gemini-3.8-flash'), equals('Fast'));
      expect(GeminiVisionFilter.calculateRecommendationLabel('gemini-3.1-pro'), equals('Think'));
      expect(GeminiVisionFilter.calculateRecommendationLabel('gemini-2.0-flash'), equals('Obsoleto'));
    });

    test('isVisionCapableModel blocks all prohibited keywords and requires flash or pro', () {
      const prohibitedKeywords = [
        'banana', 'nano', 'transcribe', 'omni', 'computer-use', 'robotics',
        'live', 'custom', 'preview-10-2025', 'embedding', 'imagen', 'tts',
        'audio', 'veo', 'bison',
      ];

      for (final keyword in prohibitedKeywords) {
        final blockedModel = {
          'name': 'models/gemini-flash-$keyword',
          'supportedGenerationMethods': ['generateContent'],
        };
        expect(
          GeminiVisionFilter.isVisionCapableModel(blockedModel),
          isFalse,
          reason: 'Model containing "$keyword" should be blocked',
        );
      }

      final noFlashNoPro = {
        'name': 'models/gemini-ultra',
        'supportedGenerationMethods': ['generateContent'],
      };
      expect(GeminiVisionFilter.isVisionCapableModel(noFlashNoPro), isFalse);

      final noGenerate = {
        'name': 'models/gemini-flash',
        'supportedGenerationMethods': ['embedContent'],
      };
      expect(GeminiVisionFilter.isVisionCapableModel(noGenerate), isFalse);

      expect(
        GeminiVisionFilter.isVisionCapableModel({
          'name': 'models/gemini-3.8-flash',
          'supportedGenerationMethods': ['generateContent'],
        }),
        isTrue,
      );
      expect(
        GeminiVisionFilter.isVisionCapableModel({
          'name': 'models/gemini-3.1-pro',
          'supportedGenerationMethods': ['generateContent'],
        }),
        isTrue,
      );
    });

    test('isVisionCapableModel strictly blocks Google AI Studio tuned models and custom models', () {
      expect(
        GeminiVisionFilter.isVisionCapableModel({
          'name': 'tunedModels/nano-banana-pro',
          'displayName': 'Nano Banana Pro',
          'supportedGenerationMethods': ['generateContent'],
          'inputModalities': ['TEXT', 'IMAGE'],
        }),
        isFalse,
      );

      expect(
        GeminiVisionFilter.isVisionCapableModel({
          'name': 'models/gemini-1.5-flash-tuned',
          'baseModel': 'models/gemini-1.5-flash',
          'supportedGenerationMethods': ['generateContent'],
        }),
        isFalse,
      );

      expect(
        GeminiVisionFilter.isVisionCapableModel({
          'name': 'models/gemini-1.5-flash-custom',
          'displayName': 'Nano Banana Pro',
          'supportedGenerationMethods': ['generateContent'],
          'inputModalities': ['TEXT', 'IMAGE'],
        }),
        isFalse,
      );
    });
  });
}
