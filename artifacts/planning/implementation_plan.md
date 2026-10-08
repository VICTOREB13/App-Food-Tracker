---
tipo: implementation_plan
proyecto: App_Food_Tracker
iteracion: v1.3.4
estado: activo
fecha: 2026-10-08
tags: [proyecto, planning, v1-3-4, gemini-vision, 16k-tokens, thinking-level-medium, micronutrients-harmonization, dynamic-pacing, sqlite-zero-freeze]
---

# 🎯 Plan de Implementación v1.3.4: Ventana de 16k Tokens, Thinking Level MEDIUM en Gemini 3.8 Flash, Armonización de Micronutrientes y Pacing Fluido en Dashboard

> **Mesa de Control (Project-Planner):** Este plan formaliza la evolución técnica de la iteración **v1.3.4** del proyecto **Victor Engineer - Food Tracker**. Se expande la ventana de salida a 16,384 tokens para dar holgura total al razonamiento latente y salida estructurada, se calibra el nivel de inteligencia a `MEDIUM` para `gemini-3.8-flash` y modelos Pro (omitiendo estrictamente `thinkingConfig` en variantes Lite para evitar `HTTP 400 INVALID_ARGUMENT`), se armonizan los micronutrientes (`fibra_g`, `sodio_mg`, `azucar_g`) en el prompt maestro y bloque Few-Shot preservando escrupulosamente las reglas clínicas de cubicaje, y se implementa el pacing continuo y fluido en memoria para la cola en el dashboard a 60 FPS sin saturar SQLite.

---

## 🔍 1. Diagnóstico Forense y Requerimientos

1. **Ampliación de Ventana de Contexto y Tokens de Salida (16k Tokens):**
   - Con modelos avanzados que despliegan razonamiento clínico profundo y cadenas de deducción volumétrica (Chain-of-Thought), un límite de 8192 tokens genera riesgo de agotamiento de presupuesto (`finishReason: MAX_TOKENS`), truncando la respuesta JSON estructurada.
   - Al elevar `maxOutputTokens` a **16,384** en `GenerationConfig` y los fallbacks de `GeminiVisionFilter`, se garantiza un margen amplio tanto para el pensamiento latente interno del transformer como para el payload JSON enriquecido con micronutrientes y justificaciones visuales.

2. **Nivel de Inteligencia / Thinking Level `MEDIUM` en Gemini 3.8 Flash:**
   - La deducción física 3D de comidas tradicionales y caseras requiere inferir vajilla, merma, hidratación y aceites/grasas ocultas con profundidad clínica sin penalizar excesivamente la latencia del usuario diario.
   - En `gemini_model_service.dart` y `gemini_vision_service.dart`: se estandariza `thinkingLevel: "MEDIUM"` para `gemini-3.8-flash` y variantes Pro.
   - **Regla Crítica de Exclusión para Variantes Lite:** Modelos livianos como `gemini-3.5-flash-lite` no admiten configuración de pensamiento; inyectarles `thinkingConfig` provoca inmediatamente el error `HTTP 400 INVALID_ARGUMENT`. Se excluye terminantemente cualquier bloque de thinking para modelos Lite.

3. **Preservación y Armonización del Prompt Master:**
   - En versiones previas, los micronutrientes (`fibra_g`, `sodio_mg`, `azucar_g`) figuraban en el esquema formal (`mealAnalysisSchema`) y en el prompt de usuario, pero el paso 4 y el ejemplo Few-Shot del sistema solo mostraban macronutrientes, creando potencial ambigüedad en modelos compactos.
   - Se armonizan los 3 micronutrientes en los pasos 4 y 5 de `baseSystemInstruction` y en el bloque Few-Shot representativo (tanto en `items` como en `totales`), preservando al 100% todas las reglas obligatorias de cubicaje clínico (`Puño cerrado`, `Palma de la mano`, `Pulgar`, `Dos manos ahuecadas`, `Conversión cocido vs crudo`, `Regla de Grasa Oculta en Comida Casera`, `5g y 10g adicionales de grasa`, `Porciones compartidas`).

4. **Pacing Dinámico y Fluido en el Dashboard (`AnalysisQueueService`):**
   - Durante la llamada de inferencia multimodal a Gemini (que toma de 15s a 90s), la interfaz del dashboard no debe quedarse estática en 45% ni realizar saltos bruscos.
   - En `AnalysisQueueService._processTask`, se activa un temporizador en memoria (`Timer.periodic` a 500ms) que avanza suavemente `task.progress` de 0.45 a 0.90 con `MealAnalysisPacing.nextProgress(task.progress)`, invocando `notifyListeners()` para alimentar la animación a 60 FPS sin realizar escrituras intermedias a SQLite (`_persistTaskToDb` solo al inicio, fin o fallo), previniendo saturación de disco.
   - En `AnalysisProgressBanner`, se resuelve dinámicamente el mensaje de la etapa mediante `MealAnalysisPacing.getStageMessage(task.progress, AppLocalizations.of(context)!)` de forma reactiva.

---

## 🏗️ 2. Solución de Arquitectura Técnica

### A. Subsistema de Inferencia y Modelos
- `GeminiVisionService`:
  - `maxOutputTokens: 16384` en `GenerationConfig`.
  - Exposición de `defaultThinkingLevel = 'MEDIUM'` y `resolveThinkingLevel`.
- `GeminiModelService`:
  - Constante `defaultThinkingLevel = 'MEDIUM'`.
  - Método `resolveThinkingLevel(modelName)` que retorna `'MEDIUM'` para `gemini-3` y Pro, y `null` para Lite o modelos no pensantes.
  - Método `supportsThinking(modelName)` que rechaza explícitamente modelos con `lite`.
  - `buildCallConfig`: inyecta `thinking_level` y `thinking_config: {'thinking_level': level}` para `gemini-3` y Pro; omite estrictamente para Lite.
- `GeminiVisionFilter`:
  - Actualización de `outputTokenLimit: 16384` para `gemini-3.8-flash` y `gemini-3.1-pro`.

### B. Prompt Master y Resiliencia
- `GeminiResilienceHelper`:
  - Armonización de `fibra_g`, `sodio_mg` y `azucar_g` en la instrucción del sistema y el bloque Few-Shot representativo.
  - Mantenimiento intacto de las 12 directivas clínicas de cubicaje volumétrico.

### C. Cola de Análisis y Banner de Progreso
- `AnalysisQueueService`:
  - Integración de temporizador de pacing en memoria durante `gemini.analyzeMealPhoto`.
  - Cancelación garantizada del temporizador en bloque `finally`.
  - Cero escrituras a SQLite en ticks periódicos.
- `AnalysisProgressBanner`:
  - Resolución dinámica de etapas con `MealAnalysisPacing.getStageMessage` sensible al contexto de idioma (`AppLocalizations`).

---

## 📅 3. Plan de Fases y Responsabilidades

| Fase | Rol | Tareas Principales | Estado |
|---|---|---|---|
| **Fase 1** | Project-Planner | Especificación técnica, diseño de pacing y actualización de artefactos. | Completado |
| **Fase 2** | Backend-Architect | Expansión a 16k tokens, Thinking Level MEDIUM, exclusión Lite y armonización prompt. | Completado |
| **Fase 3** | Frontend-UI | Pacing en memoria en cola y resolución dinámica de etapas en banner. | Completado |
| **Fase 4** | Systems-Auditor | Pruebas unitarias de thinking, pacing, tokens y auditoría modular < 300 LoC. | Completado |
| **Fase 5** | DevOps-Engineer | Bump de versión a 1.3.4+1, changelog v1.3.4 y certificación final. | Completado |
