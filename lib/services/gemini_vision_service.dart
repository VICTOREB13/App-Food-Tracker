import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/meal_analysis_result.dart';
import 'image_processing_service.dart';

export '../models/meal_analysis_result.dart';

class GeminiVisionService {
  final String apiKey;
  final String modelName;
  final String? masterPrompt;

  static const String defaultModel = 'gemini-2.5-flash';

  static const String baseSystemInstruction = '''
Eres un nutricionista clínico y experto en estimación volumétrica visual de alimentos sin báscula para comidas caseras latinoamericanas y familiares.

Reglas obligatorias de cubicaje:
1. Referencias anatómicas de volumen:
   - Puño cerrado ~ 1 taza de volumen (~140-180g de arroz cocido, ~130-160g de legumbres cocidas, ~120-150g de pastas cocidas).
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
   - PROHIBIDO agrupar o duplicar el nombre del plato como único elemento en 'items' (ej. si el plato es "Arroz blanco con frijoles y carne molida", desglosa individualmente "Arroz blanco cocido", "Frijoles negros", "Carne molida guisada", etc.). Si hay varios alimentos visibles, es OBLIGATORIO desglosarlos por separado (mínimo 2 o más items).
   - Para cada alimento en 'items', estima con precisión sus gramos, calorías, proteínas, carbohidratos y grasas específicos.
   - La suma de las calorías y macronutrientes de los 'items' individuales debe coincidir con 'totales'.
6. Estimación volumétrica precisa de gramos (PROHIBIDO fijar 200g genéricos):
   - PROHIBIDO asignar 200g de forma genérica o repetitiva a los ingredientes o al plato.
   - Cada alimento debe tener un peso en gramos estimado según su densidad visual y área en el plato:
     * Arroz o pasta cocida: típicamente 120g - 220g según volumen.
     * Carnes, pollo, pescado o carne molida: típicamente 90g - 160g cocido.
     * Legumbres o frijoles: típicamente 100g - 160g con su caldo.
     * Aguacate: una porción de tajada o medio aguacate típicamente 40g - 90g.
     * Ensaladas / vegetales: 30g - 100g.
     * Aceite o grasa visible/oculta: 5g - 15g.
7. Formato estricto:
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
        requiredProperties: ['plato', 'items', 'totales'],
        properties: {
          'plato': Schema.string(description: 'Nombre representativo del plato'),
          'items': Schema.array(
            description: 'Lista obligatoria con el desglose individual de cada alimento visible por separado',
            items: Schema.object(
              requiredProperties: [
                'alimento',
                'gramos_estimados',
                'calorias',
                'proteinas_g',
                'carbohidratos_g',
                'grasas_g',
              ],
              properties: {
                'alimento': Schema.string(description: 'Nombre del alimento o ingrediente individual (ej. "Arroz blanco", "Frijoles negros", "Carne molida", "Aguacate")'),
                'gramos_estimados': Schema.number(description: 'Peso realista estimado en gramos para este ingrediente'),
                'calorias': Schema.number(description: 'Calorías estimadas'),
                'proteinas_g': Schema.number(description: 'Proteínas en gramos'),
                'carbohidratos_g': Schema.number(description: 'Carbohidratos en gramos'),
                'grasas_g': Schema.number(description: 'Grasas en gramos'),
                'justificacion_visual': Schema.string(description: 'Explicación volumétrica visual'),
              },
            ),
          ),
          'totales': Schema.object(
            requiredProperties: ['calorias', 'proteina_g', 'carbohidratos_g', 'grasas_g'],
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
      promptBuffer.writeln('Analiza minuciosamente esta comida casera y estima su desglose nutricional siguiendo las reglas volumétricas.');
      promptBuffer.writeln('REGLAS FUNDAMENTALES DE DESGLOSE:');
      promptBuffer.writeln('1. DESGLOSE INDIVIDUAL OBLIGATORIO: Identifica y desglosa CADA alimento o ingrediente visible en la foto dentro de la lista "items" (ej. "Arroz blanco cocido", "Frijoles negros", "Carne molida", "Aguacate", "Grasa de sofrito/aceite"). Si ves arroz, carne, frijoles y aguacate, DEBEN ser al menos 4 items distintos en la lista. NUNCA devuelvas la lista de items vacía.');
      promptBuffer.writeln('2. PROHIBIDO DUPLICAR EL PLATO: NUNCA coloques el plato entero como un único ingrediente con el mismo nombre del plato.');
      promptBuffer.writeln('3. GRAMOS REALISTAS: PROHIBIDO fijar 200g genéricos. Estima los gramos según el volumen específico y densidad de cada porción en el plato.');
      promptBuffer.writeln('4. La suma de calorías y macronutrientes de los items individuales debe corresponder con los totales.');
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
