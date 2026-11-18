import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:food_tracker/core/errors/gemini_api_exception.dart';

/// Typed HTTP REST Client for Google Generative Language API (v1beta).
/// Handles SSE streaming, unary generation, decisions gate, and context caching.
class GeminiRestClient {
  final http.Client _client;
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  GeminiRestClient({http.Client? client}) : _client = client ?? http.Client();
  static final GeminiRestClient instance = GeminiRestClient();

  Map<String, String> _headers(String apiKey) => {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey.trim(),
      };

  /// Supported canonical thinking levels for Gemini reasoning models.
  static const Set<String> validThinkingLevels = {
    'AUTO',
    'OFF',
    'LOW',
    'MEDIUM',
    'HIGH',
    'XHIGH',
  };

  /// Builds standard generation config with Gemini 3.x/4.x thinking config support.
  /// If [thinkingLevel] is 'OFF', thinkingConfig is strictly omitted.
  static Map<String, dynamic> buildGenerationConfig({
    required String model,
    String? thinkingLevel,
    double temperature = 1.0,
    int maxOutputTokens = 16384,
    String responseMimeType = 'application/json',
    Map<String, dynamic>? responseSchema,
  }) {
    final config = <String, dynamic>{
      'temperature': temperature,
      'maxOutputTokens': maxOutputTokens,
      'responseMimeType': responseMimeType,
    };
    if (responseSchema != null) config['responseSchema'] = responseSchema;

    final normalized = thinkingLevel?.toUpperCase().trim();
    if (normalized == 'OFF') return config;

    final cleanModel = model.replaceFirst(RegExp(r'^models/'), '').trim();
    final lower = cleanModel.toLowerCase();
    final isReasoning = !lower.contains('lite') &&
        (lower.startsWith('gemini-3') ||
            lower.startsWith('gemini-4') ||
            lower.contains('pro') ||
            lower.contains('thinking'));
    if (isReasoning) {
      final level = (normalized != null && validThinkingLevels.contains(normalized) && normalized != 'AUTO')
          ? normalized
          : 'MEDIUM';
      config['thinkingConfig'] = {'thinkingLevel': level};
    }
    return config;
  }

  /// Sends a unary generateContent request to v1beta.
  Future<String> generateContent({
    required String apiKey,
    required String model,
    required List<Map<String, dynamic>> contents,
    Map<String, dynamic>? systemInstruction,
    Map<String, dynamic>? generationConfig,
    String? cachedContent,
    String? thinkingLevel,
    int maxOutputTokens = 16384,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final cleanModel = model.replaceFirst(RegExp(r'^models/'), '').trim();
    final uri = Uri.parse('$baseUrl/models/$cleanModel:generateContent');
    final payload = <String, dynamic>{
      'contents': contents,
      'generationConfig': generationConfig ??
          buildGenerationConfig(
            model: cleanModel,
            thinkingLevel: thinkingLevel,
            maxOutputTokens: maxOutputTokens,
          ),
      if (systemInstruction != null) 'systemInstruction': systemInstruction,
      if (cachedContent != null && cachedContent.isNotEmpty) 'cachedContent': cachedContent,
    };

    try {
      final response = await _client
          .post(uri, headers: _headers(apiKey), body: jsonEncode(payload))
          .timeout(timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _extractText(jsonDecode(response.body) as Map<String, dynamic>);
      }
      throw GeminiApiException(
        statusCode: response.statusCode,
        message: 'Unary request failed (${response.statusCode}): ${response.body}',
      );
    } on TimeoutException {
      throw const GeminiApiException(statusCode: 408, message: 'Request timed out.');
    } catch (e) {
      if (e is GeminiApiException) rethrow;
      throw GeminiApiException(statusCode: 500, message: e.toString());
    }
  }

  /// Streams content via SSE with automatic silent fallback to unary on network/socket errors.
  Stream<String> streamGenerateContent({
    required String apiKey,
    required String model,
    required List<Map<String, dynamic>> contents,
    Map<String, dynamic>? systemInstruction,
    Map<String, dynamic>? generationConfig,
    String? cachedContent,
    String? thinkingLevel,
    int maxOutputTokens = 16384,
    Duration timeout = const Duration(seconds: 90),
  }) async* {
    final cleanModel = model.replaceFirst(RegExp(r'^models/'), '').trim();
    final uri = Uri.parse('$baseUrl/models/$cleanModel:streamGenerateContent?alt=sse');
    final payload = <String, dynamic>{
      'contents': contents,
      'generationConfig': generationConfig ??
          buildGenerationConfig(
            model: cleanModel,
            thinkingLevel: thinkingLevel,
            maxOutputTokens: maxOutputTokens,
          ),
      if (systemInstruction != null) 'systemInstruction': systemInstruction,
      if (cachedContent != null && cachedContent.isNotEmpty) 'cachedContent': cachedContent,
    };

    bool streamSucceeded = false;
    final emittedChunks = <String>[];
    try {
      final request = http.Request('POST', uri)
        ..headers.addAll(_headers(apiKey))
        ..headers['Accept'] = 'text/event-stream'
        ..headers['Cache-Control'] = 'no-cache'
        ..body = jsonEncode(payload);

      final streamedResponse = await _client.send(request).timeout(timeout);
      if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
        final err = await streamedResponse.stream.bytesToString();
        throw GeminiApiException(statusCode: streamedResponse.statusCode, message: err);
      }
      final lines = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines.timeout(timeout)) {
        final trimmed = line.trim();
        if (trimmed.startsWith('data:')) {
          final dataStr = trimmed.substring(5).trim();
          if (dataStr.isEmpty || dataStr == '[DONE]') continue;
          final text = _extractText(jsonDecode(dataStr) as Map<String, dynamic>);
          if (text.isNotEmpty) {
            emittedChunks.add(text);
            yield text;
          }
        }
      }
      streamSucceeded = true;
    } catch (e) {
      debugPrint('GeminiRestClient: SSE cut ($e), activating unary fallback');
      if (emittedChunks.isNotEmpty) {
        throw GeminiApiException(statusCode: 500, message: 'SSE stream cut mid-transfer: $e');
      }
    }

