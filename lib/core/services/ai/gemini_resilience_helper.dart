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

  const GeminiSchema.object({this.description, this.requiredProperties, this.properties})
      : type = 'OBJECT', items = null;
  const GeminiSchema.string({this.description})
      : type = 'STRING', requiredProperties = null, properties = null, items = null;
  const GeminiSchema.number({this.description})
      : type = 'NUMBER', requiredProperties = null, properties = null, items = null;
  const GeminiSchema.integer({this.description})
      : type = 'INTEGER', requiredProperties = null, properties = null, items = null;
  const GeminiSchema.array({this.description, this.items})
      : type = 'ARRAY', requiredProperties = null, properties = null;

  Map<String, dynamic> toMap() => {
    'type': type,
    if (description != null) 'description': description,
    if (requiredProperties != null) 'required': requiredProperties,
    if (properties != null)
      'properties': properties!.map((k, v) => MapEntry(k, v is GeminiSchema ? v.toMap() : v)),
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
    final lower = model.toLowerCase();
    final isReasoning = !lower.contains('lite') &&
        (lower.startsWith('gemini-3') || lower.startsWith('gemini-4') || lower.contains('pro') || lower.contains('thinking'));
    if (!isReasoning) return null;
    return {'thinkingLevel': customThinkingLevel ?? 'MEDIUM'};
  }

  /// Decoupled Chain-of-Thought meal analysis schema with free-form volumetric reasoning,
  /// dish name, and food items (totals are calculated deterministically on client).
  static const Schema mealAnalysisSchema = Schema.object(
    description: 'Desglose nutricional y volumétrico desacoplado de comida',
    requiredProperties: ['razonamiento_volumetrico', 'plato', 'items'],
    properties: {
      'razonamiento_volumetrico': Schema.string(description: 'Pensamiento y deducción física libre: escala de vajilla, formas 3D, densidad, cocción, aceites y grasas ocultas'),
      'plato': Schema.string(description: 'Nombre representativo del plato'),
      'porcentaje_certeza': Schema.integer(description: 'Porcentaje estimado de certeza de la IA entre 0 y 100 basado en visibilidad, oclusión y nitidez de porciones'),
      'margen_error_kcal': Schema.integer(description: 'Margen de error calórico estimado en kilocalorías (+/- kcal)'),
      'items': Schema.array(
        description: 'Lista de alimentos desglosados (1 único ítem si es preparación unitaria, o múltiples si contiene ingredientes variados)',
        items: Schema.object(
          requiredProperties: ['alimento', 'gramos_estimados', 'calorias', 'proteinas_g', 'carbohidratos_g', 'grasas_g'],
          properties: {
            'alimento': Schema.string(description: 'Nombre del alimento individual'),
            'gramos_estimados': Schema.number(description: 'Masa derivada neta en gramos'),
            'calorias': Schema.number(description: 'Calorías calculadas a partir de gramos_estimados'),
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
Eres un nutricionista clínico y experto en estimación física y volumétrica 3D de alimentos para comidas caseras y tradicionales.

PIPELINE CAUSAL ESTRICTO - PIPELINE DE RAZONAMIENTO DESACOPLADO:
1. 'razonamiento_volumetrico': Redacta primero un análisis de texto libre en lenguaje natural donde deduzcas:
   - Escala métrica y vajilla de referencia (diámetro del plato en cm o vajilla visible).
   - Formas tridimensionales de cada alimento y volumen espacial en cm³.
   - Densidad física (g/cm³) y factor de cocción.
   - Regla de Grasa Oculta en Comida Casera: detección visual de aceites, brillo superficial y grasa oculta en sofritos/guisos (5g y 10g adicionales de grasa).
   - Masa neta derivada en gramos para cada componente.
2. 'plato': Asigna el nombre gastronómico representativo de la comida.
3. 'porcentaje_certeza' y 'margen_error_kcal':
   - Estima 'porcentaje_certeza' como un entero entre 0 y 100 basado en visibilidad, nitidez y oclusión de porciones.
   - Estima 'margen_error_kcal' como un entero en kilocalorías (+/- kcal) que refleje la incertidumbre de la estimación.
4. 'items': Desglose obligatorio de ingredientes en 'items'. Desglosa cada alimento identificado con sus gramos estimados, macronutrientes (calorias, proteinas_g, carbohidratos_g, grasas_g) y micronutrientes (fibra_g, sodio_mg, azucar_g).
   - Si la comida consta de un solo alimento o preparación unitaria, desglósalo como un único ítem en 'items'.
   - Si la comida contiene múltiples alimentos combinados, desglosa individualmente cada ingrediente o elemento reconocible.
   - Los totales nutricionales generales son derivados y calculados determinísticamente por la aplicación a partir de estos items.

Ejemplo Few-Shot de salida:
{
  "razonamiento_volumetrico": "Plato hondo de 24 cm de diámetro con guiso de lentejas y arroz blanco. El arroz ocupa un volumen semiesférico de aprox. 150 cm³ con densidad 1.3 g/cm³, totalizando ~195g cocidos. Las lentejas ocupan aprox. 180 cm³ con caldo espeso (~200g). Se aprecia brillo de aceite de oliva en sofrito (+8g de grasa).",
  "plato": "Lentejas estofadas con arroz blanco",
  "porcentaje_certeza": 90,
  "margen_error_kcal": 45,
  "items": [
    {"alimento": "Arroz blanco cocido", "gramos_estimados": 195, "calorias": 250, "proteinas_g": 5, "carbohidratos_g": 54, "grasas_g": 1, "fibra_g": 1.2, "sodio_mg": 2.0, "azucar_g": 0.1},
    {"alimento": "Lentejas guisadas con sofrito", "gramos_estimados": 200, "calorias": 230, "proteinas_g": 16, "carbohidratos_g": 32, "grasas_g": 9, "fibra_g": 8.0, "sodio_mg": 380.0, "azucar_g": 2.5}
  ]
}

Reglas obligatorias de cubicaje:
- Puño cerrado ~ 1 taza de volumen (~140-180g de arroz cocido, ~130-160g de legumbres cocidas).
- Palma de la mano (grosor del meñique) ~ 100-130g de carne, pollo o pescado cocido.
- Pulgar / Falange distal ~ 1 cucharada o ~10-15g de aceite o grasa.
- Dos manos ahuecadas ~ 50-80g de ensalada de hojas crudas.
- Conversión cocido vs crudo: arroz y pasta multiplican su peso x2.5 a 3 por absorción de agua. Carnes merma 20% a 25%.
- PROHIBIDO fijar 200g genéricos: deriva gramos por densidad visual y volumen 3D.
- Porciones compartidas: si el contexto indica porción compartida, calcula exclusivamente la porción consumida.
- Formato estricto: Responde únicamente con el JSON estructurado según el esquema.
''';

  static String buildSystemPrompt({String? masterPrompt, String? pantryContext}) {
    if ((masterPrompt == null || masterPrompt.trim().isEmpty) &&
        (pantryContext == null || pantryContext.trim().isEmpty)) {
      return baseSystemInstruction;
    }
    final buffer = StringBuffer(baseSystemInstruction);
    if (masterPrompt != null && masterPrompt.trim().isNotEmpty) {
      buffer.writeln('\n--- CONTEXTO BIOLÓGICO Y METAS DEL COMENSAL (MASTER PROMPT) ---');
      buffer.writeln(masterPrompt.trim());
      buffer.writeln('Ajusta tus estimaciones y observaciones considerando las metas calóricas, requerimientos y contexto nutricional del comensal.');
    }
    if (pantryContext != null && pantryContext.trim().isNotEmpty) {
      buffer.writeln('\n--- DESPENSA Y MARCAS PERSONALES DEL COMENSAL ---');
      buffer.writeln(pantryContext.trim());
      buffer.writeln('Si identificas alimentos o preparaciones derivadas de estas marcas (ej. arepas hechas con su harina de maíz habitual), utiliza prioritariamente los valores y proporciones de su despensa personal para maximizar la exactitud nutricional.');
    }
    return buffer.toString();
  }

  static String buildUserPrompt({String? userContext, double? dishwareDiameterCm}) {
    final buffer = StringBuffer();
    buffer.writeln('Analiza minuciosamente esta comida casera y estima su desglose nutricional siguiendo las reglas volumétricas.');
    buffer.writeln('ORDEN CAUSAL OBLIGATORIO: razonamiento_volumetrico (deducción libre 3D, vajilla, densidad, grasa) -> plato -> items.');
    buffer.writeln('REGLAS FUNDAMENTALES DE DESGLOSE:');
    buffer.writeln('1. DESGLOSE INDIVIDUAL OBLIGATORIO: Identifica y desglosa CADA alimento en "items" con proteinas_g y micronutrientes (fibra_g, sodio_mg, azucar_g). NUNCA devuelvas items vacío.');
    buffer.writeln('2. COMIDAS UNITARIAS: Si el plato contiene un solo elemento (ej. manzana, sándwich, café), devuélvelo como 1 ítem en "items".');
    buffer.writeln('3. GRAMOS REALISTAS: PROHIBIDO fijar 200g genéricos. Deriva gramos por densidad visual y volumen 3D.');
    buffer.writeln('4. La suma de calorías, macronutrientes y micronutrientes de los items individuales conforma los totales calculados por la app.');

    if (dishwareDiameterCm != null && dishwareDiameterCm > 0) {
      buffer.writeln('\nEscala métrica de referencia del comensal: El plato tiene un diámetro de ${dishwareDiameterCm.toStringAsFixed(1)} cm. Utiliza los bordes del plato como escala métrica geométrica absoluta para calcular el área, volumen y peso en gramos reales de los alimentos.');
    }
    if (userContext != null && userContext.trim().isNotEmpty) {
      buffer.writeln('Contexto y notas del comensal: ${userContext.trim()}');
    }
    return buffer.toString();
  }

  static String buildSubstitutionUserPrompt({
    required List<String> currentItemsSummary,
    required String oldIngredient,
    required String newIngredient,
    String? userNotes,
    double? dishwareDiameterCm,
  }) {
    final buffer = StringBuffer();
    buffer.writeln("El comensal corrigió el ingrediente '$oldIngredient' por '$newIngredient'.");
    buffer.writeln("Conserva el volumen y la distribución espacial de la foto, pero recalcula los macronutrientes (con proteinas_g) y micronutrientes específicos para '$newIngredient'.");
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
    return buffer.toString();
  }

  static String buildSpeechUserPrompt({String? userNotes}) {
    final buffer = StringBuffer();
    buffer.writeln('El comensal describe por voz natural los alimentos que consumió.');
    buffer.writeln('Escucha minuciosamente el audio, transcribe e identifica cada alimento y porción indicada.');
    buffer.writeln('Calcula sus gramos estimados, calorías, proteinas_g, carbohidratos_g, grasas_g y micronutrientes (fibra_g, sodio_mg, azucar_g).');
    buffer.writeln('Genera el razonamiento volumétrico libre y el desglose estructurado en "items". Los totales son calculados en cliente.');
    if (userNotes != null && userNotes.trim().isNotEmpty) {
      buffer.writeln('\nNotas adicionales del comensal: ${userNotes.trim()}');
    }
    return buffer.toString();
  }

  static String buildVideoFramesUserPrompt({
    required int framesCount,
    String? userNotes,
    double? dishwareDiameterCm,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Se proporcionan $framesCount fotogramas clave de video capturados desde diferentes ángulos del plato.');
    buffer.writeln('Realiza una inferencia volumétrica tridimensional combinando la perspectiva cenital y angular de los fotogramas para calcular con máxima precisión la profundidad, volumen y peso en gramos de cada alimento visible.');
    if (dishwareDiameterCm != null && dishwareDiameterCm > 0) {
      buffer.writeln('Escala métrica de referencia del plato: ${dishwareDiameterCm.toStringAsFixed(1)} cm de diámetro.');
    }
    if (userNotes != null && userNotes.trim().isNotEmpty) {
      buffer.writeln('\nNotas del comensal: ${userNotes.trim()}');
    }
    return buffer.toString();
  }
}
