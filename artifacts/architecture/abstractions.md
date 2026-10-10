---
tipo: abstracciones
proyecto: App_Food_Tracker
version: v1.4.1
estado: activo
fecha: 2026-10-09
tags: [proyecto, arquitectura, abstracciones, backend, gemini-streaming, 16k-tokens, thinking-level-medium, micronutrients-harmonization, dynamic-pacing, local-notifications, socket-resilience, privacy-storage, clinical-pdf, pure-dart-l10n, zero-fallbacks]
---

# Abstracciones del Sistema y Arquitectura de Código: Victor Engineer - Food Tracker (v1.4.1)

> **Mesa de Control & Backend-Architect:** Este documento centraliza las clases maestras, interfaces de dominio, servicios de negocio, funciones utilitarias nucleares, variables de estado seguro y costuras de flujo de datos (data seams) de la aplicación **Victor Engineer - Food Tracker** en su versión `v1.4.1` (Saneamiento Integral de Localización 100% Pure Dart, Modularización por Dominios e Idiomas, Erradicación de Fallbacks Defensivos Hardcodeados y Limpieza de Residuos). Complementa conceptualmente a [[PRJ_App_Food_Tracker_api_spec|Especificación de API y Modelos]] para posibilitar el entendimiento exhaustivo del software sin necesidad de inspeccionar línea por línea el código fuente.

---

## 🏛️ Filosofía de Diseño y Paradigmas de Código

1. **Local-First Determinista & Resiliencia Offline:**
   - Todo el estado transaccional (comidas, despensa, calibración de platos, ayuno intermitente, plantillas habituales, registros de peso, metas calóricas y perfil metabólico) reside localmente en **SQLite v4** optimizado en modo WAL (`PRAGMA journal_mode = WAL;`, `PRAGMA synchronous = NORMAL;`, `PRAGMA foreign_keys = ON;`).
   - Las operaciones CRUD son síncronas/inmediatas en el dispositivo. La red se invoca exclusivamente bajo demanda explícita del usuario (inferencia visual multimodal y escaneo de códigos de barras).
2. **Inmutabilidad Estricta & Patrón Sentinel:**
   - Todos los modelos de dominio son inmutables (`@immutable`).
   - Se utiliza el **Patrón Sentinel** (`static const Object _sentinel = Object();`) en todos los métodos `copyWith` para diferenciar unívocamente entre "omitir la actualización de un atributo opcional" y "resetear el atributo a `null`".
3. **Defensa contra Corrupción & Sanitización Centralizada (`ModelSanitizer`):**
   - Validación y acotamiento de strings (nombres <= 255 chars, notas <= 2.000 chars, JSON <= 100.000 chars).
   - Acotamiento numérico contra valores imposibles, infinitos y `NaN` mediante `clampDouble(val, min: 0.0, max: 9999.0)`.
   - Parsing tolerante a fallos de timestamps ISO-8601 con fallback determinista a `DateTime.now()`.
4. **Monolito Modular con Límite Duro de LoC (< 300 LoC):**
   - Separación estricta entre capa de presentación (`screens/`, `widgets/`), capa de controladores de estado (`controllers/`), capa de servicios de dominio (`services/`) y capa de persistencia/modelos (`models/`).
   - Cada pantalla o componente complejo se descompone en submódulos especializados para mantener el archivo principal por debajo de 300 líneas.
5. **BYOK (Bring Your Own Key) & Custodia Criptográfica en Hardware:**
   - Las credenciales privadas de Google Gemini y USDA FoodData Central son custodiadas en hardware criptográfico seguro mediante `flutter_secure_storage` (`EncryptedSharedPreferences` en Android, `Keychain` en iOS).
6. **Desacoplamiento de Widgets Nativos y Deep Linking:**
   - Comunicación asíncrona hacia Android AppWidgets mediante `SharedPreferences` compartidas y `home_widget`.
   - Rutas semánticas nativas (`foodtracker://scan_food`, `foodtracker://scan_barcode`, `foodtracker://new_meal`) gestionadas directamente en `MainActivity` sin inicialización pesada de Flutter.

---

## 🧩 Módulos y Capas del Sistema (v1.4.0)

