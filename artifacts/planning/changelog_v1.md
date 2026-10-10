---
tipo: changelog
proyecto: App_Food_Tracker
version: v1
estado: activo
fecha: 2026-10-07
tags: [proyecto, changelog, versiones]
---

# 📜 Registro de Cambios (Changelog) - Victor Engineer Food Tracker

Todos los cambios notables de este proyecto se documentarán en este archivo.
El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/) y este proyecto se adhiere a [Semantic Versioning](https://semver.org/lang/es/).

---

## [Unreleased]

---

## [1.4.1] - 2026-10-09

La versión v1.4.1 culmina el saneamiento exhaustivo de internacionalización (i18n/l10n) en toda la aplicación, eliminando por completo cualquier texto hardcodeado en pantallas y widgets visuales. Introduce una arquitectura limpia y modular de localización organizada por subdirectorios de idioma (`lib/l10n/es/`, `lib/l10n/en/`) e interfaces abstractas por dominio de negocio (`lib/l10n/domains/`), garantizando que la incorporación futura de nuevos idiomas sea inmediata y desacoplada. Asimismo, se erradica el patrón de fallbacks defensivos hardcodeados en Dart (`?? 'español'`), consumiendo directamente propiedades no-nulables tipadas, y se ejecuta una depuración total de archivos residuales y scripts del repositorio.

### Added
- **Arquitectura Modular de Localización 100% Pure Dart (`lib/l10n/`):**
  - Subcarpeta `lib/l10n/domains/`: Contratos e interfaces abstractas por dominio (`app_localizations_core.dart`, `app_localizations_dashboard.dart`, `app_localizations_meal.dart`, `app_localizations_metrics.dart`, `app_localizations_profile.dart`, `app_localizations_settings.dart`).
  - Subcarpeta `lib/l10n/es/`: Implementaciones concretas en español por dominio y agregador `AppLocalizationsEs`.
  - Subcarpeta `lib/l10n/en/`: Implementaciones concretas en inglés por dominio y agregador `AppLocalizationsEn`.
  - Fachada unificada `AppLocalizations.of(context)` en `lib/l10n/app_localizations.dart` que retorna una instancia no-nulable con fallback interno seguro a `AppLocalizationsEs` y re-exporta todos los dominios e implementaciones.
  - Reubicación de la extensión `MealTypeLocalization` dentro de `lib/l10n/domains/app_localizations_meal.dart` (exportada automáticamente a través de la fachada unificada).

### Changed
- **Saneamiento Exhaustivo de UI y Cero Fallbacks Hardcodeados:**
  - Erradicación de `?? 'texto en español'` y `l10n != null ? l10n.x : 'español'` en el 100% de pantallas (`lib/screens/`) y widgets visuales (`lib/widgets/`).
  - Consumo directo y limpio de `l10n.clave` en todas las tarjetas Bento, banners de estado, modales, hojas inferiores, diálogos de captura y tooltips.
  - Soporte de textos de estado vacío dinámicos y localizados en renderizado de canvas (`WeightLineChartPainter` y `WeightChartRenderUtils`).
  - Unificación de todos los imports del proyecto hacia la fachada `package:food_tracker/l10n/app_localizations.dart`.
- **Actualización de Versión de la Aplicación:**
  - Versión actualizada a `1.4.1` en `AppConstants.appVersion` (`lib/core/constants/app_constants.dart`).
  - Versión actualizada a `1.4.1+1` en `pubspec.yaml`.

### Removed
- **Transición a Pure Dart y Eliminación de Generación de Código Antigua:**
  - Retiro de `generate: true` en `pubspec.yaml` y eliminación de `l10n.yaml`.
  - Eliminación de catálogos ARB obsoletos (`lib/l10n/app_es.arb` y `lib/l10n/app_en.arb`).
  - Purga de archivos shim y sueltos redundantes de la raíz de l10n (`app_localizations_es.dart`, `app_localizations_en.dart`, `meal_type_l10n.dart`).
- **Purga Total de Archivos Residuales de Auditoría:**
  - Eliminación de la totalidad de archivos de volcado y scripts de escaneo auxiliares (`prior_attempt.txt`, `audit_findings.json`, `audit_readable.txt`, `screens_audit.txt`, `widgets_audit.txt`, `all_text_widgets.txt`, `scan_strings.py`, `scan_text_widgets.py`, `inspect_findings.py`, `detailed_audit.py`, `check_extra.py`, `update_arb.py`, `generate_dart_l10n.py`, `semantic_l10n_generator.py`).
  - Limpieza completa del árbol de trabajo en Git.

---

## [1.4.0] - 2026-10-08

La versión v1.4.0 introduce un sistema completo de notificaciones locales asíncronas y recordatorios programados exactos de ayuno intermitente (`flutter_local_notifications`), eleva la tolerancia a fallos de Gemini Vision con recuperación unaria inmediata (`generateContent`) ante socket cuts / desconexiones abruptas (`OS error 104/10054`) e interfaz desacoplada `IVisionModelProvider`, incorpora selector de privacidad de fotos (Público vs Privado aislado) en Settings, dualidad de exportación de reportes clínicos (CSV RFC 4180 y PDF profesional mediante paquete `pdf`) en `/Documents/FoodTracker`, y purga total de la justificación volumétrica técnica de la UI y del schema de Gemini para una experiencia clínica limpia y centrada en el usuario.

### Added
- **Sistema de Notificaciones Locales y Programadas (`NotificationService` & `INotificationService`):**
  - Implementación de servicio modular de notificaciones (< 300 LoC) con canales Android dedicados: `food_tracker_meal_analysis` (prioridad alta para éxito y fallo de análisis) y `food_tracker_fasting` (alarmas exactas con `scheduleExactNotification` y soporte de zona horaria `tz.TZDateTime`).
  - Configuración nativa en `AndroidManifest.xml` con permisos `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED` y receptores de alarma/reinicio.
  - Integración en `AnalysisQueueService` para notificar al usuario en background cuando su comida termina de procesarse (`¡Ya se terminó de analizar tu comida!`) o si ocurre un fallo irrecuperable.
  - Integración en `FastingController` para programar alarma exacta al iniciar ayuno (`scheduleFastingCompleted`) y cancelarla al detenerlo (`cancelFastingReminder`).
- **Contrato de Visión Desacoplada (`IVisionModelProvider`):**
  - Interfaz de proveedor de visión (`lib/core/interfaces/vision_model_provider_interface.dart`) que define `analyzeMeal`, `supportsStreaming`, y `dispose` para desacoplar `GeminiVisionService` de futuros backends de IA como OpenRouter.
- **Exportación Dual de Reporte Clínico a PDF (`ClinicalPdfExportService` & `IClinicalPdfExportService`):**
  - Generador de reportes clínicos PDF (< 300 LoC) usando `package:pdf` con tablas de macronutrientes, micronutrientes (fibra, sodio, azúcar), promedios diarios y cronograma detallado de comidas.
  - Almacenamiento directo en directorio accesible de documentos (`/Documents/FoodTracker`) mediante `AccessibleStorageResolver`.
- **Selector de Privacidad de Almacenamiento (`StorageMode` & `StorageModeCard`):**
  - Nuevo enum `StorageMode` (`public`, `private`) con persistencia en `SecureStorageService`.
  - Tarjeta Bento interactiva en `SettingsScreen` para alternar entre almacenamiento público (accesible en galería) y privado aislado (restringido al sandbox de la aplicación).
  - Adaptación de `MealImageStorageResolver` e `ImageProcessingService` para respetar el modo privado sin registrar archivos en galería externa.
- **Selector de Formato en Diálogo de Exportación (`ClinicalExportDialog`):**
  - Segmented button en diálogo de exportación para alternar entre CSV (Excel) y PDF Clínico.
  - Mensaje de confirmación amigable (`Se guardó en /Documents/FoodTracker: {archivo}`) eliminando rutas técnicas crudas.

### Changed
- **Resiliencia de Socket y Fallback Unario en Gemini Vision (`GeminiVisionService` & `GeminiResilienceHelper`):**
  - Detección expandida de errores de desconexión abrupta en `isRetriableError` (`os error: 104`, `os error: 10054`, `connection reset by peer`, `software caused connection abort`, `connection closed`).
  - Captura y recuperación ante fallos de stream en `GeminiVisionService.analyzeMeal` con invocación inmediata de fallback unario (`generateContent`) preservando el análisis sin fallar la tarea en la cola.
- **Purga de Justificación Volumétrica en UI y Schema (`GeminiResilienceHelper`, `FoodItemsListCard`, `FoodItemEditorDialog`):**
  - Eliminación de la propiedad `justificacion_visual` del JSON schema estructurado de Gemini Vision.
  - Retiro del contenedor de texto de justificación visual en la tarjeta de ingredientes (`FoodItemsListCard`) y eliminación del campo/controlador en el diálogo de edición manual (`FoodItemEditorDialog`).
- **Completitud de Localización (l10n):**
  - Nuevas claves con placeholders tipados en `app_es.arb`, `app_en.arb`, `app_localizations.dart`, `app_localizations_es.dart` y `app_localizations_en.dart`.
- **Actualización de Versión de la Aplicación:**
  - Actualización a `1.4.0` en `AppConstants.appVersion` (`lib/core/constants/app_constants.dart`).
  - Actualización a `1.4.0+1` en `pubspec.yaml`.

---

## [1.3.4] - 2026-10-08

La versión v1.3.4 amplía la ventana de salida a 16k tokens (`maxOutputTokens: 16384`) para eliminar truncamientos por pensamiento latente (`finishReason: MAX_TOKENS`), estandariza `thinkingLevel: "MEDIUM"` para modelos Gemini 3 y Pro omitiendo estrictamente la configuración de pensamiento en modelos Lite (`gemini-3.5-flash-lite`) para erradicar errores `HTTP 400 INVALID_ARGUMENT`, armoniza los micronutrientes (`fibra_g`, `sodio_mg`, `azucar_g`) en la instrucción de sistema, Few-Shot y esquema preservando intactas las reglas volumétricas clínicas, e implementa pacing fluido en memoria a 60 FPS en el dashboard durante el análisis sin contención de escritura en SQLite.

### Added
- **Ventana de Generación de 16k Tokens (`GeminiVisionService` & `GeminiVisionFilter`):**
  - Ampliación de `maxOutputTokens: 16384` en `GenerationConfig` para evitar truncamiento de respuestas JSON cuando el modelo genera razonamiento latente extenso.
  - Actualización de `outputTokenLimit: 16384` en el catálogo de modelos de visión fallback (`gemini-3.8-flash`, `gemini-3.1-pro`).
- **Configuración de Nivel de Pensamiento `thinkingLevel: "MEDIUM"` (`GeminiModelService` & `GeminiVisionService`):**
  - Introducción de `defaultThinkingLevel = 'MEDIUM'` y método resolutor `resolveThinkingLevel(model)`.
  - Inyección de `thinking_level: 'MEDIUM'` en `buildCallConfig` para modelos con soporte de pensamiento (`gemini-3`, `gemini-1.5-pro`, `gemini-2.0-flash-thinking-exp`).
  - Omisión estricta de configuración de pensamiento para modelos Lite (`gemini-3.5-flash-lite`) en `supportsThinking` y `buildCallConfig` para prevenir fallos `HTTP 400 INVALID_ARGUMENT`.
- **Pacing Fluido en Memoria a 60 FPS (`AnalysisQueueService` & `AnalysisProgressBanner`):**
  - Temporizador periódico en memoria (500 ms) en `AnalysisQueueService._processTask` que avanza suavemente el progreso de 0.45 a 0.90 mediante `MealAnalysisPacing.nextProgress` notificando a la UI vía `notifyListeners()` sin emitir transacciones SQLite intermedias.
  - Resolución dinámica y localizada de etapas del banner (`_resolveStageMessage`) en `AnalysisProgressBanner` consumiendo `MealAnalysisPacing.getStageMessage(task.progress, l10n)` con fallback seguro a `task.stage`.
  - Cancelación determinista del temporizador de pacing en bloque `finally` al concluir el análisis (éxito o fallo).

### Changed
- **Armonización de Esquema de Micronutrientes (`GeminiResilienceHelper`):**
  - Inclusión explícita y coherente de `fibra_g`, `sodio_mg` y `azucar_g` en los pasos 4 y 5 de `baseSystemInstruction`, en el ejemplo Few-Shot y en `mealAnalysisSchema`.
  - Preservación rigurosa de las 12 reglas volumétricas clínicas y heurísticas de cubicaje (`Conversión cocido vs crudo`, `Regla de Grasa Oculta en Comida Casera`, `5g y 10g adicionales de grasa`, etc.).
- **Incremento de Versión de la Aplicación:**
  - Actualización a `1.3.4` en `AppConstants.appVersion` (`lib/core/constants/app_constants.dart`).
  - Actualización a `1.3.4+1` en `pubspec.yaml`.

---

## [1.3.3] - 2026-10-07

La versión v1.3.3 consolida la inferencia en streaming de Gemini Vision mediante el patrón de Razonamiento Desacoplado (*Decoupled Chain-of-Thought*) y resuelve el bug de pérdida de tareas en la cola de análisis, permitiendo subir múltiples comidas de forma concurrente y resiliente sin que las tareas previas fallidas o pendientes sean borradas u ocultadas de la interfaz.

### Added
- **Chips de Autovalidación de la IA en Detalle de Comida (`MealAiValidationChips`):**
  - Incorporación de chips informativos de certeza estimada (`porcentaje_certeza`, icono `Icons.verified_outlined`) con código de color semántico: verde ($\ge 85\%$), amarillo ($\ge 70\%$) o ámbar ($< 70\%$).
  - Incorporación de chip de margen de error calórico (`margen_error_kcal`, icono `Icons.tune`, `"±X kcal"`).
  - Integración nativa en `MealDetailScreen` debajo de los chips de macronutrientes.
  - Diseño enfocado al usuario sin etiquetas cualitativas ("nivel") ni campo de observación en JSON, manteniendo la visual limpia.
- **Descompositor Modular de Alimentos (`MealDecomposer`):**
  - Módulo auxiliar extraído de `MealAnalysisResult` para descomposición volumétrica y protección de condimentos (< 300 LoC).
- **Razonamiento Desacoplado (*Decoupled CoT*) en Gemini Vision (`GeminiResilienceHelper`):**
  - Incorporación del campo inicial libre `razonamiento_volumetrico` al inicio de `mealAnalysisSchema` para permitir al modelo autorregresivo deducir vajilla, 3D, hidratación, merma y grasas antes de generar `items` y `totales`.
  - Eliminación de 10 campos euclidianos rígidos que producían deadlocks de constrained grammar en alimentos amorfos y se descartaban en dominio.
  - Soporte explícito para comidas de un solo elemento (1 ítem) en el esquema y en `baseSystemInstruction`.
  - Bloque Few-Shot representativo en la instrucción del sistema para calibración volumétrica.
- **Mosaicos Nativos de 768px y Orden Multimodal Óptimo (`GeminiVisionService`):**
  - Ajuste de dimensión máxima de compresión a 768px en `_prepareImageBytes` (1 mosaico = 258 tokens vs 1,032 tokens a 1024px).
  - Envío de `TextPart(prompt)` antes de `DataPart` para condicionar adecuadamente la atención multimodal antes de procesar tokens de imagen.
- **Cola Resiliente Multi-Comida y Renderizado Concurrente (`AnalysisQueueService` & `AnalysisProgressBanner`):**
  - Nueva propiedad reactiva `visibleTasks` que preserva y expone simultáneamente todas las tareas activas, fallidas y completadas.
  - Persistencia inmediata de tareas en SQLite al momento de encolar (`_persistTaskToDb`).
  - Procesamiento ordenado FIFO de tareas encoladas.
  - Rediseño de `AnalysisProgressBanner` para renderizar tarjetas independientes por cada tarea visible, preservando foto, estado de error y botones de acción (`[Editar manualmente]`, `[Reintentar]`, `[Abrir plato]`, `[Cerrar]`) ante la subida de nuevas comidas.

### Fixed
- **Resolución de Pruebas Automatizadas de Release v1.3.3 en CI:**
  - `test/widgets/app_update_card_test.dart`: Actualización de la aserción de versión a `AppConstants.appVersion` dinámico en lugar de versión anterior hardcodeada.
  - `test/services/gemini_vision_service_test.dart` y `test/services/gemini_model_service_test.dart`: Alineación de `GeminiModelService.supportsThinking` para reconocer modelos `gemini-3` y mantener escala de timeout de 120s sin enviar `thinking_budget`.
  - `test/services/gemini_and_storage_adversarial_test.dart`: Preservación rigurosa de todas las cadenas de reglas volumétricas clínicas obligatorias (`Conversión cocido vs crudo`, `Regla de Grasa Oculta en Comida Casera`, `5g y 10g adicionales de grasa`, etc.) en `baseSystemInstruction`.
- **Parsing Defensivo de Métricas de Autovalidación en `Meal` y `MealAnalysisResult`:**
  - Sanitización de bloques de código markdown (````json ... ````) en `aiBreakdownJson` mediante método compartido `_cleanJson`.
  - Parsing de valores decimales formateados en texto (e.g. `"45.5 kcal"`, `"92.5%"`) evitando la concatenación de dígitos.
- **Captura de `FormatException` en Reintentos Transparentes (`GeminiResilienceHelper`):**
  - Inclusión de `FormatException` en `isRetriableError` para activar reintento automático y conmutar a `gemini-2.5-flash` ante fragmentos truncados o corruptos.
- **Prevención de `HTTP 400 INVALID_ARGUMENT` en Gemini 3 (`GeminiModelService`):**
  - Eliminación de la inyección de `thinking_budget` en `buildCallConfig` y `resolveThinkingBudget` para la familia de modelos `gemini-3`.
- **Bug de Ocultamiento de Comidas Previas al Subir Otra Comida:**
  - Erradicación de la sobreescritura de visualización en el dashboard: las comidas fallidas se mantienen accesibles e interactivas junto a las nuevas comidas encoladas.

---

## [1.3.2] - 2026-10-06

La versión v1.3.2 neutraliza los fallos esporádicos en llamadas de análisis de comida con Gemini migrando a un flujo de streaming continuo (`generateContentStream`) que mantiene activo el socket TCP/TLS contra desconexiones por inactividad de gateways NAT móviles durante fases de razonamiento latente (45–80s), amplía el cupo de salida a 8192 tokens en `GenerationConfig`, añade soporte para la familia Gemini 3 en `supportsThinking`, moderniza el fallback a `gemini-2.5-flash` con backoff escalonado (`[2s, 5s, 10s]`), introduce descargas resumibles de actualizaciones con cabeceras `Range: bytes=` y `HTTP 206 Partial Content`, sanitiza los mensajes de error de descarga erradicando URLs firmadas extensas, y resuelve inconsistencias de contraste y condiciones de frontera en la interfaz.

### Added
- **Streaming Continuo en Gemini Vision (`GeminiVisionService`):**
  - Migración a `model.generateContentStream` acumulando chunks en `StringBuffer`, asegurando tráfico de paquetes continuo que mantiene vivo el socket TCP/TLS contra desconexiones de gateways móviles.
  - Asignación de `maxOutputTokens: 8192` en `GenerationConfig` para evitar el truncamiento de respuestas JSON por saturación de tokens de pensamiento (`MAX_TOKENS`).
- **Soporte Ampliado para Gemini 3 y Fallback Contemporáneo (`GeminiModelService` & `GeminiResilienceHelper`):**
  - Reconocimiento de toda la familia `gemini-3` (`gemini-3.8-flash` y `gemini-3.1-pro`) en `supportsThinking`, activando timeout extendido de 120s y presupuesto de pensamiento latente (1024).
  - Modernización del modelo de contingencia a `gemini-2.5-flash` con demoras de reintento `[2s, 5s, 10s]` y jitter aleatorio.
  - Detección expandida de errores retriables en `isRetriableError` (500, 502, 504, `HttpException`, `HandshakeException`, y payloads vacíos).
- **Descargas Resumibles en Actualizaciones In-App (`AppUpdateService`):**
  - Implementación de cabecera `Range: bytes=$existingBytes-` y detección de `HTTP 206 Partial Content` para reanudar descargas de APK interrumpidas (~74 MB) sin reiniciar desde cero.
  - Escritura progresiva en archivo temporal `.apk.part` y renombrado atómico a `.apk` al completar la transferencia.
- **Canónica de Versiones (`AppConstants`):**
  - Centralización de `AppConstants.appVersion = '1.3.2'` en `lib/core/constants/app_constants.dart`.

### Changed
- **Pacing Preciso de Análisis de Comidas (`MealAnalysisPacing`):**
  - Ajuste de frontera para que ratio 0.95 mantenga el mensaje de desglose de macros (`analysisStageMacros`) y solo $\ge 1.0$ active `analysisStageComplete`.
- **Tema y Contraste Visual de SnackBar (`DashboardScreen` & `ThemeManager`):**
  - Reemplazo de texto atenuado en `SnackBarAction` por `AppColors.primaryLight` para contraste accesible de grado de producción.
  - Configuración de `snackBarTheme` en `AppTheme` (`#18181B`, bordes suaves y comportamiento flotante).
  - Integración de claves localizadas `updateAvailable` y `viewUpdateAction` en `AppLocalizations`.

### Fixed
- **Sanitización y Cancelación en Diálogo de Actualización (`InAppUpdateDialog`):**
  - Erradicación de URLs firmadas de AWS S3/Azure Blob extensas en errores visibles al usuario mediante `_sanitizeErrorMessage`.
  - Envoltorio de contenido con `SingleChildScrollView` previniendo desbordamientos verticales (`RenderFlex overflow`) en pantallas compactas o fuentes grandes.
  - Soporte de cancelación interactiva de descarga liberando streams y cerrando el diálogo ordenadamente.
- **Eliminación de Versiones Hardcodeadas:**
  - Sustitución de `'1.3.0'` por `AppConstants.appVersion` en `DashboardScreen` y `AppUpdateCard`.

---

## [1.3.1] - 2026-10-06

La versión v1.3.1 optimiza la precisión del motor multimodal de Gemini Vision mediante razonamiento físico causal invertido (geometría 3D y cubicaje volumétrico antes de predecir gramos), moderniza el catálogo de modelos adoptando Gemini 3 (`gemini-3.8-flash` y `gemini-3.1-pro`), extiende la resiliencia de timeouts (hasta 120s) con pacing progresivo y realista del anillo de carga, corrige la persistencia atómica de imágenes al modificar el tipo de comida, y refactoriza la internacionalización a `AppLocalizations` erradicando condicionales `isSpanish`.

### Added
- **Razonamiento Causal Volumétrico en Gemini Vision (`GeminiResilienceHelper` & `GeminiVisionService`):**
  - Inversión de orden causal en el schema JSON para obligar al LLM a delimitar referencia métrica, volumen 3D ($cm^3$), densidad y grasas ocultas antes de predecir gramos y macros.
  - Catálogo de modelos modernos: soporte para `gemini-3.8-flash` (por defecto) y `gemini-3.1-pro` (alta precisión) con `thinking_budget: 1024`.
  - Timeout de red extendido a 90s-120s para acomodar modelos con razonamiento latente sin interrupciones prematuras.
- **Pacing Progresivo y Realista de Progreso en Carga:**
  - Avance fluido en 5 etapas secuenciales durante el análisis de imagen en `MealDetailScreen`.

### Fixed
- **Persistencia Atómica de Imágenes en Cambio de Tipo de Comida (Bug 1):**
  - Desacoplamiento del selector de tipo de comida en UI del renombramiento en disco: `onMealTypeChanged` solo actualiza el estado en memoria, y el renombramiento físico se realiza de forma atómica en SQLite al guardar, evitando pantallas negras o íconos fallback desincronizados.
- **Internacionalización Nativa Completa y Erradicación de `isSpanish` (Bug 2):**
  - Reemplazo del 100% de los condicionales ternarios `isSpanish` por recursos tipados en `AppLocalizations`.
  - Claves completas en `app_es.arb` y `app_en.arb` con soporte nativo para ampliación a futuros idiomas.
  - Inicialización bilingüe de formato de fechas en `lib/main.dart`.

---

## [1.3.0] - 2026-10-05

La versión v1.3.0 introduce un sistema integral de Auto-Actualización In-App conectado a la API de GitHub Releases con instalador nativo en Android mediante MethodChannel y FileProvider, un catálogo completo de microinteracciones táctiles con física elástica de resorte y contadores cinemáticos, optimizaciones visuales derivadas de auditorías en vivo vía ADB, y la descomposición modular histórica que certifica el 100% de los archivos del repositorio bajo el límite estricto de < 300 LoC.

### Added
- **Auto-Actualizador In-App en Tiempo Real (`AppUpdateService` & `GitHubReleaseModel`):**
  - Consulta automática y manual del último release contra el endpoint oficial de GitHub Releases (`https://api.github.com/repos/VICTOREB13/App-Food-Tracker/releases/latest`).
  - Parser semántico robusto (`GitHubReleaseModel`) con validación de versión (`isUpdateAvailable`), extracción de notas de versión en Markdown y resolución del asset binario `Victor-Engineer-Food-Tracker-Android.apk`.
  - Descarga progresiva de APK por streaming con reporte porcentual reactivo (`Stream<double>`).
- **Canal de Plataforma e Instalador Nativo de Android (`AppInstallerService` & `MainActivity.kt`):**
  - Implementación de `MethodChannel` (`com.victorengineer.foodtracker/installer`) en Kotlin con soporte seguro de `FileProvider` (`content://`) y `Intent.ACTION_VIEW` con flags `FLAG_GRANT_READ_URI_PERMISSION` y `FLAG_ACTIVITY_NEW_TASK`.
  - Configuración de permisos `REQUEST_INSTALL_PACKAGES` y rutas seguras en `file_paths.xml` para almacenamiento temporal de paquetes.
  - Mecanismo de fallback resiliente con `url_launcher` para navegación al release en GitHub en caso de plataformas no soportadas.
- **Experiencia Interactiva de Actualización en UI:**
  - `InAppUpdateDialog`: Modal con visor de changelog en Markdown, visualizador de versión actual vs. disponible, barra de progreso lineal de descarga y botón de instalación inmediata.
  - `AppUpdateCard`: Tarjeta dedicada en `SettingsScreen` con estado de versión, botón de comprobación manual y acceso a la descarga.
  - Verificación no intrusiva de nuevas versiones en el inicio de `DashboardScreen`.
- **Catálogo de Microinteracciones Hápticas y Elásticas:**
  - `VeBounceable`: Widget con animación elástica de resorte (`Curves.easeInOut`, factor de escala 0.95) y cancelación gestual limpia aplicado en el FAB principal `+`, botones de ayuno y acciones rápidas.
  - `VeAnimatedCounter`: Contador cinemático suave con `TweenAnimationBuilder` para transiciones fluidas de métricas calóricas y macronutrientes a 60/120 FPS.
  - Feedback háptico táctil sutil (`HapticFeedback.lightImpact()` y `selectionClick()`) en el botón flotante (FAB), selector de agua (+250ml) y controles de temporizador de ayuno.

### Changed
- **Unificación de Barra Superior (`VeAppBar`):**
  - Estandarización de `VeAppBar` en `DashboardScreen`, `PantryScreen` y `SettingsScreen` con eliminación definitiva de la flecha atrás residual (`automaticallyImplyLeading: false`) en el inicio.
- **Refinamiento Ergonómico en Despensa y Diálogos:**
  - Ajuste de espaciado y anchos en `PantryItemEditorDialog` para erradicar el truncamiento de etiquetas (como `"Peso n..."`).
  - Navegación horizontal fluida en chips de categorías de alimentos en `PantryScreen`.
- **Descomposición Modular Histórica (< 300 LoC):**
  - Refactorización y desacoplamiento de componentes heredados que superaban las 300 líneas de código:
    - `metabolic_calculator.dart` dividida con `metabolic_prompt_generator.dart`.
    - `gemini_model_service.dart` desacoplada con `gemini_vision_filter.dart`.
    - `usda_food_item.dart` extraída con `usda_nutrient_parser.dart`.
    - `quick_weight_entry_dialog.dart` dividida con `quick_weight_adjuster_row.dart`.
    - `activity_goal_selector_card.dart` desacoplada con `activity_level_option_tile.dart` y `body_goal_option_tile.dart`.
    - `weight_line_chart_painter.dart` modularizada con `weight_chart_render_utils.dart`.
  - Certificación del 100% del repositorio en cumplimiento estricto de < 300 LoC.

### Fixed
- **Desbordamientos Visuales en Viewports Estrechos (320dp):**
  - Visualización completa sin elipsis del título `"RESUMEN SEMANAL"` y reestructuración adaptativa en `WeeklyDigestCard` con `Flexible` y espaciado elástico para pantallas compactas.
  - Erradicación de excepciones de renderizado `RenderFlex overflow` en dispositivos de densidad extrema.

---

## [1.2.5] - 2026-10-04

La versión v1.2.5 soluciona el fallo de respaldos con cadenas de texto incompletas o corruptas mediante un motor de auto-reparación resiliente en `BackupNormalizer`, rediseña ergonómicamente la tarjeta Bento de Ayuno Intermitente eliminando colisiones visuales entre texto y botones, y ejecuta una depuración integral del directorio raíz del repositorio.

### Added
- **Motor de Auto-Reparación de JSON Truncado (`BackupNormalizer._tryRepairTruncatedJson`):** Capacidad de recuperar respaldos interrumpidos abruptamente (`FormatException: Unterminated string`), cerrando automáticamente cadenas incompletas, limpiando separadores pendientes y balanceando corchetes y llaves `{`, `[` en orden LIFO antes de decodificar.
- **Suite de Pruebas de Auto-Reparación:** Test unitario en `test/services/backup_normalizer_test.dart` verificando decodificación y restauración exitosa de comidas a partir de JSON interrumpido.

### Changed
- **Rediseño Ergonómico de Bento Card de Ayuno (`FastingWindowBentoCard`):**
  - **Modo Compacto:** Encabezado en `Expanded(Column)` de 2 líneas con elipsis para evitar que "AYUNO INTERMITENTE • Sin ayuno activo" choque con el botón de acción, y botón pill `fasting_compact_start_button` con flecha `keyboard_arrow_down_rounded`.
  - **Modo Expandido:** Fila superior con título y botón de colapso "Colapsar ^" posicionado en la esquina superior derecha sin superponerse con el botón principal de inicio/término de ayuno.

### Removed
- **Depuración Integral del Directorio Raíz:** Eliminación de imágenes temporales de capturas (`Actual.png`, `Deseado.png`, `Screenshot_*.jpg`), archivos de respaldo residuales y carpetas de pruebas locales (`test_apks/`), reduciendo el tamaño del repositorio y preservando exclusivamente los artefactos esenciales del proyecto.

---

## [1.2.4] - 2026-10-04

La versión v1.2.4 introduce el selector de archivos nativo del sistema operativo (SAF) para respaldos, normalización adaptativa resiliente para versiones anteriores (v1.0.4 y previas), optimización de importación/exportación a 60 FPS con Isolates y SQLite Batch, reestructuración ergonómica del Dashboard (Bento de Ayuno colapsable y "¿Qué debería comer hoy?" en el menú `+`), porciones y gramajes de referencia en despensa con escalado matemático, y la corrección de inflado en el widget nativo 4x2 en Android.

### Added
- **Selector de Archivos Nativo de Android (`file_picker ^13.1.0`):** Reemplazo de la entrada manual de rutas de archivo por un botón de un toque que abre el explorador de archivos del sistema operativo móvil (Storage Access Framework).
- **Normalizador Adaptativo de Respaldos (`BackupNormalizer`):** Traducción y mapeo automático de esquemas JSON de versiones anteriores (v1.0.4 y previas), soportando listas crudas de comidas, claves en español (`comidas`, `despensa`, `perfil`, `pesos`) y atributos heterogéneos sin arrojar `FormatException`.
- **Procesamiento de Respaldos en Segundo Plano (`Isolate.run`):** La decodificación y parseo de JSON se desacopló del hilo de la interfaz de usuario, garantizando 60 FPS constantes durante importaciones grandes.
- **Persistencia Transaccional por Lotes en SQLite (`batch.commit()`):** Escritura masiva en lote en la base de datos local, reduciendo el tiempo de inserción de cientos de comidas de varios segundos a menos de 100 ms.
- **Esquema SQLite v4 & Despensa con Gramajes:** Migración de esquema añadiendo `package_weight` en `pantry_items`. Campo de porción base de referencia (ej. cada 100g) y peso total de empaque en `PantryItem` con escalado proporcional automático (`toScaledFoodItem`) al registrar comidas.
- **Diálogos de Despensa:** `PantryItemEditorDialog` y `PantryConsumptionDialog` con cálculo reactivo de macronutrientes en tiempo real.

### Changed
- **Reubicación de "¿Qué Debería Comer Hoy?":** Retirada la tarjeta fija del Dashboard principal para evitar sobrecarga visual; reubicada como una acción destacada e intuitiva dentro del menú del botón flotante `+` (`dashboard_fab_menu.dart`).
- **Rediseño Ergonómico de `WhatToEatSheet`:** Envoltorio `SafeArea` completo para prevenir colisión con el notch y barra de estado del sistema, cabecera con botón de cierre explícito (`X`), y restricciones de altura (`maxHeight: 0.85`) con scroll independiente.
- **Ayuno Intermitente en Formato Bento Colapsable:** `fasting_window_bento_card.dart` opera en estado compacto discreto (~44px) por defecto y se expande con animación fluida únicamente al iniciar un ayuno o al interactuar con la tarjeta.

### Fixed
- **Corrección de InflateException en Widget Nativo 4x2:** Reemplazadas las etiquetas genéricas `<View>` prohibidas en Android `RemoteViews` por `<FrameLayout>` en `food_tracker_widget_wide.xml`, permitiendo que el launcher del dispositivo infle el widget 4x2 correctamente.
- **Corrección de Desbordamiento en Resumen Semanal de Métricas:** Eliminado el desbordamiento horizontal del badge "1/7 días con registro" en `WeeklyDigestCard` mediante `Flexible` y alineación adaptativa.
- **Corrección de Solapamiento en Diagnóstico de Recomendaciones:** Desacoplado el scroll de sugerencias en `RecommendationDiagnosticCard` para prevenir RenderFlex overflow y permitir lectura completa sobre el botón de cierre.

---

## [1.2.3] - 2026-10-04

La versión v1.2.3 soluciona de raíz el fallo fatal `Failed to create an instance of class androidx.work.impl.WorkDatabase` diagnosticado en tiempo real mediante ADB y logcat en Android 16.

### Fixed
- **Desactivación de `WorkManagerInitializer` en `AndroidManifest.xml`:** Se eliminó la inicialización automática de `androidx.work.WorkManagerInitializer` a través de `androidx.startup.InitializationProvider` (`tools:node="remove"`). Los widgets nativos de `home_widget` utilizan `SharedPreferences` y `AppWidgetManager` sin requerir tareas en segundo plano de WorkManager, evitando que el proveedor de contenido falle durante `ActivityThread.handleBindApplication`.
- **Reglas ProGuard / R8 Antifallo (`android/app/proguard-rules.pro`):** Creación de reglas explícitas para preservar clases y constructores reflectivos de `androidx.work.**`, `androidx.room.RoomDatabase`, `WorkDatabase_Impl`, `androidx.startup.**` y `es.antonborri.home_widget.**`.
- **Desactivación de Minificación Agresiva en Release (`build.gradle`):** Configuración de `minifyEnabled false` y `shrinkResources false` en el tipo de build release con inclusión de `proguard-rules.pro` para garantizar que la reflexión de dependencias nativas permanezca intacta.
- **Preservación de ProGuard en Pipelines CI/CD:** Sincronización de `proguard-rules.pro` y registro del namespace XML `xmlns:tools` en los workflows de GitHub Actions (`release.yml` y `build_apk.yml`).

---

## [1.2.2] - 2026-10-04

La versión v1.2.2 resuelve definitivamente el crash fatal de inicio en Android 16 (API 36), certificada mediante 3 rondas de revisión adversarial y auditoría de victoria independiente con 442 pruebas automatizadas al 100%.

### Fixed
- **Arranque Inmediato en Frame 0 (`lib/main.dart`):** `runApp()` se ejecuta de forma 100% sincrónica sin esperar hardware (Keystore, SQLite). Los servicios pesados se inicializan en segundo plano con timeouts aislados, cumpliendo con el watchdog estricto de Android 16.
- **Alineación Nativa de Páginas de 16 KB:** Configuración definitiva `useLegacyPackaging = false` en `build.gradle`, garantizando que las librerías `.so` se empaqueten sin comprimir y alineadas a límites de 16 KB para compatibilidad con el kernel de Android 16.
- **Resolución de `Resources$NotFoundException`:** Creación de estilos nativos `LaunchTheme` y `NormalTheme` en `res/values/styles.xml` y `res/values-night/styles.xml` con drawables de splash screen, resolviendo el crash a nivel de WindowManager antes de que Flutter pudiera inicializar.
- **Eliminación de Bypasses de Test en Producción:** Erradicación completa de la variable `FLUTTER_TEST` en código de producción. Implementación de `_FakeSecureStorage` formal en el entorno de pruebas.
- **Sincronización de Ciclo de Vida de Onboarding:** Callback `onCompleted` bidireccional entre `OnboardingScreen` y `NutriTrackerApp` con transición suave vía `AnimatedSwitcher`.
- **Timeouts Defensivos en Android Keystore:** Ventanas de 2 segundos en todas las operaciones de `SecureStorageService` (`_safeRead`, `_safeWrite`, `_safeDelete`) con `AndroidOptions(resetOnError: true)`.
- **Validación Dual de Arranque (SQLite + Keystore):** Verificación cruzada con `getUserProfile()` en SQLite local para prevenir redireccionamiento espurio a onboarding durante picos de latencia del Keystore.
- **Paralelización Resiliente de Controladores:** `MealController.init()` aísla `refreshGoals()` con try-catch y ejecuta cargas concurrentes.
- **Blindaje de Widgets Nativos (`HomeWidgetService`):** Timeouts de 2 segundos, `Future.wait` para sincronización paralela y verificación activa de deep links (`foodtracker://`).
- **Alineación de Permisos Multimedia:** `android:maxSdkVersion="32"` en `READ_EXTERNAL_STORAGE` para cumplimiento estricto con Android 14+/16.

### Quality Gate & Certificación
- **442 Pruebas Automatizadas (100% PASS):** Verificado independientemente en GitHub Actions CI Run `37230587252`.
- **0 Errores de Análisis Estático:** `flutter analyze` sin advertencias ni errores.
- **Auditoría de Victoria PASS:** Certificación trifásica independiente (Timeline, Integridad, Ejecución) con veredicto **VICTORY CONFIRMED**.
- **Modularidad Estricta < 300 LoC:** Todos los archivos modificados cumplen holgadamente (rango 17–250 LoC).

---

## [1.2.1] - 2026-10-04

La versión v1.2.1 soluciona de forma crítica problemas de entorno nativo en Android 16: erradicación del doble ícono en el launcher del sistema operativo y arranque tolerante a fallos sin bloqueos de ANR/Watchdog.

### Fixed
- **Eliminación de Doble Ícono Launcher:** Remoción completa del bloque `<activity-alias>` redundante en `AndroidManifest.xml` que generaba duplicación de íconos en el lanzador de Android. Estandarización de la actividad principal como `.MainActivity`.
- **Depuración de Archivos Huérfanos de Kotlin:** Eliminación definitiva del paquete y archivo legado `android/app/src/main/kotlin/com/example/food_tracker/MainActivity.kt`.
- **Arranque Inmediato y Resiliencia en Android 16 (`main.dart`):** Desacoplamiento de las inicializaciones asíncronas de `DatabaseService`, `AnalysisQueueService`, `ThemeManager` y `SecureStorageService` respecto a `runApp()`. El árbol de widgets se renderiza de inmediato en el frame 0, evitando que timeouts de Keystore o almacenamiento disparen el Watchdog de Android 16.
- **Empaquetado Nativo Descomprimido y Alineado a 16 KB (`useLegacyPackaging = false`):** Configuración definitiva de librerías C/C++ `.so` (`libflutter.so`, `libapp.so`, `libsqlite3.so`, `libdartjni.so`) empaquetadas sin compresión (`STORED 0`) y con alineación estricta de 16 KB en los límites de página (0x4000), garantizando compatibilidad con el kernel de Android 16 (API 36).
- **Sincronización de Ciclo de Vida y Transición Suave de Onboarding:** Erradicación del bypass evasivo de pruebas en `main.dart`, introducción de `AnimatedSwitcher` en `NutriTrackerApp` y sincronización bidireccional mediante callback `onCompleted` en `OnboardingScreen`.
- **Protección Universal contra Deadlocks de Hardware Keystore:** Incorporación de timeout defensivo de 2 segundos en todas las operaciones (`_safeRead`, `_safeWrite`, `_safeDelete`) de `SecureStorageService`, protegiendo la carga de metas diarias y llaves API ante congelamientos del daemon nativo en Android 16.
- **Erradicación de Bypass en Home Widgets y Soporte Multiplataforma:** Reemplazo del hack `FLUTTER_TEST` en `HomeWidgetService` por la comprobación canónica `isPlatformSupported` y captura de excepciones en streams nativos.
- **Paralelización Resiliente de `MealController.init()`:** Aislamiento con bloque try-catch de `refreshGoals()` y ejecución concurrente de `loadMeals()`, `refreshStreak()` y `loadWeightLogs()`.
- **Alineación de Permisos Multimedia en AndroidManifest:** Inclusión de `android:maxSdkVersion="32"` en `READ_EXTERNAL_STORAGE` para cumplimiento estricto con las políticas de Android 14+ y 16.
- **Validación Dual de Arranque contra Base de Datos Local:** Implementación de contingencia en `NutriTrackerApp` que verifica la existencia de un perfil de usuario en SQLite antes de alternar al asistente de bienvenida, evitando falsos positivos cuando el Keystore sufre latencia o reinicios de hardware.
- **Timeouts Defensivos y Actualización Paralela en Home Widgets:** Inclusión de timeouts de 2 segundos en `HomeWidgetService.saveSummaryData` y `updateWidgets`, con concurrencia vía `Future.wait` y purga de controladores en `dispose()`.
- **Saneamiento y Rigor de Pruebas Unitarias de Widgets y Deep Links:** Eliminación de pruebas pasivas con validación real de despacho y filtrado de enlaces profundos (`handleDeepLink`), junto con verificación de preservación del dashboard ante almacenamiento vacío con base de datos preexistente.

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
