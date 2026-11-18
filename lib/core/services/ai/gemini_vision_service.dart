import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:food_tracker/features/food_entry/models/food_item.dart';
import 'package:food_tracker/features/food_entry/models/meal_analysis_result.dart';
import 'package:food_tracker/core/interfaces/vision_model_provider_interface.dart';
import 'package:food_tracker/core/services/ai/gemini_model_service.dart';
import 'package:food_tracker/core/services/ai/gemini_resilience_helper.dart';
import 'package:food_tracker/core/services/ai/gemini_rest_client.dart';
import 'package:food_tracker/core/services/ai/decision_gate_service.dart';
import 'package:food_tracker/core/services/ai/gemini_cache_service.dart';
import 'package:food_tracker/core/services/storage/secure_storage_service.dart';
import 'package:food_tracker/features/food_entry/services/image_processing_service.dart';

class GeminiVisionService implements IVisionModelProvider {
  final String apiKey, modelName;
  final String? masterPrompt;
  final GeminiRestClient _restClient;
  final DecisionGateService _decisionGate;
  final GeminiCacheService _cacheService;

  static const String defaultModel = 'gemini-3.8-flash';
  static const String clinicalModel = 'gemini-3.1-pro';
  static const String fallbackModel = 'gemini-3.5-flash-lite';
  static const Duration defaultTimeout = Duration(seconds: 90);
  static const Duration clinicalTimeout = Duration(seconds: 120);

  static const String defaultThinkingLevel = GeminiModelService.defaultThinkingLevel;
  static String? resolveThinkingLevel(String modelName) =>
      GeminiModelService.resolveThinkingLevel(modelName);

  static Map<String, dynamic> buildCallConfig({
    required String modelName, int? customThinkingBudget, String? customThinkingLevel,
  }) => GeminiModelService.buildCallConfig(
    modelName: modelName, customThinkingBudget: customThinkingBudget, customThinkingLevel: customThinkingLevel,
  );

  static const String baseSystemInstruction = GeminiResilienceHelper.baseSystemInstruction;
  static const String systemInstruction = baseSystemInstruction;

  static String buildSystemInstruction([String? masterPrompt, String? pantryContext, String language = 'es']) =>
      GeminiResilienceHelper.buildSystemPrompt(masterPrompt: masterPrompt, pantryContext: pantryContext, language: language);

  GeminiVisionService({
    required this.apiKey,
    this.modelName = defaultModel,
    this.masterPrompt,
    GeminiRestClient? restClient,
    DecisionGateService? decisionGate,
    GeminiCacheService? cacheService,
  })  : _restClient = restClient ?? GeminiRestClient.instance,
        _decisionGate = decisionGate ?? DecisionGateService.instance,
        _cacheService = cacheService ?? GeminiCacheService.instance;

  static Duration resolveTimeout(String modelName) =>
      GeminiModelService.supportsThinking(modelName) ? clinicalTimeout : defaultTimeout;

  static String userFriendlyErrorMessage(dynamic error) {
    if (error == null) return 'Ocurrió un error al analizar la comida. Por favor, inténtalo nuevamente.';
    final s = error.toString().toLowerCase();
    if (error is String && (s.startsWith('se perdió') || s.startsWith('tu api key') || s.startsWith('has alcanzado') || s.startsWith('la ia no') || s.startsWith('ocurrió') || s.startsWith('el tiempo'))) return error;
    if (error is TimeoutException || s.contains('timeout')) return 'El tiempo de espera de análisis se agotó. Se perdió la conexión a internet temporalmente. Por favor, reintenta o usa registro manual.';
    if (error is SocketException || s.contains('socket') || s.contains('clientexception') || s.contains('unreachable') || s.contains('lookup')) return 'Se perdió la conexión a internet. Por favor, verifica tu red e inténtalo de nuevo.';
    if (s.contains('api key') || s.contains('permission_denied') || s.contains('401') || s.contains('403')) return 'Tu API Key de Gemini no es válida o no tiene permisos suficientes. Verifícala en Ajustes.';
    if (s.contains('429') || s.contains('resource_exhausted') || s.contains('quota') || s.contains('rate limit')) return 'Has alcanzado el límite de solicitudes de Gemini. Por favor, espera unos segundos e inténtalo de nuevo.';
    if (s.contains('safety') || s.contains('blocked') || s.contains('vacía') || s.contains('empty') || s.contains('no logr')) return 'La IA no logró identificar alimentos en la foto. Intenta con una toma más cercana o mejor iluminación.';
    return 'Ocurrió un error al analizar la comida. Por favor, inténtalo nuevamente.';
  }

