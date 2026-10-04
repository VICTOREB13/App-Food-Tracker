---
tipo: changelog
proyecto: App_Food_Tracker
version: v1
estado: activo
fecha: 2026-10-04
tags: [proyecto, changelog, versiones]
---

# 📜 Registro de Cambios (Changelog) - Victor Engineer Food Tracker

Todos los cambios notables de este proyecto se documentarán en este archivo.
El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/) y este proyecto se adhiere a [Semantic Versioning](https://semver.org/lang/es/).

---

## [Unreleased]

---

## [1.2.1] - 2026-10-04

La versión v1.2.1 soluciona de forma crítica problemas de entorno nativo en Android 16: erradicación del doble ícono en el launcher del sistema operativo y arranque tolerante a fallos sin bloqueos de ANR/Watchdog.

### Fixed
- **Eliminación de Doble Ícono Launcher:** Remoción completa del bloque `<activity-alias>` redundante en `AndroidManifest.xml` que generaba duplicación de íconos en el lanzador de Android. Estandarización de la actividad principal como `.MainActivity`.
- **Depuración de Archivos Huérfanos de Kotlin:** Eliminación definitiva del paquete y archivo legado `android/app/src/main/kotlin/com/example/food_tracker/MainActivity.kt`.
- **Arranque Inmediato y Resiliencia en Android 16 (`main.dart`):** Desacoplamiento de las inicializaciones asíncronas de `DatabaseService`, `AnalysisQueueService`, `ThemeManager` y `SecureStorageService` respecto a `runApp()`. El árbol de widgets se renderiza de inmediato en el frame 0, evitando que timeouts de Keystore o almacenamiento disparen el Watchdog de Android 16.
- **Empaquetado Nativo Descomprimido y Alineado a 16 KB (`useLegacyPackaging = false`):** Configuración definitiva de librerías C/C++ `.so` (`libflutter.so`, `libapp.so`, `libsqlite3.so`, `libdartjni.so`) empaquetadas sin compresión (`STORED 0`) y con alineación estricta de 16 KB en los límites de página (0x4000), garantizando compatibilidad con el kernel de Android 16 (API 36).
- **Recursos Nativos de Tema en `res/`:** Creación de `styles.xml`, `values-night/styles.xml` y `launch_background.xml` para prevenir `Resources$NotFoundException`.
- **Sincronización de Ciclo de Vida y Transición Suave de Onboarding:** Erradicación del bypass evasivo de pruebas en `main.dart`, introducción de `AnimatedSwitcher` en `NutriTrackerApp` y sincronización bidireccional mediante callback `onCompleted` en `OnboardingScreen`.

---

## [1.2.0] - 2026-10-04

La versión v1.2.0 introduce el Motor Inteligente de Recomendaciones Nutricionales, la experiencia interactiva "¿Qué debería comer hoy?", el sistema de exportación física e importación de archivos `.json`, y la compatibilidad integral de actualización y retrocompatibilidad con Android 16 (páginas de 16KB).

### Highlights
- **Motor de Recomendaciones Nutricionales Inteligente (`NutritionalRecommendationService`):** Análisis longitudinal de 7, 15 y 30 días del balance de macronutrientes, con diagnósticos específicos de superávit de grasas y déficit de proteínas, sustituciones inteligentes y platos sugeridos.
- **¿Qué Debería Comer Hoy? (`WhatToEatSheet`):** Cálculo en tiempo real del presupuesto calórico y de macronutrientes restante del día, consejos adaptados al contexto y sugerencias de platos balanceados con registro en 1 toque.
- **Exportación e Importación Física de Archivos `.json`:** Reemplazo definitivo del portapapeles por exportación a archivos físicos en Descargas/Documentos, explorador in-app de respaldos con previsualización de entidades y restauración atómica.
- **Identificador Canónico Unificado (`applicationId`):** Consolidación de `namespace` y `applicationId` canónico como `com.victorengineer.foodtracker` en Gradle, manifiesto y pipelines CI/CD.
- **Soporte Nativo Android 16 (16KB Page Size) y Anti-ANR:** Configuración de `packagingOptions.jniLibs.useLegacyPackaging = true` en Gradle, depuración de bibliotecas nativas, y timeouts defensivos en el arranque de servicios asíncronos en `main.dart` para evitar bloqueos en el splash screen.

### Features & Capacidades de Producto
- **Tarjeta Bento de Diagnóstico Nutricional (`RecommendationDiagnosticCard`):** Selector de período (7, 15, 30 días), comparativa gráfica de consumo real vs metas calóricas/macros, y acordeones de sugerencias de reemplazo de grasas y aumento proteico.
- **Banner de Recomendaciones en Dashboard (`WhatToEatBannerCard`):** Acceso directo y prominente desde la pantalla principal para consultar qué comer y revisar el diagnóstico nutricional.
- **Explorador y Selector de Respaldos (`JsonFilePickerDialog`):** Detección automática de archivos `.json` en el dispositivo, inspección previa del contenido (comidas, peso, despensa, perfil) y restauración segura con confirmación.
- **Timeouts Defensivos de Arranque en `main.dart`:** Inicialización desacoplada con salvaguardas de tiempo en `DatabaseService`, `AnalysisQueueService`, `ThemeManager`, `SettingsController` y `HomeWidgetService`.

### Quality Gate & Certificación
- **100% Suites Automatizadas PASS:** Pruebas unitarias de servicios de recomendación y respaldo físico, pruebas de widgets UI para las nuevas pantallas y 0 errores de linter.
- **Estricto Límite Modular:** Todos los archivos creados y modificados se mantienen estrictamente por debajo de 300 LoC.

---

## [1.1.1] - 2026-10-04

La versión v1.1.1 formaliza una actualización integral de modernización de dependencias, higiene del compilador de Android y migración a almacenamiento seguro v11. Se actualizan componentes críticos a sus versiones estables más recientes, se erradican advertencias de Gradle/KGP y duplicados de SDK, y se optimiza la resiliencia en la inicialización de hardware criptográfico.

### Highlights
- **Modernización Integral del Ecosistema de Dependencias:** Actualización mayor a `flutter_secure_storage: ^11.2.0`, `get_it: ^9.0.0`, `home_widget: ^0.10.0`, `sqflite: ^2.4.4`, `sqlite3_flutter_libs: ^0.5.42`, `google_fonts: ^9.0.0` y `flutter_lints: ^5.0.0`.
- **Aligeramiento de APK y Supresión de Warnings KGP:** Eliminación del paquete redundante `mobile_scanner`, reduciendo el footprint del binario y suprimiendo advertencias del Kotlin Gradle Plugin.
- **Migración a Secure Storage v11 (`resetOnError`):** Adopción de `AndroidOptions(resetOnError: true)` en sustitución de la directiva obsoleta `encryptedSharedPreferences`, garantizando recuperación automática ante desincronización de llaves en Keystore.
- **Flujos CI/CD con Java 17 en `setup-java@v5`:** Actualización de actions en `.github/workflows/` a `actions/setup-java@v5` y limpieza definitiva de plataformas redundantes en Android SDK.

### Fixed
- **Advertencias de SDK Duplicado en Gradle:** Eliminación del symlink duplicado `android-34` hacia `android-35` en `release.yml` y `build_apk.yml`, reteniendo la depuración limpia de la plataforma superior.
- **Deprecación de Paquete Sintético en Localización:** Remoción de la directiva deprecada `synthetic-package: false` en `l10n.yaml` conforme a Flutter 3.x.
- **Resolución de Recursos R en AppWidgets:** Namespace explícito `com.victorengineer.foodtracker` asegurado de forma determinista para la generación de la clase `R`.

### Quality Gate & Certificación
- **Zero Warnings en Pipeline:** Quality Gate estricto, análisis estático y suites automatizadas ejecutadas con 100% PASS.

---

## [1.1.0] - 2026-10-04

La versión v1.1.0 consolida la generación omnicanal de precisión volumétrica y nutricional con widgets nativos en Android (2x2 y 4x2 en modos claro/zinc), búsqueda federada de alimentos en tiempo real (USDA y Open Food Facts), migración de base de datos a SQLite v3 con soporte integral de micronutrientes, gestión clínica de ayuno intermitente y exportación tabular conforme al estándar RFC 4180 con UTF-8 BOM.

### Highlights
- **Widgets Nativos Android 2x2 y 4x2:** Visualización reactiva en tiempo real del progreso calórico y macronutrientes en launcher, con deep links interactivos (`foodtracker://scan_food`, `foodtracker://scan_barcode`) y soporte temático claro/zinc.
- **Búsqueda en Vivo de Alimentos por API:** Coordinador híbrido en tiempo real que integra el catálogo local offline con Open Food Facts y USDA FoodData Central con escalado volumétrico automático en `FoodItemEditorDialog` y `QuickMealDialog`.
- **Migración a SQLite v3 & Micronutrientes:** Incorporación de fibra, sodio y azúcar en el esquema relacional, acompañados de tablas para vajilla calibrada (`calibrated_dishware`), plantillas de comida (`meal_templates`) y registros de ayuno (`fasting_logs`).
- **Controlador y Bento de Ayuno Intermitente:** Temporizador circular interactivo en Dashboard con visualización de fases metabólicas, cálculo de adherencia clínica y persistencia reactiva en `FastingController`.

### Features & Capacidades de Producto
- **Resumen Nutricional Semanal (`WeeklyDigestCard`):** Tarjeta analítica en `MetricsScreen` con desglose promediado de calorías, micronutrientes y consistencia semanal.
- **Escáner OCR de Tablas Nutricionales (`NutritionLabelScannerService`):** Digitalización directa de tablas de información nutrimental desde fotos de empaques para alimentar la despensa.
- **Multimodalidad Omnicanal por Voz y Video:** Soporte para registro dietético mediante dictado en lenguaje natural (`analyzeSpeechMeal`) y muestreo volumétrico multi-fotograma (`analyzeVideoFramesMeal`).
- **Selector Dinámico de Idioma en Caliente:** Conmutación instantánea entre Español e Inglés en `SettingsScreen` sin reiniciar el estado de la aplicación.

### Arquitectura, Resiliencia y Rendimiento
- **Cola Asíncrona Zero-Freeze y Preservación de Fotos:** Encolado inmediato en paso 0 (`AnalysisQueueService`) con compresión en Isolate secundario y salvaguarda física de capturas ante caídas de red o cuota.
- **Resiliencia Defensiva en Gemini API:** Reintentos con retroceso exponencial, jitter y conmutación automática de modelo (`gemini-2.5-flash` $\rightarrow$ `gemini-1.5-flash`).
- **Escala Métrica de Vajilla Calibrada:** Inyección de dimensiones de plato del comensal y contexto de despensa en el prompt de inferencia visual.
- **Exportación Clínica RFC 4180:** Generación de reportes tabulares CSV con marca UTF-8 BOM (`\uFEFF`) inmunes a corrupción de caracteres en Microsoft Excel.

### Quality Gate & Certificación
- **69 Suites Automatizadas (100% PASS):** Verificación integral de modelos, migración transaccional v3, linter estricto y cero regresiones certificadas por Systems-Auditor.

---

## [1.0.4] - 2026-09-13

### Added
- **Inyección de Dependencias Formal con Service Locator (`GetIt`):**
  - Implementación de `setupServiceLocator()` en `lib/core/di/service_locator.dart` registrando contratos desacoplados e instancias singleton de servicios, DAOs y controladores.
  - Creación de interfaces de dominio en `lib/core/interfaces/` (`IDatabaseService`, `IImageProcessingService`, `IMealDao`, `IWeightLogDao`, `IUserProfileDao`, `IPantryDao`).
  - Inyección por constructor en `MealController` y `SettingsController` permitiendo pruebas unitarias completamente aisladas con mocks sin acoplamiento global, manteniendo preservada la compatibilidad transparente con accesores `.instance`.
- **DAOs Especializados y Modularización Estricta (< 300 LoC):**
  - Descomposición de `DatabaseService` (previamente 648 LoC) en DAOs atómicos: `MealDao` (220 LoC), `WeightLogDao` (185 LoC), `UserProfileDao` (83 LoC) y `PantryDao` (119 LoC), acompañados por `DatabaseSchema` (116 LoC) y `DatabaseConnectionFactory` (81 LoC), reduciendo el orquestador `DatabaseService` a 217 LoC.
  - Descomposición de `ImageProcessingService` (previamente 648 LoC) en `MealImageFileNamer` (229 LoC), `MealImageStorageResolver` (153 LoC) y `MealImageFileInfo` (59 LoC), dejando `ImageProcessingService` en 265 LoC.
  - 100% de los 25 archivos creados y modificados para la iteración cumplen con la directriz de ingeniería de permanecer estrictamente por debajo de las 300 líneas de código (< 300 LoC).
- **Internacionalización y Localización Nativa (`l10n` / `i18n`):**
  - Soporte multi-idioma oficial mediante `flutter_localizations`, `intl` y configuración de `l10n.yaml`.
  - Creación de diccionarios completos en español (`lib/l10n/app_es.arb`) e inglés (`lib/l10n/app_en.arb`) con claves para navegación, resumen diario, métricas y diálogos.
  - Implementación de `AppLocalizations` con `LocalizationsDelegate` e integración directa en `NutriTrackerApp` (`lib/main.dart`) con `localeResolutionCallback` defensivo que garantiza fallback a español en locales no soportados (ej. `fr`, `ja`).
  - Adopción activa de `AppLocalizations.of(context)` en widgets (`OnboardingBottomNav` para `saveAndStart`, `back`, `continueButton`, `QuickMealDialog` para `cancel`, `save`, etc.) con fallbacks defensivos para compatibilidad con pruebas unitarias sin delegados.
- **Manejo Funcional de Errores con Patrón `Result<T, Failure>`:**
  - Tipado funcional inspirado en Rust con clases selladas en Dart 3: `Result<T, E extends Failure>` (`Success`, `FailureResult`) en `lib/core/errors/result.dart`.
  - Jerarquía exhaustiva de fallos tipados: `DatabaseFailure`, `AiServiceFailure`, `NetworkFailure`, `ValidationFailure`, `StorageFailure`, `ImageProcessingFailure` y `UnknownFailure` en `lib/core/errors/failures.dart`.
  - Combinadores funcionales `fold`, `map`, `mapError`, `flatMap`, `getOrThrow`, `getOrDefault` y capturadores seguros `Result.guard` y `Result.guardAsync`.
  - APIs funcionales añadidas a todos los DAOs (`upsertMealResult`, `getMealByIdResult`, `insertWeightLogResult`, `saveUserProfileResult`, etc.) y delegadas convenientemente en el orquestador `IDatabaseService` y `DatabaseService`.
- **Nuevas Suites de Pruebas Automatizadas:**
  - `test/core/result_test.dart` (validación de pattern matching, combinadores y guardas).
  - `test/core/service_locator_test.dart` (validación de registro, resolución, fábricas parametrizadas y reseteo).
  - `test/services/daos_test.dart` (validación CRUD y Result en SQLite in-memory de todos los DAOs y DatabaseService).
  - `test/services/meal_image_file_namer_test.dart` (validación de nomenclatura y filtros).
  - `test/l10n/app_localizations_test.dart` (validación de diccionarios español e inglés y nuevas claves de acción).
  - `test/widgets/nutri_tracker_app_test.dart` (validación de inicio en español, inglés y fallback ante locales no soportados).

---

## [1.0.3] - 2026-09-13

### Fixed
- **Coincidencia Exacta GTIN en USDA y Fallback Limpio (H-01):** Eliminación de coincidencia difusa o primer resultado arbitrario (`matched ??= foods.first`) en `UsdaFoodDataService`. Se implementó normalización GTIN a 14 dígitos (`padLeft(14, '0')`) y retorno estricto de `null` en caso de no concordancia exacta, permitiendo a `BarcodeLookupService` activar de forma transparente el fallback hacia Open Food Facts.
- **Compresión Asíncrona en Isolate y Prevención de Recompresión (H-02):** Migración del procesamiento de imágenes a un Isolate secundario (`Isolate.run`) en `ImageProcessingService.compressAndResizeAsync` para liberar por completo el hilo principal de la UI a 60 FPS. Además, `GeminiVisionService` ahora decodifica los límites de la imagen y omite la recompresión si las dimensiones ya son $\le 1024$ px.
- **Sincronización Metabólica Completa al Registrar Peso (H-03):** En `MealController.recordWeight`, el recálculo biométrico ahora actualiza dinámicamente las metas nutricionales (`calculateMacros`) cuando el usuario tiene metas automáticas, persiste `DailyGoals` en SQLite, invoca `refreshGoals()` y emite notificación a los oyentes de la UI.
- **Protección de Hierbas, Especias y Condimentos en Desglose de Macros (H-04):** En `MealAnalysisResult.decomposeCompositeFood` y `_distributeZeroCalorieIngredients`, se añadió `isSeasoningOrHerb` para restringir la asignación de calorías y macronutrientes a ingredientes como orégano, pimienta, perejil o comino, impidiendo que absorban erróneamente más del 50% de los macros del plato principal.
- **Peso Corporal Ajustado Clínico para Obesidad (H-05):** En `MetabolicCalculator.calculateMacros`, se incorporó la fórmula clínica de Peso Corporal Ajustado ($ABW = IBW + 0.4 \times (TBW - IBW)$) para usuarios con IMC $\ge 30$, evitando la sobreestimación de requerimientos proteicos y energéticos asociada a masa grasa no metabólicamente activa.
- **Robustez y Reintento en Cola Asíncrona de Análisis (H-06):** Prevención de comidas duplicadas en `AnalysisQueueService` mediante la asignación determinista del ID de la tarea (`task.resultMeal?.id ?? task.id`), deduplicación al inicializar tareas residuales, y adición del método `retryTask(taskId)` para reintentar tareas en estado fallido sin perder la foto original.
- **Recuperación Resiliente de JSON Truncado de Gemini (H-08):** Nuevo módulo `JsonRepairHelper` (< 300 LoC) que implementa un algoritmo de balanceo de corchetes, llaves y comillas no cerradas para rescatar respuestas incompletas de la API de Gemini Vision antes de descartar el análisis.
- **Consultas Paginadas por Rango de Fecha en SQLite (H-09):** Implementación de `DatabaseService.getMealsByRange(start, end)` indexado por `idx_meals_date` y actualización de `MetricsScreen._loadData` para consultar únicamente el intervalo relevante en lugar de cargar el historial completo en RAM.
- **Timeout Defensivo en Llamadas de Red a Gemini Vision (H-14):** Inclusión de `timeout(const Duration(seconds: 35))` en `GeminiVisionService.analyzeMealImage` para evitar que la interfaz o la cola de análisis queden en espera infinita ante latencias anómalas de red o congelamientos de socket.

---

## [1.0.2] - 2026-09-12

### Fixed
- **Desglose Anatómico de Ingredientes:** Desglose estricto por componente prohibiendo duplicación de platos y erradicando el peso genérico de 200g.
- **Limpieza de Linter en CI:** Eliminación de imports redundantes en `AnalysisQueueService` y `GeminiVisionService` logrando `flutter analyze` 0 issues.

### Added
- **Cola Asíncrona en SQLite (`AnalysisQueueService`):** Procesamiento en segundo plano sin congelar UI al capturar fotos.
- **Anillo de Carga Animado (`VeLoadingRing`):** Widget con feedback progresivo en dashboard y detalle de comida.

---

## [1.0.1] - 2026-09-10

### Fixed
- **Integridad Transaccional de Comidas:** Inserción de tupla `meals` previa a `meal_items` resolviendo error de clave foránea SQLite.
- **Onboarding Limpio y Responsivo:** Formulario de biometría sin datos pre-poblados, soporte de decimales exactos y ajuste de texto en pantallas móviles.

### Added
- **Sincronización Bidireccional de Peso:** Actualización reactiva de BMR/TDEE al registrar pesajes y visualización limpia de porciones en gramos.

---

## [1.0.0] - 2026-09-10

### Added
- **Onboarding Asistido de Primer Uso (`OnboardingScreen`):** Flujo guiado de 4 pasos para biometría clínica, nivel de actividad y cálculo de macros.
- **Visor Inmersivo de Fotos (`FoodImageViewerScreen`):** Inspección de comida en pantalla completa con zoom y paneo táctil.
- **Identidad de Marca y Nomenclatura Automática:** Launcher icon oficial en squircle carmesí (`#C31723`) y sincronización automática de fotos por tipo de comida.

### Security
- **Firma Permanente Inmutable de Android:** Inyección de `release.keystore` RSA 2048 en pipelines de CI/CD para actualizaciones continuas.

---

## [0.4.0-alpha] - 2026-09-10

### Added
- **Detección y Carga Automática de Ingredientes IA:** Carga inmediata de alimentos identificados por Gemini Vision en `MealDetailScreen`.
- **Re-análisis Interactivo con Correcciones (`MealAiReanalyzeButton`):** Ajuste volumétrico refinado incorporando feedback del usuario.

### Fixed
- **Persistencia de Lista Vacía y Claves Multilingües:** Reseteo seguro de `aiBreakdownJson` y soporte de claves en español (`ingredientes`, `alimentos`) en respuestas de IA.

---

## [0.3.0-alpha] - 2026-09-09

### Added
- **Master Prompt y Selector de Modelos:** Editor interactivo de directrices de IA y explorador filtrado de modelos Gemini Flash/Pro.
- **Retención de Fotos y Rango Histórico:** Política configurable de depuración de fotos (15 a 90 días) y gráficos de pesaje históricos.

### Fixed
- **Upsert en Base de Datos y Retiro de Windows:** Implementación de `upsertMeal` en SQLite y retiro definitivo de targets no móviles en workflows.

---

## [0.2.0-alpha] - 2026-09-07

### Added
- **Descubrimiento Dinámico de Modelos Gemini & USDA:** Introspección en vivo de modelos multimodales y catálogo nutricional USDA FoodData Central con fallback a Open Food Facts.
- **Motor Metabólico Mifflin-St Jeor & Métricas Bento:** Cálculo de BMR/TDEE y panel de analíticas acelerado por hardware (`MetricsScreen`).

### Fixed
- **Deprecaciones de Color & Estabilidad de CI:** Migración completa a `.withValues(alpha: ...)` y scripts de inicialización Gradle para `compileSdk 34`.

---

## [0.1.0-alpha] - 2026-09-06

### Added
- **Arquitectura Local-First SQLite & BYOK:** Base de datos relacional con WAL mode y almacenamiento cifrado de claves API en Keystore/Keychain.
- **Visión Multimodal Gemini 2.5 Flash:** Estimación volumétrica clínica sin báscula y sanitización de datos defensiva (`ModelSanitizer`).
- **Sistema de Diseño Victor Engineer:** Temas Obsidian Zinc y Crisp Zinc con paleta semántica de macronutrientes y Bento Grid responsivo.
