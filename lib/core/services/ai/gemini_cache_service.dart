import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:food_tracker/core/services/ai/gemini_rest_client.dart';
import 'package:food_tracker/core/services/storage/secure_storage_service.dart';

/// Context Caching service for Gemini v1beta.
/// Caches large invariant contexts (Master Prompt + Pantry inventory).
/// Only creates remote CachedContent when token count exceeds the API minimum (32,768 tokens).
/// Otherwise falls back inline gracefully with zero network overhead.
class GeminiCacheService {
  final GeminiRestClient _restClient;
  final SecureStorageService _secureStorage;
  final int minTokensForCache;

  /// Default API token threshold for Gemini Context Caching (32k tokens).
  static const int apiMinTokenThreshold = 32768;

  String? _activeCacheName;
  DateTime? _activeCacheExpiresAt;
  String? _activeCacheSignature;

  GeminiCacheService({
    GeminiRestClient? restClient,
    SecureStorageService? secureStorage,
    this.minTokensForCache = apiMinTokenThreshold,
  })  : _restClient = restClient ?? GeminiRestClient.instance,
        _secureStorage = secureStorage ?? SecureStorageService.instance;

  static final GeminiCacheService instance = GeminiCacheService();

  String? get activeCacheName {
    if (_activeCacheExpiresAt != null && DateTime.now().isAfter(_activeCacheExpiresAt!)) {
      _activeCacheName = null;
      _activeCacheExpiresAt = null;
      _activeCacheSignature = null;
    }
    return _activeCacheName;
  }

  /// Fast token approximation heuristic (~3.8 characters per token).
  static int estimateTokenCount(String text) {
    if (text.isEmpty) return 0;
    return (text.length / 3.8).ceil();
  }

  /// Checks whether context exceeds the minimum token threshold.
  bool shouldCache(String combinedContext) =>
      estimateTokenCount(combinedContext) >= minTokensForCache;

  /// Retrieves an existing active cachedContent or creates a new one if threshold is met.
  /// Returns null when below threshold or when caching fails, triggering inline fallback.
  Future<String?> getOrCreateCachedContext({
    required String model,
    required String masterPrompt,
    String? pantryContext,
    Duration ttl = const Duration(minutes: 60),
  }) async {
    final combinedContext = '$masterPrompt\n${pantryContext ?? ''}'.trim();
    final estimatedTokens = estimateTokenCount(combinedContext);

    if (estimatedTokens < minTokensForCache) {
      debugPrint(
        'GeminiCacheService: $estimatedTokens tokens < $minTokensForCache minimum. Using inline fallback.',
      );
      return null;
    }

    final signature = '${model}_${combinedContext.hashCode}';
    if (activeCacheName != null && _activeCacheSignature == signature) {
      return activeCacheName;
    }

    final apiKey = await _secureStorage.getGeminiApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) return null;

    try {
      final payload = {
        'model': model.startsWith('models/') ? model : 'models/$model',
        'ttl': '${ttl.inSeconds}s',
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': combinedContext}
            ]
          }
        ],
      };

      final response = await _restClient.createCachedContent(
        apiKey: apiKey.trim(),
        body: payload,
      );

      final cacheName = response['name'] as String?;
      if (cacheName != null && cacheName.isNotEmpty) {
        _activeCacheName = cacheName;
        _activeCacheExpiresAt = DateTime.now().add(ttl);
        _activeCacheSignature = signature;
        debugPrint('GeminiCacheService: Created cached content $cacheName for $model');
        return cacheName;
      }
    } catch (e) {
      debugPrint('GeminiCacheService: Failed to create cachedContent ($e), falling back inline');
    }
    return null;
  }

  /// Invalidates and removes the current active cache remote resource.
  Future<void> purgeActiveCache() async {
    final name = _activeCacheName;
    _activeCacheName = null;
    _activeCacheExpiresAt = null;
    _activeCacheSignature = null;

    if (name != null) {
      final apiKey = await _secureStorage.getGeminiApiKey();
      if (apiKey != null && apiKey.trim().isNotEmpty) {
        try {
          await _restClient.deleteCachedContent(apiKey: apiKey.trim(), name: name);
        } catch (e) {
          debugPrint('GeminiCacheService: Error deleting cache ($e)');
        }
      }
    }
  }
}
