import 'dart:typed_data';
import '../../models/food_item.dart';
import '../../models/meal_analysis_result.dart';

/// Contract for AI Vision models analyzing meal images, speech, and video frames.
/// Enables seamless plug-and-play decoupling for Gemini, OpenRouter, and future LLM providers.
abstract class IVisionModelProvider {
  Future<MealAnalysisResult> analyzeMealPhoto({
    required Uint8List rawImageBytes,
    String? userContext,
    String? overrideModel,
    String? overrideMasterPrompt,
    double? dishwareDiameterCm,
    String? pantryContext,
  });

  Future<MealAnalysisResult> reanalyzeWithIngredientSubstitution({
    required Uint8List rawImageBytes,
    required List<FoodItem> currentItems,
    required String oldIngredient,
    required String newIngredient,
    String? userNotes,
    double? dishwareDiameterCm,
    String? pantryContext,
    String? overrideModel,
  });

  Future<MealAnalysisResult> analyzeSpeechMeal({
    required Uint8List audioBytes,
    String mimeType,
    String? userNotes,
    String? overrideModel,
  });

  Future<MealAnalysisResult> analyzeVideoFramesMeal({
    required List<Uint8List> frameBytesList,
    String? userNotes,
    double? dishwareDiameterCm,
    String? pantryContext,
    String? overrideModel,
  });
}