```text
lib/
├── controllers/          # Controladores de Estado Reactivo con Inyección por Constructor
│   ├── meal_controller.dart
│   ├── settings_controller.dart
│   ├── fasting_controller.dart
│   └── streak_calculator.dart
├── core/                 # Infraestructura Transversal y Contratos
│   ├── di/
│   │   └── service_locator.dart
│   ├── errors/
│   │   ├── failures.dart
│   │   └── result.dart
│   └── interfaces/
│       ├── daos_interfaces.dart
│       ├── dishware_dao_interface.dart
│       ├── fasting_dao_interface.dart
│       ├── meal_template_dao_interface.dart
│       ├── database_service_interface.dart
│       ├── image_processing_service_interface.dart
│       ├── notification_service_interface.dart
│       ├── vision_model_provider_interface.dart
│       └── clinical_pdf_export_service_interface.dart
├── l10n/                 # Localización e Internacionalización Multi-idioma (100% Pure Dart)
│   ├── app_localizations.dart
│   ├── domains/          # Interfaces abstractas segregadas por dominio (< 300 LoC)
│   ├── en/               # Implementaciones concretas en inglés (< 300 LoC)
│   └── es/               # Implementaciones concretas en español (< 300 LoC)
├── models/               # Modelos de Dominio Inmutables & Sanitizadores (< 300 LoC)
│   ├── analysis_task.dart
│   ├── calibrated_dishware.dart
│   ├── daily_goals.dart
│   ├── fasting_log.dart
│   ├── food_item.dart
│   ├── gemini_model_info.dart
│   ├── json_repair_helper.dart
│   ├── meal.dart
│   ├── meal_analysis_result.dart
│   ├── meal_image_file_info.dart
│   ├── meal_template.dart
│   ├── model_sanitizer.dart
│   ├── pantry_item.dart
│   ├── usda_food_item.dart
│   ├── user_profile.dart
│   └── weight_log.dart
├── services/             # Servicios de Negocio, Clientes API y Orquestación
│   ├── analysis_queue_service.dart
│   ├── backup_service.dart
│   ├── barcode_lookup_service.dart
│   ├── daos/             # Capa de Acceso a Datos Especializada (<300 LoC)
│   │   ├── database_connection_factory.dart
│   │   ├── database_schema.dart
│   │   ├── dishware_dao.dart
│   │   ├── fasting_dao.dart
│   │   ├── meal_dao.dart
│   │   ├── meal_template_dao.dart
│   │   ├── pantry_dao.dart
│   │   ├── user_profile_dao.dart
│   │   └── weight_log_dao.dart
│   ├── database_service.dart
│   ├── gemini_model_service.dart
│   ├── gemini_resilience_helper.dart
│   ├── gemini_vision_service.dart
│   ├── home_widget_service.dart
│   ├── image_processing_service.dart
│   ├── meal_image_file_namer.dart
│   ├── meal_image_storage_resolver.dart
│   ├── metabolic_calculator.dart
│   ├── offline_food_estimator_service.dart
│   ├── open_food_facts_service.dart
│   ├── secure_storage_service.dart
│   ├── theme_manager.dart
│   └── usda_food_data_service.dart
└── widgets/              # Componentes de UI Atómicos y Modulares (<300 LoC)
    ├── common/           # VeLoadingRing, VeAppBar, VeCard, VeLogo...
    ├── dashboard/        # AnalysisProgressBanner, FastingWindowBentoCard...
    ├── meal_detail/      # FoodItemEditorDialog con autocompletado local...
    ├── metrics/          # WeeklyDigestCard, CalorieComplianceBentoCard...
    ├── profile/          # DishwareCalibrationCard, BiometricInputsCard...
    └── settings/         # LanguageSelectorCard, GeminiModelSelectorCard...
```

---

## 📐 Interfaces y Contratos de Dominio

### `IDatabaseService`
- **Ubicación:** `lib/core/interfaces/database_service_interface.dart`
- **Propósito:** Contrato unificado para el orquestador de persistencia SQLite local-first y acceso a DAOs.
- **Firmas:** `get database`, `getAllMeals()`, `upsertMeal(meal)`, `deleteMeal(id)`, `getPantryItems()`, `saveUserProfile(profile)`, `insertWeightLog(log)`, etc.

### `IImageProcessingService`
- **Ubicación:** `lib/core/interfaces/image_processing_service_interface.dart`
- **Propósito:** Contrato para el procesamiento, compresión asíncrona en isolate y persistencia de imágenes.
- **Firmas:** `compressAndResizeAsync(imageBytes, ...): Future<Uint8List>`, `saveMealImage(imageBytes, ...): Future<String>`, `deleteMealImage(path): Future<void>`.

### DAOs de Dominio (`IMealDao`, `IWeightLogDao`, `IUserProfileDao`, `IPantryDao`)
- **Ubicación:** `lib/core/interfaces/daos_interfaces.dart`
- **Propósito:** Separación de responsabilidades atómicas para comidas, pesajes, perfil de usuario y despensa.
- **Firmas:** Operaciones CRUD síncronas/asíncronas y variantes funcionales con `Result<T, Failure>`.

### `IDishwareDao`
- **Ubicación:** `lib/core/interfaces/dishware_dao_interface.dart`
- **Propósito:** Contrato para la persistencia y gestión de platos y vajilla calibrada del usuario.
- **Firmas:** `insertDishware(dishware)`, `getDishwareList()`, `getDefaultDishware()`, `setDefaultDishware(id)`, `deleteDishware(id)`.

### `IFastingDao`
- **Ubicación:** `lib/core/interfaces/fasting_dao_interface.dart`
- **Propósito:** Contrato para el control del protocolo y registros de ayuno intermitente.
- **Firmas:** `startFast(startTime, {targetHours})`, `stopActiveFast(endTime, {notes})`, `getActiveFast()`, `getFastingHistory({limit})`.

### `IMealTemplateDao`
- **Ubicación:** `lib/core/interfaces/meal_template_dao_interface.dart`
- **Propósito:** Contrato para registrar y consultar comidas habituales o plantillas predefinidas.
- **Firmas:** `saveTemplate(template)`, `getTemplates({mealType})`, `deleteTemplate(id)`.

---

## ⚙️ Clases Núcleo y Servicios de Negocio

### 1. `DatabaseService`
- **Ubicación:** `lib/services/database_service.dart`
- **Responsabilidad:** Orquestador central de SQLite v3 (modo WAL, sincronización NORMAL, llaves foráneas ON). Delega en DAOs atómicos (`MealDao`, `WeightLogDao`, `UserProfileDao`, `PantryDao`, `DishwareDao`, `MealTemplateDao`, `FastingDao`).
- **Métodos Clave:**
  - `database: Future<Database>`: Inicialización perezosa con lock defensivo `_initFuture`.
  - `upsertMealResult(Meal meal): Future<Result<int, Failure>>`: Inserción transaccional atómica con retorno `Result`.
  - `getMealsByRange(DateTime start, DateTime end): Future<List<Meal>>`: Consulta indexada B-Tree sin N+1.

