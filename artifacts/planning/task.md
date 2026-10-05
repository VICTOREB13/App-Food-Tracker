---
tipo: task_list
proyecto: App_Food_Tracker
iteracion: v1.2.5
estado: activo
fecha: 2026-10-04
tags: [proyecto, tasks, checklist, v1-2-5]
---

# 📋 Checklist Maestro de Tareas de Agentes (v1.2.1)

> **Mesa de Control (Project-Planner):** Este checklist asigna y verifica los entregables atómicos de la iteración v1.2.1. Cada tarea completada se marca con `[x]`.

---

## 🌟 Iteración v1.1.0: Generación Omnicanal de Precisión Visual, Volumétrica y Nutricional

### 🧭 1. Project-Planner (Master Tech Lead & Orquestador)
- [x] (Project-Planner) Analizar y consolidar las 16 especificaciones del usuario en `artifacts/planning/implementation_plan.md`.
- [x] (Project-Planner) Definir la propuesta de versión canónica `v1.1.0` (y alternativa de producto `v2.0.0`) basada en SemVer y migración de SQLite a `v3`.
- [x] (Project-Planner) Despachar subagentes especializados (`Backend-Architect`, `Frontend-UI`, `Systems-Auditor`, `DevOps-Engineer`) por fases.
- [x] (Project-Planner) Actualizar `artifacts/architecture/architecture.md`, `abstractions.md` y compilar el diagrama HTML interactivo con `Archify`.
- [x] (Backend-Architect & Frontend-UI) **Búsqueda en Vivo de Alimentos por API (USDA & Open Food Facts Search):**
  - Implementar búsqueda textual en `OpenFoodFactsService` y unificar en `OnlineFoodSearchService` con auto-escalado proporcional por gramos.
  - Integrar dropdown reactivo con debounce (~350ms) en `FoodItemEditorDialog` y `QuickMealDialog` para rellenar macros oficiales de internet en 1 toque.

### 🗄️ 2. Backend-Architect (Datos, Migración v3, Servicios e IA)
- [x] (Backend-Architect) **Migración SQLite v3 (`DatabaseSchema` & `DatabaseConnectionFactory`):**
  - Incrementar base de datos a `version: 3`.
  - Añadir columnas `fiber REAL NOT NULL DEFAULT 0.0`, `sodium REAL NOT NULL DEFAULT 0.0`, `sugar REAL NOT NULL DEFAULT 0.0` a `meals` y `meal_items`.
  - Crear tabla `calibrated_dishware` (id, name, diameter_cm, depth_cm, shape, is_default, created_at) e índices.
  - Crear tabla `meal_templates` (id, name, meal_type, calories, protein, carbs, fat, fiber, sodium, sugar, items_json, created_at).
  - Crear tabla `fasting_logs` (id, start_time, target_hours, end_time, is_active, notes).
  - Extender `pantry_items` con campos de porción (`serving_size`, `serving_unit`), micronutrientes y palabras clave de coincidencia (`match_keywords`).
- [x] (Backend-Architect) **DAOs Especializados y Contratos (< 300 LoC):**
  - Crear `DishwareDao` y su interfaz `IDishwareDao`.
  - Crear `MealTemplateDao` y su interfaz `IMealTemplateDao`.
  - Crear `FastingDao` y su interfaz `IFastingDao`.
  - Registrar interfaces y fábricas en `lib/core/di/service_locator.dart`.
- [x] (Backend-Architect) **Modelos de Dominio:**
  - Extender `FoodItem` y `Meal` para soportar `fiber`, `sodium` y `sugar`, actualizando serializadores JSON y `recalculateFromItems`.
  - Crear modelo `CalibratedDishware`, `MealTemplate` y `FastingLog`.
- [x] (Backend-Architect) **Resiliencia de Gemini API y Backoff:**
  - Implementar reintentos con backoff exponencial y jitter (hasta 3 intentos) ante errores 429/500/503 en `GeminiVisionService`.
  - Cascada de conmutación a modelo secundario (`gemini-2.5-flash` $\rightarrow$ `gemini-1.5-flash`).
