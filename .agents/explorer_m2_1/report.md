# Dynamic Google Gemini Models & Master Prompt Injection Report
**Victor Engineer - Food Tracker (NutriTracker Local-First) — Phase 2 Milestone 2**
*Document Version: 1.0.0 — Date: 2026-09-07*
*Author: Explorer M2.1 (`explorer_m2_1`)*

---

## 1. Executive Summary & Objective

In Phase 1, visual food logging was introduced via `GeminiVisionService` with a static default model (`gemini-2.5-flash`) and static volumetric cubic rules. In Phase 2, two key enhancements are required:
1. **Dynamic Model Discovery & Selection (R1)**: Eliminate hardcoding by querying Google's official Generative Language API endpoint (`GET https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}`), filtering vision-capable models (`generateContent` + `IMAGE` modality), normalizing IDs, sorting models by tiered recommendations (`gemini-2.5-flash`, `gemini-2.0-flash`, `gemini-2.5-pro`), and providing offline fallback models.
2. **Master Prompt Context Injection (R3)**: Dynamically inject the user's biological context and TDEE nutritional goals (synthesized from Mifflin-St Jeor calculations) into the `GeminiVisionService` system instructions alongside existing volumetric rules.

This report specifies the exact Dart architecture, code structures, error handling, and unit test fixtures for implementing `GeminiModelService` and updating `GeminiVisionService` without code regression.

---

## 2. Codebase Inspection: `GeminiVisionService` & Current Integrations

### 2.1 File Inspection: `lib/services/gemini_vision_service.dart`

- **Line 89-91**:
  ```dart
  final String apiKey;
  final String modelName;
  static const String defaultModel = 'gemini-2.5-flash';
  ```
  While `modelName` is accepted as an optional constructor parameter (defaulting to `gemini-2.5-flash`), it is not exposed dynamically during execution nor does it accept user profile context.
- **Line 93-112**:
  `static const String systemInstruction = '''...''';`
  The system instruction is a compile-time constant containing only the volumetric estimation rules (puño cerrado, palma de la mano, grasa oculta 5-10g, etc.). There is no mechanism to append the user's metabolic context or goals.
- **Line 158-167**:
  ```dart
  final model = GenerativeModel(
    model: modelName,
    apiKey: apiKey,
    systemInstruction: Content.system(systemInstruction),
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      responseSchema: schema,
      temperature: 0.2,
    ),
  );
  ```
  `GenerativeModel` hardcodes `Content.system(systemInstruction)`.
- **Calling Context in `lib/screens/dashboard_screen.dart` (Line 89)**:
  ```dart
  final gemini = GeminiVisionService(apiKey: apiKey);
  ```
  `dashboard_screen.dart` instantiates `GeminiVisionService` without passing `modelName`, always falling back to the hardcoded `defaultModel`.

### 2.2 Test Suite Inspection: `test/services/gemini_vision_service_test.dart`

- **Line 104-115**:
  ```dart
  test('Instrucciones del sistema contienen reglas de cubicaje casero latinoamericano', () {
    const prompt = GeminiVisionService.systemInstruction;
    expect(prompt, contains('Puño cerrado'));
    expect(prompt, contains('Palma de la mano'));
    expect(prompt, contains('Pulgar'));
    expect(prompt, contains('Conversión cocido vs crudo'));
    expect(prompt, contains('Grasa Oculta'));
    expect(prompt, contains('5g y 10g adicionales de grasa'));
    expect(prompt, contains('Porciones compartidas'));
  });
  ```
  **Critical Constraint**: The symbol `GeminiVisionService.systemInstruction` must be preserved (as a static constant or getter) so existing tests pass without breaking changes.

---

## 3. Data Model Design: `GeminiModelInfo`

`lib/models/gemini_model_info.dart` or exported inside `lib/services/gemini_model_service.dart`:

