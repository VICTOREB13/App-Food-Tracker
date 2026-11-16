import 'package:food_tracker/core/models/gemini_model_info.dart';

/// Multimodal vision validation, tiered ranking, and offline fallback provider
/// for Google Gemini API models in visual food tracking.
class GeminiVisionFilter {
  /// Curated offline fallback models used when device is offline or API fails
  static const List<GeminiModelInfo> fallbackModels = [
    GeminiModelInfo(
      name: 'gemini-3.8-flash',
      displayName: 'Gemini 3.8 Flash',
      description: 'Modelo multimodal por defecto para análisis diario ágil y económico.',
      isRecommended: true,
      recommendationLabel: 'Fast',
      inputTokenLimit: 1048576,
      outputTokenLimit: 16384,
    ),
    GeminiModelInfo(
      name: 'gemini-3.6-flash',
      displayName: 'Gemini 3.6 Flash',
      description: 'Modelo de alta velocidad y resiliencia para análisis visual.',
      isRecommended: true,
      recommendationLabel: 'Fast',
      inputTokenLimit: 1048576,
      outputTokenLimit: 16384,
    ),
    GeminiModelInfo(
      name: 'gemini-3.1-pro',
      displayName: 'Gemini 3.1 Pro',
      description: 'Modelo clínico de alta precisión para platos complejos y guisos densos.',
      isRecommended: true,
      recommendationLabel: 'Think',
      inputTokenLimit: 2097152,
      outputTokenLimit: 16384,
    ),
    GeminiModelInfo(
      name: 'gemini-3.5-flash-lite',
      displayName: 'Gemini 3.5 Flash Lite',
      description: 'Modelo ligero de respaldo para máxima velocidad y bajo consumo.',
      isRecommended: false,
      recommendationLabel: 'Lite',
      inputTokenLimit: 1048576,
      outputTokenLimit: 8192,
    ),
  ];

  static const List<String> prohibitedKeywords = [
    'banana', 'nano', 'transcribe', 'omni', 'computer-use', 'robotics',
    'live', 'custom', 'preview-10-2025', 'embedding', 'imagen', 'tts',
    'audio', 'veo', 'bison', 'tuned', 'tuning',
  ];

  /// Strict multimodal vision filtering for Google Gemini models.
  /// Allows Gemini 4 and Gemini 3 models with vision capabilities,
  /// strictly rejecting legacy 1.x / 2.x models, custom fine-tuned models, and non-vision models.
  static bool isVisionCapableModel(Map<String, dynamic> model) {
    if (model.containsKey('baseModel') || model.containsKey('tunedModelSource')) {
      return false;
    }

    final rawName = (model['name'] ?? '').toString().toLowerCase();
    if (rawName.startsWith('tunedmodels/') || rawName.contains('tuned') || rawName.contains('tuning')) {
      return false;
    }

    final methods = (model['supportedGenerationMethods'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [];
    if (!methods.contains('generateContent')) return false;

    final cleanName = rawName.startsWith('models/') ? rawName.substring(7) : rawName;
    if (!cleanName.startsWith('gemini-')) return false;

    // Discard deprecated families (Gemini 1.x and 2.x)
    if (cleanName.startsWith('gemini-1.') || cleanName.startsWith('gemini-2.')) {
      return false;
    }

    final isGemini4 = cleanName.startsWith('gemini-4');
    final isGemini3 = cleanName.startsWith('gemini-3');
    final hasVisionTier = cleanName.contains('flash') || cleanName.contains('pro');

    if (!isGemini4 && !hasVisionTier && !isGemini3) return false;

    final displayName = (model['displayName'] ?? '').toString().toLowerCase();
    if (displayName.isNotEmpty) {
      if (!displayName.contains('gemini')) return false;
      if (displayName.contains('gemini 1.') || displayName.contains('gemini 2.')) return false;
    }

    final description = (model['description'] ?? '').toString().toLowerCase();
    for (final keyword in prohibitedKeywords) {
      if (keyword == 'custom') {
        if (cleanName.endsWith('custom') || cleanName.endsWith('-custom') || displayName.contains('custom')) {
          return false;
        }
      } else {
        if (cleanName.contains(keyword) || displayName.contains(keyword) || description.contains(keyword)) {
          return false;
        }
      }
    }

    final modalities = (model['inputModalities'] as List<dynamic>?)
            ?.map((e) => e.toString().toUpperCase())
            .toList() ?? [];
    if (modalities.isNotEmpty && !modalities.contains('IMAGE')) return false;

    return true;
  }

  /// Assigns priority rank to model ID:
  /// 1: Gemini 4 family ('gemini-4-*')
  /// 2: gemini-3.8-flash / gemini-3.6-flash / gemini-3.*-flash
  /// 3: gemini-3.1-pro / gemini-3.*-pro
  /// 4: gemini-3.5-flash-lite / flash-lite
  /// 20: gemini-2.* (Deprecado)
  /// 21: gemini-1.* (Deprecado)
  /// 99: All other models
  static int calculateTierRank(String modelName) {
    final lower = modelName.toLowerCase();
    if (lower.startsWith('gemini-4')) return 1;
    if (lower.startsWith('gemini-3.8-flash') ||
        lower.startsWith('gemini-3.6-flash') ||
        (lower.startsWith('gemini-3') && lower.contains('flash') && !lower.contains('lite'))) {
      return 2;
    }
    if (lower.startsWith('gemini-3.1-pro') ||
        (lower.startsWith('gemini-3') && lower.contains('pro'))) {
      return 3;
    }
    if (lower.contains('flash-lite')) return 4;
    if (lower.startsWith('gemini-2.')) return 20;
    if (lower.startsWith('gemini-1.')) return 21;
    return 99;
  }

  /// Assigns compact semantic badge label displayed in UI ('Fast', 'Think', 'Lite', 'Next-Gen', or 'Obsoleto')
  static String? calculateRecommendationLabel(String modelName) {
    final lower = modelName.toLowerCase();
    if (lower.contains('gemini-2') || lower.contains('gemini-1')) return 'Obsoleto';
    if (lower.startsWith('gemini-4')) return 'Next-Gen';
    if (lower.contains('lite')) return 'Lite';
    if (lower.contains('pro')) return 'Think';
    if (lower.contains('flash')) return 'Fast';
    return null;
  }
}