- [x] (Backend-Architect) **Flujo de Cola y Preservación de Fotos (`AnalysisQueueService`):**
  - Encolar tarea en el paso 0 (`progress: 0.05`, `stage: 'Optimizando foto...'`) antes de ejecutar compresión e isolate, disparando `notifyListeners()` de inmediato.
  - Garantizar preservación inmutable del archivo físico en disco ante fallos de IA, dejando la tarea en `failed` sin borrar la foto y permitiendo reintento o guardado manual.
- [x] (Backend-Architect) **Estimador Inteligente Local Zero-Tokens (`OfflineFoodEstimatorService`):**
  - Implementar catálogo offline embebido de alimentos base normalizados por 100g con búsqueda por tokens.
  - Exponer método `estimateNutrients(String foodName, double grams)` con retorno determinista en milisegundos sin consumir tokens.
- [x] (Backend-Architect) **Escáner OCR de Etiquetas y Despensa (`NutritionLabelScannerService`):**
  - Diseñar prompt estructurado para analizar fotos de tablas nutricionales y poblar `PantryItem`.
  - Inyectar contexto de despensa activa del usuario en el prompt de `GeminiVisionService`.
- [x] (Backend-Architect) **Inyección de Escala Métrica de Vajilla:**
  - Inyectar el diámetro del plato calibrado por defecto en el prompt del sistema de Gemini Vision para cubicaje volumétrico con escala métrica real.
- [x] (Backend-Architect) **Re-análisis Interactivo con Sustitución y Detección Multi-Plato:**
  - Actualizar `reanalyzeMealWithAi` para aceptar sustituciones diferenciales de ingredientes y segmentación espacial multi-plato (plato fuerte, ensalada, bebida).
- [x] (Backend-Architect) **Servicios de Exportación Clínica:**
  - [x] Crear `ClinicalExcelExportService` (< 300 LoC) para exportar historial tabular a Excel/CSV con estándar RFC 4180 y UTF-8 BOM.
- [x] (Backend-Architect) **Multimodalidad (Voz y Video):**
  - Implementar método `analyzeSpeechMeal(Uint8List audioBytes)` en `GeminiVisionService`.
  - Implementar método `analyzeVideoFramesMeal(List<Uint8List> frameBytesList)` para muestreo multi-ángulo tridimensional.

### 🎨 3. Frontend-UI (Diseño, Ergonomía y Pantallas < 300 LoC)
- [x] (Frontend-UI) **Anillo de Carga Inmediato en Dashboard:**
  - Actualizar `DashboardScreen` para que `AnalysisProgressBanner` y `VeLoadingRing` reflejen instantáneamente la etapa de optimización desde el segundo 0 al tomar la foto.
  - En caso de error de análisis, mostrar en el banner los dos botones de acción: `[Reintentar con IA]` y `[Editar manualmente]` con la foto intacta.
- [x] (Frontend-UI) **Estimador en Tiempo Real en `FoodItemEditorDialog`:**
  - Conectar el campo de texto de nombre de ingrediente y peso con `OfflineFoodEstimatorService` para autocompletar macros en tiempo real sin congelar la UI.
- [x] (Frontend-UI) **Pantalla de Despensa y Marcas (`PantryScreen`):**
  - Lista de productos del usuario, filtros por categoría y botón de escaneo de etiqueta nutricional con cámara.
- [x] (Frontend-UI) **Configuración de Calibración de Vajilla (`DishwareSettingsScreen`):**
  - Tarjeta en Perfil/Ajustes para registrar platos y especificar su diámetro en cm.
- [x] (Frontend-UI) **Desglose Visual de Micronutrientes:**
  - Actualizar `MealDetailScreen` para mostrar chips de Fibra, Sodio y Azúcar.
- [x] (Frontend-UI) **Temporizador de Ayuno Intermitente (`FastingWindowBentoCard`):**
  - Tarjeta Bento en el Dashboard con horas de ayuno transcurridas, objetivo configurable y anillo de progreso.
