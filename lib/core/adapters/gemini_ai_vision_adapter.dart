import 'dart:typed_data';
import 'package:food_tracker/features/food_entry/models/food_item.dart';
import 'package:food_tracker/features/food_entry/models/meal_analysis_result.dart';
import 'package:food_tracker/core/services/ai/gemini_vision_service.dart';
import 'package:food_tracker/core/services/storage/secure_storage_service.dart';
import '../interfaces/vision_model_provider_interface.dart';
import '../ports/ai_vision_port.dart';

/// Multimodal Gemini implementation adapter for the [IAiVisionPort] hexagonal contract.
class GeminiAiVisionAdapter implements IAiVisionPort {
  final SecureStorageService _storage;
  final IVisionModelProvider? _providedService;

  GeminiAiVisionAdapter({
    SecureStorageService? storage,
    IVisionModelProvider? visionModelProvider,
  })  : _storage = storage ?? SecureStorageService.instance,
        _providedService = visionModelProvider;

  Future<IVisionModelProvider> _resolveProvider({
    String? overrideModel,
    String? overrideMasterPrompt,
  }) async {
    if (_providedService != null) return _providedService!;

    final apiKey = await _storage.getGeminiApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw StateError(
        'Tu API Key de Gemini no está configurada. Por favor regístrala en Ajustes.',
      );
    }

    final selectedModel = await _storage.getSelectedGeminiModel();
    final masterPrompt = await _storage.getMasterPrompt();

    return GeminiVisionService(
      apiKey: apiKey.trim(),
      modelName: overrideModel ?? selectedModel ?? GeminiVisionService.defaultModel,
      masterPrompt: overrideMasterPrompt ?? masterPrompt,
    );
  }

  @override
  Future<MealAnalysisResult> analyzeMealPhoto({
    required Uint8List rawImageBytes,
    String? userContext,
    String? overrideModel,
    String? overrideMasterPrompt,
    double? dishwareDiameterCm,
    String? pantryContext,
  }) async {
    final provider = await _resolveProvider(
      overrideModel: overrideModel,
      overrideMasterPrompt: overrideMasterPrompt,
    );
    return await provider.analyzeMealPhoto(
      rawImageBytes: rawImageBytes,
      userContext: userContext,
      overrideModel: overrideModel,
      overrideMasterPrompt: overrideMasterPrompt,
      dishwareDiameterCm: dishwareDiameterCm,
      pantryContext: pantryContext,
    );
  }

  @override
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
    final provider = await _resolveProvider(overrideModel: overrideModel);
    return await provider.reanalyzeWithIngredientSubstitution(
      rawImageBytes: rawImageBytes,
      currentItems: currentItems,
      oldIngredient: oldIngredient,
      newIngredient: newIngredient,
      userNotes: userNotes,
      dishwareDiameterCm: dishwareDiameterCm,
      pantryContext: pantryContext,
      overrideModel: overrideModel,
    );
  }

  @override
  Future<MealAnalysisResult> analyzeSpeechMeal({
    required Uint8List audioBytes,
    String mimeType = 'audio/m4a',
    String? userNotes,
    String? overrideModel,
  }) async {
    final provider = await _resolveProvider(overrideModel: overrideModel);
    return await provider.analyzeSpeechMeal(
      audioBytes: audioBytes,
      mimeType: mimeType,
      userNotes: userNotes,
      overrideModel: overrideModel,
    );
  }

  @override
  Future<MealAnalysisResult> analyzeVideoFramesMeal({
    required List<Uint8List> frameBytesList,
    String? userNotes,
    double? dishwareDiameterCm,
    String? pantryContext,
    String? overrideModel,
  }) async {
    final provider = await _resolveProvider(overrideModel: overrideModel);
    return await provider.analyzeVideoFramesMeal(
      frameBytesList: frameBytesList,
      userNotes: userNotes,
      dishwareDiameterCm: dishwareDiameterCm,
      pantryContext: pantryContext,
      overrideModel: overrideModel,
    );
  }

  @override
  Future<MealAnalysisResult> reanalyzeMealWithPrompt({
    required MealAnalysisResult currentResult,
    required String prompt,
    Uint8List? rawImageBytes,
  }) async {
    final itemsSummary = currentResult.items.isNotEmpty
        ? currentResult.items
            .map((e) => '${e.name}: ${e.estimatedGrams.toStringAsFixed(0)}g')
            .join(', ')
        : 'sin ingredientes';

    final userContext = 'El comensal corrigió el análisis previo: '
        'Plato: "${currentResult.dishName}", Ingredientes previos: $itemsSummary. '
        'Indicaciones del comensal: "$prompt". '
        'Desglosa CADA ingrediente de forma independiente con sus gramos y macronutrientes reales ajustados.';

    if (rawImageBytes != null) {
      return await analyzeMealPhoto(
        rawImageBytes: rawImageBytes,
        userContext: userContext,
      );
    }

    throw ArgumentError(
      'reanalyzeMealWithPrompt requires rawImageBytes to perform multimodal vision evaluation',
    );
  }

  @override
  String formatUserFriendlyError(dynamic error) =>
      GeminiVisionService.userFriendlyErrorMessage(error);
}
