---
tipo: abstracciones
proyecto: App_Food_Tracker
version: v1.0.4
estado: activo
fecha: 2026-09-13
tags: [proyecto, arquitectura, abstracciones, backend, v1-0-4]
---

# Abstracciones del Sistema y Arquitectura de Código: Victor Engineer - Food Tracker

> **Mesa de Control & Backend-Architect:** Este documento centraliza las clases maestras, interfaces de dominio, servicios de negocio, funciones utilitarias nucleares, variables de estado seguro y costuras de flujo de datos (data seams) de la aplicación **Victor Engineer - Food Tracker**. Complementa conceptualmente a [[PRJ_App_Food_Tracker_api_spec|Especificación de API y Modelos]] para posibilitar el entendimiento exhaustivo del software sin necesidad de inspeccionar línea por línea el código fuente.

---

## 🏛️ Filosofía de Diseño y Paradigmas de Código

1. **Local-First Determinista & Resiliencia Offline:**
   - Todo el estado transaccional (comidas, despensa, registros de peso, metas calóricas y perfil metabólico) reside localmente en **SQLite v2** optimizado en modo WAL (`PRAGMA journal_mode = WAL;`, `PRAGMA synchronous = NORMAL;`, `PRAGMA foreign_keys = ON;`).
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

---

## 🧩 Módulos y Capas del Sistema

```text
lib/
├── controllers/          # Controladores de Estado Reactivo con Inyección por Constructor
│   ├── meal_controller.dart
│   ├── settings_controller.dart
│   └── streak_calculator.dart
├── core/                 # Infraestructura Transversal y Contratos
│   ├── di/
│   │   └── service_locator.dart
│   ├── errors/
│   │   ├── failures.dart
│   │   └── result.dart
│   └── interfaces/
│       ├── daos_interfaces.dart
│       ├── database_service_interface.dart
│       └── image_processing_service_interface.dart
├── l10n/                 # Localización e Internacionalización Multi-idioma
│   ├── app_en.arb
│   ├── app_es.arb
│   ├── app_localizations.dart
│   ├── app_localizations_en.dart
│   └── app_localizations_es.dart
├── models/               # Modelos de Dominio Inmutables & Sanitizadores
│   ├── daily_goals.dart
│   ├── food_item.dart
│   ├── gemini_model_info.dart
│   ├── json_repair_helper.dart
│   ├── meal.dart
│   ├── meal_analysis_result.dart
│   ├── meal_image_file_info.dart
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
│   │   ├── meal_dao.dart
│   │   ├── pantry_dao.dart
│   │   ├── user_profile_dao.dart
│   │   └── weight_log_dao.dart
│   ├── database_service.dart
│   ├── gemini_model_service.dart
│   ├── gemini_vision_service.dart
│   ├── image_processing_service.dart
│   ├── meal_image_file_namer.dart
│   ├── meal_image_storage_resolver.dart
│   ├── metabolic_calculator.dart
│   ├── open_food_facts_service.dart
│   ├── secure_storage_service.dart
│   ├── theme_manager.dart
│   └── usda_food_data_service.dart
└── widgets/              # Componentes de UI Atómicos y Modulares (<300 LoC)
    ├── common/           # VeLoadingRing, VeAppBar, VeCard, VeLogo...
    ├── dashboard/        # AnalysisProgressBanner, DailyCalorieSummary...
    ├── meal_detail/      # MealImageCard con overlay de análisis...
    ├── metrics/
    ├── profile/
    └── settings/
```

---

## 📐 Interfaces y Contratos de Dominio

### `ModelSanitizer`
- **Ubicación:** `lib/models/model_sanitizer.dart`
- **Propósito:** Contrato utilitario puro de sanitización defensiva transversal aplicado en constructores de deserialización `fromJson` y `fromSqliteMap`.
- **Firmas:**
  - `truncate(String? value, int maxLength, {String fallback = ''}): String`
  - `truncateNullable(String? value, int maxLength): String?`
  - `clampDouble(dynamic value, {double min = 0.0, double max = 9999.0}): double`
  - `parseDate(dynamic value, {DateTime? fallback}): DateTime`
  - `formatIsoDate(DateTime? date): String`

### `JsonRepairHelper`
- **Ubicación:** `lib/models/json_repair_helper.dart`
- **Propósito:** Algoritmo utilitario de recuperación resiliente de payloads JSON truncados emitidos por Gemini Vision mediante balanceo de pila (stack) de comillas, corchetes y llaves.
- **Firmas:**
  - `repairJson(String jsonStr): String`

