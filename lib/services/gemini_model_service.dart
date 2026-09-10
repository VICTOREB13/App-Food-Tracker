import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/gemini_model_info.dart';

/// Typed exception for Google Gemini API errors
class GeminiApiException implements Exception {
  final int statusCode;
  final String message;
  final String? details;

  const GeminiApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  @override
  String toString() =>
      'GeminiApiException($statusCode): $message${details != null ? ' - $details' : ''}';
}

class GeminiModelService {
  final http.Client _client;
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  GeminiModelService({http.Client? client}) : _client = client ?? http.Client();

  static final GeminiModelService instance = GeminiModelService();

  /// Curated offline fallback models used when device is offline or API fails
  static const List<GeminiModelInfo> _fallbackModels = [
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

  static const List<GeminiModelInfo> fallbackModels = _fallbackModels;

  /// Queries Google Generative Language API and returns sorted, filtered models
  Future<List<GeminiModelInfo>> fetchAvailableModels(
    String apiKey, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final sanitizedKey = apiKey.trim();
    if (sanitizedKey.isEmpty) {
      throw const GeminiApiException(
        statusCode: 400,
        message: 'La API Key de Gemini está vacía.',
      );
    }

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'key': sanitizedKey,
      'pageSize': '100',
    });

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return parseModelsResponse(response.body);
      }

      // Handle non-200 error bodies
      String errorMessage = 'Error al consultar modelos (${response.statusCode})';
      String? errorDetails;
      try {
        final Map<String, dynamic> errorJson = json.decode(response.body);
        if (errorJson['error'] is Map<String, dynamic>) {
          final err = errorJson['error'] as Map<String, dynamic>;
          errorDetails = err['message']?.toString();
        }
      } catch (_) {}

      switch (response.statusCode) {
        case 400:
          errorMessage = 'API Key de Gemini no válida o malformada.';
          break;
        case 403:
          errorMessage = 'Acceso denegado. Verifique permisos o cuota en Google AI Studio.';
          break;
        case 429:
          errorMessage = 'Cuota o límite de solicitudes excedido (HTTP 429).';
          break;
        case 500:
        case 503:
          errorMessage = 'Servicio de Google Gemini no disponible temporalmente.';
          break;
      }

      throw GeminiApiException(
        statusCode: response.statusCode,
        message: errorMessage,
        details: errorDetails,
      );
    } on SocketException catch (e) {
      throw GeminiApiException(
        statusCode: 0,
        message: 'Sin conexión a internet. Comprueba tu red.',
        details: e.message,
      );
    } on TimeoutException {
      throw const GeminiApiException(
        statusCode: 408,
        message: 'Tiempo de espera agotado al conectar con Google Gemini (10s).',
      );
    }
  }

  /// Parses raw JSON string into filtered and prioritized GeminiModelInfo list
  List<GeminiModelInfo> parseModelsResponse(String responseBody) {
    final Map<String, dynamic> data = json.decode(responseBody);
    final List<dynamic> rawList = (data['models'] as List<dynamic>?) ?? [];

    final List<GeminiModelInfo> filtered = [];

    for (final item in rawList) {
      if (item is! Map<String, dynamic>) continue;

      if (!isVisionCapableModel(item)) continue;

      final rawName = (item['name'] ?? '').toString();
      final cleanName = rawName.startsWith('models/') ? rawName.substring(7) : rawName;

      final tier = _calculateTierRank(cleanName);
      final label = _calculateRecommendationLabel(cleanName);
      final isRecommended = tier <= 3;

      filtered.add(GeminiModelInfo.fromGoogleJson(
        item,
        tierRank: tier,
        recommendationLabel: label,
        isRecommended: isRecommended,
      ));
    }

    // Sort by tier rank ascending (1 -> 2 -> 3 -> 99), then alphabetically by name
    filtered.sort((a, b) {
      final rankA = _calculateTierRank(a.name);
      final rankB = _calculateTierRank(b.name);
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.displayName.compareTo(b.displayName);
    });

    return filtered;
  }

  /// Strict multimodal vision filtering for Google Gemini models.
  /// Allows ONLY official multimodal Gemini Flash and Pro models, strictly rejecting
  /// custom / fine-tuned models created in Google AI Studio, and non-vision models.
  static bool isVisionCapableModel(Map<String, dynamic> model) {
    // 1. Exclude tuned models or models created in Google AI Studio
    if (model.containsKey('baseModel') || model.containsKey('tunedModelSource')) {
      return false;
    }

    final rawName = (model['name'] ?? '').toString().toLowerCase();
    if (rawName.startsWith('tunedmodels/') || rawName.contains('tuned') || rawName.contains('tuning')) {
      return false;
    }

    // 2. Generation Method Filter: Must contain 'generateContent'
    final methods = (model['supportedGenerationMethods'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    if (!methods.contains('generateContent')) {
      return false;
    }

    // 3. Name must be an official Gemini model
    final cleanName = rawName.startsWith('models/') ? rawName.substring(7) : rawName;
    if (!cleanName.startsWith('gemini-')) {
      return false;
    }

    // 4. Must strictly contain 'flash' or 'pro' in cleanName
    if (!cleanName.contains('flash') && !cleanName.contains('pro')) {
      return false;
    }

    // 5. Display name check:
    // Reject custom tuned names (e.g. '2', 'Nano Banana Pro', or names not containing 'gemini')
    final displayName = (model['displayName'] ?? '').toString().toLowerCase();
    if (displayName.isNotEmpty) {
      if (!displayName.contains('gemini')) {
        return false;
      }
      if (!displayName.contains('flash') && !displayName.contains('pro')) {
        return false;
      }
    }

    // 6. Prohibited keywords exclusion across name, displayName, and description
    final description = (model['description'] ?? '').toString().toLowerCase();
    const prohibitedKeywords = [
      'banana',
      'nano',
      'transcribe',
      'omni',
      'computer-use',
      'robotics',
      'live',
      'custom',
      'preview-10-2025',
      'embedding',
      'imagen',
      'tts',
      'audio',
      'veo',
      'bison',
      'tuned',
      'tuning',
    ];

    for (final keyword in prohibitedKeywords) {
      if (keyword == 'custom') {
        if (cleanName.endsWith('custom') ||
            cleanName.endsWith('-custom') ||
            displayName.contains('custom')) {
          return false;
        }
      } else {
        if (cleanName.contains(keyword) ||
            displayName.contains(keyword) ||
            description.contains(keyword)) {
          return false;
        }
      }
    }

    // 7. Multimodal Verification:
    // If inputModalities is provided by Google API, verify IMAGE capability.
    final modalities = (model['inputModalities'] as List<dynamic>?)
            ?.map((e) => e.toString().toUpperCase())
            .toList() ??
        [];

    if (modalities.isNotEmpty && !modalities.contains('IMAGE')) {
      return false;
    }

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
  static int _calculateTierRank(String modelName) {
    final lower = modelName.toLowerCase();
    if (lower.startsWith('gemini-2.5-flash') ||
        (lower.startsWith('gemini-3') && lower.contains('flash'))) {
      return 1;
    }
    if (lower.startsWith('gemini-2.0-flash') && !lower.contains('lite')) {
      return 2;
    }
    if (lower.startsWith('gemini-2.5-pro') ||
        (lower.startsWith('gemini-3') && lower.contains('pro'))) {
      return 3;
    }
    if (lower.contains('flash-lite')) {
      return 4;
    }
    if (lower.startsWith('gemini-1.5-flash')) {
      return 5;
    }
    if (lower.startsWith('gemini-1.5-pro')) {
      return 6;
    }
    return 99;
  }

  /// Assigns compact semantic badge label displayed in UI ('Fast' or 'Think')
  static String? _calculateRecommendationLabel(String modelName) {
    final lower = modelName.toLowerCase();
    if (lower.contains('pro')) {
      return 'Think';
    }
    if (lower.contains('flash')) {
      return 'Fast';
    }
    return null;
  }

  /// Resolves the effective model ID to use given the available models and stored preference
  static String resolveEffectiveModel({
    required List<GeminiModelInfo> availableModels,
    String? savedSelection,
  }) {
    if (savedSelection != null && savedSelection.trim().isNotEmpty) {
      final exists = availableModels.any((m) => m.name == savedSelection.trim());
      if (exists) return savedSelection.trim();
    }

    // Default to the first available recommended model or fallback
    final recommended = availableModels.firstWhere(
      (m) => m.isRecommended,
      orElse: () => availableModels.isNotEmpty
          ? availableModels.first
          : fallbackModels.first,
    );
    return recommended.name;
  }
}
