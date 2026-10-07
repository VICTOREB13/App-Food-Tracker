---
tipo: implementation_plan
proyecto: App_Food_Tracker
iteracion: v1.3.1
estado: activo
fecha: 2026-10-06
tags: [proyecto, planning, v1-3-1, gemini-vision-precision, timeout-resilience, atomic-image-persistence, i18n-native]
---

# 🎯 Plan de Implementación Maestro: Food Tracker (v1.1.0)
## *Generación Omnicanal de Precisión Visual, Volumétrica y Nutricional*

> **Mesa de Control (Project-Planner):** Este plan formaliza la evolución de la aplicación hacia la versión **v1.1.0** (Food Tracker Omnichannel & Precision Release). Se abordan las 16 especificaciones técnicas requeridas: resiliencia total de IA, compresión instantánea en cola con anillo, preservación de fotos ante errores, estimación local por gramaje (zero tokens), calibración de vajilla en cm, catálogo de marcas de despensa con escaneo OCR de etiquetas, micronutrientes críticos (fibra, sodio, azúcar), ventana de ayuno intermitente, exportación clínica (PDF/Excel), selector dinámico de idioma, resúmenes semanales, re-análisis interactivo, registro por voz natural y video multimodal.

---

## 🧭 1. Determinación de Versión del Sistema

### Propuesta Oficial: Versión 1.1.0 (Minor Release / Nueva Generación Funcional)
- **Justificación Técnica (SemVer 2.0.0):**
  - La versión actual de producción es `1.0.4`.
  - Esta iteración introduce una expansión mayúscula de funcionalidades y una migración de base de datos a `Schema Version 3` (nuevas tablas `calibrated_dishware`, `meal_templates`, `fasting_logs` y columnas de micronutrientes `fiber`, `sodium`, `sugar`).
  - **100% Compatible hacia atrás:** La migración (`DatabaseSchema.onUpgrade` de 2 a 3) preserva de forma determinista la totalidad de datos existentes de los usuarios (comidas, fotos, pesos, perfiles). No rompe contratos de datos previos.
  - *Nota Comercial / Alternativa:* Si a nivel de producto se desea comercializar como **Food Tracker 2.0** ("Segunda Generación"), el hito tecnológico lo justifica plenamente por la adición de voz y video multimodal. No obstante, en ingeniería de software el estándar canónico es **v1.1.0**.

---

## 🎯 2. Requerimientos Funcionales y Solución de Arquitectura

### Bloque A: Resiliencia de Inferencia y Flujo Visual sin Fricción
1. **F01 - Flujo Visual de Compresión Inmediata con Anillo desde Segundo Cero:**
   - *Diagnóstico del fallo actual:* `AnalysisQueueService.enqueueMealAnalysis` ejecutaba `compressAndResizeAsync` y `saveMealImage` antes de insertar la tarea en memoria y antes de `notifyListeners()`, provocando un lapso de 1 a 2 segundos en el que la UI parecía congelada antes de mostrar el anillo de carga (`VeLoadingRing`).
   - *Solución:* Encolar la tarea inmediatamente en estado `queued` con `progress: 0.05` y `stage: 'Optimizando foto...'` al capturar la imagen. La UI monta el anillo en el milisegundo 0. El Isolate de compresión y el guardado físico se ejecutan como parte del flujo de trabajo reportando progreso continuo (`0.20`, `0.35`, `0.65`, `1.0`).
2. **F02 - Preservación Defensiva de Fotografías ante Fallos de Gemini:**
   - *Diagnóstico del fallo actual:* Si la API de Gemini fallaba o el usuario cerraba el banner de error, la foto en disco quedaba huérfana o se descartaba sin vincularse a un registro accesible.
   - *Solución:* La fotografía se persiste de forma inmutable. Si la llamada de IA falla:
     - El archivo en disco NUNCA se elimina.
     - La tarea en cola queda en estado `failed` con acciones explícitas: `[Reintentar con IA]` y `[Registrar manualmente con esta foto]`.
     - Si el usuario elige registro manual, se abre `MealDetailScreen` precargando la fotografía ya guardada para que no tenga que volver a fotografiar su comida.
3. **F03 - Resiliencia de Red y Backoff Exponencial en Gemini API:**
   - Incorporación de política de reintento automático con jitter defensivo ante errores transitorios (429 rate limit, 503 service unavailable, timeouts) de hasta 3 intentos espaciados (1s, 2s, 4s).
   - Cascada automática hacia modelo de contingencia (`gemini-2.5-flash` $\rightarrow$ `gemini-1.5-flash`).