### `MacroDistribution`
- **Ubicación:** `lib/services/metabolic_calculator.dart`
- **Propósito:** Objeto de valor inmutable representativo del reparto calórico y de macronutrientes en gramos calculado clínicamente.
- **Campos:** `protein` (double), `carbs` (double), `fat` (double).
- **Getters Computados:** `proteinCalories`, `carbsCalories`, `fatCalories`, `totalCalories`.

### `MealAnalysisResult`
- **Ubicación:** `lib/models/meal_analysis_result.dart` (re-exportado en `lib/services/gemini_vision_service.dart`)
- **Propósito:** DTO inmutable resultante del análisis volumétrico y nutricional generado por el motor de visión IA multimodal. Incorpora descomposición automática inteligente de platos compuestos en ingredientes individuales independientes, protección de hierbas/especias (`isSeasoningOrHerb`) y recuperación resiliente con `JsonRepairHelper`.
- **Campos:** `dishName` (String), `items` (List<FoodItem>), `totalCalories` (double), `totalProtein` (double), `totalCarbs` (double), `totalFat` (double), `rawJson` (String).
- **Métodos Clave:** `extractComponents(String text): List<String>`, `decomposeCompositeFood(...): List<FoodItem>`, `fromJsonString(String jsonStr): MealAnalysisResult`.

### `BarcodeLookupResult`
- **Ubicación:** `lib/services/barcode_lookup_service.dart`
- **Propósito:** DTO que encapsula el alimento resuelto por escaneo de código de barras junto con la fuente exacta de procedencia en la cascada.
- **Campos:** `item` (PantryItem), `source` (`BarcodeSource.usda` | `BarcodeSource.openFoodFacts`).

---

## ⚙️ Clases Núcleo y Servicios de Negocio

### 1. `DatabaseService` (Singleton)
- **Ubicación:** `lib/services/database_service.dart`
- **Responsabilidad:** Gestión del ciclo de vida de la base de datos SQLite v2, configuración de pragmas de alto rendimiento (`WAL`, `NORMAL`, `foreign_keys`), ejecución de migraciones deterministas y operaciones CRUD transaccionales.
- **Métodos Clave:**
  - `init(): Future<void>`: Inicialización perezosa protegida contra carreras concurrentes mediante `_initFuture`.
  - `insertMeal(Meal meal) / updateMeal(Meal meal) / upsertMeal(Meal meal) / deleteMeal(String id): Future<int>`: Garantiza la persistencia atómica mediante `ConflictAlgorithm.replace`.
  - `getMealsForDay(DateTime day) / getAllMeals(): Future<List<Meal>>`
  - `getMealsByRange(DateTime start, DateTime end): Future<List<Meal>>`: Consulta comidas indexadas por `idx_meals_date` en un intervalo temporal específico para alimentar métricas sin sobrecargar RAM.
  - `getMealByImagePath(String imagePath): Future<Meal?>`: Resuelve la comida asociada a una ruta de imagen en disco.
  - `clearMealImagePath(String mealId): Future<int>`: Desvincula la imagen borrada del registro SQLite (`image_path = null`) durante la depuración de almacenamiento.
  - `getMealsOlderThanWithImages(DateTime cutoffDate): Future<List<Meal>>`: Consulta comidas previas a la fecha de corte que conservan imagen en disco.
  - `insertPantryItem(PantryItem item) / updatePantryItem(PantryItem item) / deletePantryItem(String id): Future<int>`
  - `insertWeightLog(WeightLog log) / getWeightLogsByRange(DateTime start, DateTime end) / getAllWeightLogs(): Future<List<WeightLog>>`: `getAllWeightLogs()` recupera todos los registros ordenados cronológicamente por `date ASC`.
  - `saveUserProfile(UserProfile profile) / getUserProfile(): Future<UserProfile?>`
  - `batchUpsertWeightLogs(List<WeightLog> logs): Future<void>`

