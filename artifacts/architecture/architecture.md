---
tipo: arquitectura
proyecto: App_Food_Tracker
version: v1.4.1
estado: activo
fecha: 2026-10-09
stack_principal: [Flutter, SQLite WAL v4, Google Gemini API, USDA FoodData Central, Open Food Facts, FlutterSecureStorage, GetIt, Flutter Localizations, HomeWidget, BackupNormalizer, NutritionalRecommendationService, GitHubReleasesUpdateService, MethodChannelAppInstaller, GeminiResilienceHelper, NotificationService, ClinicalPdfExportService]
diagrama_html: PRJ_App_Food_Tracker_architecture_diagram.html
tags: [proyecto, arquitectura, tech-stack, archify, local-first, get-it, l10n, result-pattern, android-widgets, sqlite-v4, recommendations, saf-backup, auto-repair, in-app-updater, microinteractions, android-16, gemini-vision-precision, timeout-resilience, atomic-image-persistence, i18n-native, gemini-streaming, resumable-downloads, http-206, 16k-tokens, thinking-level-medium, dynamic-pacing, local-notifications, socket-resilience, privacy-storage, clinical-pdf, purge-justification, pure-dart-l10n, zero-fallbacks]
---

# 🏗️ Arquitectura del Sistema: Victor Engineer - Food Tracker (v1.4.1)

> **Mesa de Control & Backend-Architect:** Este documento establece los componentes fundamentales, el Tech Stack tecnológico, las decisiones arquitectónicas estructurales y el flujo de datos integral de la aplicación **Victor Engineer - Food Tracker** en su versión `v1.4.1` (Saneamiento Integral de Localización 100% Pure Dart, Modularización por Dominios e Idiomas, Erradicación de Fallbacks Defensivos Hardcodeados y Limpieza de Residuos).

---

## 🛠️ 1. Tech Stack Oficial

- **Frontend:** Flutter 3.22+ / 3.27+ (Dart SDK `>=3.4.0 <4.0.0`), Google Fonts (Outfit, Inter), CustomPainter (`WeightLineChartPainter` y `VeLoadingRing` a 60 FPS).
- **Backend & Lógica de Dominio:** Dart Core, Clean Monolith modular (<300 LoC por archivo), Inmutabilidad con Patrón Sentinel, `ModelSanitizer`.
- **Inyección de Dependencias & Service Locator:** `get_it: ^9.0.0` centralizado en `lib/core/di/service_locator.dart`, registrando contratos abstractos (`IDatabaseService`, `IImageProcessingService`, `IMealDao`, `IWeightLogDao`, `IUserProfileDao`, `IPantryDao`, `IDishwareDao`, `IMealTemplateDao`, `IFastingDao`, `INutritionalRecommendationService`) con inyección por constructor y compatibilidad transparente con accesores estáticos `.instance`.
- **Manejo Funcional de Errores (Result / Either):** Tipo suma sellado en Dart 3 `Result<T, Failure>` (`Success`, `FailureResult`) en `lib/core/errors/result.dart` con combinadores funcionales (`fold`, `map`, `flatMap`, `guardAsync`) y jerarquía exhaustiva `Failure` en `lib/core/errors/failures.dart`.
- **Internacionalización y Localización 100% Pure Dart:** `flutter_localizations` e `intl` con contratos abstractos segregados por dominios en `lib/l10n/domains/`, implementaciones concretas en `lib/l10n/es/` y `lib/l10n/en/`, fachada no-nulable `AppLocalizations.of(context)` con fallback interno seguro a español, y extensión `MealTypeLocalization` exportada globalmente, con cero dependencias de generación de código (.arb / l10n.yaml eliminados).
- **Base de Datos & Cache (Local-First):** SQLite v4 mediante `sqflite` (móvil) y `sqflite_common_ffi` (escritorio/tests):
  - `PRAGMA journal_mode = WAL;` (Concurrencia óptima de lecturas y escrituras simultáneas).
  - `PRAGMA synchronous = NORMAL;` (Persistencia confiable y latencia < 16 ms).
  - `PRAGMA foreign_keys = ON;` (Integridad referencial estricta).
  - Tablas v4: `meals`, `meal_items`, `pantry_items` (con `package_weight`), `weight_logs`, `user_profile`, `analysis_queue`, `calibrated_dishware`, `meal_templates`, `fasting_logs`.
  - Columnas de micronutrientes: `fiber`, `sodium`, `sugar` en `meals` y `meal_items`.
  - Capa de DAOs atómicos: `MealDao`, `WeightLogDao`, `UserProfileDao`, `PantryDao`, `DishwareDao`, `MealTemplateDao`, `FastingDao`, `DatabaseConnectionFactory` y `DatabaseSchema`.
