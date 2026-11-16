import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:food_tracker/core/interfaces/nutrition_label_scanner_service_interface.dart';
import 'package:food_tracker/features/pantry_inventory/models/pantry_item.dart';
import 'package:food_tracker/core/services/ai/gemini_resilience_helper.dart';
import 'package:food_tracker/core/services/ai/gemini_rest_client.dart';
import 'package:food_tracker/features/food_entry/services/image_processing_service.dart';
import 'package:food_tracker/core/services/storage/secure_storage_service.dart';

/// Service specialized in OCR parsing of commercial Nutrition Facts labels using Gemini Vision.
class NutritionLabelScannerService implements INutritionLabelScannerService {
  final String? _apiKey;
  final SecureStorageService _secureStorage;
  final GeminiRestClient _restClient;

  static NutritionLabelScannerService? _mockInstance;
  static final NutritionLabelScannerService _defaultInstance = NutritionLabelScannerService();

  static NutritionLabelScannerService get instance => _mockInstance ?? _defaultInstance;

  @visibleForTesting
  static void setMockInstance(NutritionLabelScannerService? mock) => _mockInstance = mock;

  NutritionLabelScannerService({
    String? apiKey,
    SecureStorageService? secureStorageService,
    GeminiRestClient? restClient,
  })  : _apiKey = apiKey,
        _secureStorage = secureStorageService ?? SecureStorageService.instance,
        _restClient = restClient ?? GeminiRestClient.instance;

  static const String defaultModel = 'gemini-3.8-flash';
  static const String fallbackModel = 'gemini-3.6-flash';

  static const Map<String, dynamic> _labelSchema = {
    'type': 'object',
    'description': 'Extracción estructurada de etiqueta de información nutricional comercial',
    'required': [
      'nombre_producto',
      'calorias',
      'proteinas',
      'carbohidratos',
      'grasas',
    ],
    'properties': {
      'nombre_producto': {'type': 'string', 'description': 'Nombre comercial del alimento'},
      'marca': {'type': 'string', 'description': 'Marca fabricante o comercial'},
      'categoria': {'type': 'string', 'description': 'Categoría del alimento (ej. Granos, Lácteos, Carnes, Snacks, Bebidas)'},
      'tamano_porcion': {'type': 'number', 'description': 'Tamaño numérico de la porción de referencia (ej. 100 o 30)'},
      'unidad_porcion': {'type': 'string', 'description': 'Unidad de la porción (g, ml, oz, porcion)'},
      'calorias': {'type': 'number', 'description': 'Calorías por porción en kcal'},
      'proteinas': {'type': 'number', 'description': 'Proteínas por porción en gramos'},
      'carbohidratos': {'type': 'number', 'description': 'Carbohidratos por porción en gramos'},
      'grasas': {'type': 'number', 'description': 'Grasas totales por porción en gramos'},
      'fibra': {'type': 'number', 'description': 'Fibra dietaria por porción en gramos'},
      'sodio_mg': {'type': 'number', 'description': 'Sodio por porción en miligramos (mg)'},
      'azucar': {'type': 'number', 'description': 'Azúcares totales por porción en gramos'},
      'palabras_clave': {'type': 'string', 'description': 'Palabras clave de comidas o preparaciones derivadas comunes, separadas por coma'},
    },
  };

  @override
  Future<PantryItem?> scanNutritionLabel({
    required Uint8List imageBytes,
    String? brandHint,
  }) async {
    final apiKey = _apiKey ?? await _secureStorage.getGeminiApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('Configura tu API Key de Gemini en Ajustes para escanear etiquetas.');
    }

    final compressedBytes = await ImageProcessingService.instance.compressAndResizeAsync(
      imageBytes,
      targetMaxDimension: 768,
      quality: 85,
    );

    final brandNote = (brandHint != null && brandHint.trim().isNotEmpty)
        ? '\nPista de marca proporcionada por el usuario: "${brandHint.trim()}". Úsala para identificar el producto con precisión.'
        : '';

    final promptText = '''
Eres un experto en lectura clínica y análisis OCR de etiquetas nutricionales comerciales (Nutrition Facts / Información Nutricional).
Analiza detalladamente la tabla nutricional y empaque de la foto.
Extrae con máxima precisión los valores por porción declarada.$brandNote
Calcula o infiere palabras clave de preparaciones habituales derivadas para asociar en la despensa (ej. para Harina PAN: arepa, masa, empanada, bollo).
''';

    final contents = [
      {
        'parts': [
          {
            'inlineData': {
              'mimeType': 'image/jpeg',
              'data': base64Encode(compressedBytes),
            }
          },
          {'text': promptText},
        ]
      }
    ];

    final systemInstruction = {
      'parts': [
        {
          'text': 'Eres un sistema OCR especializado en parsing estructurado de etiquetas de alimentos comerciales.'
        }
      ]
    };

    return await GeminiResilienceHelper.executeWithRetry<PantryItem?>(
      primaryModel: defaultModel,
      secondaryModel: fallbackModel,
      action: (attempt, currentModel) async {
        final generationConfig = GeminiRestClient.buildGenerationConfig(
          model: currentModel,
          temperature: 0.1,
          responseMimeType: 'application/json',
          responseSchema: _labelSchema,
        );

        final text = await _restClient.generateContent(
          apiKey: apiKey,
          model: currentModel,
          contents: contents,
          systemInstruction: systemInstruction,
          generationConfig: generationConfig,
          timeout: const Duration(seconds: 30),
        );

        if (text.trim().isEmpty) {
          return null;
        }

        return parsePantryItemJson(text, brandHint: brandHint);
      },
    );
  }

  static PantryItem? parsePantryItemJson(String jsonText, {String? brandHint}) {
    try {
      String clean = jsonText.trim();
      if (clean.startsWith('```json')) {
        clean = clean.substring(7);
      }
      if (clean.startsWith('```')) {
        clean = clean.substring(3);
      }
      if (clean.endsWith('```')) {
        clean = clean.substring(0, clean.length - 3);
      }
      clean = clean.trim();

      final dynamic decoded = json.decode(clean);
      if (decoded is! Map<String, dynamic>) return null;

      final name = decoded['nombre_producto']?.toString().trim();
      if (name == null || name.isEmpty) return null;

      return PantryItem(
        name: name,
        brand: decoded['marca']?.toString().trim() ?? brandHint,
        category: decoded['categoria']?.toString().trim() ?? 'Despensa',
        calories: (decoded['calorias'] as num?)?.toDouble() ?? 0.0,
        protein: (decoded['proteinas'] as num?)?.toDouble() ?? 0.0,
        carbs: (decoded['carbohidratos'] as num?)?.toDouble() ?? 0.0,
        fat: (decoded['grasas'] as num?)?.toDouble() ?? 0.0,
        servingSize: (decoded['tamano_porcion'] as num?)?.toDouble() ?? 100.0,
        servingUnit: decoded['unidad_porcion']?.toString().trim() ?? 'g',
        fiber: (decoded['fibra'] as num?)?.toDouble() ?? 0.0,
        sodium: (decoded['sodio_mg'] as num?)?.toDouble() ?? 0.0,
        sugar: (decoded['azucar'] as num?)?.toDouble() ?? 0.0,
        matchKeywords: decoded['palabras_clave']?.toString().trim(),
        isVerifiedByUser: true,
      );
    } catch (e) {
      debugPrint('NutritionLabelScannerService: error parsing label JSON: $e');
      return null;
    }
  }
}
