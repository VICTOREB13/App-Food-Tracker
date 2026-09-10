---
tipo: abstracciones
proyecto: App_Food_Tracker
version: v0.4.0-alpha
estado: activo
fecha: 2026-09-10
tags: [proyecto, arquitectura, abstracciones, backend]
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
├── controllers/          # Controladores de Estado Reactivo (ChangeNotifier)
│   ├── meal_controller.dart
│   └── settings_controller.dart
├── models/               # Modelos de Dominio Inmutables & Sanitizadores
│   ├── daily_goals.dart
│   ├── food_item.dart
│   ├── gemini_model_info.dart
│   ├── meal.dart
│   ├── model_sanitizer.dart
│   ├── pantry_item.dart
│   ├── usda_food_item.dart
│   ├── user_profile.dart
│   └── weight_log.dart
├── services/             # Servicios de Negocio, Clientes API y Persistencia
│   ├── backup_service.dart
│   ├── barcode_lookup_service.dart
│   ├── database_service.dart
│   ├── gemini_model_service.dart
│   ├── gemini_vision_service.dart
│   ├── image_processing_service.dart
│   ├── metabolic_calculator.dart
│   ├── open_food_facts_service.dart
│   ├── secure_storage_service.dart
│   ├── theme_manager.dart
│   └── usda_food_data_service.dart
└── widgets/              # Componentes de UI Atómicos y Modulares
    ├── common/
    ├── dashboard/
    ├── meal_detail/
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

### `MacroDistribution`
- **Ubicación:** `lib/services/metabolic_calculator.dart`
- **Propósito:** Objeto de valor inmutable representativo del reparto calórico y de macronutrientes en gramos calculado clínicamente.
- **Campos:** `protein` (double), `carbs` (double), `fat` (double).
- **Getters Computados:** `proteinCalories`, `carbsCalories`, `fatCalories`, `totalCalories`.

### `MealAnalysisResult`
- **Ubicación:** `lib/services/gemini_vision_service.dart`
- **Propósito:** DTO inmutable resultante del análisis volumétrico y nutricional generado por el motor de visión IA multimodal.
- **Campos:** `dishName` (String), `items` (List<FoodItem>), `totalCalories` (double), `totalProtein` (double), `totalCarbs` (double), `totalFat` (double), `rawJson` (String).

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
  - `clearMealImagePath(String mealId): Future<int>`: Desvincula la imagen borrada del registro SQLite (`image_path = null`) durante la depuración de almacenamiento.
  - `getMealsOlderThanWithImages(DateTime cutoffDate): Future<List<Meal>>`: Consulta comidas previas a la fecha de corte que conservan imagen en disco.
  - `insertPantryItem(PantryItem item) / updatePantryItem(PantryItem item) / deletePantryItem(String id): Future<int>`
  - `insertWeightLog(WeightLog log) / getWeightLogsByRange(DateTime start, DateTime end) / getAllWeightLogs(): Future<List<WeightLog>>`: `getAllWeightLogs()` recupera todos los registros ordenados cronológicamente por `date ASC`.
  - `saveUserProfile(UserProfile profile) / getUserProfile(): Future<UserProfile?>`
  - `batchUpsertWeightLogs(List<WeightLog> logs): Future<void>`

### 2. `GeminiVisionService`
- **Ubicación:** `lib/services/gemini_vision_service.dart`
- **Responsabilidad:** Orquestación de inferencia multimodal visual utilizando Google Generative AI SDK, inyección del Master Prompt biométrico, schema estructurado JSON forzado (`responseSchema`) y traducción defensiva de errores amigables al usuario.
- **Dependencias:** `ImageProcessingService`, `ModelSanitizer`.
- **Métodos Clave:**
  - `userFriendlyErrorMessage(dynamic error): String`: Mapea excepciones técnicas (SocketException, 401/403, 429 cuota, fallos de detección/seguridad) a mensajes claros y accionables en español.
  - `analyzeMealPhoto({required Uint8List rawImageBytes, ...}) / analyzeMealImage(Uint8List imageBytes, ...): Future<MealAnalysisResult>`:
    1. Comprime y redimensiona la imagen a 1024x1024 píxeles (JPEG al 85% de calidad).
    2. Construye el modelo `GenerativeModel` con temperatura baja (`0.2`) y esquema estructurado.
    3. Concatena la instrucción clínica del sistema, el Master Prompt del usuario y las notas contextuales opcionales.
    4. Ejecuta `generateContent` capturando excepciones y envolviéndolas mediante `userFriendlyErrorMessage`.

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
  - `calculateMacros({required double targetCalories, required double weightKg, required String bodyGoal}): MacroDistribution`
  - `generateMasterPrompt(UserProfile profile): String`
  - `calculateProfile(...): UserProfile`
  - `syncUserProfileToDailyGoals(UserProfile profile): Future<void>`