- **Normalización y Respaldo Resiliente (`BackupNormalizer` & `BackupService`):**
  - Selector nativo de archivos SAF (`file_picker ^13.1.0`) para integración fluida sin tipeo manual de rutas.
  - Normalización en Isolate secundario (`Isolate.run`) y persistencia atómica por lotes con `txn.batch()` y `batch.commit(noResult: true)` a 60 FPS.
  - Motor auto-reparador de JSON truncado (`_tryRepairTruncatedJson`): Cierre de strings huérfanos, balanceo LIFO de `{`, `[` y sanitización sintáctica.
- **Widgets Nativos de Android (AppWidgets):** `home_widget: ^0.7.0` con sincronización en SharedPreferences y layouts XML nativos en `res/layout/`:
  - **Widget Compacto (2x2):** Anillo de progreso calórico, calorías restantes vs meta, y botón de acción directa `[+ Registrar]`.
  - **Widget Extendido (4x2):** Anillo de calorías a la izquierda, desglose tri-columna de macronutrientes (Proteína, Carbohidratos, Grasas), y botones táctiles interactivos de 1 toque con deep links directos (`foodtracker://scan_food` para cámara IA y `foodtracker://scan_barcode` para escáner USDA).
  - **Doble Tema Nativo:** `res/values/colors.xml` (Modo Claro) y `res/values-night/colors.xml` (Modo Oscuro Zinc/Carmesí con esquinas redondeadas de 24dp).
- **Inferencia IA & Visión Multimodal:** Google Generative AI SDK (`google_generative_ai: ^0.4.6`):
  - Streaming Continuo Resiliente (`model.generateContentStream`): Flujo de tokens acumulados en `StringBuffer` que mantiene activo el socket TCP/TLS, mitigando cierres por inactividad de gateways NAT móviles durante fases de inferencia profunda.
  - Presupuesto Ampliado a 16k Tokens (`maxOutputTokens: 16384`): Evita el agotamiento de salida por cadenas de razonamiento latente y descarta truncamientos por `finishReason: MAX_TOKENS`.
  - Calibración de Inteligencia (`thinkingLevel: "MEDIUM"`): Mayor profundidad de deducción física para porciones, vajilla y grasas ocultas en Gemini 3.8 Flash y Pro; omisión estricta en modelos Lite para prevenir `HTTP 400 INVALID_ARGUMENT`.
  - Inyección de Escala Métrica de Vajilla: Inyección del diámetro en cm de la vajilla calibrada en el prompt del sistema para cálculo volumétrico causal.
  - Inyección de Contexto de Despensa: Reconocimiento inteligente de marcas del usuario (`PantryItem`).
  - Armonización de Micronutrientes (`fibra_g`, `sodio_mg`, `azucar_g`): Coherencia entre esquema formal, pasos del sistema y Few-Shot representativo.
  - Resiliencia Defensiva: `GeminiResilienceHelper` con reintentos escalonados `[2s, 5s, 10s]`, jitter y conmutación automática de modelo a `gemini-2.5-flash`.
  - Esquema JSON estructurado (`responseSchema`), temperatura 0.2, timeout defensivo adaptativo (90s / 120s) y rescate de JSON truncado (`JsonRepairHelper`).
