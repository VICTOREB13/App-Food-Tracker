import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Helper utility managing exponential backoff, jitter, and causal schemas for Gemini Vision.
class GeminiResilienceHelper {
  static const String fallbackModel = 'gemini-2.5-flash';

  static bool isRetriableError(dynamic error) {
    if (error == null) return false;
    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException ||
        error is HandshakeException) {
      return true;
    }
    final s = error.toString().toLowerCase();
    return s.contains('429') ||
        s.contains('resource_exhausted') ||
        s.contains('quota') ||
        s.contains('rate limit') ||
        s.contains('500') ||
        s.contains('502') ||
        s.contains('503') ||
        s.contains('504') ||
        s.contains('bad gateway') ||
        s.contains('gateway timeout') ||
        s.contains('unavailable') ||
        s.contains('overloaded') ||
        s.contains('socketexception') ||
        s.contains('timeoutexception') ||
        s.contains('clientexception') ||
        s.contains('handshakeexception') ||
        s.contains('httpexception') ||
        s.contains('network') ||
        s.contains('timed out') ||
        s.contains('respuesta vacía') ||
        s.contains('empty response');
  }

  static Future<T> executeWithRetry<T>({
    required Future<T> Function(int attempt, String currentModel) action,
    required String primaryModel,
    String secondaryModel = fallbackModel,
    int maxAttempts = 3,
    List<Duration>? customDelays,
    @visibleForTesting bool addJitter = true,
  }) async {
    final delays = customDelays ??
        const [
          Duration(seconds: 2),
          Duration(seconds: 5),
          Duration(seconds: 10),
        ];

    dynamic lastError;
    String currentModel = primaryModel;
    final random = Random();

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await action(attempt, currentModel);
      } catch (e) {
        lastError = e;
        if (!isRetriableError(e) || attempt == maxAttempts - 1) {
          rethrow;
        }

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

  /// Strict causal meal analysis schema forcing autoregressive physical deduction
  /// order before computing grams and macros.
  static Schema get mealAnalysisSchema => Schema.object(
        description: 'Desglose nutricional y volumétrico causal de comida',
        requiredProperties: ['plato', 'items', 'totales'],
        properties: {
          'plato': Schema.string(description: 'Nombre representativo del plato'),
          'items': Schema.array(
            description: 'Lista obligatoria con desglose causal de cada alimento visible',
            items: Schema.object(
              requiredProperties: [
                'alimento',
                'forma_geometrica_3d',
                'dimensiones_estimadas_cm',
                'volumen_cm3',
                'densidad_g_cm3',
                'gramos_estimados',
                'calorias',
                'proteinas_g',
                'carbohidratos_g',
                'grasas_g',
              ],
              properties: {
                'alimento': Schema.string(description: '1. Nombre del alimento individual'),
                'referencia_metrica': Schema.string(description: '1b. Referencia métrica (plato en cm o proporción)'),
                'forma_geometrica_3d': Schema.string(description: '2a. Forma geométrica 3D (semiesfera, prisma, cilindro)'),
                'dimensiones_estimadas_cm': Schema.string(description: '2b. Dimensiones estimadas Largo x Ancho x Alto en cm'),
                'volumen_cm3': Schema.number(description: '2c. Volumen tridimensional estimado en cm³'),
                'densidad_g_cm3': Schema.number(description: '3a. Densidad física aproximada en g/cm³'),
                'factor_coccion': Schema.number(description: '3b. Factor de cocción (hidratación o contracción)'),
                'grasa_visible_o_oculta': Schema.string(description: '4. Detección de brillo, aceites o sofritos'),
                'gramos_estimados': Schema.number(description: '5. Gramos derivados: volumen x densidad x factor'),
                'calorias': Schema.number(description: '6a. Calorías calculadas a partir de gramos_estimados'),
                'proteinas_g': Schema.number(description: '6b. Proteínas en gramos deducidas de gramos_estimados'),
                'carbohidratos_g': Schema.number(description: '6c. Carbohidratos en gramos deducidos de gramos_estimados'),
                'grasas_g': Schema.number(description: '6d. Grasas en gramos deducidas de gramos_estimados y aceites'),
                'fibra_g': Schema.number(description: '6e. Fibra en gramos'),
                'sodio_mg': Schema.number(description: '6f. Sodio en miligramos'),
                'azucar_g': Schema.number(description: '6g. Azúcar en gramos'),
                'justificacion_visual': Schema.string(description: '7. Justificación explicativa causal y volumétrica'),
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
              'fibra_g': Schema.number(description: 'Total fibra en gramos'),
              'sodio_mg': Schema.number(description: 'Total sodio en miligramos'),
              'azucar_g': Schema.number(description: 'Total azúcar en gramos'),
            },
          ),
        },
      );

  static const String baseSystemInstruction = '''
Eres un nutricionista clínico y experto en estimación física y volumétrica 3D de alimentos para comidas caseras y tradicionales.

PIPELINE CAUSAL ESTRICTO DE PENSAMIENTO E INFERENCIA (Física Autorregresiva):
Para CADA alimento visible en la foto, deduce sus propiedades físicas en riguroso orden causal ANTES de calcular gramos y macronutrientes:
1. Identificación y Referencia Métrica:
   - Identifica el alimento individual y toma como referencia la escala métrica disponible (diámetro del plato en cm o vajilla calibrada).
2. Estimación Geométrica 3D:
   - Modela la forma tridimensional aproximada (semiesfera, cilindro, disco, prisma irregular) y estima dimensiones en cm (L x W x H).
   - Calcula el volumen espacial tridimensional en cm³ (volumen_cm3).
3. Densidad Física y Factor de Cocción:
   - Determina la densidad física aproximada (densidad_g_cm3, ej. arroz/pastas cocidas ~1.2-1.3, carnes ~1.1-1.3, legumbres con caldo ~1.1-1.2, ensaladas ~0.3-0.5, aceites ~0.9).
   - Aplica el factor de cocción: expansión por hidratación de agua (arroz x2.5-3, legumbres x2) o contracción/merma por pérdida de jugos en carnes (20-25%).
4. Detección Visual de Aceites y Grasa Oculta:
   - Observa brillo especular, fritura, aderezos o grasa oculta en sofritos/guisos caseros (añade siempre entre 5g y 10g adicionales de grasa por ración no evidente).
5. Gramos Calculados (Masa Derivada):
   - Deriva los gramos_estimados rigurosamente: volumen_cm3 x densidad_g_cm3 x factor_coccion. PROHIBIDO fijar 200g genéricos.
6. Macronutrientes y Micronutrientes Deducidos:
   - Deriva calorías y macronutrientes estrictamente a partir de los gramos calculados en el paso 5.
7. Justificación Visual Explicativa:
   - Resume la justificación física y volumétrica observada.

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
   - Es ESTRICTAMENTE OBLIGATORIO desglosar de forma individual cada alimento visible en 'items'. NUNCA devuelvas 'items' como un arreglo vacío. Mínimo 2 o más items si hay varios alimentos.
   - PROHIBIDO agrupar o duplicar el nombre del plato como único elemento en 'items'.
   - Para cada alimento en 'items', estima con precisión sus gramos, calorías, proteínas, carbohidratos y grasas específicos.
   - La suma de las calorías y macronutrientes de los 'items' individuales debe coincidir con 'totales'.
6. Estimación volumétrica precisa de gramos (PROHIBIDO fijar 200g genéricos):
   - PROHIBIDO asignar 200g de forma genérica o repetitiva a los ingredientes o al plato.
7. Formato estricto:
   - Responde únicamente con el JSON estructurado según el esquema.
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

  static String buildUserPrompt({
    String? userContext,
    double? dishwareDiameterCm,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Analiza minuciosamente esta comida casera y estima su desglose nutricional siguiendo las reglas volumétricas.');
    buffer.writeln('ORDEN CAUSAL OBLIGATORIO: Identifica referencia métrica -> Geometría 3D y volumen cm³ -> Densidad y cocción -> Brillo/grasa oculta -> Masa en gramos -> Macronutrientes.');
    buffer.writeln('REGLAS FUNDAMENTALES DE DESGLOSE:');
    buffer.writeln('1. DESGLOSE INDIVIDUAL OBLIGATORIO: Identifica y desglosa CADA alimento visible en la lista "items" con sus macros y micronutrientes (fibra_g, sodio_mg, azucar_g). NUNCA devuelvas items vacío.');
    buffer.writeln('2. PROHIBIDO DUPLICAR EL PLATO: NUNCA coloques el plato entero como un único ingrediente.');
    buffer.writeln('3. GRAMOS REALISTAS: PROHIBIDO fijar 200g genéricos. Deriva gramos por densidad visual y volumen 3D.');
    buffer.writeln('4. La suma de calorías, macronutrientes y micronutrientes de los items individuales debe corresponder con los totales.');

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
    buffer.writeln("Conserva el volumen y la distribución espacial de la foto, pero recalcula los macronutrientes y micronutrientes específicos para '$newIngredient' y ajusta coherentemente el total del plato.");
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
    buffer.writeln('Calcula sus gramos estimados, calorías, proteínas, carbohidratos, grasas y micronutrientes (fibra_g, sodio_mg, azucar_g).');
    buffer.writeln('Genera el desglose estructurado obligatorio de cada alimento individual en "items" y los "totales".');
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
