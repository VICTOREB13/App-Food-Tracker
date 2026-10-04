import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/interfaces/nutrition_label_scanner_service_interface.dart';
import '../models/pantry_item.dart';
import 'gemini_resilience_helper.dart';
import 'image_processing_service.dart';
import 'secure_storage_service.dart';

/// Service specialized in OCR parsing of commercial Nutrition Facts labels using Gemini Vision.
class NutritionLabelScannerService implements INutritionLabelScannerService {
  final String? _apiKey;
  final SecureStorageService _secureStorage;

  static NutritionLabelScannerService? _mockInstance;
  static final NutritionLabelScannerService _defaultInstance = NutritionLabelScannerService();

  static NutritionLabelScannerService get instance => _mockInstance ?? _defaultInstance;

  @visibleForTesting
  static void setMockInstance(NutritionLabelScannerService? mock) => _mockInstance = mock;

  NutritionLabelScannerService({
    String? apiKey,
    SecureStorageService? secureStorageService,
  })  : _apiKey = apiKey,
        _secureStorage = secureStorageService ?? SecureStorageService.instance;

  static const String defaultModel = 'gemini-2.5-flash';
  static const String fallbackModel = 'gemini-1.5-flash';

  static Schema get _labelSchema => Schema.object(
        description: 'Extracción estructurada de etiqueta de información nutricional comercial',
        requiredProperties: [
          'nombre_producto',
          'calorias',
          'proteinas',
          'carbohidratos',
          'grasas',
        ],
        properties: {
          'nombre_producto': Schema.string(description: 'Nombre comercial del alimento'),
          'marca': Schema.string(description: 'Marca fabricante o comercial'),
          'categoria': Schema.string(description: 'Categoría del alimento (ej. Granos, Lácteos, Carnes, Snacks, Bebidas)'),
          'tamano_porcion': Schema.number(description: 'Tamaño numérico de la porción de referencia (ej. 100 o 30)'),
          'unidad_porcion': Schema.string(description: 'Unidad de la porción (g, ml, oz, porcion)'),
          'calorias': Schema.number(description: 'Calorías por porción en kcal'),
          'proteinas': Schema.number(description: 'Proteínas por porción en gramos'),
          'carbohidratos': Schema.number(description: 'Carbohidratos por porción en gramos'),
          'grasas': Schema.number(description: 'Grasas totales por porción en gramos'),
          'fibra': Schema.number(description: 'Fibra dietaria por porción en gramos'),
          'sodio_mg': Schema.number(description: 'Sodio por porción en miligramos (mg)'),
          'azucar': Schema.number(description: 'Azúcares totales por porción en gramos'),
          'palabras_clave': Schema.string(description: 'Palabras clave de comidas o preparaciones derivadas comunes, separadas por coma (ej: arepa, masa, maiz)'),
        },
      );

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
      targetMaxDimension: 1024,
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

    final content = Content.multi([
      DataPart('image/jpeg', compressedBytes),
      TextPart(promptText),
    ]);

    return await GeminiResilienceHelper.executeWithRetry<PantryItem?>(
      primaryModel: defaultModel,
      secondaryModel: fallbackModel,
      action: (attempt, currentModel) async {
        final model = GenerativeModel(
          model: currentModel,
          apiKey: apiKey,
          systemInstruction: Content.system(
            'Eres un sistema OCR especializado en parsing estructurado de etiquetas de alimentos comerciales.',
          ),
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            responseSchema: _labelSchema,
            temperature: 0.1,
          ),
        );

        final response = await model
            .generateContent([content])
            .timeout(const Duration(seconds: 30));

        final text = response.text;
        if (text == null || text.trim().isEmpty) {
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