- **Estimación Local Zero-Tokens:** `OfflineFoodEstimatorService` con catálogo normalizado de 50+ alimentos base por 100g para autocompletado y cálculo instantáneo sin coste de red ni consumo de tokens.
- **Procesamiento Asíncrono en Background (Zero-Freeze):** Cola de tareas SQLite `AnalysisQueueService` con encolamiento en milisegundo 0 antes de la compresión en isolate (`compressAndResizeAsync`), preservación garantizada de fotos en disco ante errores y anillo interactivo `VeLoadingRing`.
- **Bases de Datos Nutricionales (Cascada Híbrida):**
  - **Primaria:** USDA FoodData Central API (`https://api.nal.usda.gov/fdc/v1/`) con coincidencia exacta GTIN (`padLeft(14, '0')`), normalización energética ($kJ \rightarrow kcal$ factor 4.184) y control de tasa.
  - **Fallback:** Open Food Facts API v2 con timeout defensivo de 10s.
- **Motor Biométrico & Metabólico:** `MetabolicCalculator` implementando Mifflin-St Jeor para TMB/TDEE con ajuste por pasos y fórmula clínica de Peso Corporal Ajustado ($ABW$) para IMC $\ge 30$.
- **Seguridad Criptográfica & BYOK:** `flutter_secure_storage` con `AndroidOptions(encryptedSharedPreferences: true)` y Keystore permanente RSA 2048 con alias `foodtracker`.

---

## 📐 2. Diagrama de Arquitectura Interactivo (Archify)

El diagrama interactivo de componentes, límites de seguridad, widgets nativos de Android y flujos de red/persistencia del sistema se mantiene como archivo HTML autónomo con SVG vectorial de alta fidelidad:

🔗 **Ver Diagrama:** [[PRJ_App_Food_Tracker_architecture_diagram.html|Abrir Diagrama de Arquitectura Interactivo]]

*(Ubicación en disco: `artifacts/architecture/architecture_diagram.html` | Archivo fuente JSON: `artifacts/architecture/src/architecture_diagram.json`)*

---

## 🏛️ 3. Principios y Decisiones Clave de Diseño v1.1.0

### 3.1. Local-First & Cero Dependencia de Red para Operaciones Básicas
- Todas las operaciones CRUD de comidas, despensa, calibración de platos, registros de ayuno, metas calóricas, registros de peso e historial son ejecutadas de manera síncrona/inmediata en SQLite local.
- La red únicamente se invoca bajo demanda explícita: estimación visual con Gemini, consulta de modelos en vivo o escaneo de códigos de barras. La pérdida de conectividad no interrumpe ninguna función de visualización o registro.

### 3.2. Concurrencia y Resiliencia en SQLite v3 (Modo WAL)
- Se activa `PRAGMA journal_mode = WAL;` y `PRAGMA synchronous = NORMAL;`.
- Migración v3 sin pérdida de datos: alteración idempotente de tablas existentes (`meals`, `meal_items`, `pantry_items`) y creación de `calibrated_dishware`, `meal_templates` y `fasting_logs` con sus respectivos índices B-Tree.
- Bloqueo de inicialización mediante `_initFuture` en `DatabaseConnectionFactory` contra arranques en frío simultáneos.

### 3.3. Arquitectura de Widgets Nativos Android (Glance / RemoteViews)
- Los widgets de pantalla de inicio operan de forma desacoplada de la VM de Flutter mediante `SharedPreferences` compartidas y `AppWidgetProvider` nativo de Android.
- `HomeWidgetService` actualiza los estados atómicamente tras cada inserción o edición de comida.
- El deep linking con esquemas `foodtracker://scan_food` y `foodtracker://scan_barcode` ofrece atajos de latencia cero desde el launcher del sistema operativo.
- Soporte nativo para modo claro y modo oscuro según la configuración del sistema de Android a través de carpetas de recursos `values` y `values-night`.

### 3.4. Resiliencia de IA y Cero-Pérdida de Capturas
- Las imágenes tomadas por el usuario se guardan de forma permanente antes de cualquier llamada a la API de Gemini.
- En caso de fallo de red, cuota (429) o indisponibilidad (503), la foto física NUNCA se elimina. La tarea queda en estado `failed` en el banner del Dashboard, permitiendo reintentar con backoff exponencial o editar manualmente precargando la captura.
- Cascada automática a modelos de respaldo para garantizar continuidad del servicio.

