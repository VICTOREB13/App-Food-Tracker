import '../models/gemini_model_info.dart';

/// Multimodal vision validation, tiered ranking, and offline fallback provider
/// for Google Gemini API models in visual food tracking.
class GeminiVisionFilter {
  /// Curated offline fallback models used when device is offline or API fails
  static const List<GeminiModelInfo> fallbackModels = [
    GeminiModelInfo(
      name: 'gemini-2.5-flash',
      displayName: 'Gemini 2.5 Flash',
      description: 'Modelo multimodal de última generación, ultrarrápido y de alta precisión visual.',
      isRecommended: true,
      recommendationLabel: 'Fast',
      inputTokenLimit: 1048576,
      outputTokenLimit: 8192,
    ),
    GeminiModelInfo(
      name: 'gemini-1.5-flash',
      displayName: 'Gemini 1.5 Flash',
      description: 'Modelo heredado rápido con amplia compatibilidad.',
      isRecommended: false,
      recommendationLabel: 'Fast',
      inputTokenLimit: 1048576,
      outputTokenLimit: 8192,
    ),
    GeminiModelInfo(
      name: 'gemini-1.5-pro',
      displayName: 'Gemini 1.5 Pro',
      description: 'Modelo de razonamiento avanzado y amplio contexto multimodal.',
      isRecommended: false,
      recommendationLabel: 'Think',
      inputTokenLimit: 2097152,
      outputTokenLimit: 8192,
    ),
    GeminiModelInfo(
      name: 'gemini-2.0-flash',
      displayName: 'Gemini 2.0 Flash',
      description: 'Modelo multimodal de producción estable y alta velocidad de inferencia.',
      isRecommended: true,
      recommendationLabel: 'Fast',
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
  /// Allows ONLY official multimodal Gemini Flash and Pro models, strictly rejecting
  /// custom / fine-tuned models created in Google AI Studio, and non-vision models.
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
    if (!cleanName.contains('flash') && !cleanName.contains('pro')) return false;

    final displayName = (model['displayName'] ?? '').toString().toLowerCase();
    if (displayName.isNotEmpty) {
      if (!displayName.contains('gemini')) return false;
      if (!displayName.contains('flash') && !displayName.contains('pro')) return false;
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
  /// 1: gemini-2.5-flash / gemini-3.*-flash (Top recommendation)
  /// 2: gemini-2.0-flash (Estable)
  /// 3: gemini-2.5-pro / gemini-3.*-pro (Máxima Precisión)
  /// 4: gemini-2.0-flash-lite
  /// 5: gemini-1.5-flash
  /// 6: gemini-1.5-pro
  /// 99: All other models
  static int calculateTierRank(String modelName) {
    final lower = modelName.toLowerCase();
    if (lower.startsWith('gemini-2.5-flash') || (lower.startsWith('gemini-3') && lower.contains('flash'))) return 1;
    if (lower.startsWith('gemini-2.0-flash') && !lower.contains('lite')) return 2;
    if (lower.startsWith('gemini-2.5-pro') || (lower.startsWith('gemini-3') && lower.contains('pro'))) return 3;
    if (lower.contains('flash-lite')) return 4;
    if (lower.startsWith('gemini-1.5-flash')) return 5;
    if (lower.startsWith('gemini-1.5-pro')) return 6;
    return 99;
  }

  /// Assigns compact semantic badge label displayed in UI ('Fast' or 'Think')
  static String? calculateRecommendationLabel(String modelName) {
    final lower = modelName.toLowerCase();
    if (lower.contains('pro')) return 'Think';
    if (lower.contains('flash')) return 'Fast';
    return null;
  }
}