### 7. `SecureStorageService` (Singleton)
- **Ubicación:** `lib/services/secure_storage_service.dart`
- **Responsabilidad:** Almacenamiento seguro en hardware cifrado para credenciales BYOK y tokens sensibles.
- **Métodos Clave:**
  - `getGeminiApiKey() / setGeminiApiKey(String key) / deleteGeminiApiKey(): Future<void>`
  - `getUsdaApiKey() / setUsdaApiKey(String key) / deleteUsdaApiKey(): Future<void>`
  - `getSelectedGeminiModel() / setSelectedGeminiModel(String model): Future<void>`
  - `getMasterPrompt() / setMasterPrompt(String prompt): Future<void>`
  - `getDailyGoals() / setDailyGoals(DailyGoals goals): Future<void>`
  - `hasCompletedOnboarding() / setCompletedOnboarding(bool completed): Future<void>`

### 8. `BackupService`
- **Ubicación:** `lib/services/backup_service.dart`
- **Responsabilidad:** Exportación e importación atómica de copias de seguridad en formato JSON v2 estructurado dentro de transacciones SQLite.
- **Métodos Clave:**
  - `exportToJsonString(): Future<String>`
  - `importFromJsonString(String jsonContent): Future<Map<String, int>>`

### 9. `ImageProcessingService`
- **Ubicación:** `lib/services/image_processing_service.dart`
- **Responsabilidad:** Compresión y redimensionamiento defensivo de fotografías de platos (máximo 1024x1024 px, JPEG 85%), gestión del almacenamiento en la carpeta pública visible del usuario (`/storage/emulated/0/Pictures/FoodTracker/images`) con cascada de fallbacks a almacenamiento de aplicación y documentos, y depuración de almacenamiento por retención temporal sin afectar registros SQLite.
- **Métodos Clave:**
  - `compressAndResize(Uint8List rawBytes, {int targetMaxDimension = 1024, int quality = 85}): Uint8List`
  - `saveMealImage(Uint8List imageBytes, {String? mealType, DateTime? date, String? mealId, int? index, Directory? customDirectory}): Future<String>`: Guarda la fotografía siguiendo la nomenclatura estricta `YYYY_MM_DD_{TYPE}_{INDEX}.jpg` (ej: `2026_06_30_B_01.jpg`), resolviendo índices secuenciales automáticamente y previniendo colisiones en la ruta pública visible de Android `/storage/emulated/0/Pictures/FoodTracker/images` (o cascada de fallbacks).
  - `generateMealImageFileName({DateTime? date, String? mealType, Directory? directory, int? explicitIndex}): Future<String>`: Genera el nombre de archivo estandarizado `YYYY_MM_DD_{TYPE}_{INDEX}.jpg` resolviendo o infiriendo tipos y secuenciales.
  - `getMealTypeCode(String? mealType): String`: Mapea categorías a códigos (`B`: Breakfast/Desayuno, `L`: Lunch/Almuerzo, `D`: Dinner/Cena, `S`: Snack/Merienda/Snarck/Botana, `O`: Fallback/Otro).
  - `getMealTypeFromCode(String code): String`: Deserializa el código de comida a su nombre canónico en español.
  - `inferMealTypeByTime([DateTime? time]): String`: Infiere automáticamente el tipo de comida sugerido según la hora actual del día.
  - `parseMealImageFileName(String pathOrFileName): MealImageFileInfo?`: Descompone nombres de archivo según la nomenclatura validando estrictamente el calendario gregoriano (días reales de cada mes y bisiestos) y extrayendo metadatos.
  - `filterMealImages(List<String> filePaths, {DateTime? date, int? year, int? month, int? day, String? mealType}): List<MealImageFileInfo>`: Filtra colecciones de fotografías por criterios temporales y de tipo de comida.
  - `listMealImages({required Directory directory, DateTime? date, int? year, int? month, int? day, String? mealType}): Future<List<MealImageFileInfo>>`: Escanea un directorio en disco y retorna todas las fotos de comida conformes que coincidan con los filtros.
  - `normalizeFilePath(String pathOrUri): String`: Normaliza rutas directas y esquemas `file://` a rutas absolutas válidas del sistema de archivos.
  - `pruneOldMealPhotos({required int retentionDays}): Future<int>`: Elimina archivos de imágenes con antigüedad mayor al umbral sin importar la ruta donde residan, manteniendo intactos los registros SQLite (`image_path = null`).
  - `deleteMealImage(String? filePath): Future<void>`: Elimina la fotografía del plato en disco de forma segura.

### 10. `ThemeManager`
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
