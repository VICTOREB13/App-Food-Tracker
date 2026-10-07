import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/errors/gemini_api_exception.dart';
import '../models/gemini_model_info.dart';
import 'gemini_vision_filter.dart';

export '../core/errors/gemini_api_exception.dart';

class GeminiModelService {
  final http.Client _client;
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  GeminiModelService({http.Client? client}) : _client = client ?? http.Client();

  static final GeminiModelService instance = GeminiModelService();

  /// Curated offline fallback models delegated to GeminiVisionFilter
  static const List<GeminiModelInfo> fallbackModels = GeminiVisionFilter.fallbackModels;

  /// Multimodal vision validation delegated to GeminiVisionFilter
  static bool isVisionCapableModel(Map<String, dynamic> model) =>
      GeminiVisionFilter.isVisionCapableModel(model);

  /// Default thinking budget token allocation for latent reasoning models
  static const int defaultThinkingBudget = 1024;

  /// Determines whether a given Gemini model supports latent reasoning / thinking budget
  static bool supportsThinking(String modelName) {
    final lower = modelName.toLowerCase();
    return lower.startsWith('gemini-3') ||
        lower.contains('pro') ||
        lower.contains('thinking');
  }

  /// Resolves the thinking budget for a given model (1024 for pro/thinking models, null otherwise)
  static int? resolveThinkingBudget(String modelName) =>
      supportsThinking(modelName) ? defaultThinkingBudget : null;

  /// Builds a call configuration map with model and thinking_budget when supported
  static Map<String, dynamic> buildCallConfig({
    required String modelName,
    int? customThinkingBudget,
  }) {
    final config = <String, dynamic>{'model': modelName};
    final budget = customThinkingBudget ?? resolveThinkingBudget(modelName);
    if (budget != null) {
      config['thinking_budget'] = budget;
      config['thinking_config'] = {'thinking_budget': budget};
    }
    return config;
  }

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
      if (!GeminiVisionFilter.isVisionCapableModel(item)) continue;

      final rawName = (item['name'] ?? '').toString();
      final cleanName = rawName.startsWith('models/') ? rawName.substring(7) : rawName;

      final tier = GeminiVisionFilter.calculateTierRank(cleanName);
      final label = GeminiVisionFilter.calculateRecommendationLabel(cleanName);
      final isRecommended = tier <= 2; // Only top tier: 3.8-flash and 3.1-pro

      filtered.add(GeminiModelInfo.fromGoogleJson(
        item,
        tierRank: tier,
        recommendationLabel: label,
        isRecommended: isRecommended,
      ));
    }

    filtered.sort((a, b) {
      final rankA = GeminiVisionFilter.calculateTierRank(a.name);
      final rankB = GeminiVisionFilter.calculateTierRank(b.name);
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.displayName.compareTo(b.displayName);
    });

    return filtered;
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

    final recommended = availableModels.firstWhere(
      (m) => m.isRecommended,
      orElse: () => availableModels.isNotEmpty
          ? availableModels.first
          : fallbackModels.first,
    );
    return recommended.name;
  }
}
