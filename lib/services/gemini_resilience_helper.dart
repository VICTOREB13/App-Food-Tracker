import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Helper utility managing exponential backoff, jitter, and fallback switching for Gemini Vision.
class GeminiResilienceHelper {
  static const String fallbackModel = 'gemini-1.5-flash';

  static bool isRetriableError(dynamic error) {
    if (error == null) return false;
    final s = error.toString().toLowerCase();
    return s.contains('429') ||
        s.contains('resource_exhausted') ||
        s.contains('quota') ||
        s.contains('rate limit') ||
        s.contains('503') ||
        s.contains('500') ||
        s.contains('unavailable') ||
        s.contains('overloaded') ||
        s.contains('socketexception') ||
        s.contains('timeoutexception') ||
        s.contains('clientexception') ||
        s.contains('network') ||
        s.contains('timed out') ||
        error is SocketException ||
        error is TimeoutException;
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
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 4),
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

        // On repeated server/quota errors, fallback to secondary model
        if (attempt >= 1 && currentModel != secondaryModel) {
          currentModel = secondaryModel;
          debugPrint('GeminiResilienceHelper: Falling back to $currentModel');
        }

        final baseDelay = attempt < delays.length ? delays[attempt] : delays.last;
        final jitterMs = addJitter ? random.nextInt(400) : 0;
        final waitDuration = baseDelay + Duration(milliseconds: jitterMs);

        debugPrint('GeminiResilienceHelper: Retrying in ${waitDuration.inMilliseconds}ms (Attempt ${attempt + 1}/$maxAttempts) due to: $e');
        await Future.delayed(waitDuration);
      }
    }

    throw lastError ?? Exception('Operación fallida tras $maxAttempts reintentos');
  }

  static Schema get mealAnalysisSchema => Schema.object(
        description: 'Desglose nutricional, volumétrico y de micronutrientes de comida',
        requiredProperties: ['plato', 'items', 'totales'],
        properties: {
          'plato': Schema.string(description: 'Nombre representativo del plato'),
          'items': Schema.array(
            description: 'Lista obligatoria con el desglose individual de cada alimento visible',
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
                'alimento': Schema.string(description: 'Nombre del alimento individual'),
                'gramos_estimados': Schema.number(description: 'Peso realista estimado en gramos'),
                'calorias': Schema.number(description: 'Calorías estimadas'),
                'proteinas_g': Schema.number(description: 'Proteínas en gramos'),
                'carbohidratos_g': Schema.number(description: 'Carbohidratos en gramos'),
                'grasas_g': Schema.number(description: 'Grasas en gramos'),
                'fibra_g': Schema.number(description: 'Fibra en gramos'),
                'sodio_mg': Schema.number(description: 'Sodio en miligramos'),
                'azucar_g': Schema.number(description: 'Azúcar en gramos'),
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
              'fibra_g': Schema.number(description: 'Total fibra en gramos'),
              'sodio_mg': Schema.number(description: 'Total sodio en miligramos'),
              'azucar_g': Schema.number(description: 'Total azúcar en gramos'),
            },
          ),
        },
      );

  static String buildSystemPrompt({String? masterPrompt, String? pantryContext}) {
    final buffer = StringBuffer('''
Eres un nutricionista clínico y experto en estimación volumétrica visual de alimentos sin báscula para comidas caseras latinoamericanas y familiares.

Reglas obligatorias de cubicaje:
1. Referencias anatómicas de volumen:
   - Puño cerrado ~ 1 taza de volumen (~140-180g de arroz cocido, ~130-160g de legumbres cocidas).
   - Palma de la mano ~ 100-130g de carne, pollo o pescado cocido.
   - Pulgar ~ 1 cucharada o ~10-15g de aceite o grasa.
   - Dos manos ahuecadas ~ 50-80g de ensalada cruda.
2. Conversión cocido vs crudo:
   - Arroz y pasta absorben agua multiplicando por 2.5-3 su peso. Estima el peso cocido visible.
   - Carnes y aves merman 20-25% por pérdida de jugos.
3. Regla de Grasa Oculta:
   - Añade 5g a 10g de grasa oculta en sofritos/guisos.
4. Desglose obligatorio de ingredientes en 'items':
   - Desglosa individualmente cada alimento e ingrediente visible. NUNCA devuelvas lista vacía ni dupliques el plato entero como único item.
5. Estimación volumétrica precisa de gramos (PROHIBIDO fijar 200g genéricos):
   - Cada alimento debe tener un peso realista estimado según su densidad visual y área en el plato.
6. Micronutrientes obligatorios:
   - Para cada ingrediente y en los totales del plato, calcula con precisión: 'fibra_g', 'sodio_mg' y 'azucar_g'.
7. Formato estricto:
   - Responde únicamente con el JSON estructurado solicitado.
''');

    if (masterPrompt != null && masterPrompt.trim().isNotEmpty) {
      buffer.writeln('\n--- CONTEXTO BIOLÓGICO Y METAS DEL COMENSAL ---');
      buffer.writeln(masterPrompt.trim());
      buffer.writeln('Ajusta tus estimaciones considerando las metas y requerimientos del comensal.');
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
    buffer.writeln('REGLAS FUNDAMENTALES DE DESGLOSE:');
    buffer.writeln('1. DESGLOSE INDIVIDUAL OBLIGATORIO: Identifica y desglosa CADA alimento visible en la lista "items" con sus macros y micronutrientes (fibra_g, sodio_mg, azucar_g). NUNCA devuelvas items vacío.');
    buffer.writeln('2. PROHIBIDO DUPLICAR EL PLATO: NUNCA coloques el plato entero como un único ingrediente.');
    buffer.writeln('3. GRAMOS REALISTAS: PROHIBIDO fijar 200g genéricos. Estima gramos por densidad visual.');
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