### 2. `GeminiVisionService`
- **Ubicación:** `lib/services/gemini_vision_service.dart`
- **Responsabilidad:** Cliente de visión multimodal con Google Generative AI SDK, temperatura 0.2, timeout defensivo de 35s y prompt enriquecido.
- **Métodos Clave:**
  - `analyzeMealImage(Uint8List imageBytes, ...): Future<MealAnalysisResult>`: Inferencia visual con inyección de escala métrica de vajilla y contexto de despensa.
  - `analyzeSpeechMeal(Uint8List audioBytes): Future<MealAnalysisResult>`: Procesamiento multimodal de voz natural.
  - `analyzeVideoFramesMeal(List<Uint8List> frameBytesList): Future<MealAnalysisResult>`: Muestreo 3D multi-ángulo.
  - `reanalyzeMealWithAi(Meal meal, String prompt): Future<MealAnalysisResult>`: Ajuste interactivo y sustitución de ingredientes.

### 3. `GeminiModelService`
- **Ubicación:** `lib/services/gemini_model_service.dart`
- **Responsabilidad:** Descubrimiento dinámico de modelos de IA vía `GET https://generativelanguage.googleapis.com/v1beta/models`.
- **Métodos Clave:**
  - `getAvailableModels({bool forceRefresh}): Future<List<GeminiModelInfo>>`: Consulta en vivo filtrando por generación estructurada y visión, con catálogo offline fallback resiliente.

### 4. `UsdaFoodDataService`
- **Ubicación:** `lib/services/usda_food_data_service.dart`
- **Responsabilidad:** Cliente HTTP para USDA FoodData Central API (`https://api.nal.usda.gov/fdc/v1`).
- **Métodos Clave:**
  - `lookupBarcode(String barcode): Future<UsdaFoodItem?>`: Búsqueda GTIN normalizada a 14 dígitos (`padLeft(14, '0')`), normalización energética ($kJ \rightarrow kcal$) y rate limiting deslizante (1.000 req/h).

### 5. `BarcodeLookupService`
- **Ubicación:** `lib/services/barcode_lookup_service.dart`
- **Responsabilidad:** Cascada híbrida de resolución de códigos de barras (USDA FoodData Central $\rightarrow$ Open Food Facts v2).
- **Métodos Clave:**
  - `lookup(String barcode): Future<BarcodeLookupResult?>`: Despacha primero a USDA; si no hay coincidencia exacta o falla, conmuta limpiamente a Open Food Facts.

### 6. `MetabolicCalculator`
- **Ubicación:** `lib/services/metabolic_calculator.dart`
- **Responsabilidad:** Motor biométrico clínico implementando Mifflin-St Jeor, factores de actividad y metas nutricionales.
- **Métodos Clave:**
  - `calculateBmr(UserProfile profile): double`: TMB estandarizada por sexo biológico.
  - `calculateTdee(UserProfile profile): double`: Gasto energético diario total según multiplicador de actividad y pasos.
  - `calculateMacros(UserProfile profile): DailyGoals`: Cálculo de macros con Peso Corporal Ajustado ($ABW$) para IMC $\ge 30$.
  - `generateMasterPrompt(UserProfile profile): String`: Síntesis del contexto metabólico para el prompt de Gemini.

### 7. `SecureStorageService`
- **Ubicación:** `lib/services/secure_storage_service.dart`
- **Responsabilidad:** Custodia de claves privadas y configuraciones sensibles con hardware seguro (`flutter_secure_storage`).
- **Métodos Clave:**
  - `getGeminiApiKey() / setGeminiApiKey(key)`: Lectura/escritura segura de clave Gemini.
  - `getUsdaApiKey() / setUsdaApiKey(key)`: Lectura/escritura segura de clave USDA.
  - `getDailyGoals() / setDailyGoals(goals)`: Persistencia segura de metas nutricionales.

### 8. `BackupService`
- **Ubicación:** `lib/services/backup_service.dart`
- **Responsabilidad:** Exportación e importación completa de la base de datos en JSON estructurado para copias de seguridad locales.
- **Métodos Clave:**
  - `exportToJsonString(): Future<String>`: Serialización transaccional de comidas, despensa, pesos y perfil.
  - `importFromJsonString(String jsonContent): Future<Map<String, int>>`: Restauración determinista con `ConflictAlgorithm.replace`.

### 9. `ImageProcessingService`
- **Ubicación:** `lib/services/image_processing_service.dart`
- **Responsabilidad:** Pipeline de preprocesamiento, escalado y compresión de capturas fotográficas.
- **Métodos Clave:**
  - `compressAndResizeAsync(Uint8List imageBytes, ...): Future<Uint8List>`: Compresión en Isolate secundario a 1024x1024 px, JPEG 85%.
  - `saveMealImage(Uint8List imageBytes, ...): Future<String>`: Almacenamiento físico seguro con nombres normalizados.

### 10. `HomeWidgetService`
- **Ubicación:** `lib/services/home_widget_service.dart`
- **Responsabilidad:** Sincronización bidireccional entre estado reactivo y AppWidgets nativos de Android (2x2 y 4x2).
- **Métodos Clave:**
  - `updateWidgetData(...)`: Actualización atómica en SharedPreferences y recarga de RemoteViews.
  - `handleWidgetLaunch(Uri uri)`: Manejo de deep links (`foodtracker://scan_food`, `foodtracker://scan_barcode`).

### 11. `AnalysisQueueService`
- **Ubicación:** `lib/services/analysis_queue_service.dart`
- **Responsabilidad:** Cola asíncrona no bloqueante con persistencia SQLite y preservación física garantizada de imágenes.
- **Métodos Clave:**
  - `enqueueTask(imagePath, ...)`: Encolado en milisegundo 0 antes de compresión, disparando `notifyListeners()`.
  - `retryTask(taskId)`: Reintento con backoff sobre la foto preservada.
  - `createManualMealFromFailedTask(taskId)`: Creación manual sin pérdida de foto.