### 3.5. Monolito Modular (< 300 LoC por Archivo)
- Toda pantalla, widget o servicio en `lib/` respeta el umbral estricto de menos de 300 líneas de código:
  - DAOs atómicos (`MealDao`, `WeightLogDao`, `UserProfileDao`, `PantryDao`, `DishwareDao`, `MealTemplateDao`, `FastingDao`).
  - Servicios auxiliares desacoplados (`GeminiResilienceHelper`, `OfflineFoodEstimatorService`, `HomeWidgetService`, `MealImageFileNamer`, `MealImageStorageResolver`).
  - Widgets Bento modulares en `lib/widgets/`.

### 3.6. Estimación Inteligente Local Zero-Tokens
- `OfflineFoodEstimatorService` resuelve búsquedas como "carne molida 100g" en menos de 5 milisegundos sin consumir tokens de IA ni realizar peticiones HTTP, reduciendo la latencia de usuario y los costes operativos.

### 3.7. Motor Inteligente de Recomendaciones Nutricionales y "¿Qué Debería Comer Hoy?"
- `NutritionalRecommendationService` procesa análisis longitudinales de 7, 15 y 30 días calculando deltas reales frente a las metas calóricas y de macronutrientes del usuario.
- Genera diagnósticos específicos (reducción de grasas saturadas, incremento de densidad proteica) acompañados de sugerencias de sustitución inteligente.
- El flujo interactivo `WhatToEatSheet` evalúa el déficit/superávit restante en la jornada actual y sugiere opciones culinarias balanceadas con capacidad de registro en 1 toque directo a la base de datos local SQLite.

### 3.8. Sistema de Respaldos Físicos JSON en Almacenamiento Local y Explorador In-App
- Sustitución de portapapeles por exportación física de archivos `.json` deterministas en directorios accesibles del dispositivo (`Downloads/FoodTracker_Backups` en Android / Documentos en Desktop).
- Diálogo interactivo `JsonFilePickerDialog` para detección de respaldos existentes, lectura previa de metadatos (conteo de comidas, peso, vajilla, perfil) y restauración atómica en transacción SQLite con salvaguarda de estado previo.

### 3.9. Identidad Permanente (`applicationId`), Firma Permanente y Arquitectura Android 16 (16KB)
- Consolidación canónica de `applicationId = "com.victorengineer.foodtracker"` y `namespace` unificado, blindado para prevenir duplicación de iconos o pérdida de sandbox de datos en actualizaciones.
- Configuración de `useLegacyPackaging = false` en Gradle (sin `extractNativeLibs` deprecado) para alineación nativa de páginas de 16 KB en Android 16 (API 36).
- Timeouts defensivos (2s) con fallback a SQLite local en caso de demoras o bloqueos de hardware en el Keystore de Android 16.
- Preservación de certificado criptográfico RSA 2048 permanente en `lib/assets/keystore/release.keystore` para instalaciones in-place continuas.

### 3.10. Motor de Normalización Adaptativo y Respaldo Auto-Sanador (v1.2.5)
- Desacoplamiento de la decodificación JSON del hilo de UI mediante `Isolate.run`.
- Persistencia masiva por lotes con `txn.batch()` y `batch.commit(noResult: true)` garantizando 60 FPS en importaciones grandes.
- Motor de auto-reparación sintáctica (`_tryRepairTruncatedJson`): recupera respaldos incompletos o con strings sin terminar (`FormatException`), equilibrando llaves y corchetes en orden LIFO.
- Ergonomía de Dashboard: Ayuno Bento colapsable (~44px) sin superposiciones y modal `WhatToEatSheet` acotado con `SafeArea`.

### 3.11. Auto-Actualizador In-App Sincronizado y Sistema de Microinteracciones (v1.3.0)
- **Cliente de Actualización GitHub Releases (`AppUpdateService`):**
  - Consulta en tiempo real al endpoint REST de GitHub Releases (`VICTOREB13/App-Food-Tracker`).
  - Detección de versión con comparador de semántica SemVer tolerante a prefijos `v` (`v1.3.0` vs `1.2.5`).
  - Streaming de bytes hacia directorio de caché (`update_vX.Y.Z.apk`) con emisión continua de ratio (`0.0` a `1.0`) para renderizado a 60 FPS de barra de progreso.
