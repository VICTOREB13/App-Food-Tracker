---
tipo: implementation_plan
proyecto: App_Food_Tracker
iteracion: v1.5.2
estado: activo
fecha: 2026-11-16
tags: [proyecto, planning, v1-5-2, voice-mode, bento-typography, image-persistence, reactive-dashboard, master-prompt, context-window, thinking-levels, inference-telemetry]
---

# 🧠 Plan de Implementación v1.5.2: Audio & Voice Mode, Tipografía Bento, Persistencia de Fotos, Estado Reactivo, Telemetría de Modelo y Niveles de Razonamiento

> **Mesa de Control & Architecture Lead:** Este documento formaliza el plan de arquitectura e implementación determinista para la versión **v1.5.2** de **Victor Engineer - Food Tracker**. Aborda los 6 requerimientos originales de usabilidad e interfaz, más los detalles de telemetría de inferencia (`modelUsed`, `thinkingLevel`) y personalización de esfuerzo de razonamiento / presupuesto de contexto solicitados por el usuario, en estricto cumplimiento de los principios de [[PRJ_App_Food_Tracker_architecture|Arquitectura V10]], [[PRJ_App_Food_Tracker_abstractions|Abstracciones del Sistema]], [[PRJ_App_Food_Tracker_design_system|Sistema de Diseño Dark Bento]] y la política estricta de < 300 LoC por archivo.

---

## 🎯 1. Objetivos Técnicos Fundamentales de la Versión 1.5.2

1. **Restauración y Rediseño del Modo Voice / Audio (`features/dashboard` & `core/services/ai`):**
   - Eliminar el empaquetado defectuoso de texto plano como audio simulado (`dummyAudioBytes`).
   - Implementar un flujo dual confiable:
     - **Ruta A (Texto Descriptivo):** Inferencia directa de texto contra `GeminiRestClient.generateContent` con esquema JSON de comida (`GeminiResilienceHelper.mealAnalysisSchema`), sin conversión espuria a audio.
     - **Ruta B (Voz / Micrófono):** Captura de audio de micrófono con el paquete estándar `record` (formato AAC/M4A nativo, bajo consumo) y envío de bytes reales con cabecera MIME `audio/m4a` al endpoint multimodal de Gemini. Alternativamente, soporte de dictado por voz de plataforma.
   - Proporcionar retroalimentación visual de onda/grabación y control de errores en tiempo real en `VoiceMealRecordingDialog`.

2. **Ajuste Tipográfico y Prevención de Partición Silábica de Carbohidratos (`features/dashboard` & `features/food_entry`):**
   - Resolver la división incómoda de la palabra *"Carbohidratos"* / *"Carbohydrates"* (`Carbohydrat`/`es` en Dashboard y `Carbohydr`/`ates` en Meal Details).
   - Envolver las etiquetas en `FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft)` con `maxLines: 1` para permitir escalado fluido en pantallas angostas.
   - Habilitar directiva Plain Language (`Carbs` o `Carbos`) cuando el ancho del componente sea inferior a 85px.

3. **Garantía de Persistencia de Fotos de Comida en Almacenamiento Permanente (`features/food_entry/services`):**
   - Erradicar la dependencia de `Directory.systemTemp` (`/cache`), que el sistema operativo Android purga rutinariamente ante presión de memoria o suspensión en segundo plano.
   - Enrutar el guardado y resolución de imágenes primariamente a `getApplicationDocumentsDirectory()` (`appDocDir.path/Pictures/FoodTracker/images/`).
   - Garantizar que los enlaces y miniaturas de fotos persistan de forma indefinida, incluso si el análisis diferido se reintenta horas después.

4. **Auto-Refresco Reactivo del Dashboard tras Completar Análisis en Segundo Plano (`features/dashboard` & `features/food_entry`):**
   - Conectar la finalización de tareas en `AnalysisQueueService` con `DashboardController.instance.loadDashboardData()`.
   - Cuando una comida termina de procesarse en segundo plano (estado `completed` o `failed`), notificar inmediatamente al controlador del Dashboard para refrescar las calorías diarias, distribución de macros y lista de comidas sin necesidad de recarga manual ni reinicio de la app.