- [x] (Frontend-UI) **Selector Dinámico de Idioma en Ajustes:**
  - Selector interactivo Español / Inglés en `SettingsScreen` conectado a `SettingsController.setLocale()`.
- [x] (Frontend-UI) **Resumen Semanal (`WeeklyDigestCard`):**
  - Tarjeta en `MetricsScreen` con promedios semanales de calorías, adherencia de macros y balance acumulado.
- [x] (Frontend-UI) **Diálogo de Exportación Clínica:**
  - Modal en `MetricsScreen` para seleccionar rango de fechas y descargar reporte en PDF o Excel.
- [x] (Frontend-UI) **Dictado por Voz y Video en Dashboard:**
  - Botón de micrófono en el Dashboard para grabación de audio natural.
  - Opción de video panning en el selector de captura de comida.
- [x] (Frontend-UI) **Widgets Nativos de Android (2x2 y 4x2 en Modo Claro y Oscuro):**
  - Diseñar layouts Android XML para Widget Compacto 2x2 (`res/layout/food_tracker_widget_compact.xml` con anillo y calorías).
  - Diseñar layout para Widget Extendido 4x2 (`res/layout/food_tracker_widget_wide.xml` con anillo de calorías, columnas de macros y botones de acción rápida).
  - Definir recursos de color y contraste en `res/values/colors.xml` (modo claro) y `res/values-night/colors.xml` (modo oscuro zinc).
  - Configurar metadatos XML de AppWidgetProvider (`res/xml/food_tracker_widget_compact_info.xml` y `res/xml/food_tracker_widget_wide_info.xml`).
  - Registrar receivers en `android/app/src/main/AndroidManifest.xml`.
  - Crear e integrar `HomeWidgetService` (`lib/services/home_widget_service.dart` < 300 LoC) conectando `home_widget` con `MealController` y `SettingsController`.
  - Soportar deep links interactivos (`foodtracker://scan_food` y `foodtracker://scan_barcode`) para abrir la cámara o el escáner de barras directamente desde el widget en 1 toque.
- [x] (Frontend-UI) **Diccionarios Bilingües (`app_es.arb` y `app_en.arb`):**
  - Traducir y registrar la totalidad de las nuevas cadenas de texto de las funcionalidades y widgets.

### 🧪 4. Systems-Auditor (Auditoría, Cobertura y Quality Gate)
- [x] (Systems-Auditor) Crear pruebas unitarias para `OfflineFoodEstimatorService`, `DishwareDao`, `FastingDao`, `MealTemplateDao`.
- [x] (Systems-Auditor) Crear pruebas de migración de base de datos (`onUpgrade` de versión 2 a 3) verificando que no se pierdan datos existentes y ejecución idempotente.
- [x] (Systems-Auditor) Crear pruebas de resiliencia y reintento en `GeminiVisionService` simulando fallos 429 y 503.
- [x] (Systems-Auditor) Crear pruebas de widget para `FastingWindowBentoCard`, `WeeklyDigestCard` y `PantryScreen`.
- [x] (Systems-Auditor) Auditar cumplimiento estricto del límite modular: 100% de los archivos nuevos y modificados por debajo de 300 LoC.
- [x] (Systems-Auditor) Verificar que todas las suites de prueba pasen al 100% con 0 errores de linter y emitir reporte de Quality Gate `veredicto: PASS` en `artifacts/audit_reports/audit_report.md`.

### 🚀 5. DevOps-Engineer (CI/CD, Versioning & Release v1.1.0)
- [x] (DevOps-Engineer) Incrementar versión en `pubspec.yaml` a `1.1.0+1`.
- [x] (DevOps-Engineer) Documentar todos los cambios y nuevas capacidades en `artifacts/planning/changelog_v1.md` bajo `[1.1.0] - 2026-10-04`.
- [x] (DevOps-Engineer) Compilar y empaquetar APK release firmado `Victor-Engineer-Food-Tracker-Android.apk`.
- [x] (DevOps-Engineer) Publicar el release oficial `v1.1.0` en GitHub Actions y GitHub Releases.

