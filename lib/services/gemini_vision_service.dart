import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/food_item.dart';
import '../models/model_sanitizer.dart';
import 'image_processing_service.dart';

class MealAnalysisResult {
  final String dishName;
  final List<FoodItem> items;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final String rawJson;

  const MealAnalysisResult({
    required this.dishName,
    required this.items,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.rawJson,
  });

  factory MealAnalysisResult.fromJsonString(String jsonStr) {
    var cleaned = jsonStr.trim();
    
    // Check if wrapped in markdown code fence anywhere in the string
    final jsonFenceMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(cleaned);
    if (jsonFenceMatch != null) {
      cleaned = jsonFenceMatch.group(1)!.trim();
    } else {
      // Fallback: extract substring between first '{' and last '}'
      final firstBrace = cleaned.indexOf('{');
      final lastBrace = cleaned.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        cleaned = cleaned.substring(firstBrace, lastBrace + 1).trim();
      }
    }

    final Map<String, dynamic> data = json.decode(cleaned);
    final String dish = (data['plato'] ?? data['nombre'] ?? data['dish'] ?? data['name'] ?? 'Comida Analizada').toString();

    final List<FoodItem> parsedItems = [];
    final dynamic itemsList = data['items'] ??
        data['ingredientes'] ??
        data['alimentos'] ??
        data['ingredients'] ??
        data['componentes'] ??
        data['desglose'] ??
        data['food_items'] ??
        data['foods'];
    if (itemsList is List) {
      for (final itemMap in itemsList) {
        if (itemMap is Map<String, dynamic>) {
          parsedItems.add(FoodItem.fromJson(itemMap));
        } else if (itemMap is String && itemMap.trim().isNotEmpty) {
          parsedItems.add(FoodItem(
            name: itemMap.trim(),
            estimatedGrams: 100,
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            visualJustification: 'Ingrediente identificado por IA',
          ));
        }
      }
    }

    double cal = 0.0;
    double prot = 0.0;
    double carbs = 0.0;
    double fat = 0.0;

    final totalesMap = data['totales'] ?? data['totals'];
    if (totalesMap is Map<String, dynamic>) {
      cal = ModelSanitizer.clampDouble(totalesMap['calorias'] ?? totalesMap['calories'] ?? totalesMap['total_calorias']);
      prot = ModelSanitizer.clampDouble(totalesMap['proteina_g'] ?? totalesMap['proteinas_g'] ?? totalesMap['protein'] ?? totalesMap['proteins_g']);
      carbs = ModelSanitizer.clampDouble(totalesMap['carbohidratos_g'] ?? totalesMap['carbohidratos'] ?? totalesMap['carbs'] ?? totalesMap['carbohydrates_g']);
      fat = ModelSanitizer.clampDouble(totalesMap['grasas_g'] ?? totalesMap['grasa_g'] ?? totalesMap['fat'] ?? totalesMap['fats_g']);
    } else {
      for (final item in parsedItems) {
        cal += item.calories;
        prot += item.protein;
        carbs += item.carbs;
        fat += item.fat;
      }
    }

    if (parsedItems.isEmpty && (cal > 0 || prot > 0 || carbs > 0 || fat > 0)) {
      parsedItems.add(FoodItem(
        name: dish,
        estimatedGrams: 200,
        calories: cal,
        protein: prot,
        carbs: carbs,
        fat: fat,
        visualJustification: 'Porción completa del plato estimada por IA',
      ));
    }

    return MealAnalysisResult(
      dishName: dish,
      items: parsedItems,
      totalCalories: ModelSanitizer.clampDouble(cal),
      totalProtein: ModelSanitizer.clampDouble(prot),
      totalCarbs: ModelSanitizer.clampDouble(carbs),
      totalFat: ModelSanitizer.clampDouble(fat),
      rawJson: jsonStr,
    );
  }
}

class GeminiVisionService {
  final String apiKey;
  final String modelName;
  final String? masterPrompt;

  static const String defaultModel = 'gemini-2.5-flash';