5. **Rediseño Dark Bento del Modal de Prompt Maestro (`features/settings_profile`):**
   - Reemplazar la vista plana de markdown crudo por una experiencia visual cohesiva con el modal de selección de modelos.
   - Estructurar el modal en tarjetas Bento modulares:
     - **Tarjeta de Biometría:** Edad, Sexo, Estatura, Peso actual.
     - **Tarjeta de Gasto Energético:** BMR, Nivel de Actividad, TDEE.
     - **Tarjeta de Metas Nutricionales:** Calorías objetivo, Macros (Proteína, Grasas, Carbos) con chips de color temático.
     - **Barra de Acciones Rápidas:** Botón táctil para copiar prompt al portapapeles, selector de pestañas (Vista Estructurada vs. Editor de Código), y botón para restablecer parámetros Mifflin-St Jeor.

6. **Ventana de Contexto Dinámica y Reactiva (`features/settings_profile`):**
   - Eliminar el valor estático hardcodeado `"Window: 1024k tokens"`.
   - Calcular y exhibir en tiempo real el consumo de contexto activo de la sesión:
     - Prompt del Sistema + Master Prompt (~1.2k tokens).
     - Contexto de Despensa / Inventario (~400-800 tokens).
     - Tile de Imagen 768px (~258 tokens).
     - Notas / Observaciones de usuario (~100 tokens).
     - Presupuesto de Generación configurado (`maxOutputTokens`: 4k / 8k / 16k tokens).
   - Presentar un indicador visual de capacidad disponible: `Consumo activo: ~2.1k / 1,024k tokens (0.2%)` con desglose informativo al interactuar.

7. **Telemetría y Transparencia de Inferencia en el JSON y la UI (`core/models` & `features/food_entry`):**
   - Enriquecer el JSON de análisis y la entidad `Meal` / `MealAnalysisResult` con metadatos reales de ejecución:
     - `model_used`: Nombre exacto del modelo de Gemini que respondió la inferencia (ej. `gemini-4-hydrogen`, `gemini-2.5-flash`).
     - `is_fallback`: Booleano que indica con 100% de transparencia si se ejecutó el modelo solicitado o si se activó el fallback automático ante timeout/error.
     - `thinking_level`: Nivel de esfuerzo de razonamiento aplicado (`OFF`, `LOW`, `MEDIUM`, `HIGH`, `X-HIGH`).
   - Exhibir un badge sutil y elegante en `MealDetailView` y en la tarjeta de comida:
     - Ej.: `Gemini 4 Hydrogen · Esfuerzo: Medio` o `Fallback: Gemini 2.5 Flash · Esfuerzo: Bajo`.

8. **Configurabilidad de Parámetros de Razonamiento y Presupuesto por el Usuario (`features/settings_profile`):**
   - Permitir al usuario definir en Ajustes de IA:
     - **Nivel de Pensamiento / Reasoning Effort:** Selector tipo chip (`NONE/OFF`, `LOW`, `MEDIUM`, `HIGH`, `X-HIGH`).
     - **Presupuesto Máximo de Salida (`maxOutputTokens`):** Selector de tokens (4.096, 8.192 o 16.384 tokens).
   - Persistir las preferencias en `SharedPreferences` e inyectarlas dinámicamente en `GeminiRestClient.buildGenerationConfig()`.
   - **Garantía de API Key en Gemini Decisions:** Asegurar contractualmente que `DecisionGateService` y `GeminiVisionService` utilicen exclusivamente la API Key propia ingresada por el usuario en el dispositivo, sin claves compartidas ni externas.

---

## 🔍 2. Diagnóstico de Causa Raíz de las Incidencias