### Bloque B: Precisión Nutricional, Despensa y Calibración Geométrica
4. **F04 - Estimación Inteligente Local por Gramaje (Zero Tokens):**
   - Creación del servicio desacoplado `OfflineFoodEstimatorService` con una base de datos local embebida de alimentos base de referencia (carnes, aves, pescados, huevos, legumbres, tubérculos, pastas, arroces, lácteos, frutas, verduras, aceites y semillas) normalizados por 100g.
   - Búsqueda determinista insensible a acentos y similitud de tokens. Al escribir por ejemplo "carne molida" y "100g" en `FoodItemEditorDialog` o en el creador rápido, la app autocompleta instantáneamente calorías, proteínas, carbohidratos y grasas con 0 llamadas a la API y 0 tokens consumidos.
5. **F05 - Calibración de Vajilla Personal (Diámetro y Radio en cm):**
   - Nueva entidad y tabla SQLite `calibrated_dishware` gestionada a través de `DishwareDao`.
   - Pantalla/sección de configuración donde el usuario registra sus platos principales (ej. "Plato Llano Blanco 26 cm", "Bowl Desayuno 16 cm").
   - Inyección en el prompt del sistema de Gemini Vision: escala métrica absoluta informando el diámetro exacto del plato en cm para calibrar el cubicaje y erradicar distorsiones de perspectiva visual.
6. **F06 - Catálogo de Marcas y Despensa con Escáner OCR de Etiquetas:**
   - Interfaz completa `PantryScreen` para gestionar marcas y productos habituales del usuario (ej. Harina PAN, Avena Quaker, Proteína Whey).
   - Escáner de etiqueta nutricional asistido por cámara: Gemini procesa la foto de la tabla de Información Nutricional una única vez, extrayendo marca, porción (serving size), calorías, macronutrientes y micronutrientes.
   - Enlace contextual: Al analizar un plato cocinado (ej. "Arepa"), Gemini recibe la lista de despensa activa del usuario en su prompt para mapear directamente a la marca y valores de su despensa personal.
7. **F07 - Plantillas de Comidas Habituales y Pesajes Verificados (1-Tap Logging):**
   - Tabla `meal_templates` en SQLite para almacenar combinaciones de alimentos pesados con balanza digital y verificados por el usuario.
   - Registro instantáneo en 1 toque desde el Dashboard sin necesidad de foto ni inferencia de IA.
8. **F08 - Re-análisis Interactivo con Sugerencias y Sustitución de Ingredientes:**
   - Al editar un ingrediente en `MealDetailScreen` (ej. sustituir mortadela por jamón de pavo), la llamada de re-análisis envía a Gemini el contexto diferencial (`previousItems`, `correctedItem`, `userNotes`).
   - La IA preserva las porciones volumétricas de la foto pero recalcula la densidad calórica, proteína y grasas específicas del ingrediente sustituido.
9. **F09 - Detección Multi-Plato y Mesa Completa:**
   - Prompting avanzado de segmentación espacial para escenas con múltiples componentes (plato principal, ensalada lateral, bebida, postre), catalogando cada ítem en su compartimento sin mezclar densidades calóricas.

### Bloque C: Datos Clínicos, Ayuno, Idioma y Reportes
10. **F10 - Desglose de Micronutrientes Críticos (Fibra, Sodio, Azúcares):**
    - Migración de SQLite a `v3`: Adición de columnas `fiber` (g), `sodium` (mg) y `sugar` (g) en `meals` y `meal_items`.
    - Actualización de modelos inmutables `FoodItem` y `Meal`.
    - Adaptación del esquema JSON en `GeminiVisionService` para inferir fibra, sodio y azúcares.
    - Chips informativos en `MealDetailScreen` y desglose de micronutrientes diarios.
11. **F11 - Temporizador de Ventana de Ayuno Intermitente (Fasting Window):**
    - Componente Bento `FastingWindowBentoCard` en el Dashboard.
    - Contabilización automática de horas transcurridas desde la última comida registrada del día anterior.
    - Selector de protocolos de ayuno estándar (16:8, 14:10, 18:6, 20:4) y visualización de progreso con anillo animado (Ayuno activo vs Ventana de alimentación).
12. **F12 - Selector Dinámico de Idioma en Ajustes:**
    - Opción de cambio de idioma (Español / Inglés) en `SettingsScreen`.
    - Persistencia en `SharedPreferences` y reactividad en `SettingsController`.
    - Cambio en caliente en `NutriTrackerApp` sin reiniciar la aplicación ni depender del idioma del sistema operativo.
13. **F13 - Resúmenes Semanales (Weekly Digest):**
    - Tarjeta/módulo de rendimiento semanal en `MetricsScreen`:
      - Promedio diario de calorías consumidas vs meta calórica.
      - Porcentaje de adherencia proteica semanal.
      - Balance calórico semanal acumulado (déficit / superávit en kcal).
      - Días con registro consistente.
