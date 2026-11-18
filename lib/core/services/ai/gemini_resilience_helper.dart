import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Lightweight schema representation for Gemini REST API avoiding external generative SDK dependencies.
class GeminiSchema {
  final String type;
  final String? description;
  final List<String>? requiredProperties;
  final Map<String, dynamic>? properties;
  final GeminiSchema? items;

  const GeminiSchema.object({this.description, this.requiredProperties, this.properties}) : type = 'OBJECT', items = null;
  const GeminiSchema.string({this.description}) : type = 'STRING', requiredProperties = null, properties = null, items = null;
  const GeminiSchema.number({this.description}) : type = 'NUMBER', requiredProperties = null, properties = null, items = null;
  const GeminiSchema.integer({this.description}) : type = 'INTEGER', requiredProperties = null, properties = null, items = null;
  const GeminiSchema.array({this.description, this.items}) : type = 'ARRAY', requiredProperties = null, properties = null;

  Map<String, dynamic> toMap() => {
    'type': type,
    if (description != null) 'description': description,
    if (requiredProperties != null) 'required': requiredProperties,
    if (properties != null) 'properties': properties!.map((k, v) => MapEntry(k, v is GeminiSchema ? v.toMap() : v)),
    if (items != null) 'items': items!.toMap(),
  };

  Map<String, dynamic> toJson() => toMap();
}

typedef Schema = GeminiSchema;

/// Helper utility managing exponential backoff, jitter, thinkingConfig, and causal schemas for Gemini Vision.
class GeminiResilienceHelper {
  static const String fallbackModel = 'gemini-3.6-flash';
  static const String secondaryFallbackModel = 'gemini-3.5-flash-lite';

  static bool isRetriableError(dynamic error) {
    if (error == null) return false;
    if (error is SocketException || error is TimeoutException ||
        error is HttpException || error is HandshakeException || error is FormatException) {
      return true;
    }
    final s = error.toString().toLowerCase();
    const patterns = ['429', 'resource_exhausted', 'quota', 'rate limit', '500', '502', '503', '504',
      'bad gateway', 'gateway timeout', 'unavailable', 'overloaded', 'socketexception', 'timeoutexception',
      'clientexception', 'handshakeexception', 'httpexception', 'formatexception', 'unexpected character',
      'syntaxerror', 'network', 'timed out', 'respuesta vacía', 'empty response',
      'connection closed', 'connection reset', 'broken pipe', 'os error: 104', 'os error: 10054',
      'software caused connection abort', 'connection aborted', 'stream was reset', 'stream closed',
      'remotely closed', 'transport is closing', 'socket cut'];
    return patterns.any(s.contains);
  }