### 12. `OfflineFoodEstimatorService`
- **Ubicación:** `lib/services/offline_food_estimator_service.dart`
- **Responsabilidad:** Estimador local determinista con catálogo de 50+ alimentos normalizados por 100g para autocompletado instantáneo (<5ms, 0 tokens).

### 13. `GeminiResilienceHelper`
- **Ubicación:** `lib/services/gemini_resilience_helper.dart`
- **Responsabilidad:** Resiliencia de red con reintentos exponenciales, jitter y cascada automática de modelos.

### 14. `BackupNormalizer`
- **Ubicación:** `lib/services/backup_normalizer.dart`
- **Responsabilidad:** Normalización adaptativa de esquemas legados (v1.0.4 y anteriores) y auto-reparación de respaldos incompletos.
- **Métodos Clave:**
  - `normalize(String jsonString): Future<Map<String, dynamic>>`: Procesa en `Isolate.run`, detecta formatos de arrays planos, traduce claves en español y devuelve el mapa canónico.
  - `_tryRepairTruncatedJson(String jsonString): String`: Auto-cierre de strings sin terminar (`FormatException: Unterminated string`), limpieza de separadores huérfanos y balanceo LIFO de llaves y corchetes.

---

## 🛠️ Funciones Críticas y Lógica Pura (Pure Functions)

### 1. `ModelSanitizer`
- **Módulo:** `lib/models/model_sanitizer.dart`
- **Lógica Pura:**
  - `clampDouble(double? val, {double min = 0.0, double max = 9999.0}): double`: Sanitización matemática estricta contra `NaN`, infinitos y negativos.
  - `sanitizeText(String? raw, {int maxLength = 255}): String`: Truncamiento seguro y remoción de caracteres nulos/corruptos.
  - `parseIsoDateTimeSafe(String? raw): DateTime`: Parsing determinista con fallback a fecha actual ante strings inválidos.

### 2. `MetabolicCalculator` (Fórmulas Clínicas Puras)
- **Módulo:** `lib/services/metabolic_calculator.dart`
- **Lógica Pura:**
  - Fórmula Mifflin-St Jeor: $TMB_{m} = 10 \times peso + 6.25 \times altura - 5 \times edad + 5$ (Varones), $- 161$ (Mujeres).
  - Peso Corporal Ajustado ($ABW$): $ABW = IBW + 0.4 \times (TBW - IBW)$ para usuarios con $IMC \ge 30$.
  - Distribución de Macronutrientes: Proteína ($2.0$ g/kg objetivo), Grasa mínima ($0.8$ g/kg) y balance restante a Carbohidratos.

### 3. `StreakCalculator`
- **Módulo:** `lib/controllers/streak_calculator.dart`
- **Lógica Pura:**
  - `calculateCurrentStreak(List<DateTime> loggedDates): int`: Computa la racha ininterrumpida de días consecutivos con registros válidos sin efectos secundarios ni dependencias externas.

### 4. `JsonRepairHelper`
- **Módulo:** `lib/models/json_repair_helper.dart`
- **Lógica Pura:**
  - `repairTruncatedJson(String jsonString): String`: Algoritmo determinista de balanceo de corchetes `]`, llaves `}` y comillas `"` para rescatar payloads JSON incompletos de la API de IA.

---

## 🌐 Variables de Estado, Configuración y Almacenamiento Seguro

- **Claves Criptográficas en `FlutterSecureStorage` (Hardware Keystore):**
  - `gemini_api_key`: Token de autenticación de Google Gemini API.
  - `usda_api_key`: Token de autenticación de USDA FoodData Central.
  - `gemini_selected_model`: Identificador del modelo preferido por el usuario.
  - `user_master_prompt`: Prompt enriquecido con biometría y preferencias.
  - `daily_goals_json`: Serialización JSON de los objetivos nutricionales diarios.
- **Configuración de Persistencia SQLite v3:**
  - `PRAGMA journal_mode = WAL;`: Concurrencia de lecturas y escrituras sin contención.
  - `PRAGMA synchronous = NORMAL;`: Rendimiento óptimo en I/O sin riesgo de corrupción.
  - `PRAGMA foreign_keys = ON;`: Integridad referencial con eliminación en cascada.

---

## 🔄 Costuras de Flujo de Datos Actualizadas (Data Seams v1.1.0)

### 1. Captura de Foto Zero-Freeze y Pipeline Volumétrico:
```text
[Cámara / Galería]
       │ (imageBytes)
       ▼
AnalysisQueueService.enqueueTask (Estado 0: queued, progress: 0.05, stage: 'Optimizando foto...')
       ├── Disparo inmediato notifyListeners() ──> Dashboard muestra VeLoadingRing instantáneamente
       │
       ▼ (Isolate secundario en background)
ImageProcessingService.compressAndResizeAsync (1024x1024 px, JPEG 85%)
       │
       ▼
GeminiVisionService.analyzeMealImage
       ├── Inyección de Diámetro de Vajilla Calibrada (e.g. "Diámetro plato: 26.0 cm")
       ├── Inyección de Contexto de Despensa Activa (Marcas y productos registrados por usuario)
       └── GeminiResilienceHelper (Reintentos con Backoff + Cascada a modelo fallback)
              │
              ├── ÉXITO:
              │     ▼
              │   MealAnalysisResult.fromJsonString
              │     ▼
              │   Estado: completed -> Notifica UI y actualiza HomeWidgetService
              │
              └── FALLO:
                    ▼
                  Foto física PRESERVADA intacta en disco
                    ▼
                  Estado: failed -> Banner ofrece [Reintentar con IA] o [Editar manualmente]
```