14. **F14 - Exportación de Reportes Clínicos en PDF y Excel/CSV:**
    - Servicios desacoplados `ClinicalPdfExportService` y `ClinicalExcelExportService`.
    - Generación de informes PDF formateados con estándares clínicos (promedios de macros y micronutrientes, tendencia ponderal, desglose de platos y observaciones para nutricionistas/médicos).
    - Exportación estructurada en CSV/Excel para análisis en hojas de cálculo.

### Bloque D: Multimodalidad Avanzada (Voz y Video)
15. **F15 - Registro Rápido por Voz Natural (Audio-to-Macros):**
    - Botón de dictado por voz en el Dashboard (icono de micrófono).
    - Grabación de audio liviana y envío directo de la señal de voz a Gemini Flash Multimodal Audio (`audio/m4a` / `audio/wav`).
    - Gemini interpreta lenguaje natural coloquial ("Me comí dos arepas con queso blanco y un café con leche sin azúcar") y genera de inmediato el desglose de ingredientes y macros listo para registrar.
16. **F16 - Exploración de Video de Comida (Panning Volumétrico 3D):**
    - Grabación de un video corto (3 a 5 segundos con paneo circular) de la comida mediante `ImagePicker().pickVideo()`.
    - Envío directo a Gemini 1.5/2.0 Flash multimodal video (`video/mp4` inlineData) o extracción de fotogramas clave cenitales y laterales para inferencia volumétrica con profundidad 3D real.
17. **F17 - Widgets Nativos de Android para Pantalla de Inicio (Modo Claro y Modo Oscuro):**
    - **Widget 1: Compact Bento Widget (2x2):**
      - Anillo circular con calorías consumidas vs meta diaria (y calorías restantes).
      - Indicador numérico de calorías (ej. "850 / 2200 kcal").
      - Botón de acción rápida: `[+ Registrar Comida]` (abre directamente la app en la cámara o selector rápido).
      - Soporte nativo para Modo Claro (zinc claro `#FFFFFF` / `#F4F4F5`, texto carbón) y Modo Oscuro (zinc obsidiana `#09090B` / `#18181B`, acento carmesí `#DC2626`).
    - **Widget 2: Glance Wide Nutrition & Quick-Actions Widget (4x2):**
      - Columna Izquierda: Anillo de calorías con valor central ("1250 kcal restantes" o "850 / 2200 kcal").
      - Columna Central: Desglose de macronutrientes consumidos vs meta con iconos sobrios:
        - 🍗 Proteína consumida / restante (ej. "85g / 150g").
        - 🌾 Carbohidratos consumidos / restantes (ej. "120g / 220g").
        - 🥑 Grasas consumidas / restantes (ej. "35g / 65g").
      - Columna Derecha: Acciones interactivas de 1 toque:
        - 📸 **Escanear Comida (Cámara IA):** deep link `foodtracker://scan_food` que abre directamente la cámara para analizar comida sin fricción.
        - 🏷️ **Código de Barras:** deep link `foodtracker://scan_barcode` que abre directamente el escáner de barras.
      - Soporte para Modo Claro y Modo Oscuro vía Android XML resources (`values/colors.xml` y `values-night/colors.xml`).
    - **Infraestructura de Datos y Sincronización:**
      - Integración de `home_widget` y servicio `HomeWidgetService` (`lib/services/home_widget_service.dart` < 300 LoC).
      - Sincronización automática de datos cada vez que se registre, modifique o elimine una comida, o cambien las metas.
      - Manejo de Deep Links en `main.dart` / `DashboardScreen` para responder inmediatamente a los toques de los widgets.

---

## 🏗️ 3. Fases de Ejecución Progresiva (Teamwork)

```
[Fase 1: Base de Datos v3, Modelos y Servicios Core]
       │
       ▼
[Fase 2: Resiliencia Gemini, Zero-Token Estimator & Anillo Instantáneo]
       │
       ▼
[Fase 3: Despensa Personal, Escáner OCR de Etiquetas & Calibración de Vajilla]
       │
       ▼
[Fase 4: Widgets Nativos Android (2x2 Compacto & 4x2 Extendido con Macros)]
       │
       ▼
[Fase 5: Ayuno Intermitente, Selector de Idioma & Resumen Semanal]
       │
       ▼
[Fase 6: Exportación Clínica (PDF / Excel)]
       │
       ▼
[Fase 7: Multimodalidad: Dictado por Voz y Video Panning]
       │
       ▼
[Fase 8: Quality Gate Completo (Systems-Auditor) y Release v1.1.0 (DevOps-Engineer)]
```