- **Canal de Plataforma e Instalador Nativo Android (`AppInstallerService` & `MainActivity.kt`):**
  - `MethodChannel("com.victorengineer.foodtracker/app_installer")` con métodos `installApk`, `canRequestPackageInstalls` y `openInstallPermissionSettings`.
  - Android `FileProvider` con `androidx.core.content.FileProvider` y XML `file_paths.xml` para compartir URI con `FLAG_GRANT_READ_URI_PERMISSION`.
  - Permiso nativo `<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>` para Android 8.0+ (API 26) hasta Android 16 (API 36).
  - Fallback defensivo a navegador web mediante URL directa del release si la instalación nativa no es autorizada.
- **Microinteracciones y Polish Visual:**
  - `VeBounceable`: Física de rebote táctil (`scale: 0.96`, `Curves.easeOutBack`) para botones de alto impacto.
  - `VeAnimatedCounter`: Animación numérica continua para métricas de calorías y macronutrientes.
  - Feedback háptico (`HapticFeedback.lightImpact()` y `selectionClick()`) en FAB de comidas, agua y ayuno.
  - Eliminación de flecha `<-` errónea en Dashboard (`automaticallyImplyLeading: false` en `VeAppBar`).

### 3.12. Inferencia Causal Volumétrica 3D, Modernización a Gemini 3, Persistencia Atómica e i18n Nativo (v1.3.1)
- **Inversión Causal Autorregresiva (`GeminiResilienceHelper`):**
  - La predicción autoregresiva del LLM se reordena estrictamente para forzar al modelo a calcular primero la geometría y propiedades físicas antes de deducir masa y calorías:
    1. Delimitación de vajilla o referencia métrica anatómica.
    2. Estimación geométrica 3D (Largo x Ancho x Alto en cm) y volumen ($cm^3$).
    3. Densidad física volumétrica ($g/cm^3$) y estado de cocción (merma/hidratación).
    4. Detección visual de brillo especular, fritura y grasas/aceites ocultos.
    5. Deducción de masa física en gramos: $Masa = Volumen \times Densidad \times FactorCoccion$.
    6. Macronutrientes y micronutrientes consecuentes a la masa deducida.
- **Catálogo de Modelos Modernos & Thinking Budget (`GeminiModelService` & `GeminiVisionFilter`):**
  - Incorporación prioritaria de `gemini-3.8-flash` (por defecto, ágil y económico) y `gemini-3.1-pro` (alta precisión clínica).
  - Democión de `gemini-2.0-flash` a categoría obsoleta.
  - Inyección de `thinking_budget: 1024` para habilitar razonamiento latente en modelos compatibles.
- **Timeouts Resilientes y Pacing Progresivo de UI:**
  - Ampliación de timeout en `GeminiVisionService` de 35s a 90s (Flash) y hasta 120s (Pro/Thinking).
  - Pacing progresivo no lineal en `MealAnalysisPacing` / `MealDetailScreen` estructurado en 5 fases traducidas para eliminar congelamientos al 88%.
- **Persistencia Atómica en Cambio de Tipo de Comida (Bug 1):**
  - `MealDetailScreen.onMealTypeChanged` muta únicamente el estado en memoria; el renombramiento físico del archivo en disco se acopla atómicamente a la transacción de guardado en SQLite en `meal_detail_actions.dart`.
- **Internacionalización Nativa Pura (Bug 2):**
  - Erradicación del 100% de los condicionales ternarios `isSpanish` en los widgets de UI.
  - Centralización bilingüe (118 claves) en `lib/l10n/app_es.arb` y `lib/l10n/app_en.arb`.
  - Extensión `toLocalizedMealType(context)` para traducir etiquetas de comidas sin mutar las claves canónicas invariantes en base de datos.

### 3.13. Streaming Resiliente en Gemini Vision, HTTP 206 Resumable Updates y Consistencia de UI (v1.3.2)
- **Streaming Continuo contra Desconexiones NAT (`GeminiVisionService`):**
  - Migración de `model.generateContent()` a `model.generateContentStream()` acumulando chunks en `StringBuffer`.
  - Los paquetes de red intermedios mantienen viva la conexión TCP/TLS, mitigando el cierre de sockets por inactividad impuesto por NAT gateways de redes móviles durante fases prolongadas de razonamiento (45–80s).
