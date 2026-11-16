---
tipo: implementation_plan
proyecto: App_Food_Tracker
iteracion: v1.5.0
estado: activo
fecha: 2026-11-15
tags: [proyecto, planning, v1-5-0, inference-engine, gemini-rest-client, decision-gate, context-caching, network-resilience]
---

# 🧠 Plan de Implementación v1.5.0: Modernización del Motor de Inferencia, Cliente REST v1beta, Pre-Gate Multimodal y Resiliencia en Red Móvil

> **Mesa de Control & Architecture Lead:** Este documento formaliza el plan de ejecución determinista para la versión **v1.5.0** de **Victor Engineer - Food Tracker**. Resuelve las causas raíz de la falla del Quality Gate (deprecación del SDK oficial y errores de imports en tests), sustituye `google_generative_ai` por un cliente REST nativo (`GeminiRestClient`), integra `DecisionGateService` con `gemini-decision-1` como control plane ultrarrápido (<250ms), unifica el tiling a 768px (ahorro de 75% en tokens de visión), incorpora Context Caching para el Master Prompt y blinda la resiliencia en redes móviles y datos inestables sin degradar el modelo seleccionado por el usuario.

---

## 🎯 1. Objetivos Técnicos Fundamentales

1. **Eliminación del SDK Deprecado:** Remover `google_generative_ai: ^0.4.6` de `pubspec.yaml` y reemplazar el transporte con `GeminiRestClient` sobre `http: ^1.3.0` contra `https://generativelanguage.googleapis.com/v1beta`.
2. **Resiliencia de Red y Fallback Unario Silencioso:**
   - Intentar streaming continuo SSE (`POST /v1beta/models/{model}:streamGenerateContent?alt=sse`).
   - Ante corte de socket TCP/TLS o desconexión en datos móviles, conmutar en silencio a `POST /v1beta/models/{model}:generateContent` (petición atómica unaria).
   - Reintentos asíncronos en segundo plano mediante `AnalysisQueueService` preservando fotos en disco ante pérdida total de señal.
   - Respeto irrestricto de la selección de modelo del usuario (sin degradación forzada a modelos inferiores).
3. **Unificación a 768px (1 Tile = 258 Tokens):**
   - Configurar `ImageProcessingService` a dimensión máxima `768x768 px` (JPEG 80-85%).
   - Eliminar recomposiciones redundantes en el motor de visión, reduciendo payload de subida en >90% y costo de tokens a 1 mosaico.
4. **Pre-Gate Multimodal con `DecisionGateService` (`gemini-decision-1`):**
   - Evaluar 4 preguntas simultáneas en una única llamada de $0.10 / 1M tokens (<250ms).
   - Detección temprana de no-comida y calidad ilegible con aviso interactivo en `AnalysisProgressBanner` (`[Tomar otra foto]` / `[Analizar de todos modos]`).
   - Modulación de `thinking_level` (`LOW` vs `MEDIUM`) según complejidad sin cambiar el modelo elegido.
   - Fail-open transparente ante timeouts > 2500ms o fallas de red en el gate.
5. **Context Caching con Fallback Transparente (`GeminiCacheService`):**
   - Utilizar `CachedContent` (`POST /v1beta/cachedContents`, TTL 1h) para el Master Prompt + Despensa solo si se alcanza el umbral mínimo de tokens de Gemini API; fallback inline transparente si es menor.
6. **Esquema Simplificado y Cálculo Determinista:**
   - Remover `"totales"` de `mealAnalysisSchema`; calcular totales en Dart mediante suma de `items[]`.
   - Estandarizar `"proteinas_g"` en plural.
   - Bandera `isPartial: true` en `MealAnalysisResult` si interviene `JsonRepairHelper`.
7. **Saneamiento Integral de Quality Gate & Paridad VSA:**
   - Corregir todos los imports relativos en `lib/core/models/` y referencias en `lib/features/`.
   - Actualizar suites en `test/` para consumir la arquitectura canónica (VSA + Micro-MVC).
   - 100% de los 250+ archivos en `lib/` estrictamente bajo el límite `< 300 LoC`.

---

## 🛠️ 2. Fases de Ejecución Paso a Paso

### 📦 Fase 1: Manifiesto, Modelos Core e Infraestructura REST (`pubspec.yaml` & `core/services/ai/`)
1. Remover `google_generative_ai: ^0.4.6` de `pubspec.yaml` y actualizar manifiesto a `version: 1.5.0+1`.
2. Actualizar `AppConstants.appVersion = '1.5.0'`.
3. Crear `lib/core/services/ai/gemini_rest_client.dart` (< 250 LoC) implementando SSE Streaming, Unary Fallback, `/decisions` y `/cachedContents`.
4. Implementar `lib/core/services/ai/decision_gate_service.dart` (< 250 LoC) e interfaz `IDecisionGateService`.
5. Implementar `lib/core/services/ai/gemini_cache_service.dart` (< 200 LoC) con verificación de umbral de tokens y fallback inline.
6. Registrar los nuevos servicios en `lib/core/di/service_locator.dart`.

### 🔄 Fase 2: Saneamiento de Modelos, Esquemas e Imagen (`lib/core/models/` & `ImageProcessingService`)
1. Sanear `lib/core/models/analysis_task.dart` y `usda_food_item.dart` con imports absolutos a `features/food_entry/models/` y `pantry_inventory/models/`.
2. Actualizar `lib/features/food_entry/models/meal_analysis_result.dart`: agregar `isPartial`, cálculo determinista de macronutrientes sin dependencia de objeto `totales`.
3. Actualizar `GeminiResilienceHelper.mealAnalysisSchema` eliminando `"totales"` y asegurando compatibilidad con Gemini 3.x (`thinkingLevel`, `temperature: 1.0`).
4. Ajustar `ImageProcessingService.compressAndResizeAsync` a límite estricto `<= 768 px` (JPEG 85%).

### 🔌 Fase 3: Integración de Puertos y Adaptadores Hexagonales (`core/adapters/` & `features/food_entry/`)
1. Actualizar `GeminiAiVisionAdapter` (`lib/core/adapters/gemini_ai_vision_adapter.dart`) y `GeminiVisionService` para consumir `GeminiRestClient`, `DecisionGateService` y `GeminiCacheService`.
2. Implementar banner interactivo en `AnalysisProgressBanner` (`lib/features/food_entry/widgets/meal_analysis_pacing.dart` / views) para calidad baja o advertencia de no-comida.
3. Actualizar `biometrics_weight.controller.dart` corrigiendo la referencia de tipo `WeightLog`.

### 🧪 Fase 4: Saneamiento de Suites de Pruebas y Certificación de Quality Gate (`test/`)
1. Actualizar tests en `test/widgets/` y `test/controllers/` reemplazando nombres legados (`DashboardScreen` -> `DashboardView`, accesores de controladores VSA).
2. Crear tests unitarios dedicados:
   - `test/services/gemini_rest_client_test.dart`
   - `test/services/decision_gate_service_test.dart`
   - `test/services/gemini_cache_service_test.dart`
   - `test/models/meal_analysis_result_deterministic_test.dart`
3. Ejecutar `bun test`, `bun run lint:contracts` y `bun run validate`.
4. Verificar con `flutter analyze` que existan 0 errores y 0 warnings.

---

## 📊 3. Verificación de Presupuesto de Código (< 300 LoC)
- Ningún archivo nuevo o modificado en `lib/` superará las 300 líneas.
- Totalidad de suites probadas antes de la entrega final.