---

## 🌟 Iteración v1.1.1: Modernización de Dependencias, Higiene de Compilador y Estabilidad Criptográfica
- [x] (DevOps-Engineer) Incrementar versión en `pubspec.yaml` a `1.1.1+1`.
- [x] (DevOps-Engineer) Modernizar dependencias mayores (`flutter_secure_storage: ^11.2.0`, `get_it: ^9.0.0`, `home_widget: '>=0.9.0 <0.10.0'`, `sqflite: ^2.4.4`, `sqlite3_flutter_libs: ^0.5.42`, `google_fonts: ^9.0.0`, `flutter_lints: ^5.0.0`).
- [x] (DevOps-Engineer) Purgar paquete redundante `mobile_scanner: ^5.2.3` y directiva deprecada `synthetic-package: false` en `l10n.yaml`.
- [x] (DevOps-Engineer) Migrar `SecureStorageService` a `AndroidOptions(resetOnError: true)`.
- [x] (DevOps-Engineer) Alinear 8 suites de prueba con `FakeFlutterSecureStorage` actualizando parámetros a `AppleOptions`.
- [x] (DevOps-Engineer) Configurar scripts de Gradle para resolver compatibilidad con Java 17 y Android SDK 34 (`sqflite_android`, `androidx.work:2.9.1`).
- [x] (DevOps-Engineer) Compilar, firmar y publicar APK oficial `v1.1.1` (`Victor-Engineer-Food-Tracker-Android.apk`) en GitHub Releases.

## 🌟 Iteración v1.2.0: Motor de Recomendaciones Nutricionales, Exportación Física e Higiene Android 16
- [x] (Backend-Architect) Diseñar e implementar `NutritionalRecommendationService` con análisis de 7, 15 y 30 días, cálculo de deltas de macros vs metas, diagnósticos de grasa/proteína, sustituciones inteligentes y sugerencias de platos.
- [x] (Backend-Architect) Diseñar e implementar `getWhatShouldIEatToday` para calcular presupuesto calórico y de macronutrientes restante hoy, consejo dietético dinámico y lista de platos sugeridos.
- [x] (Backend-Architect) Diseñar e implementar en `BackupService` exportación física a archivo `.json` (`exportToJsonFile`), guardado en carpeta pública Downloads/Documentos, listado de respaldos (`listAvailableBackups`), e inspección de contenido (`inspectBackupFile`).
- [x] (Backend-Architect) Registrar `INutritionalRecommendationService` en `service_locator.dart`.
- [x] (Frontend-UI) Implementar bottom sheet interactivo `WhatToEatSheet` con desglose visual de macros restantes, consejos de balance y botón de registro directo en 1 toque.
- [x] (Frontend-UI) Implementar tarjeta bento `RecommendationDiagnosticCard` con selector de período (7/15/30 días), comparativas de macros y paneles de sugerencias.
- [x] (Frontend-UI) Implementar banner `WhatToEatBannerCard` e integrarlo en `DashboardScreen`.
- [x] (Frontend-UI) Implementar diálogo modal `JsonFilePickerDialog` para navegación y selección de archivos físicos `.json` con vista previa de entidades a restaurar.
- [x] (Frontend-UI) Actualizar `BackupCard` en `SettingsScreen` para enlazar exportación física y apertura del explorador de respaldos.
- [x] (Systems-Auditor) Crear pruebas unitarias completas para `NutritionalRecommendationService` y `BackupService` físico.
- [x] (Systems-Auditor) Crear pruebas de widgets para `WhatToEatSheet` y componentes de recomendación.
- [x] (Systems-Auditor) Auditar que el 100% de los archivos nuevos y modificados cumplan con < 300 LoC.
- [x] (DevOps-Engineer) Consolidar e implementar canónicamente `applicationId: com.victorengineer.foodtracker` y `namespace` unificado conforme a la directiva del usuario.
- [x] (DevOps-Engineer) Configurar `useLegacyPackaging = false` en Gradle (removiendo `extractNativeLibs` explícito de `AndroidManifest.xml` para cumplimiento estricto con AGP y páginas de 16 KB en Android 16).
- [x] (DevOps-Engineer) Incorporar timeouts de arranque en servicios en `main.dart` y `HomeWidgetService` para prevenir ANR.
- [x] (DevOps-Engineer) Incrementar versión en `pubspec.yaml` a `1.2.1+1` y registrar cambios en `artifacts/planning/changelog_v1.md`.