### 2. `GeminiVisionService`
- **Ubicación:** `lib/services/gemini_vision_service.dart`
- **Responsabilidad:** Orquestación de inferencia multimodal visual utilizando Google Generative AI SDK, inyección del Master Prompt biométrico, schema estructurado JSON forzado (`responseSchema`), timeout defensivo de 35 segundos y traducción defensiva de errores amigables al usuario.
- **Dependencias:** `ImageProcessingService`, `ModelSanitizer`.
- **Métodos Clave:**
  - `userFriendlyErrorMessage(dynamic error): String`: Mapea excepciones técnicas (SocketException, 401/403, 429 cuota, fallos de detección/seguridad) a mensajes claros y accionables en español.
  - `analyzeMealPhoto({required Uint8List rawImageBytes, ...}) / analyzeMealImage(Uint8List imageBytes, ...): Future<MealAnalysisResult>`:
    1. Decodifica dimensiones y omite recompresión si ancho y alto ya son <= 1024 px; de lo contrario comprime en Isolate asíncrono.
    2. Construye el modelo `GenerativeModel` con temperatura baja (`0.2`) y esquema estructurado.
    3. Concatena la instrucción clínica del sistema, el Master Prompt del usuario y las notas contextuales opcionales.
    4. Ejecuta `generateContent` con timeout defensivo de 35s (`.timeout(Duration(seconds: 35))`), capturando excepciones y envolviéndolas mediante `userFriendlyErrorMessage`.

### 3. `GeminiModelService`
- **Ubicación:** `lib/services/gemini_model_service.dart`
- **Responsabilidad:** Introspección en vivo de modelos multimodales reales mediante llamada HTTP a `GET https://generativelanguage.googleapis.com/v1beta/models`, filtrado estricto por soporte multimodal y fallback offline curado.
- **Métodos Clave:**
  - `fetchAvailableModels(String apiKey, {Duration timeout}): Future<List<GeminiModelInfo>>`
  - `parseModelsResponse(String responseBody): List<GeminiModelInfo>`
  - `isVisionCapableModel(Map<String, dynamic> model): bool`: Filtro estricto que exige 'gemini', presencia de 'flash' o 'pro', soporte de 'generateContent', y exclusión de lista negra (`banana`, `nano`, `transcribe`, `omni`, `computer-use`, `robotics`, `live`, `custom`, `preview-10-2025`, `embedding`, `imagen`, `tts`, `audio`, `veo`, `bison`).
  - `_fallbackModels / fallbackModels`: Modelos canónicos de producción (`gemini-2.5-flash`, `gemini-1.5-flash`, `gemini-1.5-pro`, `gemini-2.0-flash`).

### 4. `UsdaFoodDataService`
- **Ubicación:** `lib/services/usda_food_data_service.dart`
- **Responsabilidad:** Cliente HTTP para la API oficial de USDA FoodData Central (`api.nal.usda.gov/fdc/v1`).
- **Capacidades Defensivas:**
  - Ventana deslizante de limitación de tasa (1.000 solicitudes/hora) y lectura defensiva de headers `x-ratelimit-remaining`.
  - Coincidencia exacta de GTIN mediante normalización de 14 dígitos (`padLeft(14, '0')`) y fallback limpio retornando `null` para activar delegación transparente a Open Food Facts.
  - Normalización energética de kilojulios a kilocalorías ($kJ \rightarrow kcal$ factor 4.184).
  - Manejo de excepciones tipadas: `UsdaRateLimitException`, `UsdaAuthenticationException`.
- **Métodos Clave:**
  - `searchFoodsByQuery(String query, {int pageSize = 10, String? apiKey}): Future<List<UsdaFoodItem>>`
  - `searchByGtinUpc(String gtinUpc, {String? apiKey}): Future<PantryItem?>`

### 5. `BarcodeLookupService`
- **Ubicación:** `lib/services/barcode_lookup_service.dart`
- **Responsabilidad:** Implementación del motor en cascada de códigos de barras: consulta primero USDA FoodData Central si la clave de API está presente; si retorna nulo o falla, conmuta automáticamente a Open Food Facts API v2.
- **Métodos Clave:**
  - `lookup(String barcode): Future<BarcodeLookupResult?>`

