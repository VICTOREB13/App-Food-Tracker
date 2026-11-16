---
tipo: blueprint_tecnico
proyecto: App_Food_Tracker
version_objetivo: v1.4.6 / v1.5.0
fecha: 2026-11-14
audiencia: Agentes de implementación (Gemini 3.8 Flash - Thinking High)
---

# Especificación Técnica de Mejoras, Refactorizaciones y Motor de Inferencia — Victor Engineer: Food Tracker

> **Instrucción obligatoria para el agente implementador:** Este documento es un plano de ejecución determinista. Sigue cada contrato, ruta de archivo, esquema JSON, nombre de clase y regla de arquitectura al pie de la letra. **No inventes campos, no cambies nombres de tablas SQLite existentes y respeta estrictamente el límite modular de menos de 300 líneas de código (`< 300 LoC`) por archivo en `lib/`.**

---

## Reglas Invariantes del Proyecto (No Romper)

1. **Límite duro de modularidad:** Ningún archivo en `lib/` puede alcanzar o superar las `300` líneas de código. Si un servicio crece, extrae helpers o clientes dedicados (ej. `GeminiRestClient`, `DecisionGateService`, `GeminiCacheService`).
2. **Manejo funcional de errores:** Todas las operaciones de servicios y DAOs deben retornar `Future<Result<T, Failure>>` (`lib/core/errors/result.dart` y `lib/core/errors/failures.dart`), nunca lanzar excepciones sin capturar hacia la UI.
3. **Inyección de dependencias (`GetIt`):** Registrar todas las interfaces nuevas y concretas en `lib/core/di/service_locator.dart` e inyectarlas por constructor en controladores y servicios.
4. **Localización 100% Pure Dart (`AppLocalizations`):** Cualquier texto nuevo visible para el usuario (ej. alertas de foto borrosa o comida parcial) debe declararse en `lib/l10n/domains/` e implementarse en `lib/l10n/es/` y `lib/l10n/en/`. Prohibido usar strings hardcodeados o fallbacks `?? 'texto'` en widgets.
5. **Persistencia Local-First:** Mantener intacto SQLite v4 en modo WAL (`PRAGMA journal_mode = WAL;`, `PRAGMA synchronous = NORMAL;`, `PRAGMA foreign_keys = ON;`). Las fotos físicas en disco **nunca** se eliminan ante un fallo de red o calidad.

---

## Bloque 1: Puntos de Falla y Problemas de Lógica Detectados

A continuación se detallan los 7 fallos estructurales, inconsistencias de contratos y riesgos de producción identificados al auditar los artefactos de `PRJ_App_Food_Tracker` frente a la API de Gemini vigente (noviembre de 2026).