### 2. Sincronización Bidireccional con Widgets Nativos de Android:
```text
[MealController.addMeal / deleteMeal]
       │
       ▼
HomeWidgetService.updateFromDailyTotals(consumed, target)
       │ (SharedPreferences nativo de Android)
       ▼
AppWidgetManager.updateAppWidget(FoodTrackerCompactWidgetProvider & WideWidgetProvider)
       │
       ├── Modo Claro: res/values/colors.xml
       └── Modo Oscuro: res/values-night/colors.xml
```

### 3. Normalización Resiliente de Respaldos y Escalado de Despensa (v1.2.4)

#### Flujo de Importación Resiliente en Isolate:
```text
Usuario pulsa "Importar JSON" -> FilePicker nativo (SAF) selecciona archivo
       │
       ▼
BackupService.importBackupFile(filePath)
       │
       ▼
Isolate.run(() => BackupNormalizer.decodeAndNormalize(jsonString))
       │
       ├── Detección de formato (Map o List)
       ├── Si es List: envuelve en {'meals': list}
       ├── Mapeo de claves legadas:
       │     'comidas'      -> 'meals'
       │     'despensa'     -> 'pantry_items'
       │     'perfil'       -> 'user_profile'
       │     'pesos'        -> 'weight_logs'
       │     'plantillas'   -> 'meal_templates'
       │     'ayuno'        -> 'fasting_logs'
       │     'vajilla'      -> 'calibrated_dishware'
       └── Sanitización de tipos y campos nulos
       │
       ▼ Retorna Map<String, dynamic> normalizado
db.transaction((txn) async {
  final batch = txn.batch();
  // batch.insert(...) para comidas, despensa, etc.
  await batch.commit(noResult: true);
})
       │
       ▼
Refresco reactivo de controladores -> 60 FPS sin stutters en UI
```

#### Modelo y Escalado Proporcional de Despensa:
```text
PantryItem {
  ...
  final double servingSize;        // e.g. 100.0g (porción de referencia)
  final String servingUnit;        // e.g. 'g'
  final double? packageWeight;     // e.g. 500.0g (peso neto empaque)
  ...
  FoodItem toScaledFoodItem({required double gramsConsumed}) {
    final factor = gramsConsumed / (servingSize > 0 ? servingSize : 100.0);
    return FoodItem(
      name: name,
      calories: calories * factor,
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
      grams: gramsConsumed,
      ...
    );
  }
}
```

---

## 🚀 8. Abstracciones de Auto-Actualizador In-App y Microinteracciones (v1.3.0)

### 8.1. Modelo: `GitHubReleaseModel`
Entidad inmutable que representa el release de GitHub obtenido vía REST API.
```dart
@immutable
class GitHubReleaseModel {
  final String tagName;             // e.g. "v1.3.0"
  final String title;               // e.g. "Release v1.3.0"
  final String releaseNotes;        // Markdown del changelog
  final String? apkDownloadUrl;     // URL directa de Victor-Engineer-Food-Tracker-Android.apk
  final int? apkSizeBytes;          // Tamaño en bytes del asset
  final DateTime publishedAt;       // Fecha de publicación
  final String htmlUrl;             // URL web del release en GitHub
}
```

### 8.2. Contrato de Servicio: `IAppUpdateService`
```dart
abstract interface class IAppUpdateService {
  Future<Result<GitHubReleaseModel?, Failure>> checkLatestRelease();
  bool isUpdateAvailable(String currentVersion, String latestTag);
  Future<Result<String, Failure>> downloadApk({
    required String downloadUrl,
    required String destinationFileName,
    void Function(double ratio, int receivedBytes, int totalBytes)? onProgress,
  });
}
```

### 8.3. Contrato de Servicio Instalador: `IAppInstallerService`
```dart
abstract interface class IAppInstallerService {
  Future<Result<bool, Failure>> installApk(String filePath);
  Future<bool> canRequestPackageInstalls();
  Future<void> openInstallPermissionSettings();
  Future<bool> openWebRelease(String url);
}
```

### 8.4. Widgets de Microinteracciones UI
```dart
// VeBounceable: Revestimiento con física elástica de toque (scale: 0.96)
class VeBounceable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor; // default: 0.96
  final Duration duration;  // default: 120ms
  const VeBounceable({super.key, required this.child, this.onTap, this.scaleFactor = 0.96, ...});
}

// VeAnimatedCounter: Transición rodante/fluida para cifras numéricas
class VeAnimatedCounter extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final String Function(num)? formatter;
  final Duration duration; // default: 600ms
  const VeAnimatedCounter({super.key, required this.value, this.style, ...});
}
```

---

## 🧩 9. Descomposición Modular y Submódulos Especializados (< 300 LoC)

Para garantizar la estricta mantenibilidad del monolito modular sin romper compatibilidad previa, se extrajeron los siguientes submódulos atómicos:

### 9.1. Capa de Dominio Metabólico
- **`MacroDistribution` (`lib/models/macro_distribution.dart` - 21 LoC):** Modelo inmutable de reparto de macronutrientes en gramos y calorías derivadas.
- **`MetabolicPromptGenerator` (`lib/services/metabolic_prompt_generator.dart` - 90 LoC):** Síntesis del Master Prompt Markdown para Gemini Vision con formatters clínicos de TDEE y objetivos.
- **`MetabolicCalculator` (`lib/services/metabolic_calculator.dart` - 257 LoC):** Reducido de 450 LoC; conserva exclusivamente la lógica clínica pura de Mifflin-St Jeor, BMR, TDEE, y persistencia/sincronización.