  Future<MealAnalysisResult> analyzeMealImage(
    Uint8List imageBytes, {
    String? userContext, String? overrideModel, String? overrideMasterPrompt,
    double? dishwareDiameterCm, String? pantryContext,
    String language = 'es',
  }) => analyzeMealPhoto(
    rawImageBytes: imageBytes, userContext: userContext, overrideModel: overrideModel,
    overrideMasterPrompt: overrideMasterPrompt, dishwareDiameterCm: dishwareDiameterCm,
    pantryContext: pantryContext, language: language,
  );

  Future<String> _resolveEffectiveThinking(String recommended) async {
    final userSetting = await SecureStorageService.instance.getThinkingLevel();
    final normalized = userSetting?.toUpperCase().trim() ?? 'AUTO';
    return normalized == 'AUTO' ? recommended : normalized;
  }

  @override
  Future<MealAnalysisResult> analyzeMealPhoto({
    required Uint8List rawImageBytes,
    String? userContext, String? overrideModel, String? overrideMasterPrompt,
    double? dishwareDiameterCm, String? pantryContext,
    String language = 'es',
  }) async {
    try {
      final imageToSend = await _prepareImageBytes(rawImageBytes);
      final initialModel = (overrideModel != null && overrideModel.trim().isNotEmpty) ? overrideModel.trim() : modelName;

      final decision = await _decisionGate.evaluatePhoto(photoBytes: imageToSend, userNotes: userContext);
      final effectivePrompt = overrideMasterPrompt ?? masterPrompt;
      final cachedName = await _cacheService.getOrCreateCachedContext(
        model: initialModel, masterPrompt: effectivePrompt ?? '', pantryContext: pantryContext,
      );

      final instruction = buildSystemInstruction(effectivePrompt, pantryContext, language);
      final userPrompt = GeminiResilienceHelper.buildUserPrompt(
        userContext: userContext, dishwareDiameterCm: dishwareDiameterCm, language: language,
      );
      final parts = <Map<String, dynamic>>[
        {'text': userPrompt},
        {'inlineData': {'mimeType': 'image/jpeg', 'data': base64Encode(imageToSend)}},
      ];

      final thinking = await _resolveEffectiveThinking(decision.recommendedThinkingLevel);
      return await _executeGenerativeContent(
        parts: parts, systemInstruction: instruction, initialModel: initialModel,
        thinkingLevel: thinking, cachedContent: cachedName,
      );
    } catch (e) {
      throw Exception(userFriendlyErrorMessage(e));
    }
  }

  @override
  Future<MealAnalysisResult> reanalyzeWithIngredientSubstitution({
    required Uint8List rawImageBytes, required List<FoodItem> currentItems,
    required String oldIngredient, required String newIngredient,
    String? userNotes, double? dishwareDiameterCm, String? pantryContext, String? overrideModel,
    String language = 'es',
  }) async {
    try {
      final imageToSend = await _prepareImageBytes(rawImageBytes);
      final initialModel = (overrideModel != null && overrideModel.trim().isNotEmpty) ? overrideModel.trim() : modelName;
      final instruction = buildSystemInstruction(masterPrompt, pantryContext, language);
      final summary = currentItems.map((i) => '${i.name} (${i.estimatedGrams.toStringAsFixed(0)}g)').toList();
      final userPrompt = GeminiResilienceHelper.buildSubstitutionUserPrompt(
        currentItemsSummary: summary, oldIngredient: oldIngredient,
        newIngredient: newIngredient, userNotes: userNotes, dishwareDiameterCm: dishwareDiameterCm,
        language: language,
      );
      return await _executeGenerativeContent(
        parts: [{'text': userPrompt}, {'inlineData': {'mimeType': 'image/jpeg', 'data': base64Encode(imageToSend)}}],
        systemInstruction: instruction, initialModel: initialModel,
      );
    } catch (e) {
      throw Exception(userFriendlyErrorMessage(e));
    }
  }

  @override
  Future<MealAnalysisResult> analyzeSpeechMeal({
    required Uint8List audioBytes, String mimeType = 'audio/mp3',
    String? userNotes, String? overrideModel,
    String language = 'es',
  }) async {
    try {
      final initialModel = (overrideModel != null && overrideModel.trim().isNotEmpty) ? overrideModel.trim() : modelName;
      final prompt = GeminiResilienceHelper.buildSpeechUserPrompt(userNotes: userNotes);
      return await _executeGenerativeContent(
        parts: [{'text': prompt}, {'inlineData': {'mimeType': mimeType, 'data': base64Encode(audioBytes)}}],
        systemInstruction: buildSystemInstruction(masterPrompt, null, language), initialModel: initialModel,
      );
    } catch (e) {
      throw Exception(userFriendlyErrorMessage(e));
    }
  }