```dart
import 'package:flutter/foundation.dart';

@immutable
class GeminiModelInfo {
  /// Normalized model identifier without 'models/' prefix (e.g., 'gemini-2.5-flash')
  final String name;

  /// Human-readable name provided by Google (e.g., 'Gemini 2.5 Flash')
  final String displayName;

  /// Model capabilities description
  final String description;

  /// Whether this model is marked as recommended for visual food analysis
  final bool isRecommended;

  /// Semantic badge label displayed in Settings (e.g., 'RECOMENDADO (Ultrarrápido)')
  final String? recommendationLabel;

  /// Maximum input tokens supported by the model
  final int inputTokenLimit;

  /// Maximum output tokens supported
  final int outputTokenLimit;

  /// List of supported generation methods (e.g., ['generateContent', 'countTokens'])
  final List<String> supportedGenerationMethods;

  /// Input modalities supported (e.g., ['TEXT', 'IMAGE'])
  final List<String> inputModalities;

  const GeminiModelInfo({
    required this.name,
    required this.displayName,
    required this.description,
    required this.isRecommended,
    this.recommendationLabel,
    this.inputTokenLimit = 0,
    this.outputTokenLimit = 0,
    this.supportedGenerationMethods = const ['generateContent'],
    this.inputModalities = const ['TEXT', 'IMAGE'],
  });

  /// Factory to parse official Google Generative Language API model JSON object
  factory GeminiModelInfo.fromGoogleJson(
    Map<String, dynamic> json, {
    int? tierRank,
    String? recommendationLabel,
    bool? isRecommended,
  }) {
    final rawName = (json['name'] ?? '').toString();
    // Normalize: strip 'models/' prefix
    final cleanName = rawName.startsWith('models/') ? rawName.substring(7) : rawName;
    final displayName = (json['displayName'] ?? cleanName).toString();
    final description = (json['description'] ?? '').toString();
    final inputTokens = (json['inputTokenLimit'] as num?)?.toInt() ?? 0;
    final outputTokens = (json['outputTokenLimit'] as num?)?.toInt() ?? 0;

    final genMethods = (json['supportedGenerationMethods'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const ['generateContent'];

    final modalities = (json['inputModalities'] as List<dynamic>?)
            ?.map((e) => e.toString().toUpperCase())
            .toList() ??
        const [];

    return GeminiModelInfo(
      name: cleanName,
      displayName: displayName.isNotEmpty ? displayName : cleanName,
      description: description,
      isRecommended: isRecommended ?? false,
      recommendationLabel: recommendationLabel,
      inputTokenLimit: inputTokens,
      outputTokenLimit: outputTokens,
      supportedGenerationMethods: genMethods,
      inputModalities: modalities,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'displayName': displayName,
        'description': description,
        'isRecommended': isRecommended,
        'recommendationLabel': recommendationLabel,
        'inputTokenLimit': inputTokenLimit,
        'outputTokenLimit': outputTokenLimit,
        'supportedGenerationMethods': supportedGenerationMethods,
        'inputModalities': inputModalities,
      };

  factory GeminiModelInfo.fromJson(Map<String, dynamic> json) {
    return GeminiModelInfo(
      name: json['name']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isRecommended: json['isRecommended'] == true,
      recommendationLabel: json['recommendationLabel']?.toString(),
      inputTokenLimit: (json['inputTokenLimit'] as num?)?.toInt() ?? 0,
      outputTokenLimit: (json['outputTokenLimit'] as num?)?.toInt() ?? 0,
      supportedGenerationMethods: (json['supportedGenerationMethods'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['generateContent'],
      inputModalities: (json['inputModalities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['TEXT', 'IMAGE'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeminiModelInfo &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() =>
      'GeminiModelInfo(name: $name, displayName: $displayName, recommended: $isRecommended, badge: $recommendationLabel)';
}
```

---

## 4. Service Design: `GeminiModelService`

File: `lib/services/gemini_model_service.dart`

### 4.1 Requirements Checklist Alignment
1. **Endpoint**: `GET https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}`.
2. **Filtering**: `supportedGenerationMethods.contains('generateContent')` AND `inputModalities.contains('IMAGE')` (or model name contains 'gemini' and is not a non-vision model).
3. **Prefix**: Strip `models/` prefix.
4. **Tiered Recommendations**:
   - `gemini-2.5-flash`: `RECOMENDADO (Ultrarrápido)` (Top recommendation, rank 1)
   - `gemini-2.0-flash`: `ESTABLE (Alta Velocidad)` (Rank 2)
   - `gemini-2.5-pro`: `MÁXIMA PRECISIÓN (Razonamiento)` (Rank 3)