### 9.2. Capa de IA y Catálogo Nutricional
- **`GeminiApiException` (`lib/core/errors/gemini_api_exception.dart` - 16 LoC):** Excepción tipada para respuestas HTTP erróneas de la API de Google Gemini.
- **`GeminiVisionFilter` (`lib/services/gemini_vision_filter.dart` - 127 LoC):** Filtrado estricto multimodal (`isVisionCapableModel`), lista de exclusión de modelos experimentales/banana, fallback models y ranking de recomendación.
- **`GeminiModelService` (`lib/services/gemini_model_service.dart` - 156 LoC):** Reducido de 352 LoC; orquesta consultas remotas y delegación al filtro.
- **`UsdaNutrientParser` (`lib/models/usda_nutrient_parser.dart` - 71 LoC):** Parser de IDs de nutrientes USDA (1008, 1003, 1004, 1005), conversión de kJ a kcal y navegación anidada defensiva.
- **`UsdaFoodItem` (`lib/models/usda_food_item.dart` - 235 LoC):** Reducido de 344 LoC; entidad inmutable de alimentos FDC.

### 9.3. Capa de Presentación y Métricas
- **`QuickWeightAdjusterRow` (`lib/widgets/metrics/quick_weight_adjuster_row.dart` - 51 LoC):** Selector táctil de chips de ajuste rápido (`+/- 0.5`, `+/- 1.0 kg`).
- **`QuickWeightEntryDialog` (`lib/widgets/metrics/quick_weight_entry_dialog.dart` - 218 LoC):** Reducido de 444 LoC.
- **`ActivityLevelOptionTile` (`lib/widgets/profile/activity_level_option_tile.dart` - 78 LoC):** Selector bento de factor de actividad física.
- **`BodyGoalOptionTile` (`lib/widgets/profile/body_goal_option_tile.dart` - 76 LoC):** Selector bento de objetivo metabólico y déficit calórico.
- **`ActivityGoalSelectorCard` (`lib/widgets/profile/activity_goal_selector_card.dart` - 166 LoC):** Reducido de 406 LoC.
- **`WeightChartRenderUtils` (`lib/widgets/metrics/weight_chart_render_utils.dart` - 79 LoC):** Renderizado de estado vacío y punto único en gráfico de peso.
- **`WeightLineChartPainter` (`lib/widgets/metrics/weight_line_chart_painter.dart` - 185 LoC):** Reducido de 342 LoC.

---

## 🧠 10. Abstracciones y Servicios Introducidos en v1.3.1

### 10.1. Pacing Asíncrono de UI (`MealAnalysisPacing`)
- **Ubicación:** `lib/widgets/meal_detail/meal_analysis_pacing.dart` (47 LoC).
- **Función:** Genera una progresión asintótica suave durante la llamada a Gemini Vision distribuida en 5 etapas localizadas:
  - Fase 1 (0% - 20%): Calibración óptica y dimensiones de vajilla (`analysisStageOptimizing`).
  - Fase 2 (20% - 45%): Enlace de red y cifrado con Gemini Vision (`analysisStageConnecting`).
  - Fase 3 (45% - 70%): Geometría 3D y cubicaje volumétrico ($cm^3$) (`analysisStageVolumetric`).
  - Fase 4 (70% - 85%): Densidad física y detección de grasas ocultas (`analysisStageDensities`).
  - Fase 5 (85% - 95%): Desglose nutricional y macronutrientes (`analysisStageMacros`).
  - Completado (100%): Inserción atómica en formulario (`analysisStageComplete`).

### 10.2. Extensión de Localización Desacoplada (`MealTypeLocalization`)
- **Ubicación:** `lib/l10n/domains/app_localizations_meal.dart` (reubicada y exportada por `lib/l10n/app_localizations.dart`).
- **Función:** `String toLocalizedMealType(BuildContext context)` mapea las claves invariantes persistidas en SQLite ('Desayuno', 'Almuerzo', 'Cena', 'Snack', 'Otro') a las cadenas tipadas de `AppLocalizations.of(context)` ('Breakfast', 'Lunch', 'Dinner', 'Snack', 'Other') sin alterar nunca la base de datos relacional.

### 10.3. Inversión Causal de Schema y Prompt en `GeminiResilienceHelper`
- **Ubicación:** `lib/services/gemini_resilience_helper.dart` (292 LoC).
- **Estructura Causal:** Inversión estricta del flujo autorregresivo del LLM. Obliga al token de inferencia a predecir dimensiones físicas tridimensionales, volumen y densidad antes de generar gramos o macronutrientes, eliminando la adivinación previa de masa.

---

## ⚡ 11. Abstracciones y Mejoras de Resiliencia Introducidas en v1.3.2

### 11.1. Streaming Continuo en `GeminiVisionService` contra Desconexiones NAT
- **Ubicación:** `lib/services/gemini_vision_service.dart` (295 LoC).
- **Abstracción de Streaming:**
  ```dart
  // Reemplazo de model.generateContent por flujo streaming acumulativo:
  final stream = model.generateContentStream([
    Content.multi([
      TextPart(effectivePrompt),
      DataPart('image/jpeg', imageBytes),
    ]),
  ]);
  final buffer = StringBuffer();
  await for (final response in stream) {
    if (response.text != null) {
      buffer.write(response.text);
    }
  }
  final responseText = buffer.toString();
  ```
- **Propósito:** Mantener activo el socket TCP/TLS transmitiendo paquetes continuos, evitando desconexiones por inactividad impuestas por NAT gateways móviles (habituales tras 45–80s sin tráfico) durante inferencias complejas de modelos con pensamiento latente.
- **Configuración de Generación:**
  ```dart
  GenerationConfig(
    temperature: 0.2,
    responseMimeType: 'application/json',
    responseSchema: GeminiResilienceHelper.mealAnalysisSchema,
    maxOutputTokens: 16384, // Cupo ampliado para pensamiento latente y JSON completo
  )
  ```