  static const String baseSystemInstruction = '''
Eres un nutricionista clínico y experto en estimación volumétrica visual de alimentos sin báscula para comidas caseras latinoamericanas y familiares.

Reglas obligatorias de cubicaje:
1. Referencias anatómicas de volumen:
   - Puño cerrado ~ 1 taza de volumen (~150-200g de arroz, frijoles o pastas cocidas).
   - Palma de la mano (grosor del meñique) ~ 100-130g de carne, pollo o pescado cocido.
   - Pulgar / Falange distal ~ 1 cucharada o ~10-15g de aceite, mantequilla o grasa.
   - Dos manos ahuecadas ~ 50-80g de ensalada de hojas crudas.
2. Conversión cocido vs crudo:
   - Arroz y pasta: absorben agua, multiplicando por 2.5 a 3 su peso (100g crudo = ~250-300g cocido). Estima el peso cocido visible.
   - Carnes y aves: merma por cocción de 20% a 25% por pérdida de jugos.
   - Legumbres (frijoles, lentejas): absorben agua duplicando o triplicando su peso.
3. Regla de Grasa Oculta en Comida Casera:
   - En platos caseros tradicionales (guisos, sofritos, arroz con aderezo, estofados), añade siempre entre 5g y 10g adicionales de grasa (aceite/sofrito) por ración que no se ven a simple vista pero están integrados en la salsa o preparación.
4. Porciones compartidas:
   - Si el usuario indica en el contexto que la foto es de una fuente, olla o plato compartido y especifica su porción (ej. "me comí 1/3"), calcula exclusivamente la porción consumida por el usuario.
5. Desglose obligatorio de ingredientes en 'items':
   - Es ESTRICTAMENTE OBLIGATORIO desglosar de forma individual cada alimento, guarnición e ingrediente que compone el plato dentro de la lista 'items'.
   - NUNCA devuelvas 'items' como un arreglo vacío cuando haya alimentos visibles en la foto. Cada elemento debe ser una porción identificable (ej. "Arroz blanco cocido", "Pechuga de pollo asada", "Aguacate", "Grasa oculta de sofrito/aceite").
   - Para cada alimento en 'items', estima con precisión sus gramos, calorías, proteínas, carbohidratos y grasas específicos.
   - La suma de las calorías y macronutrientes de los 'items' individuales debe coincidir con 'totales'.
6. Formato estricto:
   - Responde únicamente con el JSON definido en el esquema.
''';

  /// Backward-compatible alias preserving exact test suite assertions
  static const String systemInstruction = baseSystemInstruction;

  /// Builds dynamic system instruction injecting user biological profile & TDEE goals
  static String buildSystemInstruction([String? masterPrompt]) {
    final buffer = StringBuffer(baseSystemInstruction);
    if (masterPrompt != null && masterPrompt.trim().isNotEmpty) {
      buffer.writeln('\n--- CONTEXTO BIOLÓGICO Y METAS DEL COMENSAL (MASTER PROMPT) ---');
      buffer.writeln(masterPrompt.trim());
      buffer.writeln('Ajusta tus estimaciones y observaciones considerando las metas calóricas, requerimientos y contexto nutricional del comensal.');
    }
    return buffer.toString();
  }

  GeminiVisionService({
    required this.apiKey,
    this.modelName = defaultModel,
    this.masterPrompt,
  });

  /// Maps technical API and network errors into clear, actionable messages for the user
  static String userFriendlyErrorMessage(dynamic error) {
    if (error == null) {
      return 'Ocurrió un error al analizar la comida. Por favor, inténtalo nuevamente.';
    }

    final errString = error.toString().toLowerCase();

    // Check if error is already a translated user-friendly string
    if (error is String) {
      if (error.startsWith('Se perdió la conexión') ||
          error.startsWith('Tu API Key') ||
          error.startsWith('Has alcanzado el límite') ||
          error.startsWith('La IA no logró') ||
          error.startsWith('Ocurrió un error')) {
        return error;
      }
    }

    // Network errors
    if (error is SocketException ||
        error is TimeoutException ||
        errString.contains('socketexception') ||
        errString.contains('timeoutexception') ||
        errString.contains('clientexception') ||
        errString.contains('network is unreachable') ||
        errString.contains('failed host lookup') ||
        errString.contains('connection refused') ||
        errString.contains('connection reset') ||
        errString.contains('connection closed') ||
        errString.contains('timed out')) {
      return 'Se perdió la conexión a internet. Por favor, verifica tu red e inténtalo de nuevo.';
    }

    // Auth & Permission errors
    if (errString.contains('api key not valid') ||
        errString.contains('api_key_invalid') ||
        errString.contains('permission_denied') ||
        errString.contains('unauthenticated') ||
        errString.contains('401') ||
        errString.contains('403') ||
        (errString.contains('400') && !errString.contains('safety'))) {
      return 'Tu API Key de Gemini no es válida o no tiene permisos suficientes. Verifícala en Ajustes.';
    }

    // Quota and rate limiting errors
    if (errString.contains('429') ||
        errString.contains('resource_exhausted') ||
        errString.contains('quota') ||
        errString.contains('rate limit')) {
      return 'Has alcanzado el límite de solicitudes de Gemini. Por favor, espera unos segundos e inténtalo de nuevo.';
    }

    // Safety filter or unrecognized food errors
    if (errString.contains('safety') ||
        errString.contains('recitation') ||
        errString.contains('blocked') ||
        errString.contains('bloqueada') ||
        errString.contains('respuesta vacía') ||
        errString.contains('empty response') ||
        errString.contains('no logr') ||
        errString.contains('no food') ||
        errString.contains('alimentos')) {
      return 'La IA no logró identificar alimentos en la foto. Intenta con una toma más cercana, con mejor iluminación o ángulo superior.';
    }

    return 'Ocurrió un error al analizar la comida. Por favor, inténtalo nuevamente.';
  }

