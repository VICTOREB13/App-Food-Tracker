import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:food_tracker/core/interfaces/decision_gate_service_interface.dart';
import 'package:food_tracker/core/services/ai/gemini_rest_client.dart';
import 'package:food_tracker/core/services/storage/secure_storage_service.dart';
import 'package:food_tracker/features/food_entry/services/image_processing_service.dart';

export 'package:food_tracker/core/interfaces/decision_gate_service_interface.dart';

/// Pre-gate decision service using 'gemini-decision-1'.
/// Sends a 768px photo with 4 questions: is_food, image_quality, dish_complexity, meal_category.
/// Enforces strict BYOK and fails open on timeout (>2500ms) or network drops.
class DecisionGateService implements IDecisionGateService {
  final GeminiRestClient _restClient;
  final SecureStorageService _secureStorage;
  final ImageProcessingService _imageProcessor;

  static const String decisionModel = 'gemini-decision-1';
  static const Duration timeoutDuration = Duration(milliseconds: 2500);

  DecisionGateService({
    GeminiRestClient? restClient,
    SecureStorageService? secureStorage,
    ImageProcessingService? imageProcessor,
  })  : _restClient = restClient ?? GeminiRestClient.instance,
        _secureStorage = secureStorage ?? SecureStorageService.instance,
        _imageProcessor = imageProcessor ?? ImageProcessingService.instance;

  static final DecisionGateService instance = DecisionGateService();

  @override
  Future<DecisionGateResult> evaluatePhoto({
    required Uint8List photoBytes,
    String? userNotes,
  }) async {
    final apiKey = await _secureStorage.getGeminiApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      debugPrint('DecisionGateService: API key not configured, failing open');
      return DecisionGateResult.failOpen(
        reason: 'API Key de Gemini no configurada. Configúrala en Ajustes.',
      );
    }

    try {
      final preparedBytes = await _ensureMax768(photoBytes);
      final base64Image = base64Encode(preparedBytes);

      final prompt = _buildDecisionPrompt(userNotes);
      final payload = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'responseMimeType': 'application/json',
          'maxOutputTokens': 256,
        }
      };

      final response = await _restClient
          .postDecision(
            apiKey: apiKey.trim(),
            body: payload,
            timeout: timeoutDuration,
          )
          .timeout(timeoutDuration);

      return _parseDecisionResponse(response);
    } on TimeoutException {
      debugPrint('DecisionGateService: Timed out (>2500ms), failing open');
      return DecisionGateResult.failOpen(reason: 'Tiempo de evaluación excedido (>2.5s).');
    } catch (e) {
      debugPrint('DecisionGateService: Error evaluating photo ($e), failing open');
      return DecisionGateResult.failOpen(reason: e.toString());
    }
  }

  Future<Uint8List> _ensureMax768(Uint8List bytes) async {
    try {
      return await _imageProcessor.compressAndResizeAsync(
        bytes,
        targetMaxDimension: 768,
        quality: 85,
      );
    } catch (_) {
      return bytes;
    }
  }

  String _buildDecisionPrompt(String? userNotes) {
    final notes = (userNotes != null && userNotes.trim().isNotEmpty)
        ? ' Contexto del usuario: "$userNotes".'
        : '';
    return 'Evalúa esta imagen para análisis nutricional.$notes '
        'Responde ÚNICAMENTE en JSON con este esquema exacto:\n'
        '{\n'
        '  "is_food": true,\n'
        '  "image_quality": "high",\n'
        '  "dish_complexity": "simple",\n'
        '  "meal_category": "lunch"\n'
        '}\n'
        'Reglas:\n'
        '- is_food (bool): true si hay comida/bebida, false si no hay alimentos.\n'
        '- image_quality (string): "high", "medium" o "low".\n'
        '- dish_complexity (string): "simple" (1-2 ingredientes) o "complex" (elaborado/múltiples).\n'
        '- meal_category (string): "breakfast", "lunch", "dinner", "snack".';
  }

  DecisionGateResult _parseDecisionResponse(Map<String, dynamic> response) {
    try {
      if (response.containsKey('is_food') || response.containsKey('isFood')) {
        return DecisionGateResult.fromJson(response);
      }
      final candidates = response['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates.first['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts.first['text'] as String?;
          if (text != null && text.trim().isNotEmpty) {
            final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
            final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
            return DecisionGateResult.fromJson(decoded);
          }
        }
      }
      return DecisionGateResult.fromJson(response);
    } catch (e) {
      debugPrint('DecisionGateService: Fallback parsing JSON: $e');
      return DecisionGateResult.failOpen(reason: 'Respuesta de decisión no interpretable');
    }
  }
}