- **Nivel de Pensamiento (Thinking Level):** Configuración estandarizada a `MEDIUM` para `gemini-3.8-flash` y modelos Pro, omitida estrictamente en modelos Lite (`gemini-3.5-flash-lite`) para evitar `HTTP 400 INVALID_ARGUMENT`.

### 11.2. Cascada Moderna y Resiliencia en `GeminiResilienceHelper`
- **Ubicación:** `lib/services/gemini_resilience_helper.dart` (292 LoC).
- **Modelo de Respaldo:** Sustitución del modelo legado por `fallbackModel = 'gemini-2.5-flash'`.
- **Estrategia de Backoff Escalonado:** Reintentos con retardos `[Duration(seconds: 2), Duration(seconds: 5), Duration(seconds: 10)]` y jitter aleatorio de hasta 500 ms.
- **Clasificación de Errores Transitorios (`isRetriableError`):**
  - Detección de códigos HTTP de gateway: 500, 502, 504.
  - Excepciones de bajo nivel de socket: `HttpException`, `HandshakeException`, `SocketException`.
  - Detección de payloads vacíos o terminados abruptamente.

### 11.3. Descargas Resumibles (HTTP 206 & Range) en `AppUpdateService`
- **Ubicación:** `lib/services/app_update_service.dart` (226 LoC).
- **Mecanismo de Reanudación de Descarga:**
  ```dart
  final partFile = File('$destinationPath.part');
  int existingBytes = 0;
  if (await partFile.exists()) {
    existingBytes = await partFile.length();
  }
  final request = http.Request('GET', Uri.parse(downloadUrl));
  if (existingBytes > 0) {
    request.headers['Range'] = 'bytes=$existingBytes-';
  }
  // Detección de statusCode 206 (Partial Content) vs 200 (reinicio completo si servidor ignora Range)
  ```
- **Persistencia Atómica:** Descarga directa a `.part` en modo append (`FileMode.append`) y renombrado atómico `await partFile.rename(destinationPath)` únicamente al completar el 100% de los bytes.

### 11.4. Blindaje y Sanitización de Errores en `InAppUpdateDialog`
- **Ubicación:** `lib/widgets/settings/in_app_update_dialog.dart` (276 LoC).
- **Sanitización de URLs (`_sanitizeErrorMessage`):** Filtra URLs firmadas extensas con regex para evitar saturar la interfaz de usuario con cadenas inacabables de tokens AWS S3/Azure Blob.
- **Manejo de Cancelación:** Control de variable `_isCancelled` con cierre del diálogo y descarte de streams de I/O en progreso.
- **Ergonomía de Renderizado:** Envoltorio `SingleChildScrollView` previniendo overflow vertical en dispositivos con fuentes grandes.

### 11.5. Canónica de Versiones del Sistema (`AppConstants`)
- **Ubicación:** `lib/core/constants/app_constants.dart` (5 LoC).
- **Definición:** `static const String appVersion = '1.3.4';`. Centraliza la versión de referencia consumida por `DashboardScreen`, `AppUpdateCard` y tests unitarios.

---

## 🔬 12. Abstracciones de Autovalidación de la IA (v1.3.3)

### 12.1. Métricas de Autovalidación en Dominio (`MealAnalysisResult` & `Meal`)
- **Ubicación:** `lib/models/meal_analysis_result.dart` (287 LoC) y `lib/models/meal.dart` (295 LoC).
- **Campos Numéricos:**
  - `confidencePercentage`: `int?` (0–100) derivado de `porcentaje_certeza` / `confidence_percentage` en JSON.
  - `calorieErrorMargin`: `int?` (0–2000) derivado de `margen_error_kcal` / `calorie_error_margin` en JSON (+/- kcal).
- **Resiliencia de Parsing:** Soporte tolerante a fallos para strings decimales (e.g. `"45.5 kcal"`, `"92.4%"`) mediante `double.tryParse` y `.round()`, acotamiento clamped y sanitización de markdown code fences en `aiBreakdownJson`.
- **Inmutabilidad en Edición:** `Meal.recalculateFromItems` preserva fielmente `confidencePercentage` y `calorieErrorMargin` cuando el usuario añade, edita o elimina ingredientes.

### 12.2. Descompositor Modular de Alimentos (`MealDecomposer`)
- **Ubicación:** `lib/models/meal_decomposer.dart` (114 LoC).
- **Responsabilidad:** Extraído de `MealAnalysisResult` para satisfacer estrictamente el estándar arquitectónico `< 300 LoC`.
- **Métodos Nucleares:**
  - `extractComponents(String text)`: Segmentación textual inteligente separando conjunciones (`y`, `con`, `,`).
  - `isSeasoningOrHerb(String name)`: Detección defensiva de hierbas/especias para proteger asignación macro.
  - `decomposeCompositeFood(...)`: Desglose volumétrico proporcional de platos compuestos asignando densidades físicas reales.

### 12.3. Componente Visual de Autovalidación (`MealAiValidationChips`)
- **Ubicación:** `lib/widgets/meal_detail/meal_ai_validation_chips.dart` (97 LoC).
- **Chips Visuales Desplegados:**
  - **Chip de Certeza:** Muestra `"$confidencePercentage% Certeza"` con icono `Icons.verified_outlined`. Color semántico reactivo: `AppColors.success` (verde) si $\ge 85\%$, `AppColors.carbs` (amarillo/ámbar) si $\ge 70\%$, o `AppColors.caloriesFlame` (naranja) si $< 70\%$.
  - **Chip de Margen de Error:** Muestra `"±$calorieErrorMargin kcal"` con icono `Icons.tune` y color `AppColors.portion`.