- **Presupuesto Ampliado (`maxOutputTokens: 8192`):**
  - Configuración explícita en `GenerationConfig` para evitar que las cadenas de pensamiento agoten el presupuesto de salida (`finishReason: MAX_TOKENS`) y trunquen la estructura JSON.
- **Cascada de Alta Capacidad y Backoff Escalonado (`GeminiResilienceHelper`):**
  - Conmutación de fallback a `gemini-2.5-flash` con demoras `[2s, 5s, 10s]` y jitter aleatorio.
  - Clasificación ampliada en `isRetriableError` reconociendo códigos HTTP 500, 502, 504, `HttpException`, `HandshakeException` y payloads de respuesta vacíos.
  - Reconocimiento de modelos Gemini 3 (`gemini-3.8-flash` y `gemini-3.1-pro`) en `supportsThinking` para asignar timeout de 120s y presupuesto de pensamiento latente (1024).
- **Descargas Resumibles de Actualizaciones GitHub (HTTP 206 & Range) (`AppUpdateService`):**
  - Reanudación de transferencias interrumpidas (~74 MB) mediante cabeceras `Range: bytes=$existingBytes-` y detección de `HTTP 206 Partial Content`.
  - Escritura incremental en archivo temporal `.apk.part` y renombrado atómico a `.apk` al completar la descarga total.
- **Sanitización y Ergonomía del Diálogo de Actualización (`InAppUpdateDialog`):**
  - `_sanitizeErrorMessage` erradica URLs de firma digital extensas de AWS/Azure/GitHub en mensajes de error visibles.
  - Contenedor con `SingleChildScrollView` evitando desbordamientos de renderizado vertical en pantallas con tipografía ampliada.
  - Soporte de cancelación interactiva del proceso de descarga con liberación inmediata de recursos.
- **Corrección de Frontera en Pacing y Contraste de Notificaciones:**
  - `MealAnalysisPacing.getStageMessage`: ratio 0.95 mantiene el mensaje de análisis de macros (`analysisStageMacros`), activando `analysisStageComplete` estrictamente en $\ge 1.0$.
  - Corrección de contraste WCAG en SnackBar oscuro (`#18181B`) y centralización de versión canónica en `AppConstants.appVersion`.

### 3.14. Ventana de 16k Tokens, Thinking Level MEDIUM y Pacing Fluido sin Saturación SQLite (v1.3.4)
- **Ampliación a 16k Tokens (`maxOutputTokens: 16384`):**
  - Margen ampliado para tokens de pensamiento latente interno del transformer y respuesta JSON estructurada con micronutrientes, eliminando cortes por `finishReason: MAX_TOKENS`.
  - Actualización del catálogo de contingencia en `GeminiVisionFilter` para `gemini-3.8-flash` y `gemini-3.1-pro`.
- **Estandarización de Inteligencia (`thinkingLevel: "MEDIUM"`):**
  - Configuración predeterminada `defaultThinkingLevel = 'MEDIUM'` y método resolutor `resolveThinkingLevel(model)`.
  - Inyección de `thinking_level` y `thinking_config: {'thinking_level': level}` en `buildCallConfig` para modelos Gemini 3 y Pro.
  - Omisión estricta de configuración de pensamiento en variantes Lite (`gemini-3.5-flash-lite`) para prevenir el error `HTTP 400 INVALID_ARGUMENT`.
- **Armonización de Micronutrientes (`fibra_g`, `sodio_mg`, `azucar_g`):**
  - Estandarización entre la instrucción del sistema, el ejemplo Few-Shot y el esquema formal `mealAnalysisSchema`.
  - Preservación íntegra de las 12 reglas de cubicaje volumétrico clínico (`Conversión cocido vs crudo`, `Regla de Grasa Oculta en Comida Casera`, `5g y 10g adicionales de grasa`, etc.).
- **Pacing Fluido en Memoria a 60 FPS en Dashboard:**
  - Temporizador periódico `Timer.periodic(const Duration(milliseconds: 500))` durante la llamada a Gemini que avanza suavemente `task.progress` (0.45 a 0.90) con `MealAnalysisPacing.nextProgress(task.progress)`.
  - Notificación reactiva a la UI con `notifyListeners()` a 60 FPS con cero contención de I/O en disco (sin llamar a `_persistTaskToDb` en cada tick).
  - Cancelación determinista en bloque `finally { pacingTimer?.cancel(); }`.
  - `AnalysisProgressBanner`: resolución dinámica y localizada del mensaje de etapa vía `MealAnalysisPacing.getStageMessage(task.progress, l10n)` cuando la tarea está activamente en progreso (`task.status == AnalysisStatus.processing`).