  /// Alias for analyzeMealPhoto conforming to backend contract
  Future<MealAnalysisResult> analyzeMealImage(
    Uint8List imageBytes, {
    String? userContext,
    String? overrideModel,
    String? overrideMasterPrompt,
  }) {
    return analyzeMealPhoto(
      rawImageBytes: imageBytes,
      userContext: userContext,
      overrideModel: overrideModel,
      overrideMasterPrompt: overrideMasterPrompt,
    );
  }

  Future<MealAnalysisResult> analyzeMealPhoto({
    required Uint8List rawImageBytes,
    String? userContext,
    String? overrideModel,
    String? overrideMasterPrompt,
  }) async {
    try {
      final compressedBytes = ImageProcessingService.instance.compressAndResize(
        rawImageBytes,
        targetMaxDimension: 1024,
        quality: 85,
      );

      final effectiveModel = (overrideModel != null && overrideModel.trim().isNotEmpty)
          ? overrideModel.trim()
          : modelName;

      final effectivePrompt = overrideMasterPrompt ?? masterPrompt;
      final effectiveInstruction = buildSystemInstruction(effectivePrompt);

      final schema = Schema.object(
        description: 'Desglose nutricional y volumétrico de comida casera',
        properties: {
          'plato': Schema.string(description: 'Nombre representativo del plato'),
          'items': Schema.array(
            description: 'Lista obligatoria con el desglose detallado de cada ingrediente o alimento individual identificado en el plato',
            items: Schema.object(
              properties: {
                'alimento': Schema.string(description: 'Nombre del alimento o ingrediente individual'),
                'gramos_estimados': Schema.number(description: 'Peso estimado en gramos'),
                'calorias': Schema.number(description: 'Calorías estimadas'),
                'proteinas_g': Schema.number(description: 'Proteínas en gramos'),
                'carbohidratos_g': Schema.number(description: 'Carbohidratos en gramos'),
                'grasas_g': Schema.number(description: 'Grasas en gramos'),
                'justificacion_visual': Schema.string(description: 'Explicación volumétrica visual'),
              },
            ),
          ),
          'totales': Schema.object(
            properties: {
              'calorias': Schema.number(description: 'Total calorías del plato'),
              'proteina_g': Schema.number(description: 'Total proteínas en gramos'),
              'carbohidratos_g': Schema.number(description: 'Total carbohidratos en gramos'),
              'grasas_g': Schema.number(description: 'Total grasas en gramos'),
            },
          ),
        },
      );

      final model = GenerativeModel(
        model: effectiveModel,
        apiKey: apiKey,
        systemInstruction: Content.system(effectiveInstruction),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: schema,
          temperature: 0.2,
        ),
      );

      final promptBuffer = StringBuffer();
      promptBuffer.writeln('Analiza esta comida casera y estima su desglose nutricional siguiendo las reglas volumétricas.');
      promptBuffer.writeln('IMPORTANTE: Identifica y desglosa OBLIGATORIAMENTE cada uno de los ingredientes y alimentos individuales que componen el plato en la lista "items" con sus gramos y macronutrientes correspondientes. NUNCA devuelvas la lista de items vacía.');
      if (userContext != null && userContext.trim().isNotEmpty) {
        promptBuffer.writeln('Contexto y notas del comensal: ${userContext.trim()}');
      }

      final content = Content.multi([
        DataPart('image/jpeg', compressedBytes),
        TextPart(promptBuffer.toString()),
      ]);

      final response = await model.generateContent([content]);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw Exception('Gemini devolvió una respuesta vacía');
      }

      return MealAnalysisResult.fromJsonString(text);
    } catch (e) {
      throw Exception(userFriendlyErrorMessage(e));
    }
  }
}