### Fase 1: Arquitectura de Persistencia v3 y Modelos (Backend-Architect)
- Incrementar versión de base de datos a `version: 3` en `DatabaseConnectionFactory`.
- Implementar `DatabaseSchema.onUpgrade` de 2 a 3:
  - Alter table `meals` y `meal_items` agregando `fiber`, `sodium`, `sugar`.
  - Crear tabla `calibrated_dishware` e índices.
  - Crear tabla `meal_templates`.
  - Crear tabla `fasting_logs`.
  - Extender `pantry_items` con campos de serving y micronutrientes.
- Crear `DishwareDao`, `FastingDao`, `MealTemplateDao` y contratos abstractos en `lib/core/interfaces/`.
- Actualizar modelos inmutables `Meal` y `FoodItem` con micronutrientes (`fiber`, `sodium`, `sugar`).
- Registrar nuevos DAOs y servicios en `lib/core/di/service_locator.dart`.

### Fase 2: Resiliencia de IA, Compresión Inmediata y Estimador Zero-Token (Backend-Architect & Frontend-UI)
- Modificar `AnalysisQueueService.enqueueMealAnalysis`: Crear la tarea e insertarla en `_tasks` en el paso 0 antes de la compresión, disparando `notifyListeners()` de inmediato.
- Actualizar el worker para reportar las etapas de compresión y guardado con progreso fino.
- Modificar la gestión de errores en `AnalysisQueueService`: Nunca borrar el archivo de foto ante fallos de IA, mantener la tarea fallida con opciones "Reintentar" y "Registrar manualmente con esta foto".
- Implementar `OfflineFoodEstimatorService` con catálogo local de alimentos y algoritmo de búsqueda por tokens.
- Integrar la estimación automática en `FoodItemEditorDialog`.
- Implementar reintentos con backoff exponencial defensivo en `GeminiVisionService`.

### Fase 3: Despensa de Marcas con OCR de Etiquetas y Calibración de Platos (Backend-Architect & Frontend-UI)
- Crear `PantryScreen` y pantalla/diálogo de gestión de platos `DishwareSettingsScreen`.
- Implementar `NutritionLabelScannerService`: Prompt especializado para analizar fotos de tablas nutricionales y extraer datos estructurados hacia `PantryItem`.
- Actualizar `GeminiVisionService` para inyectar en el prompt el catálogo de marcas del usuario y el diámetro del plato calibrado.
- Soporte para re-análisis interactivo con sustitución de ingredientes en `MealDetailScreen`.

### Fase 4: Ayuno Intermitente, Selector Dinámico de Idioma y Resumen Semanal (Frontend-UI & Backend-Architect)
- Crear `FastingController` y `FastingWindowBentoCard` para el Dashboard.
- Incorporar `Locale _appLocale` en `SettingsController` con persistencia en `SharedPreferences`.
- Añadir selector interactivo de idioma en `SettingsScreen`.
- Actualizar diccionarios `app_es.arb` y `app_en.arb` con todas las nuevas cadenas.
- Implementar `WeeklyDigestCard` en `MetricsScreen` con cálculo de promedios, adherencia proteica y balance calórico.

### Fase 5: Exportación de Reportes Clínicos en PDF y Excel (Backend-Architect & Frontend-UI)
- Incorporar dependencias `pdf` y `csv`/`excel` en `pubspec.yaml`.
- Crear `ClinicalPdfExportService` con diseño clínico sobrio, gráficos y tablas de resumen nutricional.
- Crear `ClinicalExcelExportService` para exportación tabular.
- Crear diálogo de exportación en `MetricsScreen` con selector de fechas.

### Fase 6: Multimodalidad Avanzada: Voz y Video (Backend-Architect & Frontend-UI)
- Incorporar dependencia `record` para captura de audio.
- Implementar botón de dictado por voz en el Dashboard y método `analyzeSpeechMeal` en `GeminiVisionService`.
- Implementar selector de video corto en cámara/galería con inferencia multimodal en Gemini o muestreo multi-ángulo de fotogramas.

### Fase 7: Quality Gate Riguroso y Publicación (Systems-Auditor & DevOps-Engineer)
- Ejecutar suite completa de tests unitarios y de widgets (`flutter test`).
- Verificar que todos los archivos nuevos y modificados respeten el límite estricto de < 300 LoC.
- Verificar 0 errores en `flutter analyze`.
- Actualizar `artifacts/planning/changelog_v1.md` con la sección `[1.1.0] - 2026-10-04`.
- Incrementar versión en `pubspec.yaml` a `1.1.0+1`.
- Emitir veredicto formal `PASS` en `artifacts/audit_reports/audit_report.md`.
- Compilar y empaquetar APK release firmado en GitHub Actions.

---

## 🚀 3.5. Plan de Ejecución Iteración v1.2.4 (File Picker, Retrocompatibilidad JSON, Dashboard Ergonómico y Gramajes)