---

## 🌟 Iteración v1.2.1: Erradicación de Doble Ícono y Arranque Resiliente en Android 16
- [x] (DevOps-Engineer) Incrementar versión en `pubspec.yaml` a `1.2.1+1`.
- [x] (DevOps-Engineer) Eliminar bloque `<activity-alias>` en `android/app/src/main/AndroidManifest.xml` y fijar actividad principal en `.MainActivity`.
- [x] (DevOps-Engineer) Purgar archivo huérfano de Kotlin en `android/app/src/main/kotlin/com/example/food_tracker/MainActivity.kt`.
- [x] (DevOps-Engineer) Desacoplar inicializaciones asíncronas de `runApp()` en `lib/main.dart` para arranque inmediato en frame 0 sin ANR en Android 16.
- [x] (Reviewer & QA) Erradicar bypass de `FLUTTER_TEST` en `lib/main.dart`, implementar `_FakeSecureStorage` y `databaseFactoryFfiNoIsolate` en `nutri_tracker_app_test.dart`.
- [x] (Reviewer & QA) Sincronizar ciclo de vida de finalización de onboarding con callback `onCompleted` en `OnboardingScreen` y `NutriTrackerApp`.
- [x] (Reviewer & QA) Incorporar `AnimatedSwitcher` en `NutriTrackerApp` para transición suave sin parpadeo visual en frame 0.
- [x] (Reviewer & QA R2) Erradicar bypass remanente de `FLUTTER_TEST` en `lib/services/home_widget_service.dart` implementando detección limpia de plataforma `isPlatformSupported` y salvaguarda try-catch en suscripción de eventos.
- [x] (Reviewer & QA R2) Incorporar defensas contra deadlocks del hardware Keystore en Android 16 con timeout unificado de 2 segundos en `SecureStorageService._safeRead`, `_safeWrite` y `_safeDelete`.
- [x] (Reviewer & QA R2) Aislar y paralelizar la inicialización de `MealController.init()` para prevenir congelamientos en cascada si Keystore o SQLite demoran en startup.
- [x] (Reviewer & QA R2) Alinear permisos multimedia en `AndroidManifest.xml` agregando `android:maxSdkVersion="32"` a `READ_EXTERNAL_STORAGE`.
- [x] (Reviewer & QA R2) Añadir pruebas unitarias de timeouts y resiliencia ante Keystore hang en `secure_storage_service_test.dart` y seguridad multiplataforma en `home_widget_service_test.dart`.
- [x] (Reviewer & QA R3) Implementar verificación de contingencia contra SQLite en `NutriTrackerApp._checkOnboardingInBackground()` para evitar expulsión de usuarios ante demoras de Keystore.
- [x] (Reviewer & QA R3) Incorporar timeouts de 2s y actualización concurrente en `HomeWidgetService.saveSummaryData` y `updateWidgets`, purgando handlers en `dispose()`.
- [x] (Reviewer & QA R3) Reemplazar aserción pasiva en `home_widget_service_test.dart` con verificación activa de recepción de deep links y filtrado de esquemas externos.
- [x] (Reviewer & QA R3) Añadir prueba de integración en `nutri_tracker_app_test.dart` validando retención en `DashboardScreen` cuando SecureStorage está vacío pero el perfil existe en SQLite.
- [x] (DevOps-Engineer) Documentar versión en `artifacts/planning/changelog_v1.md` bajo `[1.2.1] - 2026-10-04`.
- [x] (DevOps-Engineer) Publicar release `v1.2.1` en GitHub Actions y GitHub Releases.

