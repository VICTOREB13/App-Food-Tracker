---
tipo: task_list
proyecto: App_Food_Tracker
iteracion: v1.1.1
estado: completado
fecha: 2026-10-04
tags: [proyecto, tasks, checklist, v1-1-1]
---

# 📋 Checklist Maestro de Tareas de Agentes (v1.1.1)

> **Mesa de Control (Project-Planner):** Este checklist asigna y verifica los entregables atómicos de la iteración v1.1.1. Cada tarea completada se marca con `[x]`.

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