### 1.1. SDK oficial de Dart deprecado (`google_generative_ai: ^0.4.6`)
- **Dónde ocurre:** `pubspec.yaml` y `lib/services/gemini_vision_service.dart` (documentado en `architecture.md`).
- **Problema:** El paquete `google_generative_ai` fue [archivado y deprecado oficialmente por Google](https://github.com/google-gemini/deprecated-generative-ai-dart) en favor de [`firebase_ai`](https://firebase.google.com/docs/ai-logic/migrate-from-google-ai-client-sdks) (ver [librerías oficiales de Gemini API](https://aistudio.google.com/docs/libraries)). El paquete `0.4.6` no expone tipado nativo para parámetros de Gemini 3.x como `thinking_level`, `media_resolution`, `cachedContent` ni el endpoint `/v1beta/decisions`.
- **Acción requerida:** Eliminar la dependencia de `google_generative_ai` para las llamadas de inferencia y reemplazarla por un cliente REST tipado propio (`GeminiRestClient`) contra `https://generativelanguage.googleapis.com/v1beta` usando `http` o `dio` (manteniendo la arquitectura BYOK sin acoplar Firebase).

### 1.2. Fallback obsoleto y restringido (`gemini-2.5-flash`)
- **Dónde ocurre:** `lib/services/gemini_resilience_helper.dart` y `lib/services/gemini_vision_filter.dart` (documentado en `api_spec.md` §7.2 y §7.4).
- **Problema:** Desde octubre de 2026, Google restringió la serie Gemini 2.5 a proyectos que ya la habían utilizado previamente ([guía de niveles de pensamiento](https://www.aifreeapi.com/en/posts/gemini-api-thinking-level)). Un usuario nuevo que ingrese su propia API key (BYOK) recibirá error al conmutar al fallback `gemini-2.5-flash`.
- **Acción requerida:** Cambiar el modelo de fallback por defecto a `gemini-3.5-flash-lite` (o `gemini-3.6-flash` como respaldo intermedio) y actualizar `GeminiVisionFilter` para dar prioridad a la familia 3.x.

### 1.3. Parámetro inválido en `gemini-3.1-pro` (`thinking_budget` vs `thinking_level`)
- **Dónde ocurre:** `lib/services/gemini_vision_service.dart` / `GeminiVisionFilter` (documentado en `api_spec.md` §7.2).
- **Problema:** Se configura `gemini-3.1-pro` con `thinking_budget: 1024`. Según la [documentación oficial de Gemini Thinking](https://aistudio.google.com/docs/thinking), los modelos Gemini 3+ rechazan `thinking_budget` (exclusivo de Gemini 2.5) y requieren `thinking_level` (`"LOW"`, `"MEDIUM"`, `"HIGH"`), devolviendo `HTTP 400 INVALID_ARGUMENT` si se envían parámetros de 2.5. Asimismo, en `gemini-3.8-flash` no existe `"MINIMAL"` (solo `"LOW"`, `"MEDIUM"`, `"HIGH"`, según [especificación de Gemini 3.8 Flash](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/gemini/3-8-flash)).
- **Acción requerida:** Usar exclusivamente `thinkingConfig: { "thinkingLevel": "..." }` para cualquier modelo `gemini-3.*`, omitiendo `thinkingBudget` por completo en esa familia.

### 1.4. Contradicción de resolución de imagen (`1024x1024` vs `768x768`) y gasto 4x de tokens
- **Dónde ocurre:** `lib/services/image_processing_service.dart` (`abstractions.md` documenta `1024x1024 px`) frente a `_prepareImageBytes` en `gemini_vision_service.dart` (`project_overview.md` documenta `768 px`).
- **Problema:** En Gemini, cualquier imagen que supere `384 px` se divide en mosaicos de `768x768 px` (cada tile cuesta `258` tokens, según las [reglas de tiling de Gemini](https://fast.io/resources/gemini-image-upload-limit/)). Si `ImageProcessingService` comprime a `1024x1024 px`, fuerza un tiling de `2x2` (4 tiles = `1,032` a `1,120` tokens) en lugar de `1` tile (`258` tokens), cuadruplicando el costo de visión. Y si `_prepareImageBytes` vuelve a reescalar de `1024` a `768`, se produce doble compresión JPEG con pérdida de nitidez.
- **Acción requerida:** Unificar la compresión y redimensionado en **un único paso** a un máximo de `768x768 px` (lado mayor `<= 768`, JPEG calidad `85%`) dentro de `ImageProcessingService.compressAndResizeAsync`, eliminando cualquier reescalado redundante en `GeminiVisionService`. Adicionalmente, pasar `media_resolution` (`LOW` / `MEDIUM` / `HIGH`) de forma explícita cuando se requiera mayor detalle ([documentación de Media Resolution](https://aistudio.google.com/docs/media-resolution)).

### 1.5. Clave asimétrica (`proteinas_g` vs `proteina_g`) y totales redundantes en `mealAnalysisSchema`
- **Dónde ocurre:** `GeminiResilienceHelper.mealAnalysisSchema` y `MealAnalysisResult.fromJsonString` (`api_spec.md` §7.1).
- **Problema:**
  1. En `items[]` la propiedad se llama `"proteinas_g"` (plural), pero en `"totales"` se llama `"proteina_g"` (singular).
  2. Pedir al LLM que calcule y devuelva el objeto `"totales"` dentro del JSON consume tokens de salida innecesarios y permite inconsistencias aritméticas entre la suma real de `items[]` y lo reportado en `totales`.
- **Acción requerida:** Eliminar por completo el objeto `"totales"` del `mealAnalysisSchema` y calcular los totales determinísticamente en Dart sumando `items[]`. Estandarizar el campo de proteína en `items[]` como `"proteinas_g"`.

### 1.6. Riesgo de datos corruptos silenciosos en `JsonRepairHelper`
- **Dónde ocurre:** `lib/models/json_repair_helper.dart` y `GeminiVisionService` (`api_spec.md` §5.2).
- **Problema:** Si una respuesta de `generateContentStream` se corta a mitad de camino y `JsonRepairHelper.repairTruncatedJson` cierra llaves/corchetes en orden LIFO, el parser puede construir una comida con solo 1 o 2 ingredientes de 5 reales y guardarla en SQLite como `completed`, distorsionando el conteo calórico del usuario sin advertencia.
- **Acción requerida:** Si `JsonRepairHelper` tuvo que intervenir (es decir, el JSON original falló `jsonDecode` antes de la reparación), marcar el resultado con `isPartial: true` y forzar confirmación o revisión visual en `MealDetailScreen` (mostrando un banner de advertencia localizado) en lugar de marcarlo silenciosamente como 100% preciso.

### 1.7. Sesgo métrico en `CalibratedDishware` y desincronización de artefactos SDD
- **Dónde ocurre:** `GeminiVisionService.analyzeMealImage` (`api_spec.md` §3.1), `abstractions.md` y `design_system.md`.
- **Problema:**
  1. Inyectar automáticamente el diámetro del plato por defecto asume que toda foto fue tomada sobre ese plato y en plano cenital; en restaurantes o bowls distintos genera estimaciones de volumen falsas.
  2. Existen desincronizaciones documentales: `abstractions.md` aún cita SQLite v3, timeout de 35s y 1024px; `design_system.md` cita `#EF4444` para proteína, mientras `changelog_v1.md` (v1.4.2) y los widgets Android usan `#10B981` (proteína), `#F59E0B` (carbohidratos) y `#0EA5E9` (grasas).
- **Acción requerida:** Permitir seleccionar rápidamente el recipiente (`Plato por defecto` / `Otro plato` / `Sin referencia métrica`) antes de encolar la foto, y actualizar `abstractions.md`, `api_spec.md` y `design_system.md` al finalizar la refactorización.

---

## Bloque 2: Refactorizaciones y Mejoras de Código (Blueprint Ejecutable)

### 2.1. Nuevo Cliente REST `v1beta` (`lib/services/gemini_rest_client.dart` — `< 250 LoC`)
Crear una clase dedicada encargada exclusivamente del transporte HTTP/SSE contra `https://generativelanguage.googleapis.com/v1beta`, registrada en `GetIt`:

- **Endpoints a encapsular:**
  1. `POST /v1beta/models/{model}:streamGenerateContent?alt=sse` (header `x-goog-api-key: {apiKey}`).
  2. `POST /v1beta/models/{model}:generateContent` (fallback unario ante cortes de socket).
  3. `POST /v1beta/cachedContents` (para Context Caching del Master Prompt + Despensa).
  4. `POST /v1beta/decisions` (para `gemini-decision-1`).
- **Reglas de payload para `generationConfig` en Gemini 3.x:**
  - `temperature`: **`1.0`** cuando el modelo pertenezca a la serie `gemini-3.*` y use `thinkingConfig` (evita degradación del razonamiento; mantener `0.2` solo si se usa `gemini-2.5-*` legado).
  - `maxOutputTokens`: `16384`.
  - `responseMimeType`: `"application/json"`.
  - `responseJsonSchema`: el esquema simplificado sin `totales`.
  - `thinkingConfig`:
    - Si el modelo es `gemini-3.8-flash` o `gemini-3.6-flash`: `{ "thinkingLevel": level }` donde `level` es `"LOW"` o `"MEDIUM"` según la complejidad (nunca `"MINIMAL"` en `3.8-flash`).
    - Si el modelo es `gemini-3.1-pro`: `{ "thinkingLevel": "MEDIUM" }` o `"HIGH"`.
    - Si el modelo es `*-lite` (`gemini-3.5-flash-lite`): omitir `thinkingConfig` o usar `"LOW"` solo si la doc del modelo lo habilita; nunca enviar `thinkingBudget`.
- **Orden de partes en `contents[0].parts`:**
  - Mantener el orden actual: primero el bloque `{"text": prompt}` y segundo el bloque `{"inlineData": {"mimeType": "image/jpeg", "data": base64Bytes}}`.

### 2.2. Nuevo `mealAnalysisSchema` sin `totales` y cálculo determinista en Dart
Actualizar `GeminiResilienceHelper.mealAnalysisSchema` eliminando la propiedad `"totales"` y su `required`:

```json
{
  "type": "object",
  "properties": {
    "razonamiento_volumetrico": {
      "type": "string",
      "description": "Deducción física libre: escala de vajilla, volumen 3D, densidad, cocción y grasas ocultas."
    },
    "plato": {
      "type": "string",
      "description": "Nombre representativo del plato en el idioma del usuario."
    },
    "porcentaje_certeza": {
      "type": "integer",
      "description": "Certeza de 0 a 100 según visibilidad, oclusión y nitidez."
    },
    "margen_error_kcal": {
      "type": "integer",
      "description": "Margen de error calórico estimado en +/- kcal."
    },
    "items": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "alimento": { "type": "string" },
          "gramos_estimados": { "type": "number" },
          "calorias": { "type": "number" },
          "proteinas_g": { "type": "number" },
          "carbohidratos_g": { "type": "number" },
          "grasas_g": { "type": "number" },
          "fibra_g": { "type": "number" },
          "sodio_mg": { "type": "number" },
          "azucar_g": { "type": "number" }
        },
        "required": [
          "alimento",
          "gramos_estimados",
          "calorias",
          "proteinas_g",
          "carbohidratos_g",
          "grasas_g",
          "fibra_g",
          "sodio_mg",
          "azucar_g"
        ]
      }
    }
  },
  "required": [
    "razonamiento_volumetrico",
    "plato",
    "porcentaje_certeza",
    "margen_error_kcal",
    "items"
  ]
}
```

- **En `MealAnalysisResult` (`lib/models/meal_analysis_result.dart`):**
  - Añadir campo inmutable `final bool isPartial;` (default `false`).
  - Calcular `totalCalories`, `totalProtein`, `totalCarbs`, `totalFat`, `totalFiber`, `totalSodium`, `totalSugar` mediante getters o en el factory `fromJsonString` sumando `items`, aplicando `ModelSanitizer.clampDouble(...)` a cada campo.
  - Si `jsonDecode` falla inicialmente y `JsonRepairHelper.repairTruncatedJson` logra rescatar el payload, instanciar `MealAnalysisResult(..., isPartial: true)`.

### 2.3. Unificación de Compresión a `768 px` en `ImageProcessingService`
- **Archivo:** `lib/services/image_processing_service.dart`.
- **Cambio exacto:** Establecer `maxDimension = 768` por defecto en `compressAndResizeAsync` (manteniendo relación de aspecto original, JPEG calidad `85`).
- **Validación:** Confirmar que `GeminiVisionService` **no** vuelva a decodificar ni recomprimir los bytes recibidos de la cola si ya cumplen `<= 768 px`. Esto garantiza exactamente `1 tile = 258 tokens` por foto en Gemini.

### 2.4. Actualización de `GeminiResilienceHelper` y `GeminiVisionFilter`
- **Archivo:** `lib/services/gemini_resilience_helper.dart` y `lib/services/gemini_vision_filter.dart`.
- **Cambios exactos:**
  - Fallback primario: `gemini-3.6-flash` -> fallback secundario: `gemini-3.5-flash-lite` (reemplazando `gemini-2.5-flash`).
  - Ranking en `GeminiVisionFilter`:
    1. `gemini-3.8-flash` (Rank 1, Default, badge `'Fast'`)
    2. `gemini-3.1-pro` (Rank 2, badge `'Think'`)
    3. `gemini-3.6-flash` (Rank 3, Compatible)
    4. `gemini-3.5-flash-lite` (Rank 4, Lite / Rápido)
    5. `gemini-2.5-flash` (Rank 8, Legado solo si la API devuelve acceso)

---

## Bloque 3: Motor de Inferencia — API Tradicional vs. Gemini Decisions (`gemini-decision-1`)

### 3.1. Decisión Arquitectónica (No Reemplazar, Complementar)
- **¿Puede `gemini-decision-1` reemplazar a `gemini-3.8-flash` en el cubicaje nutricional?** **NO.** `gemini-decision-1` es un modelo discriminativo que solo responde preguntas cerradas (`noul`, `choice`, `score`) y **no puede generar texto ni valores numéricos continuos** como gramos, calorías o nombres de platos ([blog oficial de Google](https://blog.google/innovation-and-ai/technology/developers-tools/gemini-decisions-api/), [DataCamp](https://www.datacamp.com/blog/gemini-decision-1)).
- **¿Cómo mejora la app?** Integrándolo como **Control Plane (`DecisionGateService`)** en **150–250 ms** a **$0.10 / 1M tokens de entrada** ($0 salida) antes de invocar modelos generativos costosos. (Nota: [`gemini-3.8-flash` duplicará su precio el 1 de enero de 2027](https://klymentiev.com/blog/gemini-api-pricing) a `$1.50` entrada / `$7.50` salida por 1M tokens, por lo que filtrar y enrutar antes ahorra presupuesto real del usuario BYOK).

### 3.2. Diseño de `DecisionGateService` (`lib/services/decision_gate_service.dart` — `< 250 LoC`)
Crear la interfaz `IDecisionGateService` en `lib/core/interfaces/decision_gate_service_interface.dart` e implementarla en `DecisionGateService`.

#### Caso de Uso 1: Pre-Gate Multimodal y Router de Complejidad (antes de `GeminiVisionService`)
Enviar una única petición `POST https://generativelanguage.googleapis.com/v1beta/decisions` con la imagen (768x768) y 4 preguntas simultáneas (en `gemini-decision-1`, el input se factura una sola vez sin importar cuántas preguntas evalúes en el mismo request):

```json
{
  "model": "gemini-decision-1",
  "input": [
    {
      "type": "image",
      "data": "<BASE64_JPEG_768PX>",
      "mime_type": "image/jpeg"
    },
    {
      "type": "text",
      "text": "Pre-evaluación de foto de comida para registro nutricional."
    }
  ],
  "questions": {
    "is_food": {
      "type": "noul",
      "instructions": "Does this image clearly show food or a beverage meant for consumption?"
    },
    "image_quality": {
      "type": "score",
      "instructions": "Rate the visual clarity and lighting of the food in the photo.",
      "criteria": [
        "Unusable: pitch black, severely blurred, or completely occluded.",
        "Poor: partially visible or blurry, hard to estimate portions.",
        "Acceptable: main items visible with minor shadows.",
        "Optimal: sharp, well-lit, all ingredients clearly distinguishable."
      ]
    },
    "dish_complexity": {
      "type": "choice",
      "instructions": "Classify the structural complexity of the meal for calorie estimation.",
      "criteria": {
        "simple_single_item": "Single whole food or simple packaged item (e.g. one banana, boiled egg, yogurt cup, black coffee).",
        "standard_plate": "2 to 4 distinct separated components without heavy mixed sauces.",
        "complex_mixed_dish": "Stews, mixed rice/pasta, fried foods, salads with dressing, or multiple hidden-fat ingredients."
      }
    },
    "meal_category": {
      "type": "choice",
      "instructions": "Which meal category best matches this food?",
      "criteria": {
        "Desayuno": "Breakfast items (eggs, bread, arepa, oats, coffee).",
        "Almuerzo": "Main midday meal (protein, rice, pasta, soup, salad).",
        "Cena": "Evening meal or light dinner.",
        "Snack": "Small snack, fruit, bar, nuts, or beverage."
      }
    }
  }
}
```

#### Reglas Exactas de Enrutamiento (Umbrales Deterministas)
Evaluar la respuesta de `gemini-decision-1` siguiendo esta tabla de decisión estricta:

1. **Si `is_food.noul == false` y `is_food.confidence >= 0.80`:**
   - **Acción:** Abortar inmediatamente antes de llamar a `gemini-3.8-flash`. Retornar `FailureResult(AiServiceFailure.invalidInput(l10n.errorNotFoodDetected))`. La foto se conserva en disco por si el usuario quiere forzar análisis manual.
2. **Si `image_quality.score < 1.2` (sobre escala 0–3):**
   - **Acción:** Advertir al usuario en el banner (`VeLoadingRing` / `AnalysisProgressBanner`) con opción de `[Tomar otra foto]` o `[Analizar de todos modos]`, evitando gastar tokens de razonamiento en una foto ilegible.
3. **Si `dish_complexity.choice == "simple_single_item"` y `dish_complexity.confidence >= 0.75`:**
   - **Acción:** Enrutar a **`gemini-3.5-flash-lite`** (sin `thinking_level`) para respuesta ultra-rápida y costo mínimo, usando `meal_category.choice` como tipo de comida sugerido.
4. **Si `dish_complexity.choice == "standard_plate"`:**
   - **Acción:** Enrutar a **`gemini-3.8-flash`** con `thinkingLevel: "LOW"`.
5. **Si `dish_complexity.choice == "complex_mixed_dish"` (o `confidence < 0.75`):**
   - **Acción:** Enrutar a **`gemini-3.8-flash`** con `thinkingLevel: "MEDIUM"` (o al modelo Pro seleccionado por el usuario) para cubicaje causal profundo.
6. **Resiliencia del Pre-Gate (Fail-Open):**
   - Si `/v1beta/decisions` falla por red, timeout (> 2500 ms) o cuota, **no bloquear al usuario**: hacer bypass silencioso directo al flujo tradicional con el modelo seleccionado por el usuario.

#### Caso de Uso 2: Reranking de `pantry_items` y `meal_templates` sin generar texto
Cuando el usuario tenga `>= 5` plantillas (`meal_templates`) o productos favoritos (`pantry_items`), se puede enviar la foto junto con una lista de preguntas `noul` (hasta 25–50 ítems por llamada, ya que la latencia se mantiene casi plana hasta 100 preguntas) preguntando si el plato corresponde a la plantilla X. Si alguna supera `confidence >= 0.85`, ofrecer un botón de registro instantáneo en 1 toque sin gastar tokens generativos.

#### Limitaciones de `gemini-decision-1` a respetar en código
- **Sin Context Caching ni Batch API:** El endpoint `/v1beta/decisions` **no soporta** `cachedContent` ni Batch API ([análisis DataCamp](https://www.datacamp.com/blog/gemini-decision-1)). Agrupa todas las preguntas sobre la misma imagen en un solo request.
- **Sin salida de texto:** Nunca intentes pedir descripciones o gramos a `gemini-decision-1`.

### 3.3. Optimización del Motor Generativo Tradicional con Context Caching
Para las llamadas que sí llegan a `gemini-3.8-flash`:
- **Context Caching (`lib/services/gemini_cache_service.dart`):** El *Master Prompt* metabólico, las 12 reglas de cubicaje clínico y la lista serializada de `pantry_items` se repiten en cada comida escaneada. Almacenarlos en un `CachedContent` (`POST /v1beta/cachedContents` con TTL de 1 hora o 24 horas, renovado solo cuando cambia el perfil o la despensa) reduce el costo de esos tokens de entrada en un **90%** (se facturan al 10% del precio base, según [guía de precios de Gemini](https://www.cloudzero.com/blog/gemini-pricing/)).
- **Fallback si el prompt no supera el mínimo de tokens de caché:** Si el usuario aún no tiene suficientes ítems en despensa como para superar el umbral mínimo de tokens requerido por la API para crear un caché, enviar el system prompt inline de forma normal (degradación elegante sin error).

---

## Checklist de Verificación para el Agente Implementador

Al finalizar los cambios en el código fuente de `App-Food-Tracker`:
1. [ ] **Modularidad:** Ejecutar conteo de líneas en todo `lib/`; `0` archivos con `>= 300` líneas.
2. [ ] **Análisis estático:** `flutter analyze` con `0` errores y `0` warnings de deprecación.
3. [ ] **Suite de pruebas:** Actualizar y crear tests unitarios para:
   - `GeminiRestClient` (mock HTTP verificando `thinkingLevel`, `temperature: 1.0` en Gemini 3.x y ausencia de `totales` en el schema).
   - `MealAnalysisResult` (cálculo determinista de totales y bandera `isPartial: true` cuando actúa `JsonRepairHelper`).
   - `ImageProcessingService` (verificando salida máxima `<= 768 px`).
   - `DecisionGateService` (evaluando los 5 caminos de enrutamiento y el fail-open ante timeout > 2500ms).
4. [ ] **Sincronización SDD en Obsidian:** Actualizar `PRJ_App_Food_Tracker_abstractions.md`, `PRJ_App_Food_Tracker_api_spec.md` y `PRJ_App_Food_Tracker_design_system.md` para reflejar los nuevos contratos, la unificación a 768 px y la paleta cromática real de macros.