```text
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                   DIAGNÓSTICO DETERMINISTA DE LAS 8 INCIDENCIAS v1.5.2                           │
├────┬────────────────────────────┬──────────────────────────────────┬─────────────────────────────┤
│ #  │ Síntoma en UI              │ Causa Raíz Técnica               │ Archivo Responsable         │
├────┼────────────────────────────┼──────────────────────────────────┼─────────────────────────────┤
│ 1  │ Grabación no graba / Error │ `_toggleRecording()` solo cambia │ `features/dashboard/widgets │
│    │ al pulsar "Analyze with AI"│ bool. Texto se envía empaquetado │ /voice_meal_recording_      │
│    │                            │ como fake MP3 en dummyAudioBytes │ dialog.dart`                │
├────┼────────────────────────────┼──────────────────────────────────┼─────────────────────────────┤
│ 2  │ "Carbohydrat/es" se corta  │ Ancho limitado en Expanded sin   │ `features/dashboard/widgets │
│    │ en el inicio y en detalle  │ FittedBox ni maxLines: 1         │ /macro_bento_card.dart`     │
├────┼────────────────────────────┼──────────────────────────────────┼─────────────────────────────┤
│ 3  │ Fotos se pierden tras      │ Fallback a Directory.systemTemp; │ `features/food_entry/       │
│    │ esperar mucho tiempo       │ Android purga /cache en reposo   │ services/meal_image_storage │
│    │                            │                                  │ _resolver.dart`             │
├────┼────────────────────────────┼──────────────────────────────────┼─────────────────────────────┤
│ 4  │ Dashboard no se actualiza  │ QueueService notifica a FoodEntry│ `features/food_entry/       │
│    │ al terminar el análisis    │ pero NO a DashboardController    │ services/analysis_queue_    │
│    │                            │                                  │ service.dart`               │
├────┼────────────────────────────┼──────────────────────────────────┼─────────────────────────────┤
│ 5  │ Modal de Master Prompt     │ Vista básica con Markdown puro   │ `features/settings_profile/ │
│    │ sin estilo ni jerarquía    │ sin tarjetas Bento ni chips      │ widgets/profile/master_     │
│    │                            │                                  │ prompt_bottom_sheet.dart`   │
├────┼────────────────────────────┼──────────────────────────────────┼─────────────────────────────┤
│ 6  │ Ventana de contexto        │ Cálculo estático derivado solo   │ `features/settings_profile/ │
│    │ hardcodeada a 1024k        │ de model.inputTokenLimit / 1024  │ widgets/gemini_model_       │
│    │                            │ sin telemetría de payload real   │ selector_card.dart`         │
├────┼────────────────────────────┼──────────────────────────────────┼─────────────────────────────┤
│ 7  │ Usuario no sabe si se usó  │ El modelo que atendió el request │ `core/services/ai/gemini_   │
│    │ el modelo real o fallback  │ y el thinkingLevel no se guardan │ vision_service.dart` y      │
│    │ ni qué esfuerzo se aplicó  │ en Meal ni se muestran en UI     │ `features/food_entry/`      │
├────┼────────────────────────────┼──────────────────────────────────┼─────────────────────────────┤
│ 8  │ Nivel de pensamiento y     │ Hardcodeados en código a MEDIUM  │ `core/services/ai/gemini_   │
│    │ tokens no son ajustables   │ y 16k sin controles en Ajustes   │ rest_client.dart` y         │
│    │ por el usuario en la app   │                                  │ `features/settings_profile` │
└────┴────────────────────────────┴──────────────────────────────────┴─────────────────────────────┘
```

---

## 🛠️ 3. Fases de Ejecución

### Fase 1: Especificación y Contratos SDD (`Backend-Architect` / `vsa-contracts`)
1. Actualizar [[PRJ_App_Food_Tracker_abstractions|abstractions.md]] con:
   - Nuevo contrato `ContextUsageMetrics` (totalLimit, activePayloadTokens, breakdownDetails).
   - Contrato `InferenceTelemetry` (`modelUsed`, `isFallback`, `thinkingLevel`, `executionTimeMs`).
   - Interfaz `AudioRecordingService` para captura limpia de micrófono.
2. Actualizar [[PRJ_App_Food_Tracker_api_spec|api_spec.md]] con:
   - Endpoint de análisis de comida basado en texto puro: `POST /ai/meal/analyze-text`.
   - Especificación de campos en `ai_breakdown_json` (`model_used`, `is_fallback`, `thinking_level`).
   - Parámetros de configuración de usuario (`thinking_level`, `max_output_tokens`).
3. Verificar paridad con `bun run lint:contracts`.

### Fase 2: Implementación Guiada por VSA y TDD (`vsa-contracts` Subagentes)

#### Subfase 2.1: Reparación del Modo Voice/Audio (`features/dashboard` & `core/services/ai`)
- Co-localizar suite TDD `test/features/dashboard/voice_meal_recording_dialog_test.dart`.
- Modificar `VoiceMealRecordingDialog`:
  - Si el usuario escribió texto, ejecutar directamente `GeminiVisionService.instance.analyzeMealText(text)`.
  - Integrar captura de audio real para el botón de micrófono (usando grabación de archivo temporal de audio válido o dictado por voz del sistema operativo).
  - Manejo robusto de errores con mensajes Plain Language (≤ 1 frase concreta).
  - Mantener archivo estrictamente < 300 LoC.