- **Versión Canónica:** `AppConstants.appVersion = '1.3.4'` y `pubspec.yaml version: 1.3.4+1`.

### 3.15. Notificaciones Asíncronas en Segundo Plano, Resiliencia de Socket Gemini con Fallback Unario, Privacidad de Almacenamiento y Reportes Clínicos en PDF (v1.4.0)
- **Sistema de Notificaciones Locales y Programadas (`NotificationService` & `INotificationService`):**
  - Implementación de servicio de notificaciones (< 300 LoC) con canales de alta prioridad (`food_tracker_meal_analysis`) y canales de alarma exacta (`food_tracker_fasting`) basados en `flutter_local_notifications` y soporte de zona horaria `tz.TZDateTime`.
  - Configuración nativa en `AndroidManifest.xml` con permisos `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM` y `RECEIVE_BOOT_COMPLETED`.
  - Notificaciones en segundo plano al terminar de procesar una comida en `AnalysisQueueService` (`¡Ya se terminó de analizar tu comida!` con nombre de plato y calorías aproximadas, o aviso de fallo si la imagen es irreconocible).
  - Alarma programada exacta en `FastingController` al iniciar un ayuno (`scheduleFastingCompleted`) con cancelación automática al interrumpir o finalizar el ayuno antes de tiempo (`cancelFastingReminder`).
- **Resiliencia ante Socket Cuts y Fallback Unario en Visión (`GeminiVisionService` & `GeminiResilienceHelper`):**
  - Detección exhaustiva de caídas abruptas de socket en `isRetriableError` (`os error: 104`, `os error: 10054`, `connection reset by peer`, `software caused connection abort`, `connection closed`).
  - En caso de interrupción del flujo en streaming (`generateContentStream`), `GeminiVisionService` ejecuta de inmediato un fallback unario (`generateContent`) transparente sin fallar la tarea de la cola de análisis.
  - Creación del contrato `IVisionModelProvider` en `lib/core/interfaces/vision_model_provider_interface.dart` para desacoplar el motor de visión de futuros proveedores como OpenRouter.
- **Purga de Justificación Volumétrica Técnica:**
  - Supresión de `justificacion_visual` del esquema estructurado `mealAnalysisSchema` en `GeminiResilienceHelper`.
  - Eliminación del contenedor de justificación en `FoodItemsListCard` y del controlador/campo en `FoodItemEditorDialog` para centrar la experiencia de usuario exclusivamente en los alimentos y valores nutricionales.
- **Selector de Privacidad de Almacenamiento de Fotos:**
  - Modelo `StorageMode` (`public`, `private`) persistido en `SecureStorageService`.
  - Tarjeta Bento `StorageModeCard` en `SettingsScreen` permitiendo alternar entre almacenamiento público (visible en la galería del dispositivo `/Pictures/FoodTracker`) y privado aislado (sandbox de la aplicación).
  - Adaptación en `MealImageStorageResolver` e `ImageProcessingService` para asegurar que en modo privado ninguna captura se propague a la galería del sistema.
- **Exportación Clínica Dual (CSV RFC 4180 y PDF Profesional):**
  - Nuevo servicio `ClinicalPdfExportService` e interfaz `IClinicalPdfExportService` (< 300 LoC) usando `package:pdf` para estructurar tablas de macronutrientes, micronutrientes (fibra, sodio, azúcar), promedios diarios y cronograma detallado de comidas.
  - Almacenamiento directo en el directorio accesible `/Documents/FoodTracker` vía `AccessibleStorageResolver`.
  - Diálogo `ClinicalExportDialog` con selector segmented button (CSV / PDF) y confirmación amigable (`Se guardó en /Documents/FoodTracker: {archivo}`).
- **Versión Canónica:** `AppConstants.appVersion = '1.4.0'` y `pubspec.yaml version: 1.4.0+1`.