### 6. `MetabolicCalculator`
- **Ubicación:** `lib/services/metabolic_calculator.dart`
- **Responsabilidad:** Motor de cálculo clínico biométrico implementando la ecuación internacional **Mifflin-St Jeor**, cálculo de TMB, TDEE por nivel de actividad y pasos diarios, ajuste por objetivos corporales y síntesis del Master Prompt.
- **Métodos Clave:**
  - `calculateBmr({required String gender, required double weightKg, required double heightCm, required int age}): double`
  - `calculateTdee({required double bmr, required String activityLevel}): double`
  - `calculateCaloricGoal({required double tdee, required double bmr, required String bodyGoal}): double`
  - `calculateMacros({required double targetCalories, required double weightKg, required String bodyGoal, double? heightCm, String? gender}): MacroDistribution`: Aplica la fórmula de Peso Corporal Ajustado ($ABW = IBW + 0.4 \times (TBW - IBW)$) cuando el IMC $\ge 30$, protegiendo contra la sobreestimación proteica en obesidad.
  - `generateMasterPrompt(UserProfile profile): String`
  - `calculateProfile(...): UserProfile`
  - `saveAndSynchronizeProfile(UserProfile profile): Future<UserProfile>`: Persiste en SQLite, sincroniza DailyGoals y Master Prompt en SecureStorage, actualiza reactivamente `MealController` y sincroniza en memoria `SettingsController`.
  - `calculateAndSaveProfile(...): Future<UserProfile>`

### 7. `AnalysisQueueService` (Singleton)
- **Ubicación:** `lib/services/analysis_queue_service.dart`
- **Responsabilidad:** Motor asíncrono no bloqueante con persistencia en SQLite (`analysis_queue`) para desacoplar el procesamiento fotográfico del hilo de la UI.
- **Métodos Clave:**
  - `init(): Future<void>`: Carga y recupera tareas pendientes, deduplicando contra comidas ya persistidas en SQLite.
  - `enqueueTask(String imagePath, {String? mealType, String? notes, DateTime? targetDate}): Future<AnalysisTask>`
  - `retryTask(String taskId): Future<void>`: Reintenta tareas fallidas restableciendo su estado sin perder los datos originales.
  - `purgeCompletedTasks(): Future<void>`

### 8. `SecureStorageService` (Singleton)
- **Ubicación:** `lib/services/secure_storage_service.dart`
- **Responsabilidad:** Almacenamiento seguro en hardware cifrado para credenciales BYOK y tokens sensibles.
- **Métodos Clave:**
  - `getGeminiApiKey() / setGeminiApiKey(String key) / deleteGeminiApiKey(): Future<void>`
  - `getUsdaApiKey() / setUsdaApiKey(String key) / deleteUsdaApiKey(): Future<void>`
  - `getSelectedGeminiModel() / setSelectedGeminiModel(String model): Future<void>`
  - `getMasterPrompt() / setMasterPrompt(String prompt): Future<void>`
  - `getDailyGoals() / setDailyGoals(DailyGoals goals): Future<void>`
  - `hasCompletedOnboarding() / setCompletedOnboarding(bool completed): Future<void>`

### 9. `BackupService`
- **Ubicación:** `lib/services/backup_service.dart`
- **Responsabilidad:** Exportación e importación atómica de copias de seguridad en formato JSON v2 estructurado dentro de transacciones SQLite.
- **Métodos Clave:**
  - `exportToJsonString(): Future<String>`
  - `importFromJsonString(String jsonContent): Future<Map<String, int>>`

### 10. `ImageProcessingService`
- **Ubicación:** `lib/services/image_processing_service.dart`
- **Responsabilidad:** Compresión y redimensionamiento defensivo de fotografías de platos (máximo 1024x1024 px, JPEG 85%), gestión del almacenamiento en la carpeta pública visible del usuario con cascada de fallbacks, y compresión asíncrona en Isolate secundario para mantener 60 FPS en UI.
- **Métodos Clave:**
  - `compressAndResize(Uint8List rawBytes, {int targetMaxDimension = 1024, int quality = 85}): Uint8List`
  - `compressAndResizeAsync(Uint8List rawBytes, {int targetMaxDimension = 1024, int quality = 85}): Future<Uint8List>`: Ejecuta la compresión en `Isolate.run`.
  - `saveMealImage(Uint8List imageBytes, ...): Future<String>`
  - `generateMealImageFileName(...): Future<String>`
  - `pruneOldMealPhotos({required int retentionDays}): Future<int>`
  - `deleteMealImage(String? filePath): Future<void>`

### 11. `ThemeManager`
- **Ubicación:** `lib/services/theme_manager.dart`
- **Responsabilidad:** Gestión reactiva del modo de visualización (`ThemeMode.light`, `ThemeMode.dark`, `ThemeMode.system`) persistido en `SharedPreferences`.

---

## 🛠️ Funciones Críticas y Lógica Pura

