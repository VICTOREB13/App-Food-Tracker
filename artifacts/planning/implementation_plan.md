---
tipo: implementation_plan
proyecto: App_Food_Tracker
iteracion: v1.3.3
estado: activo
fecha: 2026-10-07
tags: [proyecto, planning, v1-3-3, gemini-vision, streaming, decoupled-cot, queue-resilience, multi-task, native-tiling, resilience]
---

# 🎯 Plan de Implementación v1.3.3: Inferencia en Streaming con Razonamiento Desacoplado y Cola Resiliente Multi-Comida

> **Mesa de Control (Project-Planner):** Este plan formaliza la optimización y estabilización del subsistema de inferencia de IA en streaming (`GeminiVisionService`, `GeminiResilienceHelper`, `GeminiModelService`), y la reingeniería de la cola de análisis en segundo plano (`AnalysisQueueService`, `AnalysisProgressBanner`) para la versión **v1.3.3**. Se preserva la inferencia en streaming continuo con `StringBuffer` para evitar caídas NAT, se desacopla el razonamiento volumétrico (*Decoupled CoT*), y se dota a la cola de resiliencia concurrente para evitar que una nueva comida borre o tape platos pendientes o fallidos.

---

## 🔍 1. Diagnóstico Forense y Requerimientos

1. **Streaming vs Inferencia Unaria en Gemini Vision:**
   - La inferencia mediante **Streaming** (`model.generateContentStream` acumulando en `StringBuffer`) es la estrategia óptima para mitigar caídas por inactividad de sockets TCP en gateways NAT móviles durante análisis de 45–80s.
   - El 70% de los fallos diagnosticados previamente no se debía al streaming en sí, sino a:
     - **Deadlock de Gramática Restringida (CFG):** Se exigían 10 campos euclidianos fijos (`forma_geometrica_3d`, `dimensiones_estimadas_cm`, `volumen_cm3`, etc.) que colapsaban en alimentos amorfos (sopas, guisos, arroz) y que además se descartaban al 100% en `lib/models/food_item.dart`.
     - **Tiling ineficiente:** Imágenes de 1024px generaban 4 tiles (1,032 tokens) aumentando latencia y riesgo de timeout.
     - **Incompatibilidad de `thinking_budget`:** En Gemini 3 causaba errores `HTTP 400 INVALID_ARGUMENT`.
     - **Falta de captura de `FormatException`:** Errores de parseo JSON no activaban el fallback a `gemini-2.5-flash`.

2. **Bug de Cola y Pérdida de Comidas en Segundo Plano:**
   - Cuando una comida fallaba o quedaba en segundo plano sin reintentar y el usuario enviaba otra comida, la anterior desaparecía visualmente ("se borraba completamente").
   - Causa raíz:
     - `AnalysisProgressBanner` evaluaba únicamente `currentActiveTask ?? latestFailedTask ?? latestCompletedTask`, seleccionando exclusivamente un único objeto `AnalysisTask`. Al encolar la comida B, la comida A quedaba instantáneamente oculta de la pantalla.
     - `enqueueMealAnalysis` no realizaba persistencia inmediata en SQLite, arriesgando pérdida de estado.
     - La cola requería soporte nativo para múltiples tareas visibles (`visibleTasks`), preservación física de fotos y procesamiento ordenado FIFO.

---

## 🏗️ 2. Solución de Arquitectura Técnica

### A. Streaming Continuo con Razonamiento Desacoplado (*Decoupled CoT*)
- Se mantiene `model.generateContentStream([content])` acumulando fragmentos de texto en `StringBuffer`.
- Se implementa el campo libre inicial `razonamiento_volumetrico` (String) al inicio de `mealAnalysisSchema`:
  - Permite al transformer autorregresivo deducir vajilla, 3D, hidratación, merma y grasas ocultas sin restricciones sintácticas rígidas.
  - Luego genera ordenadamente `plato`, `items` (con `alimento`, `gramos_estimados`, macros y micronutrientes) y `totales`.
- Soporte oficial y positivo para comidas unitarias (1 ítem) en `baseSystemInstruction` y Few-Shot representativo.

### B. Mosaicos Nativos de 768px y Orden Multimodal Óptimo
- Se fija `targetMaxDimension: 768` en `_prepareImageBytes` de `GeminiVisionService` (1 tile = 258 tokens vs 1,032 tokens a 1024px).
- Se envía `TextPart(prompt)` antes de `DataPart('image/jpeg', bytes)` para condicionar la atención multimodal antes de decodificar imágenes.