### Fase A: Backend Architecture & Storage (Backend-Architect)
1. **Versionado & Dependencias:**
   - Actualizar `pubspec.yaml` a `version: 1.2.4+1`.
   - Añadir `file_picker: ^8.1.7` (soporte multiplataforma, SAF sin permisos invasivos en Android).
2. **Normalización Retrocompatible de JSON (`BackupNormalizer`):**
   - Crear `lib/services/backup_normalizer.dart` (< 250 LoC) para traducir esquemas legados (v1.0.4 y anteriores):
     - Mapeo de claves en español (`comidas` $\rightarrow$ `meals`, `despensa` $\rightarrow$ `pantry_items`, `perfil` $\rightarrow$ `user_profile`, `pesos` $\rightarrow$ `weight_logs`).
     - Soporte para arrays crudos `[...]` envolviéndolos en `{"meals": [...]}`.
     - Ejecución de decodificación y parseo JSON en segundo plano mediante `Isolate.run`.
3. **Persistencia SQLite de Alto Rendimiento:**
   - Modificar `BackupService` (`lib/services/backup_service.dart` < 250 LoC) para persistir registros dentro de una única transacción usando `txn.batch()` y `batch.commit(noResult: true)` garantizando 60 FPS sin stutters en respaldos mayores a 500 registros.
4. **Esquema SQLite v4 y Gramaje de Despensa:**
   - Incrementar versión en `DatabaseConnectionFactory.dart` a 4.
   - Añadir columna `package_weight REAL` en `createPantryTable` y migración defensiva `_safeAddColumn(db, 'pantry_items', 'package_weight REAL')` en `DatabaseSchema.dart`.
   - Extender `PantryItem` (`lib/models/pantry_item.dart`): añadir `packageWeight`, serialización tolerante a nulos, y método `toScaledFoodItem({required double gramsConsumed})`.
5. **Pruebas Automatizadas Backend:**
   - `test/services/backup_normalizer_test.dart` y `test/models/pantry_item_portion_scaling_test.dart`.

### Fase B: Frontend UX/UI & Modales (Frontend-UI)
1. **Selector Nativo de Respaldos (R1 UI):**
   - Actualizar `JsonFilePickerDialog` (`lib/widgets/settings/json_file_picker_dialog.dart` < 250 LoC) con botón de 1 toque que invoca el selector nativo del sistema (`FilePicker.platform.pickFiles`), eliminando entradas de texto manuales.
2. **Reubicación Ergonómica de "¿Qué Debería Comer Hoy?" (R2 UI):**
   - Retirar la tarjeta fija `WhatToEatBannerCard` de `lib/screens/dashboard_screen.dart`.
   - Incorporar banner/botón destacado dentro del menú flotante `lib/widgets/dashboard/dashboard_fab_menu.dart`.
   - Rediseñar `WhatToEatSheet` (`lib/widgets/recommendations/what_to_eat_sheet.dart`): envolver en `SafeArea`, barra superior con botón explícito de cerrar (`IconButton(icon: Icon(Icons.close))`), límite de altura (`0.85`), y scroll fluido.
3. **Bento Card Colapsable de Ayuno Intermitente (R3 UI):**
   - Refactorizar `FastingWindowBentoCard` (`lib/widgets/dashboard/fasting_window_bento_card.dart` < 280 LoC) con diseño compacto (~44px) por defecto en estado inactivo, expandiéndose con animación al estar en ayuno o al pulsar.
4. **Corrección de Diálogo de Recomendaciones y Métricas (R3 UI):**
   - En `RecommendationDiagnosticCard` / diálogo: encapsular en `Dialog` con cabecera fija y scroll desacoplado para eliminar solapamiento con el botón de cierre.
   - En `WeeklyDigestCard` (`lib/widgets/metrics/weekly_digest_card.dart`): evitar desbordamiento horizontal del badge envolviendo en `Flexible`.
   - En `MetricsScreen` (`lib/screens/metrics_screen.dart`): aplicar `IntrinsicHeight` en fila calórica/racha para prevenir recorte del contenedor sobre tarjeta de macronutrientes.
5. **Editor de Despensa y Registro con Escalado Automático (R4 UI):**
   - Extraer `PantryItemEditorDialog` (`lib/widgets/pantry/pantry_item_editor_dialog.dart` < 200 LoC) con campos para porción de referencia (ej. 100g) y peso neto de empaque (ej. 500g).
   - Crear `PantryConsumptionDialog` (`lib/widgets/pantry/pantry_consumption_dialog.dart` < 200 LoC) con cálculo reactivo de macros escalados al registrar hacia comidas.
   - Añadir pruebas de widgets frontend.