#### Subfase 2.2: Ajuste Tipográfico Bento (`features/dashboard` & `features/food_entry`)
- Modificar `MacroBentoCard` (`lib/features/dashboard/widgets/macro_bento_card.dart`):
  - Envolver la etiqueta en `FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(label, maxLines: 1))`.
  - Ajustar padding interior para pantallas angostas.
- Modificar `MealDetailView` (`lib/features/food_entry/meal_detail.view.dart`):
  - Aplicar `FittedBox` con `maxLines: 1` en el contenedor de Carbohidratos.

#### Subfase 2.3: Persistencia Segura de Imágenes (`features/food_entry/services`)
- Actualizar `MealImageStorageResolver`:
  - Priorizar `getApplicationDocumentsDirectory()` sobre cualquier directorio efímero o temporal.
  - Eliminar el uso de `Directory.systemTemp` como almacén de persistencia de fotos de comida.
  - Añadir verificación de existencia y rescate en `Meal.imagePath`.

#### Subfase 2.4: Auto-Refresco Reactivo del Dashboard (`features/food_entry/services`)
- Actualizar `AnalysisQueueService`:
  - En `_processTask`, tras actualizar estado a `completed` o `failed`, invocar:
    ```dart
    await DashboardController.instance.loadDashboardData();
    await FoodEntryController.instance.loadMeals();
    ```
  - Notificar a listeners para que el widget del Dashboard reconstruya los contadores calóricos y macros de forma instantánea.

#### Subfase 2.5: Rediseño Dark Bento de Master Prompt (`features/settings_profile`)
- Rediseñar `MasterPromptBottomSheet`:
  - Reemplazar el contenedor plano por un layout estructurado con pestaña de visualización Bento y pestaña de editor.
  - Crear mini-tarjetas Bento para BMR, TDEE, Presupuesto Calórico y Distribución de Macros.
  - Añadir botón de copiar con notificación snackbar.
  - Mantener archivo estrictamente < 300 LoC mediante la extracción de widgets atómicos de tarjetas si es necesario.

#### Subfase 2.6: Ventana de Contexto Dinámica (`features/settings_profile`)
- Crear servicio/calculador liviano `ContextMetricsCalculator`:
  - Estimar tokens del Master Prompt actual, catálogo de despensa, tile de imagen estándar y notas.
  - Exponer métricas mediante `ValueNotifier` o método estático liviano.
- Actualizar `GeminiModelSelectorCard` y `ModelPickerBottomSheet`:
  - Mostrar el consumo activo en formato visual claro: `Uso: ~2.1k / 1024k tokens (0.2%)`.
  - Añadir diálogo/tooltip con el desglose de los componentes del payload.

#### Subfase 2.7: Telemetría de Inferencia y Badges de Modelo en UI (`core/services/ai` & `features/food_entry`)
- Inyectar en `MealAnalysisResult` y en `ai_breakdown_json` de `Meal`:
  - `modelUsed`: Modelo exacto de respuesta devuelto por el runner (`currentModel`).
  - `isFallback`: Booleano determinista si `currentModel != primaryModel`.
  - `thinkingLevel`: Nivel de esfuerzo configurado para esa llamada.
- Actualizar `MealDetailView` y `MealCard`:
  - Renderizar un badge discreto con chip temático:
    - Normal: `[Gemini 4 Hydrogen · Esfuerzo: Medio]`
    - Fallback: `[Fallback: Gemini 2.5 Flash · Esfuerzo: Bajo]` (aviso transparente).

#### Subfase 2.8: Selectores de Esfuerzo de Pensamiento y Tokens en Ajustes (`features/settings_profile`)
- Añadir sección en `GeminiModelSelectorCard` o submodal:
  - Selector de esfuerzo: `OFF`, `LOW`, `MEDIUM`, `HIGH`, `X-HIGH`.
  - Selector de ventana/salida: `4k`, `8k`, `16k` max tokens.
- Persistir en almacenamiento local e inyectar en `GeminiVisionService` y `GeminiRestClient`.

### Fase 3: Quality Gate & Auditoría ODD (`quality-gate`)
1. Ejecutar suites TDD locales: `flutter test` y `bun test`.
2. Validar que 100% de los archivos modificados cumplan el límite de < 300 LoC.
3. Auditar con `flutter analyze` para asegurar 0 issues, 0 warnings y 0 deprecaciones.
4. Generar `artifacts/audit_reports/audit_report.md` con veredicto `PASS`.

