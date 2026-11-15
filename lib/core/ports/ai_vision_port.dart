import 'dart:typed_data';
import 'package:food_tracker/features/food_entry/models/food_item.dart';
import 'package:food_tracker/features/food_entry/models/meal_analysis_result.dart';

/// Hexagonal port for multimodal AI Vision services (Gemini, OpenRouter, etc.).
abstract interface class IAiVisionPort {
  /// Analyzes a raw meal photo and returns structured nutritional estimation.
  Future<MealAnalysisResult> analyzeMealPhoto({
    required Uint8List rawImageBytes,
    String? userContext,
    String? overrideModel,
    String? overrideMasterPrompt,
    double? dishwareDiameterCm,
    String? pantryContext,
  });

  /// Reanalyzes a meal photo with an ingredient substitution request.
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

  /// Analyzes audio recording of meal description and returns nutritional estimation.
  Future<MealAnalysisResult> analyzeSpeechMeal({
    required Uint8List audioBytes,
    String mimeType = 'audio/m4a',
    String? userNotes,
    String? overrideModel,
  });

  /// Analyzes multiple video frames for 3D multi-angle volumetric meal estimation.
  Future<MealAnalysisResult> analyzeVideoFramesMeal({
    required List<Uint8List> frameBytesList,
    String? userNotes,
    double? dishwareDiameterCm,
    String? pantryContext,
    String? overrideModel,
  });

  /// Interactively reanalyzes or refines a meal with custom user prompt instructions.
  Future<MealAnalysisResult> reanalyzeMealWithPrompt({
    required MealAnalysisResult currentResult,
    required String prompt,
    Uint8List? rawImageBytes,
  });

  /// Converts technical or network exceptions into user-friendly error messages.
  String formatUserFriendlyError(dynamic error);
}