### C. Captura de `FormatException` y Exclusión de `thinking_budget` en Gemini 3
- `GeminiResilienceHelper.isRetriableError` captura `FormatException` y errores sintácticos de chunk para activar fallback inmediato a `gemini-2.5-flash`.
- `GeminiModelService.buildCallConfig` y `resolveThinkingBudget` excluyen la inyección de `thinking_budget` en modelos que inicien con `gemini-3`, evitando el error `HTTP 400 INVALID_ARGUMENT`.

### D. Cola y Banner Multi-Tarea Resilientes
- `AnalysisQueueService`:
  - Expone `visibleTasks` conteniendo todas las tareas activas, fallidas y completadas pendientes de revisión.
  - Encola tareas de forma no destructiva con persistencia inmediata en SQLite (`_persistTaskToDb`).
  - Procesa en orden FIFO (`lastWhere` con inserción al inicio).
- `AnalysisProgressBanner`:
  - Renderiza una lista reactiva (`Column`) de tarjetas independientes (`_buildTaskCard`) para cada tarea en `visibleTasks`.
  - Si una comida falló y el usuario sube otra, ambas se muestran simultáneamente con sus estados, fotos, porcentajes y botones de acción independientes (`[Editar manualmente]`, `[Reintentar]`, `[Abrir plato]`, `[Cerrar]`).

---

## 🛠️ 3. Fases de Ejecución

### Fase 1: Servicios de Inferencia e IA (`Backend-Architect`)
1. `lib/services/gemini_resilience_helper.dart`: Esquema `razonamiento_volumetrico` desacoplado, Few-Shot representativo y captura de `FormatException`.
2. `lib/services/gemini_vision_service.dart`: Streaming continuo, compresión a 768px y `TextPart` antes de `DataPart`.
3. `lib/services/gemini_model_service.dart`: Exclusión de `thinking_budget` en Gemini 3.

### Fase 2: Cola y UI Multi-Comida (`Backend-Architect` & `Frontend-UI`)
1. `lib/services/analysis_queue_service.dart`: `visibleTasks`, persistencia SQLite inmediata en encolado, orden FIFO.
2. `lib/widgets/dashboard/analysis_progress_banner.dart`: Renderizado concurrente de tarjetas por cada tarea visible.

### Fase 3: Versionado y Calidad (`DevOps-Engineer` & `Systems-Auditor`)
1. Actualización a versión `1.3.3` en `lib/core/constants/app_constants.dart` y `1.3.3+1` en `pubspec.yaml`.
2. Suites de pruebas en `test/` actualizadas para streaming, CoT desacoplado y concurrencia en cola.
3. Verificación estricta de `< 300 LoC` en todos los archivos de `lib/`.
4. Quality Gate aprobado en `artifacts/audit_reports/audit_report.md`.
5. Git commit, push a origin main y creación y push del tag `v1.3.3`.

---

## 🔒 4. Matriz de Cumplimiento de Restricciones Técnicas

| Restricción | Estrategia de Cumplimiento |
| :--- | :--- |
| **Límite de < 300 LoC por archivo** | Verificación estricta en el 100% de archivos en `lib/` (ninguno supera 299 líneas). |
| **Streaming Activo** | `model.generateContentStream` acumulando en `StringBuffer` contra desconexiones NAT. |
| **Multi-Comida Resiliente** | `visibleTasks` y renderizado individual por tarjeta en `AnalysisProgressBanner`. |
| **Compatibilidad hacia atrás** | Modelos `FoodItem` y `MealAnalysisResult` inmutables; sin alteraciones de esquema SQLite. |
| **Despliegue y Release** | Push y tag `v1.3.3` autorizados explícitamente por el usuario para esta iteración. |

---

## 📋 5. Enlaces a Artefactos Vinculados

- **Visión General del Proyecto:** [[PRJ_App_Food_Tracker_overview|Visión General del Proyecto]]
- **Arquitectura del Sistema:** [[PRJ_App_Food_Tracker_architecture|Arquitectura del Sistema]]
- **Abstracciones y Contratos:** [[PRJ_App_Food_Tracker_abstractions|Abstracciones]]
- **Especificación de API y Modelos:** [[PRJ_App_Food_Tracker_api_spec|Especificación de API]]
- **Checklist de Tareas:** [[PRJ_App_Food_Tracker_task|Checklist de Tareas]]
- **Historial de Cambios:** [[PRJ_App_Food_Tracker_changelog_v1|Changelog]]
- **Reporte de Auditoría:** [[PRJ_App_Food_Tracker_audit_report|Reporte de Auditoría]]