---

## 🌟 Iteración v1.2.4: Selector Nativo de Respaldos, Normalización Resiliente, Ergonomía de Dashboard y Gramaje de Despensa

### 🧭 1. Project-Planner (Master Tech Lead & Orquestador)
- [x] (Project-Planner) Conducir Survey Técnico con 3 Exploradores en paralelo (Backend, Frontend, Despensa).
- [x] (Project-Planner) Definir arquitectura y desglosar tareas atómicas en `artifacts/planning/task.md`, `implementation_plan.md`, `abstractions.md` y `api_spec.md`.
- [x] (Project-Planner) Despachar y supervisar subagentes especializados (`Backend-Architect`, `Frontend-UI`, `Systems-Auditor`, `DevOps-Engineer`).

### 🗄️ 2. Backend-Architect (Datos, Normalización Resiliente, Isolate, Batch y Gramajes)
- [x] (Backend-Architect) **Dependencias y Versión:**
  - Incrementar versión en `pubspec.yaml` a `1.2.4+1`.
  - Añadir dependencia `file_picker: ^8.1.7` en `pubspec.yaml`.
- [x] (Backend-Architect) **Normalizador Adaptativo de Respaldos (`BackupNormalizer`):**
  - Crear `lib/services/backup_normalizer.dart` (< 250 LoC) con soporte completo para esquemas legados (v1.0.4 y anteriores).
  - Traducir claves legadas en español y formatos directos: `comidas` $\rightarrow$ `meals`, `despensa` $\rightarrow$ `pantry_items`, `perfil` $\rightarrow$ `user_profile`, `pesos` $\rightarrow$ `weight_logs`, array crudo `[...]` $\rightarrow$ `{"meals": [...]}`.
  - Implementar ejecución en isolate secundario con `Isolate.run` para decodificación y parseo JSON sin bloqueo de UI.
- [x] (Backend-Architect) **Persistencia Transaccional por Lotes en SQLite:**
  - Actualizar `BackupService` (`lib/services/backup_service.dart` < 250 LoC) para ejecutar inserciones masivas mediante `txn.batch()` y `batch.commit(noResult: true)` garantizando 60 FPS durante importaciones grandes.
- [x] (Backend-Architect) **Esquema SQLite v4 y Modelo de Despensa:**
  - Incrementar versión de base de datos a `4` en `DatabaseConnectionFactory.dart`.
  - Agregar columna `package_weight REAL` en `createPantryTable` y migración `_safeAddColumn(db, 'pantry_items', 'package_weight REAL')` en `DatabaseSchema.dart`.
  - Actualizar `PantryItem` (`lib/models/pantry_item.dart`): añadir campo inmutable `packageWeight`, serialización JSON/SQLite tolerante a nulos, y método `toScaledFoodItem({required double gramsConsumed})` para escalado proporcional de calorías y macronutrientes.
- [x] (Backend-Architect) **Pruebas Automatizadas Backend:**
  - Crear `test/services/backup_normalizer_test.dart` validando traducción de claves legadas, arrays crudos, isolate y tolerancia a fallos.
  - Crear `test/models/pantry_item_portion_scaling_test.dart` verificando escalado matemático y migración de esquema v4.

### 🎨 3. Frontend-UI (Ergonomía Visual, Modales, Bento Fasting y Despensa)
- [x] (Frontend-UI) **Selector Nativo de Respaldos JSON (R1 UI):**
  - Modificar `JsonFilePickerDialog` (`lib/widgets/settings/json_file_picker_dialog.dart` < 250 LoC) reemplazando la entrada de texto manual por un botón prominente de 1 toque que invoca `FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'])`.