| Función | Módulo | Entradas | Salida / Comportamiento |
| :--- | :--- | :--- | :--- |
| `clampDouble` | `models/model_sanitizer.dart` | `dynamic value`, `min: 0.0`, `max: 9999.0` | `double` truncado a 2 decimales, protegido contra `null`, `NaN` y valores fuera de rango. |
| `truncate` | `models/model_sanitizer.dart` | `String? value`, `int maxLength`, `fallback` | `String` acotada a longitud máxima sin desbordar memoria. |
| `parseDate` | `models/model_sanitizer.dart` | `dynamic value`, `DateTime? fallback` | `DateTime` válido; si el formato falla, retorna el fallback seguro. |
| `calculateBmr` | `services/metabolic_calculator.dart` | `gender`, `weightKg`, `heightCm`, `age` | `double` (kcal/día) según Mifflin-St Jeor ($10W + 6.25H - 5A + s$). |
| `calculateTdee` | `services/metabolic_calculator.dart` | `bmr`, `activityLevel` | `double` (kcal/día) multiplicando por factores (1.2, 1.375, 1.55, 1.725). |
| `calculateCaloricGoal` | `services/metabolic_calculator.dart` | `tdee`, `bmr`, `bodyGoal` | `double` (kcal/día): Déficit (-500 kcal piso en BMR), Mantenimiento (TDEE) o Superávit (+300 kcal). |
| `calculateMacros` | `services/metabolic_calculator.dart` | `targetCalories`, `weightKg`, `bodyGoal` | `MacroDistribution` (Proteína por kg, Grasa al 25% mín 0.8g/kg, Carbohidratos remanentes). |
| `generateMasterPrompt` | `services/metabolic_calculator.dart` | `UserProfile` | `String` estructurada en Markdown con biometría y pautas clínicas para inyección en Gemini. |

---

## 🌐 Variables de Estado, Constantes Globales y Configuración

### Claves de Hardware Seguro (`FlutterSecureStorage`):
- `gemini_api_key`: Clave privada de API para Google Generative AI SDK.
- `gemini_selected_model`: Nombre del modelo seleccionado (e.g., `gemini-2.5-flash`, `gemini-1.5-pro`).
- `usda_api_key`: Clave privada de API para USDA FoodData Central.
- `has_completed_onboarding`: Booleano en String (`true`/`false`) que rige la ruta inicial de la aplicación.
- `user_master_prompt`: Markdown compilado con el contexto metabólico inyectado a la visión IA.
- `daily_goals_json`: Serialización JSON de los objetivos diarios de calorías y macros.

### Constantes Globales de Operación:
- `ModelSanitizer.maxNameLength`: `255`
- `ModelSanitizer.maxNotesLength`: `2000`
- `ModelSanitizer.maxJsonLength`: `100000`
- `UsdaFoodDataService.maxRequestsPerHour`: `1000`
- `ImageProcessingService.maxDimension`: `1024`
- `ImageProcessingService.jpegQuality`: `85`
- `DatabaseService.version`: `2`

---

## 🔄 Costuras de Flujo de Datos (Data Seams)

### 1. Inferencia Volumétrica de Visión IA:
```text
[Cámara / Galería]
       │ (Uint8List)
       ▼
ImageProcessingService.compressAndResize (1024x1024 px, JPEG 85%)
       │
       ▼
GeminiVisionService.analyzeMealImage
   ├── Inyección de Master Prompt (desde UserProfile / SecureStorage)
   ├── Inyección de Notas Contextuales del Usuario
   └── Forzado de Schema Estructurado JSON (responseSchema)
       │ (HTTP POST generativelanguage.googleapis.com)
       ▼
MealAnalysisResult.fromJsonString
       │ (Desglose de alimentos + totales clampDouble)
       ▼
MealDetailScreen (Revisión interactiva y edición por el usuario)
       │
       ▼
MealController.upsertMeal -> DatabaseService.upsertMeal (SQLite WAL v2)
```

### 2. Cascada de Escaneo de Códigos de Barras:
```text
[Lector de Código de Barras] (UPC / EAN)
       │
       ▼
BarcodeLookupService.lookup(barcode)
       │
       ├── ¿Existe USDA API Key configurada?
       │     ├── SÍ ──> UsdaFoodDataService.searchByGtinUpc(barcode)
       │     │            │
       │     │            ├── Éxito: Retorna BarcodeLookupResult(source: usda)
       │     │            └── Fallo / Null: Salta al fallback
       │     └── NO ──> Salta directo al fallback
       │
       └── Fallback Automático: OpenFoodFactsService.lookupBarcode(barcode)
             │
             ├── Éxito: Retorna BarcodeLookupResult(source: openFoodFacts)
             └── Fallo: Retorna null (Producto no encontrado)
```