5. **Dependency Injection**: Injectable `http.Client` for clean unit tests.

### 4.2 Exact Implementation Structure

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/gemini_model_info.dart';

/// Typed exception for Google Gemini API errors
class GeminiApiException implements Exception {
  final int statusCode;
  final String message;
  final String? details;

  const GeminiApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  @override
  String toString() =>
      'GeminiApiException($statusCode): $message${details != null ? ' - $details' : ''}';
}

class GeminiModelService {
  final http.Client _client;
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  GeminiModelService({http.Client? client}) : _client = client ?? http.Client();

  static final GeminiModelService instance = GeminiModelService();

  /// Curated offline fallback models used when device is offline or API fails
  static const List<GeminiModelInfo> fallbackModels = [
    GeminiModelInfo(
      name: 'gemini-2.5-flash',
      displayName: 'Gemini 2.5 Flash',
      description: 'Modelo multimodal de última generación, ultrarrápido y de alta precisión visual.',
      isRecommended: true,
      recommendationLabel: 'RECOMENDADO (Ultrarrápido)',
      inputTokenLimit: 1048576,
      outputTokenLimit: 8192,
    ),
    GeminiModelInfo(
      name: 'gemini-2.0-flash',
      displayName: 'Gemini 2.0 Flash',
      description: 'Modelo multimodal de producción estable y alta velocidad de inferencia.',
      isRecommended: true,
      recommendationLabel: 'ESTABLE (Alta Velocidad)',
      inputTokenLimit: 1048576,
      outputTokenLimit: 8192,
    ),
    GeminiModelInfo(
      name: 'gemini-2.5-pro',
      displayName: 'Gemini 2.5 Pro',
      description: 'Modelo de razonamiento profundo para platos complejos, densos y mixtos.',
      isRecommended: true,
      recommendationLabel: 'MÁXIMA PRECISIÓN (Razonamiento)',
      inputTokenLimit: 2097152,
      outputTokenLimit: 8192,
    ),
    GeminiModelInfo(
      name: 'gemini-1.5-flash',
      displayName: 'Gemini 1.5 Flash',
      description: 'Modelo heredado rápido con amplia compatibilidad.',
      isRecommended: false,
      recommendationLabel: 'HEREDADO (Compatibilidad)',
      inputTokenLimit: 1048576,
      outputTokenLimit: 8192,
    ),
  ];