### Fase 4: Pipeline de Release v1.5.2 (`release-pipeline`)
1. Incrementar versión a `1.5.2+1` en `pubspec.yaml`.
2. Registrar cambios en `artifacts/planning/changelog_v1.md`.
3. Compilar notas de release en `RELEASE_NOTES.md` con tablas de integridad.
4. Crear commit semántico `chore(release): v1.5.2` y tag `v1.5.2`.
5. Publicar en GitHub Releases con `gh release create`.

---

## 📊 4. Matriz de Asignación por Capacidad y Subagente

| Tarea Atómica | Capacidad Metodológica | Subagente Swarm | Archivos Impactados |
| :--- | :--- | :--- | :--- |
| **Voice & Text AI Analysis Fix** | `vsa-contracts` | `engine` | `lib/features/dashboard/widgets/voice_meal_recording_dialog.dart`, `lib/core/services/ai/gemini_vision_service.dart` |
| **Bento Typography & Label Scaling** | `vsa-contracts` | `bridge` | `lib/features/dashboard/widgets/macro_bento_card.dart`, `lib/features/food_entry/meal_detail.view.dart` |
| **Persistent Image Storage** | `vsa-contracts` | `domain` | `lib/features/food_entry/services/meal_image_storage_resolver.dart`, `lib/features/food_entry/models/meal.dart` |
| **Reactive Dashboard State Auto-Reload** | `vsa-contracts` | `domain` | `lib/features/food_entry/services/analysis_queue_service.dart`, `lib/features/dashboard/dashboard.controller.dart` |
| **Master Prompt Dark Bento Redesign** | `vsa-contracts` | `bridge` | `lib/features/settings_profile/widgets/profile/master_prompt_bottom_sheet.dart` |
| **Reactive Dynamic Context Window** | `vsa-contracts` | `engine` | `lib/features/settings_profile/widgets/gemini_model_selector_card.dart`, `lib/features/settings_profile/widgets/model_picker_bottom_sheet.dart` |
| **Inference Telemetry & UI Badges** | `vsa-contracts` | `engine` | `lib/core/services/ai/gemini_vision_service.dart`, `lib/features/food_entry/models/meal_analysis_result.dart`, `lib/features/food_entry/meal_detail.view.dart` |
| **User Thinking Level & Token Controls** | `vsa-contracts` | `bridge` | `lib/features/settings_profile/widgets/gemini_model_selector_card.dart`, `lib/core/services/ai/gemini_rest_client.dart` |
| **Quality Gate & 0 Lints Audit** | `quality-gate` | `audit` | `artifacts/audit_reports/audit_report.md` |
| **Release Pipeline v1.5.2** | `release-pipeline` | `coordinator` | `pubspec.yaml`, `artifacts/planning/changelog_v1.md` |

---

## ⏱️ 5. Criterios de Aceptación y Verificación

1. **Voz/Audio:** Pulsar el botón de grabación inicia captura real o indica claramente el estado de dictado; pulsar "Analyze with AI" con texto procesa la comida con Gemini y la añade sin error 400.
2. **Tipografía:** La palabra "Carbohidratos" / "Carbohydrates" se lee en una sola línea escalada o adaptada sin quiebres de guión (`Carbohydrat`/`es`) en resoluciones desde 320px de ancho.
3. **Persistencia de Fotos:** Una foto capturada permanece visible en el historial y en la vista de detalle de la comida incluso tras forzar el reinicio de la app o diferir el análisis.
4. **Auto-Refresco:** Al tomar una foto de una comida, el Dashboard se actualiza automáticamente tan pronto la notificación de fondo confirma el análisis, sin necesidad de pull-to-refresh manual.
5. **Master Prompt Modal:** Presenta una interfaz visual Dark Bento con chips métricos, pestañas claras y estética alineada con el selector de modelos.
6. **Ventana de Contexto:** El indicador muestra la cantidad real de tokens consumidos en la sesión frente al límite del modelo activo.
7. **Telemetría Transparente:** La vista de detalle de la comida muestra con certeza el modelo que respondió (`gemini-4-hydrogen` vs `fallback: gemini-2.5-flash`) y el nivel de esfuerzo ejecutado.
8. **Control de Razonamiento:** El usuario puede seleccionar en Ajustes su nivel de pensamiento preferido (`NONE`, `LOW`, `MEDIUM`, `HIGH`, `X-HIGH`) y su presupuesto de tokens (`4k`, `8k`, `16k`).
9. **Quality Gate:** `flutter analyze` reporta 0 issues y 100% de tests pasan en verde.