6. **Corrección de InflateException en Widget Nativo 4x2 (Android RemoteViews):**
   - Sustituir etiquetas `<View>` en `android/app/src/main/res/layout/food_tracker_widget_wide.xml` y `lib/assets/android_widgets/food_tracker_widget_wide.xml` (líneas 96, 129, 197) por `<FrameLayout>` compatibles con `RemoteViews` para evitar `InflateException`.

### Fase C: Auditoría de Calidad y Verificación (Systems-Auditor)
1. `flutter analyze` con 0 errores y 0 advertencias.
2. 100% pruebas automatizadas exitosas (`flutter test`).
3. Verificación de modularidad: todos los archivos < 300 LoC.
4. Auditoría forense de integridad con veredicto CLEAN.
5. Emisión de `artifacts/audit_reports/audit_report.md` con veredicto PASS.

### Fase D: DevOps & Certificación de Release (DevOps-Engineer)
1. Verificación de Gradle / pubspec `1.2.4+1`.
2. Documentación formal en `artifacts/planning/changelog_v1.md` `[1.2.4]`.
3. Quality Gate final y reporte a Sentinel.

---

## 🌟 Iteración v1.2.5: Auto-Reparación de Respaldos, Rediseño Bento de Ayuno y Depuración Raíz

### Fase A: Backend & Resiliencia de Respaldos (Backend-Architect)
1. **Auto-Reparación de JSON Truncado (`BackupNormalizer._tryRepairTruncatedJson`):**
   - Detección de cadenas sin comilla de cierre (`FormatException: Unterminated string`).
   - Cierre automático de strings, sanitización de tokens pendientes y balanceo LIFO de llaves `{` y corchetes `[`.
   - Recuperación íntegra de la copia de respaldo en `Downloads/food_tracker_backup_restaurado.json` (11 comidas, perfil y pesos).
   - Suite de prueba unitaria en `test/services/backup_normalizer_test.dart` (PASS).

### Fase B: Frontend & Ergonomía Visual (Frontend-UI)
1. **Alineación de Tarjeta Bento de Ayuno (`FastingWindowBentoCard` < 300 LoC):**
   - Modo compacto: `Row` con `Expanded(Column)` de 2 líneas con elipsis y botón pill `Iniciar v` a la derecha sin superposición.
   - Modo expandido: Cabecera superior con título y botón de colapso en esquina derecha, cuerpo principal con anillo 52px y botón centrado verticalmente.

### Fase C: Auditoría de Calidad (Systems-Auditor)
1. Corrección de teardown en `test/widgets/fasting_window_bento_card_test.dart`.
2. Verificación de modularidad (< 300 LoC en todos los archivos modificados).
3. 100% de la suite automatizada superada (469 tests PASS) y 0 lints en CI.
4. Ratificación de `veredicto: PASS` en `artifacts/audit_reports/audit_report.md`.

### Fase D: DevOps, Higiene y Release (DevOps-Engineer)
1. Depuración completa de la carpeta raíz del proyecto (`Actual.png`, `Deseado.png`, `Screenshot_*.jpg`, respaldos y `test_apks/`).
2. Sincronización de versión a `1.2.5+1` en `pubspec.yaml` y `changelog_v1.md`.
3. Creación y push del tag anotado `v1.2.5`.
4. Monitoreo y publicación oficial del release en GitHub Actions (APK binario verificado).

---

## 🌟 Iteración v1.3.0: Auto-Actualizador In-App Sincronizado con GitHub, Microinteracciones y Refinamiento Visual ADB

### Fase A: Backend & Servicio de Actualización In-App (Backend-Architect)
1. **Servicio de Actualización GitHub (`AppUpdateService` < 250 LoC):**
   - Integración con API pública de GitHub Releases (`https://api.github.com/repos/VICTOREB13/App-Food-Tracker/releases/latest`).
   - Modelo de dominio `GitHubReleaseModel` (tag, title, notes/body, apkUrl, apkSizeBytes, publishedAt).
   - Comparador de SemVer estricto (`isUpdateAvailable(String currentVersion, String latestTag)`).
   - Descarga progresiva de bytes del APK en `cache/updates/` reportando ratio de progreso continuo (`onProgress(double ratio, int receivedBytes, int totalBytes)`).
2. **Servicio Instalador Nativo (`AppInstallerService` < 150 LoC):**
   - Canal de plataforma `MethodChannel("com.victorengineer.foodtracker/app_installer")`.
   - Métodos: `installApk(String filePath)`, `canRequestPackageInstalls()`, `openInstallPermissionSettings()`.
   - Fallback resiliente con `url_launcher` para abrir la URL de descarga web en navegador si el usuario deniega permisos o falla el provider nativo.
