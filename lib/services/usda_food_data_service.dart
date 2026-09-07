import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pantry_item.dart';
import '../models/usda_food_item.dart';
import 'open_food_facts_service.dart';
import 'secure_storage_service.dart';

class UsdaApiException implements Exception {
  final String message;
  final int? statusCode;
  const UsdaApiException(this.message, {this.statusCode});
  @override
  String toString() => 'UsdaApiException($statusCode): $message';
}

class UsdaRateLimitException extends UsdaApiException {
  const UsdaRateLimitException([super.message = 'Límite de solicitudes USDA excedido (1,000 req/hora).'])
      : super(statusCode: 429);
}

class UsdaAuthenticationException extends UsdaApiException {
  const UsdaAuthenticationException([super.message = 'API Key de USDA no válida o no autorizada (HTTP 403).'])
      : super(statusCode: 403);
}

class UsdaFoodDataService {
  static final UsdaFoodDataService instance = UsdaFoodDataService();

  final http.Client _client;
  final SecureStorageService _storage;
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';

  // Rate Limiting (1,000 requests per hour limit)
  static const int maxRequestsPerHour = 1000;
  final List<DateTime> _requestLog = [];
  int? _lastRemainingHeader;

  UsdaFoodDataService({
    http.Client? client,
    SecureStorageService? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? SecureStorageService.instance;

  int? get lastRemainingRequests => _lastRemainingHeader;

  /// Validates whether a request can be dispatched according to local sliding-window rate limits
  bool _canDispatchRequest() {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    _requestLog.removeWhere((timestamp) => timestamp.isBefore(oneHourAgo));
    if (_requestLog.length >= maxRequestsPerHour) return false;
    if (_lastRemainingHeader != null && _lastRemainingHeader! <= 0) return false;
    return true;
  }

  void _recordRequest() {
    _requestLog.add(DateTime.now());
  }

  void _updateRateLimitHeaders(Map<String, String> headers) {
    final remaining = headers['x-ratelimit-remaining'];
    if (remaining != null) {
      _lastRemainingHeader = int.tryParse(remaining);
    }
  }

  Future<String?> _resolveApiKey(String? explicitKey) async {
    if (explicitKey != null && explicitKey.trim().isNotEmpty) {
      return explicitKey.trim();
    }
    return await _storage.getUsdaApiKey();
  }

  /// Searches foods by keyword with pagination
  Future<List<UsdaFoodItem>> searchFoods(
    String query, {
    int pageSize = 10,
    String? apiKey,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];

    final key = await _resolveApiKey(apiKey);
    if (key == null || key.isEmpty) return const [];

    if (!_canDispatchRequest()) {
      throw const UsdaRateLimitException();
    }

    final uri = Uri.parse('$_baseUrl/foods/search').replace(queryParameters: {
      'api_key': key,
      'query': trimmedQuery,
      'pageSize': pageSize.clamp(1, 100).toString(),
      'dataType': 'Branded,Foundation,SR Legacy',
    });

    try {
      _recordRequest();
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      _updateRateLimitHeaders(response.headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> foods = data['foods'] ?? [];
        return foods
            .whereType<Map<String, dynamic>>()
            .map((f) => UsdaFoodItem.fromFdcJson(f))
            .toList();
      } else if (response.statusCode == 403) {
        throw const UsdaAuthenticationException();
      } else if (response.statusCode == 429) {
        throw const UsdaRateLimitException();
      } else {
        return const [];
      }
    } on TimeoutException {
      return const [];
    } catch (e) {
      if (e is UsdaApiException) rethrow;
      return const [];
    }
  }

  /// Fetches a food item by UPC/GTIN barcode with auto-fallback for 12/13 digit formatting
  Future<UsdaFoodItem?> fetchByBarcode(
    String barcode, {
    String? apiKey,
  }) async {
    final sanitizedBarcode = barcode.trim();
    if (sanitizedBarcode.isEmpty) return null;

    final key = await _resolveApiKey(apiKey);
    if (key == null || key.isEmpty) return null;

    // 1. Direct query with scanned barcode
    var item = await _queryBarcodeOnce(sanitizedBarcode, key);
    if (item != null) return item;

    // 2. EAN-13 (13 digits starting with 0) -> Retry as UPC-A (12 digits)
    if (sanitizedBarcode.length == 13 && sanitizedBarcode.startsWith('0')) {
      item = await _queryBarcodeOnce(sanitizedBarcode.substring(1), key);
      if (item != null) return item;
    }

    // 3. UPC-A (12 digits) -> Retry as EAN-13 (13 digits prepended with 0)
    if (sanitizedBarcode.length == 12) {
      item = await _queryBarcodeOnce('0$sanitizedBarcode', key);
      if (item != null) return item;
    }

    return null;
  }

  /// Convenience wrapper returning PantryItem for barcode consumers
  Future<PantryItem?> fetchProductByBarcode(
    String barcode, {
    String? apiKey,
  }) async {
    final item = await fetchByBarcode(barcode, apiKey: apiKey);
    return item?.toPantryItem();
  }

  Future<UsdaFoodItem?> _queryBarcodeOnce(String code, String key) async {
    if (!_canDispatchRequest()) return null;

    final uri = Uri.parse('$_baseUrl/foods/search').replace(queryParameters: {
      'api_key': key,
      'query': code,
      'dataType': 'Branded',
      'pageSize': '5',
    });

    try {
      _recordRequest();
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      _updateRateLimitHeaders(response.headers);

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> foods = data['foods'] ?? [];
      if (foods.isEmpty) return null;

      // Find exact GTIN match or best hit
      Map<String, dynamic>? matched;
      for (final f in foods) {
        if (f is Map<String, dynamic>) {
          final gtin = f['gtinUpc']?.toString();
          if (gtin == code || (gtin != null && (gtin.endsWith(code) || code.endsWith(gtin)))) {
            matched = f;
            break;
          }
        }
      }
      matched ??= (foods.first as Map<String, dynamic>);
      return UsdaFoodItem.fromFdcJson(matched);
    } catch (_) {
      return null;
    }
  }

  /// Fetches complete food details by FDC ID (/food/{fdcId})
  Future<UsdaFoodItem?> fetchFoodDetails(
    int fdcId, {
    String? apiKey,
  }) async {
    if (fdcId <= 0) return null;

    final key = await _resolveApiKey(apiKey);
    if (key == null || key.isEmpty) return null;

    if (!_canDispatchRequest()) {
      throw const UsdaRateLimitException();
    }

    final uri = Uri.parse('$_baseUrl/food/$fdcId').replace(queryParameters: {
      'api_key': key,
      'format': 'full',
    });

    try {
      _recordRequest();
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      _updateRateLimitHeaders(response.headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UsdaFoodItem.fromFdcJson(data);
      } else if (response.statusCode == 403) {
        throw const UsdaAuthenticationException();
      } else if (response.statusCode == 429) {
        throw const UsdaRateLimitException();
      } else {
        return null;
      }
    } on TimeoutException {
      return null;
    } catch (e) {
      if (e is UsdaApiException) rethrow;
      return null;
    }
  }

  /// Cascading Barcode Resolution: Queries USDA first, falls back to Open Food Facts
  Future<PantryItem?> fetchProductWithFallback(
    String barcode, {
    String? apiKey,
  }) async {
    final sanitized = barcode.trim();
    if (sanitized.isEmpty) return null;

    try {
      final usdaItem = await fetchByBarcode(sanitized, apiKey: apiKey);
      if (usdaItem != null) {
        return usdaItem.toPantryItem();
      }
    } catch (_) {
      // Gracefully continue to fallback
    }

    // Fallback: Open Food Facts
    return await OpenFoodFactsService.instance.fetchProductByBarcode(sanitized);
  }
}