- [x] (Frontend-UI) **Reubicación y Rediseño de "¿Qué Debería Comer Hoy?" (R2 UI):**
  - Retirar la tarjeta fija `WhatToEatBannerCard` del scroll principal en `lib/screens/dashboard_screen.dart:250`.
  - Reubicar la acción como opción destacada dentro de `lib/widgets/dashboard/dashboard_fab_menu.dart` (manteniendo < 300 LoC).
  - Rediseñar `WhatToEatSheet` (`lib/widgets/recommendations/what_to_eat_sheet.dart`): envolver en `SafeArea`, barra superior con `IconButton(icon: Icon(Icons.close))`, restricciones de altura (`maxHeight: 0.85`) y scroll fluido.
- [x] (Frontend-UI) **Tarjeta Bento Colapsable de Ayuno Intermitente (R3 UI):**
  - Refactorizar `FastingWindowBentoCard` (`lib/widgets/dashboard/fasting_window_bento_card.dart` < 280 LoC) para mostrar formato Bento compacto (~44px) por defecto cuando está inactivo, expandiéndose con animación al estar en ayuno o al tocarlo.
- [x] (Frontend-UI) **Corrección de Diálogo de Recomendaciones y Métricas (R3 UI):**
  - Corregir solapamiento de textos en `RecommendationDiagnosticCard` / diálogo asegurando scroll independiente sobre el botón de cierre.
  - Corregir `WeeklyDigestCard` (`lib/widgets/metrics/weekly_digest_card.dart`): envolver badge en `Flexible`/`Expanded` para eliminar desbordamiento horizontal de "1/7 días con registro" en anchos reducidos.
  - Corregir `MetricsScreen` (`lib/screens/metrics_screen.dart`): aplicar `IntrinsicHeight` en fila calórica/racha para evitar recorte sobre tarjeta de macronutrientes.
- [x] (Frontend-UI) **Editor de Despensa y Registro con Escalado Automático (R4 UI):**
  - Extraer y construir `PantryItemEditorDialog` (`lib/widgets/pantry/pantry_item_editor_dialog.dart` < 200 LoC) con campos para porción de referencia (ej. 100g) y peso neto de empaque (ej. 500g).
  - Implementar `PantryConsumptionDialog` (`lib/widgets/pantry/pantry_consumption_dialog.dart` < 200 LoC) para registrar alimentos de despensa a comidas con previsualización reactiva de macros escalados según los gramos consumidos.
  - Conectar autocompletado en `FoodItemEditorDialog`.
- [x] (Frontend-UI / Android) **Corrección de InflateException en Widget Nativo 4x2:**
  - Reemplazar etiquetas prohibidas `<View>` en `RemoteViews` (líneas 96, 129 y 197) por `<FrameLayout>` en `android/app/src/main/res/layout/food_tracker_widget_wide.xml` y `lib/assets/android_widgets/food_tracker_widget_wide.xml`.
- [x] (Frontend-UI) **Pruebas de Widgets Frontend:**
  - Crear pruebas de widgets para `JsonFilePickerDialog`, `WhatToEatSheet`, `FastingWindowBentoCard` y `WeeklyDigestCard`.

### 🛡️ 4. Systems-Auditor (Auditoría de Calidad, Integridad y Modularidad)
- [x] (Systems-Auditor) Ejecutar `flutter analyze` garantizando 0 errores y 0 advertencias.
- [x] (Systems-Auditor) Ejecutar 100% de la suite de pruebas unitarias y de widgets (`flutter test`).
- [x] (Systems-Auditor) Auditar estricto cumplimiento modular: todos los archivos creados o modificados deben tener < 300 LoC.
- [x] (Forensic Auditor) Ejecutar auditoría forense de integridad (`teamwork_preview_auditor`) confirmando implementaciones reales sin hardcoding ni fachadas.
- [x] (Systems-Auditor) Emitir `artifacts/audit_reports/audit_report.md` con veredicto `PASS`.