3. **Capa Nativa Android (`MainActivity.kt`, `AndroidManifest.xml`, `file_paths.xml`):**
   - `FileProvider` (`androidx.core.content.FileProvider`) apuntando a caché y archivos con URI segura `content://com.victorengineer.foodtracker.fileprovider/...`.
   - Permiso `<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>`.
   - Intent `Intent.ACTION_VIEW` con `FLAG_GRANT_READ_URI_PERMISSION` y tipo `application/vnd.android.package-archive`.
4. **Registro DI y Pruebas Unitarias:**
   - Registro en `lib/core/di/service_locator.dart`.
   - Pruebas unitarias de parsing, SemVer, descargas y fallback en `test/services/app_update_service_test.dart`.

### Fase B: Frontend, Diálogos y Microinteracciones (Frontend-UI)
1. **Diálogo Modal y Comprobación de Versión (`InAppUpdateDialog` & Ajustes < 250 LoC):**
   - Diálogo modal con release notes en markdown/texto, tamaño de descarga, botón "Actualizar Ahora" con barra de progreso reactiva y botón "Descargar desde GitHub".
   - Verificación en segundo plano al abrir el Dashboard (banner no intrusivo o snackbar sutil).
   - Sección dedicada "Actualizaciones de la Aplicación" en `SettingsScreen` con botón manual "Buscar actualizaciones", estado de versión actual y última comprobación.
2. **Microinteracciones Hápticas y Elásticas (`VeBounceable` & `VeAnimatedCounter`):**
   - `VeBounceable` (< 120 LoC): componente con feedback elástico `Transform.scale(0.96)` y física amortiguada `Curves.easeOutBack` al presionar botones principales (FAB `+`, Ayuno `Iniciar`, Acciones).
   - `VeAnimatedCounter` (< 120 LoC): transiciones numéricas fluidas para calorías y macros en el Dashboard.
   - Feedback háptico táctil con `HapticFeedback.lightImpact()` y `selectionClick()` en FAB, registro de agua (+250ml), temporizador de ayuno y selectores.
   - Animación "Breathing Glow" en anillo y badge de ayuno cuando esté activo.
3. **Refinamiento Visual Ergonómico (Hallazgos Auditoría ADB):**
   - `DashboardScreen`: eliminar flecha `<-` residual con `automaticallyImplyLeading: false` en `VeAppBar`.
   - `PantryItemEditorDialog`: corregir etiqueta recortada "Peso n..." ajustando diseño a dos líneas o label conciso "Peso total (g)".
   - `WeeklyDigestCard`: asegurar ancho adecuado para el título "RESUMEN SEMANAL" sin elipsis.
   - `PantryScreen`: optimizar padding y scroll horizontal de chips de categorías.

### Fase C: Auditoría de Calidad (Systems-Auditor)
1. Verificación del límite modular (< 300 LoC en el 100% de archivos creados y modificados).
2. Ejecución de `flutter analyze` con 0 errores y 0 warnings.
3. Ejecución de la suite completa de pruebas unitarias y de widgets (`flutter test`).
4. Ratificación formal de `veredicto: PASS` en `artifacts/audit_reports/audit_report.md`.

### Fase D: DevOps & Publicación de Release (DevOps-Engineer)
1. Incremento de versión en `pubspec.yaml` a `1.3.0+1`.
2. Documentación formal en `artifacts/planning/changelog_v1.md` `[1.3.0] - 2026-10-05`.
3. Sincronización y actualización de todos los artefactos.
4. Creación y push del tag anotado `v1.3.0` para compilar y publicar el APK oficial en GitHub Actions.

---

## 🌟 3.5. Plan de Implementación de la Iteración v1.3.1: Alta Precisión Volumétrica, Resiliencia de Timeouts, Persistencia Atómica e i18n Nativo

### Fase A: Backend, Esquema Causal de IA y Timeouts Extendidos (Backend-Architect)
1. **Inversión Causal del Schema y Prompt de Gemini Vision (`gemini_resilience_helper.dart`):**
   - Reestructurar el JSON schema para obligar al modelo LLM autorregresivo a calcular:
     - Detección de referencia métrica (plato de 26 cm o vajilla calibrada).
     - Dimensiones 3D y volumen en $cm^3$ ($L \times W \times H$).
     - Densidad ($g/cm^3$) y estado de cocción (pérdida de agua / hidratación).
     - Detección de brillo y grasas/aceites ocultos.
     - Gramos calculados $\text{Masa} = \text{Volumen} \times \text{Densidad} \times \text{Factor de cocción}$.
     - Macronutrientes deducidos estrictamente a partir de los gramos calculados.