  static Future<T> executeWithRetry<T>({
    required Future<T> Function(int attempt, String currentModel) action,
    required String primaryModel,
    String secondaryModel = fallbackModel,
    int maxAttempts = 3,
    List<Duration>? customDelays,
    @visibleForTesting bool addJitter = true,
  }) async {
    final delays = customDelays ?? const [Duration(seconds: 2), Duration(seconds: 5), Duration(seconds: 10)];
    dynamic lastError;
    String currentModel = primaryModel;
    final random = Random();

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await action(attempt, currentModel);
      } catch (e) {
        lastError = e;
        if (!isRetriableError(e) || attempt == maxAttempts - 1) rethrow;

        if (attempt >= 1 && currentModel != secondaryModel) {
          currentModel = secondaryModel;
          debugPrint('GeminiResilienceHelper: Falling back to $currentModel');
        }

        final baseDelay = attempt < delays.length ? delays[attempt] : delays.last;
        final jitterMs = addJitter ? random.nextInt(500) : 0;
        final waitDuration = baseDelay + Duration(milliseconds: jitterMs);

        debugPrint('GeminiResilienceHelper: Retrying in ${waitDuration.inMilliseconds}ms (Attempt ${attempt + 1}/$maxAttempts) due to: $e');
        await Future.delayed(waitDuration);
      }
    }
    throw lastError ?? Exception('Operación fallida tras $maxAttempts reintentos');
  }

  /// Resolves thinking config for Gemini 3.x/4.x models using thinkingLevel (never thinkingBudget)
  static Map<String, dynamic>? resolveThinkingConfig(String model, {String? customThinkingLevel}) {
    final clean = model.replaceFirst(RegExp(r'^models/'), '').trim().toLowerCase();
    final isReasoning = !clean.contains('lite') &&
        (clean.startsWith('gemini-3') || clean.startsWith('gemini-4') || clean.contains('pro') || clean.contains('thinking'));
    if (!isReasoning) return null;
    final normalized = customThinkingLevel?.toUpperCase().trim();
    if (normalized == 'OFF') return null;
    return {'thinkingLevel': (normalized == 'AUTO' || normalized == null) ? 'MEDIUM' : normalized};
  }

  /// Decoupled Chain-of-Thought meal analysis schema with free-form volumetric reasoning,
  /// dish name, and food items (totals are calculated deterministically on client).
  static const Schema mealAnalysisSchema = Schema.object(
    description: 'Desglose nutricional y volumétrico desacoplado de comida',
    requiredProperties: ['razonamiento_volumetrico', 'plato', 'items'],
    properties: {
      'razonamiento_volumetrico': Schema.string(description: 'Pensamiento y deducción física libre: escala de vajilla, formas 3D, densidad, cocción, aceites y grasas ocultas'),
      'plato': Schema.string(description: 'Nombre representativo del plato'),
      'porcentaje_certeza': Schema.integer(description: 'Certeza 0-100 basada en visibilidad, oclusión y nitidez'),
      'margen_error_kcal': Schema.integer(description: 'Margen de error calórico estimado (+/- kcal)'),
      'items': Schema.array(
        description: 'Lista de alimentos desglosados con macros y micronutrientes',
        items: Schema.object(
          requiredProperties: ['alimento', 'gramos_estimados', 'calorias', 'proteinas_g', 'carbohidratos_g', 'grasas_g'],
          properties: {
            'alimento': Schema.string(description: 'Nombre individual'),
            'gramos_estimados': Schema.number(description: 'Masa derivada neta en gramos'),
            'calorias': Schema.number(description: 'Calorías calculadas'),
            'proteinas_g': Schema.number(description: 'Proteínas en gramos'),
            'carbohidratos_g': Schema.number(description: 'Carbohidratos en gramos'),
            'grasas_g': Schema.number(description: 'Grasas en gramos'),
            'fibra_g': Schema.number(description: 'Fibra en gramos'),
            'sodio_mg': Schema.number(description: 'Sodio en miligramos'),
            'azucar_g': Schema.number(description: 'Azúcar en gramos'),
          },
        ),
      ),
    },
  );

  static const String baseSystemInstruction = '''
Experto en nutrición clínica y estimación física volumétrica 3D de alimentos.
PIPELINE CAUSAL ESTRICTO - PIPELINE DE RAZONAMIENTO DESACOPLADO y causal en formato estricto JSON:
1. "razonamiento_volumetrico": Deducción 3D (vajilla, volumen cm³, densidad g/cm³, factor cocción, grasa oculta +5-10g).
2. "plato": Nombre gastronómico representativo.
3. "porcentaje_certeza": Entero 0-100 (visibilidad, nitidez y oclusión).
4. "margen_error_kcal": Entero (+/- kcal).
5. "items": Desglose obligatorio de ingredientes en 'items' (PROHIBIDO fijar 200g genéricos).
Para cada ítem en "items" reporta: alimento, gramos_estimados, calorias, proteinas_g, carbohidratos_g, grasas_g, fibra_g, sodio_mg, azucar_g.
Los totales nutricionales son derivados y calculados en cliente desde estos items.
Reglas obligatorias de cubicaje:
- Puño cerrado ~ 1 taza de volumen (~140-180g de arroz cocido, ~130-160g de legumbres cocidas).
- Palma de la mano (grosor del meñique) ~ 100-130g de carne, pollo o pescado cocido.
- Pulgar / Falange distal ~ 1 cucharada o ~10-15g de aceite o grasa.
- Dos manos ahuecadas ~ 50-80g de ensalada de hojas crudas.
- Conversión cocido vs crudo: arroz y pasta multiplican su peso x2.5 a 3 por absorción de agua. Carnes merma 20% a 25%.
- Regla de Grasa Oculta en Comida Casera: detección visual de aceites, brillo superficial y grasa oculta en sofritos/guisos (5g y 10g adicionales de grasa).
- Porciones compartidas: si el contexto indica porción compartida, calcula exclusivamente la porción consumida.
- Formato estricto: Responde únicamente con el JSON estructurado según el esquema.
''';

  static const String baseSystemInstructionEn = '''
Clinical nutritionist and 3D physical volumetric food estimation expert.
DECOUPLED REASONING PIPELINE and strict causal JSON response:
1. "razonamiento_volumetrico": Free-form 3D deduction (dishware scale, volume cm³, density g/cm³, cooking state, hidden fat/oil +5-10g).
2. "plato": Representative culinary dish name.
3. "porcentaje_certeza": Integer 0-100 (visibility, clarity, occlusion).
4. "margen_error_kcal": Integer (+/- kcal).
5. "items": Itemized breakdown of EVERY food item (never empty items or generic 200g).
For each item in "items" report: alimento, gramos_estimados, calorias, proteinas_g, carbohidratos_g, grasas_g, fibra_g, sodio_mg, azucar_g.
Nutritional totals are derived and computed on client from these items.
Sizing rules: fist ~ 1 cup (150-180g rice/legumes); palm ~ 100-130g meat; thumb ~ 10-15g fat; 2 cupped hands ~ 60-80g salad.
Rice/pasta expands 2.5-3x in water. Meat cooks down 20-25%.
Output ONLY structured JSON matching the schema.
''';

  static String buildSystemPrompt({
    String? masterPrompt,
    String? pantryContext,
    String language = 'es',
  }) {
    final isEn = language.toLowerCase().startsWith('en');
    final baseInstruction = isEn ? baseSystemInstructionEn : baseSystemInstruction;
    if ((masterPrompt == null || masterPrompt.trim().isEmpty) &&
        (pantryContext == null || pantryContext.trim().isEmpty)) {
      return baseInstruction;
    }
    final buffer = StringBuffer(baseInstruction);
    if (masterPrompt != null && masterPrompt.trim().isNotEmpty) {
      buffer.writeln(isEn
          ? '\n--- DINER BIOLOGICAL CONTEXT & GOALS (MASTER PROMPT) ---'
          : '\n--- CONTEXTO BIOLÓGICO Y METAS DEL COMENSAL (MASTER PROMPT) ---');
      buffer.writeln(masterPrompt.trim());
      buffer.writeln(isEn
          ? 'Adjust your estimates and observations taking into account the calorie goals and nutritional requirements of the diner.'
          : 'Ajusta tus estimaciones y observaciones considerando las metas calóricas, requerimientos y contexto nutricional del comensal.');
    }
    if (pantryContext != null && pantryContext.trim().isNotEmpty) {
      buffer.writeln(isEn
          ? '\n--- DINER PANTRY & PERSONAL BRANDS ---'
          : '\n--- DESPENSA Y MARCAS PERSONALES DEL COMENSAL ---');
      buffer.writeln(pantryContext.trim());
      buffer.writeln(isEn
          ? 'If you identify foods derived from these brands, prioritize their pantry nutritional values.'
          : 'Si identificas alimentos o preparaciones derivadas de estas marcas, utiliza prioritariamente los valores y proporciones de su despensa personal para maximizar la exactitud nutricional.');
    }
    return buffer.toString();
  }

  static String buildUserPrompt({String? userContext, double? dishwareDiameterCm, String language = 'es'}) {
    final isEn = language.toLowerCase().startsWith('en');
    final buffer = StringBuffer();
    if (isEn) {
      buffer.writeln('Thoroughly analyze this home-cooked meal and estimate its nutritional breakdown following volumetric rules.\n'
          'MANDATORY CAUSAL ORDER: razonamiento_volumetrico (3D deduction, dishware, density, fat) -> plato -> items.\n'
          'CORE BREAKDOWN RULES:\n'
          '1. MANDATORY INDIVIDUAL BREAKDOWN: Identify and itemize EACH food in "items" with proteinas_g and micronutrients (fibra_g, sodio_mg, azucar_g). NEVER return empty items.\n'
          '2. SINGLE-ITEM MEALS: If the dish is a single item, return it as 1 item in "items".\n'
          '3. REALISTIC GRAMS: NEVER use generic 200g. Derive grams from visual density and 3D volume.\n'
          '4. The sum of calories, macronutrients and micronutrients of individual items makes up the totals calculated by the app.');
    } else {
      buffer.writeln('Analiza minuciosamente esta comida casera y estima su desglose nutricional siguiendo las reglas volumétricas.\n'
          'ORDEN CAUSAL OBLIGATORIO: razonamiento_volumetrico (deducción libre 3D, vajilla, densidad, grasa) -> plato -> items.\n'
          'REGLAS FUNDAMENTALES DE DESGLOSE:\n'
          '1. DESGLOSE INDIVIDUAL OBLIGATORIO: Identifica y desglosa CADA alimento en "items" con proteinas_g y micronutrientes (fibra_g, sodio_mg, azucar_g). NUNCA devuelvas items vacío.\n'
          '2. COMIDAS UNITARIAS: Si el plato contiene un solo elemento (ej. manzana, sándwich, café), devuélvelo como 1 ítem en "items".\n'
          '3. GRAMOS REALISTAS: PROHIBIDO fijar 200g genéricos. Deriva gramos por densidad visual y volumen 3D.\n'
          '4. La suma de calorías, macronutrientes y micronutrientes de los items individuales conforma los totales calculados por la app.');
    }
    if (dishwareDiameterCm != null && dishwareDiameterCm > 0) {
      buffer.writeln(isEn
          ? '\nDiner metric scale reference: Plate diameter is ${dishwareDiameterCm.toStringAsFixed(1)} cm. Use plate edges as geometric reference scale to calculate area, volume, and gram weight.'
          : '\nEscala métrica de referencia del comensal: El plato tiene un diámetro de ${dishwareDiameterCm.toStringAsFixed(1)} cm. Utiliza los bordes del plato como escala métrica geométrica absoluta para calcular el área, volumen y peso en gramos reales de los alimentos.');
    }
    if (userContext != null && userContext.trim().isNotEmpty) {
      buffer.writeln(isEn ? 'Diner context and notes: ${userContext.trim()}' : 'Contexto y notas del comensal: ${userContext.trim()}');
    }
    return buffer.toString();
  }

  static String buildSubstitutionUserPrompt({
    required List<String> currentItemsSummary,
    required String oldIngredient,
    required String newIngredient,
    String? userNotes,
    double? dishwareDiameterCm,
    String language = 'es',
  }) {
    final isEn = language.toLowerCase().startsWith('en');
    final buffer = StringBuffer();
    if (isEn) {
      buffer.writeln("The diner substituted ingredient '$oldIngredient' with '$newIngredient'.\n"
          "Keep the volume and spatial distribution from the photo, but recalculate the specific macronutrients (with proteinas_g) and micronutrients for '$newIngredient'.");
      if (dishwareDiameterCm != null && dishwareDiameterCm > 0) {
        buffer.writeln('Plate metric scale reference: ${dishwareDiameterCm.toStringAsFixed(1)} cm diameter.');
      }
      buffer.writeln('\nPrevious ingredients identified in photo:');
      for (final item in currentItemsSummary) {
        buffer.writeln('- $item');
      }
      if (userNotes != null && userNotes.trim().isNotEmpty) {
        buffer.writeln('\nDiner notes: ${userNotes.trim()}');
      }
    } else {
      buffer.writeln("El comensal corrigió el ingrediente '$oldIngredient' por '$newIngredient'.\n"
          "Conserva el volumen y la distribución espacial de la foto, pero recalcula los macronutrientes (con proteinas_g) y micronutrientes específicos para '$newIngredient'.");
      if (dishwareDiameterCm != null && dishwareDiameterCm > 0) {
        buffer.writeln('Escala métrica de referencia del plato: ${dishwareDiameterCm.toStringAsFixed(1)} cm de diámetro.');
      }
      buffer.writeln('\nIngredientes previos identificados en la foto:');
      for (final item in currentItemsSummary) {
        buffer.writeln('- $item');
      }
      if (userNotes != null && userNotes.trim().isNotEmpty) {
        buffer.writeln('\nNotas del comensal: ${userNotes.trim()}');
      }
    }
    return buffer.toString();
  }

  static String buildSpeechUserPrompt({String? userNotes}) {
    final buffer = StringBuffer(
      'El comensal describe por voz natural los alimentos que consumió.\n'
      'Escucha minuciosamente el audio, transcribe e identifica cada alimento y porción indicada.\n'
      'Calcula sus gramos estimados, calorías, proteinas_g, carbohidratos_g, grasas_g y micronutrientes (fibra_g, sodio_mg, azucar_g).\n'
      'Genera el razonamiento volumétrico libre y el desglose estructurado en "items". Los totales son calculados en cliente.\n',
    );
    if (userNotes != null && userNotes.trim().isNotEmpty) buffer.writeln('\nNotas adicionales del comensal: ${userNotes.trim()}');
    return buffer.toString();
  }

  static String buildVideoFramesUserPrompt({required int framesCount, String? userNotes, double? dishwareDiameterCm}) {
    final buffer = StringBuffer(
      'Se proporcionan $framesCount fotogramas clave de video capturados desde diferentes ángulos del plato.\n'
      'Realiza una inferencia volumétrica tridimensional combinando la perspectiva cenital y angular de los fotogramas para calcular con máxima precisión la profundidad, volumen y peso en gramos de cada alimento visible.\n',
    );
    if (dishwareDiameterCm != null && dishwareDiameterCm > 0) buffer.writeln('Escala métrica de referencia del plato: ${dishwareDiameterCm.toStringAsFixed(1)} cm de diámetro.');
    if (userNotes != null && userNotes.trim().isNotEmpty) buffer.writeln('\nNotas del comensal: ${userNotes.trim()}');
    return buffer.toString();
  }
}