### 🚀 5. DevOps-Engineer (Empaquetado y Certificación de Release)
- [x] (DevOps-Engineer) Verificar sincronización de versión `1.2.4+1` en `pubspec.yaml` y Gradle.
- [x] (DevOps-Engineer) Redactar y formalizar la sección `## [1.2.4] - 2026-10-04` en `artifacts/planning/changelog_v1.md`.
- [x] (DevOps-Engineer) Certificar Quality Gate para cierre formal de la iteración.

---

## 🌟 Iteración v1.2.5: Auto-Reparación Resiliente de Respaldos Truncados, Rediseño Ergonómico de Ayuno Bento y Depuración de Raíz

### 🗄️ 1. Backend-Architect (Resiliencia y Auto-Reparación de Respaldos)
- [x] (Backend-Architect) **Auto-Reparación de JSON Truncado (`BackupNormalizer`):**
  - Implementar `_tryRepairTruncatedJson` en `lib/services/backup_normalizer.dart` (< 300 LoC).
  - Cierre automático de strings incompletos (`Unterminated string`), recorte de separadores huérfanos y cierre LIFO de llaves/corchetes `{`, `[`.
  - Crear suite `test/services/backup_normalizer_test.dart` validando recuperación de JSON cortado abruptamente.
  - Generar copia de seguridad reparada en `Downloads/food_tracker_backup_restaurado.json` con las 11 comidas, perfil y pesos intactos.

### 🎨 2. Frontend-UI (Rediseño y Alineación Ergonómica de Ayuno Intermitente)
- [x] (Frontend-UI) **Alineación de Tarjeta Bento de Ayuno (`FastingWindowBentoCard`):**
  - Refactorizar `lib/widgets/dashboard/fasting_window_bento_card.dart` (< 300 LoC, 281 LoC).
  - Estado colapsado: diseño en `Row` con `Expanded` de 2 líneas de texto y botón pill `Iniciar v` a la derecha sin superposición.
  - Estado expandido: cabecera superior con botón `Colapsar ^` alineado a la derecha, cuerpo principal con anillo 52px y botón centrado verticalmente.

### 🛡️ 3. Systems-Auditor (Quality Gate & LoC Audit)
- [x] (Systems-Auditor) Corregir teardown de timer en `test/widgets/fasting_window_bento_card_test.dart`.
- [x] (Systems-Auditor) Auditar cumplimiento estricto del límite modular: 100% de los archivos < 300 LoC.
- [x] (Systems-Auditor) Verificar que la suite de pruebas (469 tests) pase al 100% con 0 fallos y linter limpio en CI.
- [x] (Systems-Auditor) Ratificar `veredicto: PASS` en `artifacts/audit_reports/audit_report.md`.

### 🚀 4. DevOps-Engineer (Depuración de Raíz, Versionado & Release v1.2.5)
- [x] (DevOps-Engineer) Incrementar versión en `pubspec.yaml` a `1.2.5+1`.
- [x] (DevOps-Engineer) Depurar archivos obsoletos, imágenes de captura y respaldos de la raíz del proyecto.
- [x] (DevOps-Engineer) Documentar la versión en `artifacts/planning/changelog_v1.md` bajo `[1.2.5] - 2026-10-04`.
- [x] (DevOps-Engineer) Compilar y publicar release oficial `v1.2.5` en GitHub Releases.

---

## 📜 Historial de Iteraciones Previas (Completadas)

### [1.1.0] - Generación Omnicanal de Precisión Visual, Volumétrica y Nutricional
- [x] Todas las tareas completadas y verificadas con 69 suites de prueba (100% PASS).

### [1.0.4] - Inyección de Dependencias, DAOs Modulares, l10n y Result Type
- [x] Todas las tareas completadas y verificadas con 53 suites de prueba (367 tests PASS).

### [1.0.3] - Robustez, Resiliencia, Salvaguarda de Condimentos y Rango SQLite
- [x] Todas las tareas completadas y verificadas en CI/CD.

### [1.0.2] - Desglose Fino de Ingredientes y Cola Asíncrona con Anillo
- [x] Todas las tareas completadas y publicadas en release.
