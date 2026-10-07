import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/food_item.dart';
import '../models/meal_analysis_result.dart';
import 'gemini_model_service.dart';
import 'gemini_resilience_helper.dart';
import 'image_processing_service.dart';

export '../models/meal_analysis_result.dart';

class GeminiVisionService {
  final String apiKey;
  final String modelName;
  final String? masterPrompt;

  static const String defaultModel = 'gemini-3.8-flash';
  static const String clinicalModel = 'gemini-3.1-pro';
  static const String fallbackModel = 'gemini-2.5-flash';

  static const Duration defaultTimeout = Duration(seconds: 90);
  static const Duration clinicalTimeout = Duration(seconds: 120);

  static const String baseSystemInstruction = GeminiResilienceHelper.baseSystemInstruction;
  static const String systemInstruction = baseSystemInstruction;

  static String buildSystemInstruction([String? masterPrompt, String? pantryContext]) =>
      GeminiResilienceHelper.buildSystemPrompt(masterPrompt: masterPrompt, pantryContext: pantryContext);

  GeminiVisionService({
    required this.apiKey,
    this.modelName = defaultModel,
    this.masterPrompt,
  });

  /// Resolves the network timeout based on model tier and reasoning capacity (90s - 120s)
  static Duration resolveTimeout(String modelName) =>
      GeminiModelService.supportsThinking(modelName) ? clinicalTimeout : defaultTimeout;

  static String userFriendlyErrorMessage(dynamic error) {
    if (error == null) return 'Ocurrió un error al analizar la comida. Por favor, inténtalo nuevamente.';
    final s = error.toString().toLowerCase();

    if (error is String && (s.startsWith('se perdió la conexión') ||
        s.startsWith('tu api key') || s.startsWith('has alcanzado el límite') ||
        s.startsWith('la ia no logró') || s.startsWith('ocurrió un error') ||
        s.startsWith('el tiempo de espera'))) {
      return error;
    }
    if (error is TimeoutException || s.contains('timeoutexception') || s.contains('timed out')) {
      return 'El tiempo de espera de análisis se agotó (la red tardó demasiado). Se perdió la conexión a internet temporalmente. Por favor, reintenta o usa registro manual.';
    }
    if (error is SocketException || s.contains('socketexception') || s.contains('clientexception') ||
        s.contains('unreachable') || s.contains('lookup') || s.contains('refused')) {
      return 'Se perdió la conexión a internet. Por favor, verifica tu red e inténtalo de nuevo.';
    }
    if (s.contains('api key') || s.contains('permission_denied') || s.contains('unauthenticated') ||
        s.contains('401') || s.contains('403') || (s.contains('400') && !s.contains('safety'))) {
      return 'Tu API Key de Gemini no es válida o no tiene permisos suficientes. Verifícala en Ajustes.';
    }
    if (s.contains('429') || s.contains('resource_exhausted') || s.contains('quota') || s.contains('rate limit')) {
      return 'Has alcanzado el límite de solicitudes de Gemini. Por favor, espera unos segundos e inténtalo de nuevo.';
    }
    if (s.contains('safety') || s.contains('recitation') || s.contains('blocked') ||
        s.contains('vacía') || s.contains('empty') || s.contains('no logr') || s.contains('alimentos')) {
      return 'La IA no logró identificar alimentos en la foto. Intenta con una toma más cercana, con mejor iluminación o ángulo superior.';
    }
    return 'Ocurrió un error al analizar la comida. Por favor, inténtalo nuevamente.';
  }

  Future<MealAnalysisResult> analyzeMealImage(
    Uint8List imageBytes, {
    String? userContext,
    String? overrideModel,
    String? overrideMasterPrompt,
    double? dishwareDiameterCm,
    String? pantryContext,
  }) => analyzeMealPhoto(
    rawImageBytes: imageBytes,
    userContext: userContext,
    overrideModel: overrideModel,
    overrideMasterPrompt: overrideMasterPrompt,
    dishwareDiameterCm: dishwareDiameterCm,
    pantryContext: pantryContext,
  );

  Future<MealAnalysisResult> analyzeMealPhoto({
    required Uint8List rawImageBytes,
    String? userContext,
    String? overrideModel,
    String? overrideMasterPrompt,
    double? dishwareDiameterCm,
    String? pantryContext,
  }) async {
    try {
      final imageBytesToSend = await _prepareImageBytes(rawImageBytes);
      final initialModel = (overrideModel != null && overrideModel.trim().isNotEmpty)
          ? overrideModel.trim()
          : modelName;

      final effectivePrompt = overrideMasterPrompt ?? masterPrompt;
      final effectiveInstruction = buildSystemInstruction(effectivePrompt, pantryContext);
      final userPromptText = GeminiResilienceHelper.buildUserPrompt(
        userContext: userContext,
        dishwareDiameterCm: dishwareDiameterCm,
      );

      return await _executeGenerativeContent(
        parts: [TextPart(userPromptText), DataPart('image/jpeg', imageBytesToSend)],
        systemInstruction: effectiveInstruction,
        initialModel: initialModel,
      );
    } catch (e) {
      throw Exception(userFriendlyErrorMessage(e));
    }
  }