### 3. Onboarding Clínico y Calibración Metabólica:
```text
[UserProfileScreen] (Edad, Género, Estatura, Peso, Actividad, Meta)
       │
       ▼
MetabolicCalculator.calculateProfile
   ├── calculateBmr (Mifflin-St Jeor)
   ├── calculateTdee (Multiplicador de actividad + pasos)
   ├── calculateCaloricGoal (Déficit / Mantenimiento / Superávit)
   ├── calculateMacros (Proteína g/kg + Grasa 25% + Carbos)
   └── generateMasterPrompt (Markdown de contexto clínico)
       │
       ├── DatabaseService.saveUserProfile (Persistencia SQLite v2)
       ├── SecureStorageService.setMasterPrompt (Custodia para IA)
       └── MealController.updateGoals (Sincronización reactiva del Dashboard)
```

---

## 🏛️ Nuevas Abstracciones de Arquitectura (v1.0.4)

### 1. Inyección de Dependencias y Service Locator (`lib/core/di/service_locator.dart`)
- **`GetIt getIt`**: Instancia central del Service Locator para desacoplar implementaciones concretas de sus contratos.
- **`setupServiceLocator({bool isTesting = false})`**: Registra `IDatabaseService`, `IImageProcessingService`, DAOs (`IMealDao`, `IWeightLogDao`, etc.), controladores y fábrica parametrizada de `GeminiVisionService`.
- **`resetServiceLocator()`**: Limpia los registros para garantizar aislamiento total entre pruebas unitarias.

### 2. Manejo Funcional de Errores: Patrón Result / Either (`lib/core/errors/`)
- **`Result<T, E extends Failure>`**: Tipo suma sellado (`sealed class`) en Dart 3 con subtipos `Success<T, E>` y `FailureResult<T, E>`.
- **Métodos Funcionales**: `fold(onSuccess, onFailure)`, `map(fn)`, `flatMap(fn)`, `mapError(fn)`, `getOrThrow()`, `getOrDefault(def)`.
- **Captura Segura**: `Result.guard(() => syncCode)` y `Result.guardAsync(() => asyncCode)` capturan excepciones y las transforman en fallos de dominio.
- **Jerarquía `Failure`**: `DatabaseFailure`, `AiServiceFailure`, `NetworkFailure`, `ValidationFailure`, `StorageFailure`, `ImageProcessingFailure`, `UnknownFailure`.
- **Delegaciones de Dominio**: `IDatabaseService` y `DatabaseService` exponen directamente métodos Result (`upsertMealResult`, `getMealByIdResult`, etc.) delegando a los DAOs especializados.

### 3. Capa de DAOs Especializados (`lib/services/daos/`)
- **`MealDao`**: Manejo de persistencia de comidas y alimentos asociados (`meal_items`).
- **`WeightLogDao`**: Control de registros de peso corporal, time-series e inserciones por lote (`batchUpsertWeightLogs`).
- **`UserProfileDao`**: Gestión de perfil de usuario, biometría y metas calóricas.
- **`PantryDao`**: Catálogo de despensa y favoritos.
- **`DatabaseConnectionFactory`**: Resuelve la ruta SQLite dependiente de plataforma, inicializa WAL y pragmas de integridad.
- **`DatabaseSchema`**: DDL centralizado de tablas, índices B-Tree y migraciones de versión.

### 4. Capa de Nomenclatura y Almacenamiento de Fotos (`lib/services/`)
- **`MealImageFileNamer`**: Estandarización de nombres de fotos `YYYY_MM_DD_{TYPE}_{INDEX}.jpg`, mapeo de códigos, parseo regex e inferencia por hora del día.
- **`MealImageStorageResolver`**: Resolución en cascada de directorios de almacenamiento en Android y plataformas de escritorio con anti-colisión determinista.

### 5. Localización e Internacionalización (`lib/l10n/`)
- **`AppLocalizations`**: Contrato tipado de textos multi-idioma (`app_es.arb` y `app_en.arb`) con delegados `localizationsDelegates` integrados en `NutriTrackerApp`.
- **`localeResolutionCallback`**: Algoritmo de resolución defensivo que respeta idiomas soportados y redirige de forma segura a español en caso de idiomas no soportados sin lanzar `FlutterError`.
- **Desacoplamiento de Widgets**: Extracción de textos a `AppLocalizations.of(context)` en componentes clave (`OnboardingBottomNav`, `QuickMealDialog`).
