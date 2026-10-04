import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/services/gemini_resilience_helper.dart';
import 'package:food_tracker/services/gemini_vision_service.dart';

void main() {
  group('Gemini Multimodal Speech and Video Frames Prompt Tests', () {
    test('builds natural speech prompt with transcription directives', () {
      final prompt = GeminiResilienceHelper.buildSpeechUserPrompt(
        userNotes: 'Comí rápido antes de entrenar',
      );

      expect(prompt, contains('El comensal describe por voz natural los alimentos que consumió.'));
      expect(prompt, contains('Escucha minuciosamente el audio, transcribe e identifica'));
      expect(prompt, contains('fibra_g, sodio_mg, azucar_g'));
      expect(prompt, contains('Notas adicionales del comensal: Comí rápido antes de entrenar'));
    });

    test('builds video frames volumetric prompt with 3D and multi-angle directives', () {
      final prompt = GeminiResilienceHelper.buildVideoFramesUserPrompt(
        framesCount: 3,
        userNotes: 'Plato hondo con sopa',
        dishwareDiameterCm: 22.5,
      );

      expect(prompt, contains('Se proporcionan 3 fotogramas clave de video'));
      expect(prompt, contains('inferencia volumétrica tridimensional'));
      expect(prompt, contains('22.5 cm de diámetro'));
      expect(prompt, contains('Notas del comensal: Plato hondo con sopa'));
    });

    test('GeminiVisionService has valid speech and video frame analysis signatures', () {
      final service = GeminiVisionService(apiKey: 'dummy_key');

      expect(service.apiKey, 'dummy_key');
      expect(service.modelName, 'gemini-2.5-flash');

      // Verify methods exist and can be referenced
      expect(service.analyzeSpeechMeal, isA<Function>());
      expect(service.analyzeVideoFramesMeal, isA<Function>());
    });
  });
}