    if (!streamSucceeded && emittedChunks.isEmpty) {
      yield await generateContent(
        apiKey: apiKey,
        model: cleanModel,
        contents: contents,
        systemInstruction: systemInstruction,
        generationConfig: generationConfig,
        cachedContent: cachedContent,
        thinkingLevel: thinkingLevel,
        maxOutputTokens: maxOutputTokens,
        timeout: timeout,
      );
    }
  }

  /// Evaluates decision using a standard generateContent call on Gemini Decisions 1 model.
  Future<Map<String, dynamic>> postDecision({
    required String apiKey,
    required Map<String, dynamic> body,
    String model = 'gemini-decision-1',
    Duration timeout = const Duration(milliseconds: 2500),
  }) async {
    final cleanModel = model.replaceFirst(RegExp(r'^models/'), '').trim();
    final uri = Uri.parse('$baseUrl/models/$cleanModel:generateContent');
    final response = await _client
        .post(uri, headers: _headers(apiKey), body: jsonEncode(body))
        .timeout(timeout);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw GeminiApiException(statusCode: response.statusCode, message: response.body);
  }

  /// Creates a cached content resource under `/v1beta/cachedContents`.
  Future<Map<String, dynamic>> createCachedContent({
    required String apiKey,
    required Map<String, dynamic> body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = Uri.parse('$baseUrl/cachedContents');
    final response = await _client
        .post(uri, headers: _headers(apiKey), body: jsonEncode(body))
        .timeout(timeout);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw GeminiApiException(statusCode: response.statusCode, message: response.body);
  }

  /// Retrieves a cached content resource by name.
  Future<Map<String, dynamic>> getCachedContent({
    required String apiKey,
    required String name,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = Uri.parse('$baseUrl/$name');
    final response = await _client.get(uri, headers: _headers(apiKey)).timeout(timeout);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw GeminiApiException(statusCode: response.statusCode, message: response.body);
  }

  /// Deletes a cached content resource by name.
  Future<void> deleteCachedContent({
    required String apiKey,
    required String name,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = Uri.parse('$baseUrl/$name');
    final response = await _client.delete(uri, headers: _headers(apiKey)).timeout(timeout);
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw GeminiApiException(statusCode: response.statusCode, message: response.body);
  }

  static String _extractText(Map<String, dynamic> json) {
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return '';
    final first = candidates.first as Map<String, dynamic>;
    final content = first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return '';
    final buffer = StringBuffer();
    for (final p in parts) {
      if (p is Map<String, dynamic> && p['text'] != null) {
        buffer.write(p['text']);
      }
    }
    return buffer.toString();
  }
}