  /// Queries Google Generative Language API and returns sorted, filtered models
  Future<List<GeminiModelInfo>> fetchAvailableModels(
    String apiKey, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final sanitizedKey = apiKey.trim();
    if (sanitizedKey.isEmpty) {
      throw const GeminiApiException(
        statusCode: 400,
        message: 'La API Key de Gemini está vacía.',
      );
    }

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'key': sanitizedKey,
      'pageSize': '100',
    });

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return parseModelsResponse(response.body);
      }

      // Handle non-200 error bodies
      String errorMessage = 'Error al consultar modelos (${response.statusCode})';
      String? errorDetails;
      try {
        final Map<String, dynamic> errorJson = json.decode(response.body);
        if (errorJson['error'] is Map<String, dynamic>) {
          final err = errorJson['error'] as Map<String, dynamic>;
          errorDetails = err['message']?.toString();
        }
      } catch (_) {}

      switch (response.statusCode) {
        case 400:
          errorMessage = 'API Key de Gemini no válida o malformada.';
          break;
        case 403:
          errorMessage = 'Acceso denegado. Verifique permisos o cuota en Google AI Studio.';
          break;
        case 429:
          errorMessage = 'Cuota o límite de solicitudes excedido (HTTP 429).';
          break;
        case 500:
        case 503:
          errorMessage = 'Servicio de Google Gemini no disponible temporalmente.';
          break;
      }

      throw GeminiApiException(
        statusCode: response.statusCode,
        message: errorMessage,
        details: errorDetails,
      );
    } on SocketException catch (e) {
      throw GeminiApiException(
        statusCode: 0,
        message: 'Sin conexión a internet. Comprueba tu red.',
        details: e.message,
      );
    } on TimeoutException {
      throw const GeminiApiException(
        statusCode: 408,
        message: 'Tiempo de espera agotado al conectar con Google Gemini (10s).',
      );
    }
  }

  /// Parses raw JSON string into filtered and prioritized GeminiModelInfo list
  List<GeminiModelInfo> parseModelsResponse(String responseBody) {
    final Map<String, dynamic> data = json.decode(responseBody);
    final List<dynamic> rawList = (data['models'] as List<dynamic>?) ?? [];

    final List<GeminiModelInfo> filtered = [];

    for (final item in rawList) {
      if (item is! Map<String, dynamic>) continue;

      if (!isVisionCapableModel(item)) continue;

      final rawName = (item['name'] ?? '').toString();
      final cleanName = rawName.startsWith('models/') ? rawName.substring(7) : rawName;

      final tier = _calculateTierRank(cleanName);
      final label = _calculateRecommendationLabel(cleanName);
      final isRecommended = tier <= 3;

      filtered.add(GeminiModelInfo.fromGoogleJson(
        item,
        tierRank: tier,
        recommendationLabel: label,
        isRecommended: isRecommended,
      ));
    }

    // Sort by tier rank ascending (1 -> 2 -> 3 -> 99), then alphabetically by name
    filtered.sort((a, b) {
      final rankA = _calculateTierRank(a.name);
      final rankB = _calculateTierRank(b.name);
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.displayName.compareTo(b.displayName);
    });

    return filtered;
  }

  /// Primary + fallback criteria to determine if model can perform image food analysis
  static bool isVisionCapableModel(Map<String, dynamic> model) {
    // 1. Generation Method Filter: Must contain 'generateContent'
    final methods = (model['supportedGenerationMethods'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    if (!methods.contains('generateContent')) {
      return false;
    }

    final rawName = (model['name'] ?? '').toString().toLowerCase();

    // 2. Primary Check: If inputModalities is provided by Google API
    final modalities = (model['inputModalities'] as List<dynamic>?)
            ?.map((e) => e.toString().toUpperCase())
            .toList() ??
        [];
    if (modalities.isNotEmpty) {
      return modalities.contains('IMAGE');
    }

    // 3. Resilient Fallback Check: Name inspection if inputModalities is absent
    if (!rawName.contains('gemini')) {
      return false;
    }

    // Exclude explicit non-vision or specialized non-generalist prefixes
    const excludedKeywords = [
      'embedding',
      'imagen',
      'tts',
      'audio',
      'text-bison',
      'chat-bison',
      'learnlm',
      'aqa',
      'veo',
    ];

    for (final keyword in excludedKeywords) {
      if (rawName.contains(keyword)) return false;
    }

    return true;
  }

  /// Assigns priority rank to model ID:
  /// 1: gemini-2.5-flash / gemini-3.*-flash (Top recommendation)
  /// 2: gemini-2.0-flash (Estable)
  /// 3: gemini-2.5-pro / gemini-3.*-pro (Máxima Precisión)
  /// 4: gemini-2.0-flash-lite
  /// 5: gemini-1.5-flash / gemini-1.5-pro
  /// 99: All other models
  static int _calculateTierRank(String modelName) {
    final lower = modelName.toLowerCase();
    if (lower.startsWith('gemini-2.5-flash') ||
        (lower.startsWith('gemini-3') && lower.contains('flash'))) {
      return 1;
    }
    if (lower.startsWith('gemini-2.0-flash') && !lower.contains('lite')) {
      return 2;
    }
    if (lower.startsWith('gemini-2.5-pro') ||
        (lower.startsWith('gemini-3') && lower.contains('pro'))) {
      return 3;
    }
    if (lower.contains('flash-lite')) {
      return 4;
    }
    if (lower.startsWith('gemini-1.5-flash')) {
      return 5;
    }
    if (lower.startsWith('gemini-1.5-pro')) {
      return 6;
    }
    return 99;
  }

  /// Assigns semantic badge label displayed in UI
  static String? _calculateRecommendationLabel(String modelName) {
    final rank = _calculateTierRank(modelName);
    switch (rank) {
      case 1:
        return 'RECOMENDADO (Ultrarrápido)';
      case 2:
        return 'ESTABLE (Alta Velocidad)';
      case 3:
        return 'MÁXIMA PRECISIÓN (Razonamiento)';
      case 4:
        return 'LIGERO / ECONÓMICO';
      case 5:
      case 6:
        return 'HEREDADO (Compatibilidad)';
      default:
        return null;
    }
  }

  /// Resolves the effective model ID to use given the available models and stored preference
  static String resolveEffectiveModel({
    required List<GeminiModelInfo> availableModels,
    String? savedSelection,
  }) {
    if (savedSelection != null && savedSelection.trim().isNotEmpty) {
      final exists = availableModels.any((m) => m.name == savedSelection.trim());
      if (exists) return savedSelection.trim();
    }

    // Default to the first available recommended model or fallback
    final recommended = availableModels.firstWhere(
      (m) => m.isRecommended,
      orElse: () => availableModels.isNotEmpty
          ? availableModels.first
          : fallbackModels.first,
    );
    return recommended.name;
  }
}
```

---

## 5. `GeminiVisionService` Enhancements (Master Prompt & Dynamic Model)

File: `lib/services/gemini_vision_service.dart`

### 5.1 System Instruction Builder

We decouple the volumetric rules into `baseSystemInstruction`, keep `systemInstruction` as a backward-compatible alias, and provide `buildSystemInstruction([String? masterPrompt])`:

```dart
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
5. Formato estricto:
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

  Future<MealAnalysisResult> analyzeMealPhoto({
    required Uint8List rawImageBytes,
    String? userContext,
    String? overrideModel,
    String? overrideMasterPrompt,
  }) async {
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
          description: 'Lista de ingredientes o alimentos identificados',
          items: Schema.object(
            properties: {
              'alimento': Schema.string(description: 'Nombre del alimento o ingrediente'),
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
  }
}
```

### 5.2 Dynamic Invocations in `DashboardScreen` (Planned for M4)

When `DashboardScreen` invokes visual photo analysis:
```dart
// 1. Fetch user-selected model from SecureStorageService (with fallback to default)
final selectedModel = await SecureStorageService.instance.getGeminiModel() ?? GeminiVisionService.defaultModel;

// 2. Fetch active user profile from DatabaseService (M1) or cached masterPrompt
final userProfile = await DatabaseService.instance.getUserProfile();
final masterPrompt = userProfile?.masterPrompt;

// 3. Instantiate GeminiVisionService dynamically
final gemini = GeminiVisionService(
  apiKey: apiKey,
  modelName: selectedModel,
  masterPrompt: masterPrompt,
);
final analysis = await gemini.analyzeMealPhoto(rawImageBytes: bytes);
```

---

## 6. Error Handling & Network Resilience Matrix

| Error Scenario | Cause | Response / Exception | Recovery Strategy in UI & Service |
| :--- | :--- | :--- | :--- |
| **Invalid Key (HTTP 400)** | Typos or corrupted string | `GeminiApiException(400, 'API Key de Gemini no válida o malformada.')` | Surface inline error in `SettingsScreen`; do not clear previous valid model list. |
| **Forbidden (HTTP 403)** | Key lacks Gemini API permissions, billing issue, or geo-restriction | `GeminiApiException(403, 'Acceso denegado. Verifique permisos...')` | Notify user to enable Generative Language API in Google AI Studio. |
| **Rate Limit (HTTP 429)** | RPM or daily quota exhausted | `GeminiApiException(429, 'Cuota o límite de solicitudes excedido.')` | Show friendly snackbar; suggest user wait a minute or use a different API key. |
| **Server Outage (HTTP 500/503)** | Google service temporary failure | `GeminiApiException(500, 'Servicio de Google Gemini no disponible...')` | Fall back seamlessly to `GeminiModelService.fallbackModels`. |
| **Offline / Airplane Mode** | `SocketException` (DNS / No route) | `GeminiApiException(0, 'Sin conexión a internet...')` | Catch error in `SettingsController`; populate dropdown with cached or `fallbackModels`. |
| **Timeout (> 10s)** | High latency / throttled connection | `GeminiApiException(408, 'Tiempo de espera agotado...')` | Cancel HTTP connection to avoid blocking UI thread; provide retry action. |
| **Deprecated Model Selected** | Google retires previously selected model | Model missing from `availableModels` | `resolveEffectiveModel` detects absence and gracefully falls back to `gemini-2.5-flash`. |

---

## 7. Mock Data & Comprehensive Unit Test Strategy

### 7.1 Mock JSON Fixtures for Unit Testing

#### Fixture A: Success Response (`mockGeminiModelsSuccessJson`)
```json
{
  "models": [
    {
      "name": "models/gemini-2.5-flash",
      "version": "2.5",
      "displayName": "Gemini 2.5 Flash",
      "description": "Next-generation multimodal model offering fast speed, low latency, and highly accurate vision comprehension.",
      "inputTokenLimit": 1048576,
      "outputTokenLimit": 8192,
      "supportedGenerationMethods": ["generateContent", "countTokens"],
      "inputModalities": ["TEXT", "IMAGE"]
    },
    {
      "name": "models/gemini-2.5-pro",
      "version": "2.5",
      "displayName": "Gemini 2.5 Pro",
      "description": "State-of-the-art multimodal model with deep reasoning capabilities for complex visual analysis.",
      "inputTokenLimit": 2097152,
      "outputTokenLimit": 8192,
      "supportedGenerationMethods": ["generateContent", "countTokens"],
      "inputModalities": ["TEXT", "IMAGE"]
    },
    {
      "name": "models/gemini-2.0-flash",
      "version": "2.0",
      "displayName": "Gemini 2.0 Flash",
      "description": "Fast multimodal model for high-throughput tasks.",
      "inputTokenLimit": 1048576,
      "outputTokenLimit": 8192,
      "supportedGenerationMethods": ["generateContent", "countTokens"],
      "inputModalities": ["TEXT", "IMAGE"]
    },
    {
      "name": "models/gemini-1.5-flash",
      "version": "1.5",
      "displayName": "Gemini 1.5 Flash",
      "description": "Legacy fast multimodal model.",
      "inputTokenLimit": 1048576,
      "outputTokenLimit": 8192,
      "supportedGenerationMethods": ["generateContent"],
      "inputModalities": ["TEXT", "IMAGE"]
    },
    {
      "name": "models/text-embedding-004",
      "version": "004",
      "displayName": "Text Embedding 004",
      "description": "Generates high quality text embeddings.",
      "inputTokenLimit": 2048,
      "outputTokenLimit": 1,
      "supportedGenerationMethods": ["embedContent"],
      "inputModalities": ["TEXT"]
    },
    {
      "name": "models/imagen-3.0-generate-002",
      "version": "3.0",
      "displayName": "Imagen 3.0",
      "description": "Image generation model.",
      "inputTokenLimit": 512,
      "outputTokenLimit": 1,
      "supportedGenerationMethods": ["generateImage"]
    }
  ]
}
```

#### Fixture B: Missing Modalities / Proxy Response (`mockGeminiModelsMissingModalitiesJson`)
```json
{
  "models": [
    {
      "name": "models/gemini-2.5-flash",
      "displayName": "Gemini 2.5 Flash",
      "description": "Model with omitted modalities array.",
      "supportedGenerationMethods": ["generateContent"]
    },
    {
      "name": "models/text-embedding-004",
      "displayName": "Text Embedding",
      "supportedGenerationMethods": ["embedContent"]
    }
  ]
}
```

#### Fixture C: API Error 400 (`mockGeminiError400Json`)
```json
{
  "error": {
    "code": 400,
    "message": "API key not valid. Please pass a valid API key.",
    "status": "INVALID_ARGUMENT"
  }
}
```

#### Fixture D: API Error 403 (`mockGeminiError403Json`)
```json
{
  "error": {
    "code": 403,
    "message": "Method doesn't allow unregistered callers (callers without established identity).",
    "status": "PERMISSION_DENIED"
  }
}
```

### 7.2 Test Suite Specification: `test/services/gemini_model_service_test.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:food_tracker/services/gemini_model_service.dart';
import 'package:food_tracker/models/gemini_model_info.dart';

void main() {
  group('GeminiModelService Unit Tests', () {
    test('parseModelsResponse filters vision models and strips models/ prefix', () {
      final service = GeminiModelService();
      final models = service.parseModelsResponse(mockGeminiModelsSuccessJson);

      // Only 4 of 6 models should pass (gemini-2.5-flash, gemini-2.0-flash, gemini-2.5-pro, gemini-1.5-flash)
      expect(models.length, equals(4));

      // Discard text-embedding-004 and imagen-3.0
      expect(models.any((m) => m.name == 'text-embedding-004'), isFalse);
      expect(models.any((m) => m.name == 'imagen-3.0-generate-002'), isFalse);

      // Normalization check: no 'models/' prefix
      for (final m in models) {
        expect(m.name.startsWith('models/'), isFalse);
      }
    });

    test('parseModelsResponse applies tiered recommendation ranking and labels', () {
      final service = GeminiModelService();
      final models = service.parseModelsResponse(mockGeminiModelsSuccessJson);

      // 1st: gemini-2.5-flash (RECOMENDADO)
      expect(models[0].name, equals('gemini-2.5-flash'));
      expect(models[0].isRecommended, isTrue);
      expect(models[0].recommendationLabel, equals('RECOMENDADO (Ultrarrápido)'));

      // 2nd: gemini-2.0-flash (ESTABLE)
      expect(models[1].name, equals('gemini-2.0-flash'));
      expect(models[1].isRecommended, isTrue);
      expect(models[1].recommendationLabel, equals('ESTABLE (Alta Velocidad)'));

      // 3rd: gemini-2.5-pro (MÁXIMA PRECISIÓN)
      expect(models[2].name, equals('gemini-2.5-pro'));
      expect(models[2].isRecommended, isTrue);
      expect(models[2].recommendationLabel, equals('MÁXIMA PRECISIÓN (Razonamiento)'));

      // 4th: gemini-1.5-flash (HEREDADO)
      expect(models[3].name, equals('gemini-1.5-flash'));
      expect(models[3].isRecommended, isFalse);
      expect(models[3].recommendationLabel, equals('HEREDADO (Compatibilidad)'));
    });

    test('parseModelsResponse falls back to name inspection when inputModalities is missing', () {
      final service = GeminiModelService();
      final models = service.parseModelsResponse(mockGeminiModelsMissingModalitiesJson);

      expect(models.length, equals(1));
      expect(models.first.name, equals('gemini-2.5-flash'));
    });

    test('fetchAvailableModels handles HTTP 400 Invalid Key error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(mockGeminiError400Json, 400);
      });

      final service = GeminiModelService(client: mockClient);

      expect(
        () => service.fetchAvailableModels('invalid-key'),
        throwsA(isA<GeminiApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(400),
        )),
      );
    });

    test('fetchAvailableModels handles HTTP 403 Permission Denied error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(mockGeminiError403Json, 403);
      });

      final service = GeminiModelService(client: mockClient);

      expect(
        () => service.fetchAvailableModels('blocked-key'),
        throwsA(isA<GeminiApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(403),
        )),
      );
    });

    test('fetchAvailableModels rejects empty API key without network call', () async {
      final service = GeminiModelService();
      expect(
        () => service.fetchAvailableModels('   '),
        throwsA(isA<GeminiApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(400),
        )),
      );
    });

    test('resolveEffectiveModel returns saved selection if valid', () {
      final models = [
        const GeminiModelInfo(
          name: 'gemini-2.0-flash',
          displayName: 'Gemini 2.0 Flash',
          description: '',
          isRecommended: true,
        ),
        const GeminiModelInfo(
          name: 'gemini-2.5-flash',
          displayName: 'Gemini 2.5 Flash',
          description: '',
          isRecommended: true,
        ),
      ];

      final resolved = GeminiModelService.resolveEffectiveModel(
        availableModels: models,
        savedSelection: 'gemini-2.0-flash',
      );
      expect(resolved, equals('gemini-2.0-flash'));
    });

    test('resolveEffectiveModel falls back to top recommendation if saved model is missing', () {
      final models = [
        const GeminiModelInfo(
          name: 'gemini-2.5-flash',
          displayName: 'Gemini 2.5 Flash',
          description: '',
          isRecommended: true,
        ),
      ];

      final resolved = GeminiModelService.resolveEffectiveModel(
        availableModels: models,
        savedSelection: 'deprecated-model',
      );
      expect(resolved, equals('gemini-2.5-flash'));
    });
  });
}
```

### 7.3 Test Suite Specification for `GeminiVisionService` Master Prompt

In `test/services/gemini_vision_service_test.dart`:

```dart
test('buildSystemInstruction sin masterPrompt devuelve baseSystemInstruction intacta', () {
  final resultNull = GeminiVisionService.buildSystemInstruction(null);
  final resultEmpty = GeminiVisionService.buildSystemInstruction('');
  final resultWhitespace = GeminiVisionService.buildSystemInstruction('   ');

  expect(resultNull, equals(GeminiVisionService.systemInstruction));
  expect(resultEmpty, equals(GeminiVisionService.systemInstruction));
  expect(resultWhitespace, equals(GeminiVisionService.systemInstruction));
});