- **Alineación con el Usuario:** Ausencia total de etiquetas cualitativas subjetivas (sin "nivel") y sin caja de observaciones, manteniendo la interfaz despejada y concisa.

---

## ⚡ 13. Abstracciones de Inferencia 16k, Thinking Level MEDIUM y Pacing Fluido (v1.3.4)

### 13.1. Calibración de Inteligencia en Modelos (`GeminiModelService` & `GeminiVisionService`)
- **Ubicación:** `lib/services/gemini_model_service.dart` (185 LoC) y `lib/services/gemini_vision_service.dart` (270 LoC).
- **Constantes y Resolutores:**
  - `defaultThinkingLevel = 'MEDIUM'`.
  - `resolveThinkingLevel(modelName)`: Retorna `'MEDIUM'` para Gemini 3 y variantes Pro; `null` para Lite o modelos no reasoning.
  - `buildCallConfig`: Facade canónico que inyecta `thinking_level` y `thinking_config: {'thinking_level': level}` para modelos con soporte, y omite terminantemente cualquier bloque de pensamiento en variantes Lite (`gemini-3.5-flash-lite`) erradicando el error `HTTP 400 INVALID_ARGUMENT`.
- **Ventana de Generación:** `maxOutputTokens: 16384` en `GenerationConfig`, garantizando holgura completa para pensamiento latente y estructuración JSON sin riesgo de `finishReason: MAX_TOKENS`.

### 13.2. Pacing Continuo en Memoria a 60 FPS (`AnalysisQueueService` & `AnalysisProgressBanner`)
- **Ubicación:** `lib/services/analysis_queue_service.dart` (251 LoC) y `lib/widgets/dashboard/analysis_progress_banner.dart` (271 LoC).
- **Patrón Cero Contención SQLite:**
  - Durante `analyzeMealPhoto`, un `Timer.periodic(const Duration(milliseconds: 500))` en memoria incrementa suavemente el progreso de 0.45 a 0.90 con `MealAnalysisPacing.nextProgress(task.progress)`.
  - Notifica a la interfaz gráfica vía `notifyListeners()` asegurando 60 FPS continuos sin escrituras a disco SQLite en cada tick.
  - Cancelación determinista y segura en cláusula `finally { pacingTimer?.cancel(); }`.
- **Resolución Reactiva de Etapa:** `AnalysisProgressBanner._resolveStageMessage` delega en `MealAnalysisPacing.getStageMessage(task.progress, l10n)` únicamente cuando la tarea se encuentra activamente en estado `AnalysisStatus.processing`, respetando fielmente los textos de estado predeterminados (`En cola`, `En cola para reintento...`) para tareas en espera.

---

## 🌐 14. Abstracciones de Localización Modular 100% Pure Dart y Cero Fallbacks (v1.4.1)

### 14.1. Segregación de Interfaces por Dominio (`lib/l10n/domains/`)
- **Arquitectura de Herencia Encadenada:**
  - `AppLocalizationsCore`: Cadenas transversales y de sistema (`appTitle`, `save`, `cancel`, `errorGeneric`, `networkError`, etc.).
  - `AppLocalizationsDashboard extends AppLocalizationsCore`: Métricas de dashboard, fab menu, ayuno, widgets Bento.
  - `AppLocalizationsMeal extends AppLocalizationsDashboard`: Detalle de comidas, ingredientes, porciones, tags de validación IA. Contiene además la extensión `MealTypeLocalization`.
  - `AppLocalizationsMetrics extends AppLocalizationsMeal`: Estadísticas, gráficos de peso, balances semanales y promedios diarios.
  - `AppLocalizationsProfile extends AppLocalizationsMetrics`: Onboarding, fórmulas BMR/TDEE, perfil antropométrico y metas de actividad.
  - `AppLocalizationsSettings extends AppLocalizationsProfile`: Ajustes, modelos Gemini, almacenamiento de fotos, backups JSON y mantenimiento SQLite.

### 14.2. Fachada Unificada y Delegados (`lib/l10n/app_localizations.dart`)
- **Firma:** `abstract class AppLocalizations extends AppLocalizationsSettings`
- **Accesor Canónico:**
  ```dart
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizationsEs();
  }
  ```
  Garantiza retorno tipado **no-nulable** con fallback interno seguro a `AppLocalizationsEs` sin ensuciar la capa de UI.
- **Exportaciones Unificadas:** Exporta los contratos de los 6 dominios, los agregadores de idioma y la extensión `MealTypeLocalization`, sirviendo como Single Source of Truth para todas las pantallas, widgets y tests del proyecto.

### 14.3. Implementaciones Concretas por Idioma (`lib/l10n/es/` y `lib/l10n/en/`)
- Módulos concretos por dominio (`app_localizations_es_core.dart`, `app_localizations_en_core.dart`, etc.) implementando el 100% de getters y métodos sin discrepancias de firma.
- Clases agregadoras `AppLocalizationsEs` y `AppLocalizationsEn` cumpliendo estrictamente con `< 300 LoC` por archivo.

### 14.4. Extensión Contextual de Tipos de Comida (`MealTypeLocalization`)
- **Ubicación:** `lib/l10n/domains/app_localizations_meal.dart`.
- **Implementación:** `String toLocalizedMealType(BuildContext context)` mapea transparentemente las claves invariantes persistidas en SQLite (`'Desayuno'`, `'Almuerzo'`, `'Cena'`, `'Snack'`, `'Otro'`) al idioma activo en la UI sin modificar los registros en disco.