2. **Catálogo de Modelos Modernos y Thinking Budget (`gemini_model_service.dart`):**
   - Retirar la familia obsoleta `gemini-2.0-flash`.
   - Establecer `gemini-3.8-flash` como modelo diario predeterminado y `gemini-3.1-pro` como modo clínico de alta precisión.
   - Soportar `thinking_budget: 1024` para modelos con razonamiento latente.
3. **Resiliencia de Timeouts a 90s - 120s (`gemini_vision_service.dart`):**
   - Incrementar el timeout de red de 35s a 90s (y hasta 120s para modos pro/pensamiento profundo), protegiendo contra excepciones prematuras en redes móviles o análisis complejos.
   - Manejo de contingencia claro ante expiración de tiempo.

### Fase B: Frontend, Pacing Asíncrono, Persistencia Atómica e i18n Limpio (Frontend-UI)
1. **Persistencia Atómica de Imágenes al Cambiar Tipo de Comida (Bug 1 Fix):**
   - En `MealDetailScreen`, el dropdown solo modifica la variable en memoria `_mealType = val`.
   - En `meal_detail_actions.dart`, el renombramiento físico se realiza atómicamente al confirmar "Guardar" / "Actualizar" junto a la transacción SQLite. Si el usuario cancela, la imagen y el registro permanecen intactos.
2. **Erradicación Total de `isSpanish` y Soporte Multilingüe Nativo (Bug 2 Fix):**
   - Cero condicionales de idioma en widgets de Flutter.
   - Poblar `lib/l10n/app_es.arb` y `lib/l10n/app_en.arb` con todas las claves de comidas, formularios, etapas de IA y tooltips.
   - Compilar con `flutter gen-l10n` y consumir `AppLocalizations.of(context)!` universalmente.
   - Inicializar formato de fechas para todos los idiomas en `lib/main.dart`.
3. **Pacing Realista del Anillo de Carga y Feedback de Estado:**
   - Rediseñar el temporizador en `MealDetailScreen` para un avance suave y progresivo en 5 etapas reales sin saltar abruptamente al 88%.

### Fase C: Auditoría de Calidad y Pruebas (Systems-Auditor)
1. Ejecución de `flutter analyze` (0 errores, 0 warnings).
2. Verificación de `flutter test` (100% pruebas pasando).
3. Verificación de cumplimiento estricto del límite de < 300 LoC por archivo.
4. Emisión de informe formal con `veredicto: PASS` en `artifacts/audit_reports/audit_report.md`.

### Fase D: DevOps, Tagging y Publicación de Release (DevOps-Engineer)
1. Incremento de versión a `version: 1.3.1+1` en `pubspec.yaml`.
2. Actualización de `artifacts/planning/changelog_v1.md` con la versión `[1.3.1] - 2026-10-06`.
3. Creación y push del tag anotado `v1.3.1` en GitHub para disparar el workflow de compilación y publicación de APK.

---

---

## 🔒 4. Matriz de Cumplimiento de Restricciones Técnicas

| Restricción | Estrategia de Cumplimiento |
| :--- | :--- |
| **Límite de < 300 LoC por archivo** | Descomposición en servicios atómicos (`OfflineFoodEstimatorService`, `NutritionLabelScannerService`, `ClinicalPdfExportService`, DAOs independientes). |
| **Inyección de Dependencias** | Registro riguroso en `lib/core/di/service_locator.dart` (`GetIt`). |
| **Manejo Funcional de Errores** | Uso de `Result<T, Failure>` en todos los nuevos DAOs y servicios de exportación/estimación. |
| **Internacionalización (l10n)** | Cero textos hardcodeados; uso estricto de `AppLocalizations` con soporte bilingüe ES/EN. |
| **No Mermaid** | Diagramas de arquitectura y flujos documentados en HTML/SVG con Archify. |
| **Cero Código en Chat Raíz** | Orquestación exclusiva por Project-Planner; delegación a subagentes especializados. |

---

## 📋 5. Enlaces a Artefactos Vinculados

- **Visión General del Proyecto:** [[PRJ_App_Food_Tracker_overview|Visión General del Proyecto]]
- **Arquitectura del Sistema:** [[PRJ_App_Food_Tracker_architecture|Arquitectura del Sistema]]
- **Abstracciones y Contratos:** [[PRJ_App_Food_Tracker_abstractions|Abstracciones]]
- **Especificación de API y Modelos:** [[PRJ_App_Food_Tracker_api_spec|Especificación de API]]
- **Checklist de Tareas:** [[PRJ_App_Food_Tracker_task|Checklist de Tareas]]
- **Historial de Cambios:** [[PRJ_App_Food_Tracker_changelog_v1|Changelog]]
- **Reporte de Auditoría:** [[PRJ_App_Food_Tracker_audit_report|Reporte de Auditoría]]