  Future<MealAnalysisResult> reanalyzeWithIngredientSubstitution({
    required Uint8List rawImageBytes,
    required List<FoodItem> currentItems,
    required String oldIngredient,
    required String newIngredient,
    String? userNotes,
    double? dishwareDiameterCm,
    String? pantryContext,
    String? overrideModel,
  }) async {
    try {
      final imageBytesToSend = await _prepareImageBytes(rawImageBytes);
      final initialModel = (overrideModel != null && overrideModel.trim().isNotEmpty)
          ? overrideModel.trim()
          : modelName;

      final effectiveInstruction = buildSystemInstruction(masterPrompt, pantryContext);
      final itemsSummary = currentItems
          .map((i) => '${i.name} (${i.estimatedGrams.toStringAsFixed(0)}g - ${i.calories.toStringAsFixed(0)} kcal)')
          .toList();

      final userPromptText = GeminiResilienceHelper.buildSubstitutionUserPrompt(
        currentItemsSummary: itemsSummary,
        oldIngredient: oldIngredient,
        newIngredient: newIngredient,
        userNotes: userNotes,
        dishwareDiameterCm: dishwareDiameterCm,
      );

      return await _executeGenerativeContent(
        parts: [TextPart(userPromptText), DataPart('image/jpeg', imageBytesToSend)],
        systemInstruction: effectiveInstruction,
        initialModel: initialModel,
      );
    } catch (e) {
      throw Exception(userFriendlyErrorMessage(e));
    }
  }

  Future<MealAnalysisResult> analyzeSpeechMeal({
    required Uint8List audioBytes,
    String mimeType = 'audio/mp3',
    String? userNotes,
    String? overrideModel,
  }) async {
    try {
      final initialModel = (overrideModel != null && overrideModel.trim().isNotEmpty)
          ? overrideModel.trim()
          : modelName;

      final promptText = GeminiResilienceHelper.buildSpeechUserPrompt(userNotes: userNotes);
      final effectiveInstruction = buildSystemInstruction(masterPrompt);

      return await _executeGenerativeContent(
        parts: [TextPart(promptText), DataPart(mimeType, audioBytes)],
        systemInstruction: effectiveInstruction,
        initialModel: initialModel,
      );
    } catch (e) {
      throw Exception(userFriendlyErrorMessage(e));
    }
  }

  Future<MealAnalysisResult> analyzeVideoFramesMeal({
    required List<Uint8List> frameBytesList,
    String? userNotes,
    double? dishwareDiameterCm,
    String? pantryContext,
    String? overrideModel,
  }) async {
    try {
      final initialModel = (overrideModel != null && overrideModel.trim().isNotEmpty)
          ? overrideModel.trim()
          : modelName;

      final effectiveInstruction = buildSystemInstruction(masterPrompt, pantryContext);
      final promptText = GeminiResilienceHelper.buildVideoFramesUserPrompt(
        framesCount: frameBytesList.length,
        userNotes: userNotes,
        dishwareDiameterCm: dishwareDiameterCm,
      );

      final preparedParts = <Part>[TextPart(promptText)];
      for (final frame in frameBytesList) {
        preparedParts.add(DataPart('image/jpeg', await _prepareImageBytes(frame)));
      }

      return await _executeGenerativeContent(
        parts: preparedParts,
        systemInstruction: effectiveInstruction,
        initialModel: initialModel,
      );
    } catch (e) {
      throw Exception(userFriendlyErrorMessage(e));
    }
  }

  Future<Uint8List> _prepareImageBytes(Uint8List rawBytes) async {
    final fastDims = _getFastDimensions(rawBytes);
    if (fastDims == null || fastDims.$1 > 768 || fastDims.$2 > 768) {
      return await ImageProcessingService.instance.compressAndResizeAsync(
        rawBytes,
        targetMaxDimension: 768,
        quality: 85,
      );
    }
    return rawBytes;
  }

  Future<MealAnalysisResult> _executeGenerativeContent({
    required List<Part> parts,
    required String systemInstruction,
    required String initialModel,
  }) async {
    final content = Content.multi(parts);

    return await GeminiResilienceHelper.executeWithRetry<MealAnalysisResult>(
      primaryModel: initialModel,
      secondaryModel: fallbackModel,
      action: (attempt, currentModel) async {
        final model = GenerativeModel(
          model: currentModel,
          apiKey: apiKey,
          systemInstruction: Content.system(systemInstruction),
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            responseSchema: GeminiResilienceHelper.mealAnalysisSchema,
            temperature: 0.2,
            maxOutputTokens: 8192,
          ),
        );

        final timeoutDuration = resolveTimeout(currentModel);
        final responseStream = model.generateContentStream([content]);
        final buffer = StringBuffer();
        await for (final chunk in responseStream.timeout(timeoutDuration)) {
          final chunkText = chunk.text;
          if (chunkText != null && chunkText.isNotEmpty) {
            buffer.write(chunkText);
          }
        }

        final text = buffer.toString().trim();
        if (text.isEmpty) {
          throw Exception('Gemini devolvió una respuesta vacía');
        }

        return MealAnalysisResult.fromJsonString(text);
      },
    );
  }

  static (int, int)? _getFastDimensions(Uint8List bytes) {
    if (bytes.length < 30) return null;
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      final width = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
      final height = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
      return (width, height);
    }
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      int offset = 2;
      while (offset + 8 < bytes.length) {
        if (bytes[offset] != 0xFF) break;
        final marker = bytes[offset + 1];
        if (marker == 0xC0 || marker == 0xC1 || marker == 0xC2) {
          final height = (bytes[offset + 5] << 8) | bytes[offset + 6];
          final width = (bytes[offset + 7] << 8) | bytes[offset + 8];
          return (width, height);
        }
        offset += 2 + ((bytes[offset + 2] << 8) | bytes[offset + 3]);
      }
    }
    return null;
  }
}