  /// Direct text inference without multimodal fake audio payloads.
  Future<MealAnalysisResult> analyzeMealText({
    required String textPrompt,
    String? overrideModel,
    String? thinkingLevel,
    String language = 'es',
  }) async {
    try {
      final initialModel = (overrideModel != null && overrideModel.trim().isNotEmpty)
          ? overrideModel.trim()
          : modelName;
      final prompt = GeminiResilienceHelper.buildSpeechUserPrompt(userNotes: textPrompt);
      return await _executeGenerativeContent(
        parts: [{'text': prompt}],
        systemInstruction: buildSystemInstruction(masterPrompt, null, language),
        initialModel: initialModel,
        thinkingLevel: thinkingLevel,
      );
    } catch (e) {
      throw Exception(userFriendlyErrorMessage(e));
    }
  }

  @override
  Future<MealAnalysisResult> analyzeVideoFramesMeal({
    required List<Uint8List> frameBytesList, String? userNotes,
    double? dishwareDiameterCm, String? pantryContext, String? overrideModel,
  }) async {
    try {
      final initialModel = (overrideModel != null && overrideModel.trim().isNotEmpty) ? overrideModel.trim() : modelName;
      final prompt = GeminiResilienceHelper.buildVideoFramesUserPrompt(
        framesCount: frameBytesList.length, userNotes: userNotes, dishwareDiameterCm: dishwareDiameterCm,
      );
      final parts = <Map<String, dynamic>>[{'text': prompt}];
      for (final frame in frameBytesList) {
        final prep = await _prepareImageBytes(frame);
        parts.add({'inlineData': {'mimeType': 'image/jpeg', 'data': base64Encode(prep)}});
      }
      return await _executeGenerativeContent(
        parts: parts, systemInstruction: buildSystemInstruction(masterPrompt, pantryContext), initialModel: initialModel,
      );
    } catch (e) {
      throw Exception(userFriendlyErrorMessage(e));
    }
  }

  Future<Uint8List> _prepareImageBytes(Uint8List rawBytes) async {
    return await ImageProcessingService.instance.compressAndResizeAsync(
      rawBytes, targetMaxDimension: 768, quality: 85,
    );
  }

  Future<MealAnalysisResult> _executeGenerativeContent({
    required List<Map<String, dynamic>> parts, required String systemInstruction,
    required String initialModel, String? thinkingLevel, String? cachedContent,
  }) async {
    final contents = [{'role': 'user', 'parts': parts}];
    final schema = GeminiResilienceHelper.mealAnalysisSchema.toMap();

    return await GeminiResilienceHelper.executeWithRetry<MealAnalysisResult>(
      primaryModel: initialModel, secondaryModel: GeminiVisionService.fallbackModel,
      action: (attempt, currentModel) async {
        final timeout = resolveTimeout(currentModel);
        final isSwitched = currentModel != initialModel;
        final effectiveCached = isSwitched ? null : cachedContent;
        final systemMap = (effectiveCached != null && effectiveCached.isNotEmpty)
            ? null
            : {'parts': [{'text': systemInstruction}]};
        final genConfig = GeminiRestClient.buildGenerationConfig(
          model: currentModel, thinkingLevel: thinkingLevel, temperature: 1.0, maxOutputTokens: 16384,
          responseMimeType: 'application/json', responseSchema: schema,
        );
        final buffer = StringBuffer();
        bool isPartial = false;
        try {
          final stream = _restClient.streamGenerateContent(
            apiKey: apiKey, model: currentModel, contents: contents,
            systemInstruction: systemMap, generationConfig: genConfig,
            cachedContent: effectiveCached, timeout: timeout,
          );
          await for (final chunk in stream.timeout(timeout)) {
            if (chunk.isNotEmpty) buffer.write(chunk);
          }
        } catch (streamErr) {
          debugPrint('GeminiVisionService: SSE cut ($streamErr), fallback unary');
          buffer.clear();
          final unaryRes = await _restClient.generateContent(
            apiKey: apiKey, model: currentModel, contents: contents,
            systemInstruction: systemMap, generationConfig: genConfig,
            cachedContent: effectiveCached, timeout: timeout,
          );
          buffer.write(unaryRes);
        }

        var text = buffer.toString().trim();
        if (text.isEmpty) {
          text = await _restClient.generateContent(
            apiKey: apiKey, model: currentModel, contents: contents,
            systemInstruction: systemMap, generationConfig: genConfig,
            cachedContent: effectiveCached, timeout: timeout,
          );
        }
        if (text.isEmpty) throw Exception('Gemini devolvió una respuesta vacía');
        final result = MealAnalysisResult.fromJsonString(
          text,
          isPartial: isPartial,
          modelUsed: currentModel,
          isFallback: isSwitched,
          thinkingLevel: thinkingLevel,
        );
        if (result.items.isEmpty && result.totalCalories == 0) {
          throw FormatException('No se pudieron extraer alimentos del análisis estructurado: $text');
        }
        return result;
      },
    );
  }
}