test('buildSystemInstruction con masterPrompt inyecta contexto biológico y metas', () {
  const masterPrompt = '''
USUARIO: Varón, 28 años, 78kg, 178cm.
ACTIVIDAD: Moderada (10,000 pasos/día, fuerza 4x/semana).
OBJETIVO: Pérdida de grasa (-500 kcal).
METAS DIARIAS: 2,100 kcal | 160g Proteína | 210g Carbohidratos | 60g Grasa.
''';

  final prompt = GeminiVisionService.buildSystemInstruction(masterPrompt);

  // Must retain original volumetric rules
  expect(prompt, contains('Puño cerrado'));
  expect(prompt, contains('Palma de la mano'));
  expect(prompt, contains('5g y 10g adicionales de grasa'));

  // Must include Master Prompt section
  expect(prompt, contains('--- CONTEXTO BIOLÓGICO Y METAS DEL COMENSAL (MASTER PROMPT) ---'));
  expect(prompt, contains('Pérdida de grasa (-500 kcal)'));
  expect(prompt, contains('160g Proteína'));
  expect(prompt, contains('Ajusta tus estimaciones y observaciones considerando las metas calóricas'));
});
```

---

## 8. Implementation Steps for Worker Agents

1. **Step 1: Create `GeminiModelInfo`**:
   - Create `lib/models/gemini_model_info.dart` with immutability, `fromGoogleJson`, `toJson`, `fromJson`, and `operator ==`.
2. **Step 2: Implement `GeminiModelService`**:
   - Create `lib/services/gemini_model_service.dart` with injectable `http.Client`, `fetchAvailableModels`, `parseModelsResponse`, `isVisionCapableModel`, `resolveEffectiveModel`, and `fallbackModels`.
3. **Step 3: Update `GeminiVisionService`**:
   - In `lib/services/gemini_vision_service.dart`, define `baseSystemInstruction`, alias `systemInstruction = baseSystemInstruction`, implement `buildSystemInstruction([String? masterPrompt])`.
   - Add `masterPrompt` to constructor and optional parameters to `analyzeMealPhoto`.
   - Use `buildSystemInstruction(effectivePrompt)` for `GenerativeModel`.
4. **Step 4: Create Unit Tests**:
   - Write `test/services/gemini_model_service_test.dart` with 100% offline mock coverage.
   - Add master prompt tests to `test/services/gemini_vision_service_test.dart`.
5. **Step 5: Run Verification**:
   - Run `flutter test test/services/gemini_model_service_test.dart test/services/gemini_vision_service_test.dart`.
   - Run `flutter analyze` to ensure 0 errors and 0 warnings.
