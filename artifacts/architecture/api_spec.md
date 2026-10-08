---
tipo: api_spec
proyecto: App_Food_Tracker
version: v1.4.0
estado: activo
fecha: 2026-10-08
tags: [proyecto, api, backend, contratos, sqlite-v4, github-releases, methodchannel-installer, gemini-streaming, 16k-tokens, thinking-level-medium, dynamic-pacing, local-notifications, socket-resilience, privacy-storage, clinical-pdf, purge-justification]
---

# 📡 Especificación de Contrato de Datos, Esquema SQLite v4 y Servicios Backend (v1.4.0)

> **Backend-Architect:** Este artefacto define formalmente el esquema relacional de base de datos local SQLite v4, los índices B-Tree de cobertura, los modelos de dominio inmutables (Sentinel), los contratos de servicios internos (DAOs, Service Locator, Result Pattern, BackupNormalizer con auto-reparación, NotificationService, ClinicalPdfExportService) y externos (Dynamic Gemini API con Streaming, Fallback Unario, IVisionModelProvider, 16k Tokens, Thinking Level MEDIUM, Descargas Resumibles HTTP 206 en GitHub Releases, HomeWidget, USDA FoodData Central, Open Food Facts y Calculadora Metabólica).

---

## 🗄️ 1. Esquema Relacional de Base de Datos SQLite v4 (DDL)

La base de datos opera localmente bajo el archivo `app_food_tracker.db` en el directorio de documentos de la aplicación, configurada con WAL mode y llaves foráneas (`DatabaseConnectionFactory` y `DatabaseSchema`).

### 1.1. Tabla: `meals` (Actualizada v3 con Micronutrientes)
Almacena cada registro de comida incluyendo micronutrientes críticos (fibra, sodio, azúcar).

```sql
CREATE TABLE meals (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  meal_type TEXT NOT NULL,
  date TEXT NOT NULL,
  image_path TEXT,
  calories REAL NOT NULL,
  protein REAL NOT NULL,
  carbs REAL NOT NULL,
  fat REAL NOT NULL,
  fiber REAL NOT NULL DEFAULT 0.0,
  sodium REAL NOT NULL DEFAULT 0.0,
  sugar REAL NOT NULL DEFAULT 0.0,
  notes TEXT,
  ai_breakdown_json TEXT
);
```

### 1.2. Tabla: `meal_items` (Desglose normalizado con Micronutrientes)
Almacena los ingredientes atómicos de cada comida para persistencia relacional acoplada.

```sql
CREATE TABLE meal_items (
  id TEXT PRIMARY KEY,
  meal_id TEXT NOT NULL,
  name TEXT NOT NULL,
  calories REAL NOT NULL,
  protein REAL NOT NULL,
  carbs REAL NOT NULL,
  fat REAL NOT NULL,
  fiber REAL NOT NULL DEFAULT 0.0,
  sodium REAL NOT NULL DEFAULT 0.0,
  sugar REAL NOT NULL DEFAULT 0.0,
  FOREIGN KEY (meal_id) REFERENCES meals (id) ON DELETE CASCADE
);
```

### 1.3. Tabla: `pantry_items` (Actualizada v4 con Gramajes y Peso de Empaque)
Almacena productos de marca, ingredientes de despensa, porción de referencia y peso neto del empaque.

```sql
CREATE TABLE pantry_items (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  brand TEXT,
  category TEXT,
  serving_size REAL DEFAULT 100.0,
  serving_unit TEXT DEFAULT 'g',
  package_weight REAL,
  calories REAL NOT NULL,
  protein REAL NOT NULL,
  carbs REAL NOT NULL,
  fat REAL NOT NULL,
  fiber REAL DEFAULT 0.0,
  sodium REAL DEFAULT 0.0,
  sugar REAL DEFAULT 0.0,
  is_favorite INTEGER NOT NULL DEFAULT 0,
  barcode TEXT,
  nutrition_label_image_path TEXT,
  is_verified_by_user INTEGER DEFAULT 0,
  match_keywords TEXT
);
```

### 1.4. Tabla: `calibrated_dishware` (Nueva en v3: Escala Métrica)
Registra los platos y vajilla del usuario con su diámetro real en centímetros para guiar el cubicaje visual volumétrico de la IA.

```sql
CREATE TABLE IF NOT EXISTS calibrated_dishware (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  diameter_cm REAL NOT NULL,
  depth_cm REAL DEFAULT 0.0,
  shape TEXT NOT NULL DEFAULT 'circle',
  is_default INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);
```

### 1.5. Tabla: `meal_templates` (Nueva en v3: Comidas Habituales)
Almacena combinaciones o platos pre-pesados y verificados por el usuario para registro en 1 toque.

```sql
CREATE TABLE IF NOT EXISTS meal_templates (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  meal_type TEXT NOT NULL,
  calories REAL NOT NULL,
  protein REAL NOT NULL,
  carbs REAL NOT NULL,
  fat REAL NOT NULL,
  fiber REAL DEFAULT 0.0,
  sodium REAL DEFAULT 0.0,
  sugar REAL DEFAULT 0.0,
  items_json TEXT NOT NULL,
  created_at TEXT NOT NULL
);
```

### 1.6. Tabla: `fasting_logs` (Nueva en v3: Ventana de Ayuno Intermitente)
Controla el protocolo de ayuno (16/8, 18/6, 20/4) y marcas de tiempo inicio/fin.

```sql
CREATE TABLE IF NOT EXISTS fasting_logs (
  id TEXT PRIMARY KEY,
  start_time TEXT NOT NULL,
  target_hours REAL NOT NULL DEFAULT 16.0,
  end_time TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  notes TEXT
);
```

### 1.7. Tablas Existentes: `weight_logs`, `user_profile`, `analysis_queue`
- `weight_logs`: Histórico ponderal de pesajes (`id`, `date`, `weight`, `notes`).
- `user_profile`: Perfil metabólico Mifflin-St Jeor y metas nutricionales.
- `analysis_queue`: Tareas asíncronas de cubicaje de fotos.

### 1.8. Índices B-Tree de Cobertura y Rendimiento
```sql
CREATE INDEX IF NOT EXISTS idx_meals_date ON meals(date);
CREATE INDEX IF NOT EXISTS idx_meals_meal_type ON meals(meal_type);
CREATE INDEX IF NOT EXISTS idx_meals_date_type ON meals(date, meal_type);
CREATE INDEX IF NOT EXISTS idx_pantry_name ON pantry_items(name COLLATE NOCASE);
CREATE INDEX IF NOT EXISTS idx_pantry_favorite ON pantry_items(is_favorite);
CREATE INDEX IF NOT EXISTS idx_pantry_barcode ON pantry_items(barcode);
CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);
CREATE INDEX IF NOT EXISTS idx_meal_items_meal_id ON meal_items(meal_id);
CREATE INDEX IF NOT EXISTS idx_calibrated_dishware_default ON calibrated_dishware(is_default);
CREATE INDEX IF NOT EXISTS idx_meal_templates_meal_type ON meal_templates(meal_type);
CREATE INDEX IF NOT EXISTS idx_fasting_logs_start ON fasting_logs(start_time);
```

---

## 🧬 2. Modelos de Dominio Inmutables (v1.1.0)

### 2.1. Modelo `CalibratedDishware`
- `id` (String): UUID v4.
- `name` (String): Nombre identificador (ej. "Plato Llano Principal", "Bowl Avena").
- `diameterCm` (double): Diámetro en centímetros (e.g. 26.0).
- `depthCm` (double): Profundidad promedio en cm.
- `shape` (String): 'circle', 'square', 'oval'.
- `isDefault` (bool): Si es la referencia primaria inyectada en el prompt de Gemini.
- `createdAt` (DateTime).

### 2.2. Modelo `MealTemplate`
- `id` (String): UUID v4.
- `name` (String): Nombre del combo/receta (ej. "Arepa con Queso y Huevo").
- `mealType` (String): 'Desayuno', 'Almuerzo', 'Cena', 'Snack'.
- `calories`, `protein`, `carbs`, `fat`, `fiber`, `sodium`, `sugar` (double).
- `items` (List<FoodItem>): Lista completa de ingredientes individuales.
- `createdAt` (DateTime).

### 2.3. Modelo `FastingLog`
- `id` (String): UUID v4.
- `startTime` (DateTime): Inicio del ayuno.
- `targetHours` (double): Meta en horas (por defecto 16.0).
- `endTime` (DateTime?): Fin del ayuno (null si está activo).
- `isActive` (bool): Estado del ayuno en curso.
- `notes` (String?): Observaciones.

### 2.4. Modelo `AnalysisTask`
- `id` (String): UUID v4.
- `imagePath` (String): Ruta física inmutable de la foto.
- `status` (`queued`, `processing`, `completed`, `failed`).
- `progress` (double): Progreso 0.0 a 1.0.
- `stage` (String): Texto amigable de la etapa actual.
- `error` (String?): Excepción amigable mapeada.
- `resultMealId` (String?): ID de la comida generada en SQLite.

---

## 🤖 3. Inferencia de Visión con Escala Métrica y Contexto de Despensa

### 3.1. Inyección de Escala Métrica de Plato Calibrado
En `GeminiVisionService.analyzeMealImage`:
```text
ESCALA MÉTRICA DE REFERENCIA FÍSICA:
El usuario ha calibrado su plato con un diámetro real de: {diameterCm} cm (profundidad: {depthCm} cm).
Utiliza esta dimensión exacta para deducir el volumen tridimensional (cm³) de cada porción antes de calcular la masa en gramos.
```

### 3.2. Inyección de Despensa y Productos Favoritos
```text
PRODUCTOS Y MARCAS REGISTRADOS POR EL USUARIO:
- Harina P.A.N. (100g = 360 kcal, 7g prot, 78g carbos, 1.5g grasa)
- Jamón de Pavo Plumrose (100g = 95 kcal, 18g prot, 1g carbos, 2g grasa)
Si el plato visualizado contiene alimentos correspondientes a estos productos, prioriza estos valores nutricionales específicos.
```

---

## 📱 4. Contratos de Widgets Nativos de Android (`home_widget`)

### 4.1. SharedPreferences Keys
- `widget_calories_consumed`: Double con las calorías registradas hoy.
- `widget_calories_target`: Double con la meta calórica.
- `widget_calories_left`: Double con las calorías remanentes.
- `widget_protein_consumed`: Double con gramos de proteína consumidos.
- `widget_carbs_consumed`: Double con gramos de carbohidratos consumidos.
- `widget_fat_consumed`: Double con gramos de grasas consumidos.
- `widget_last_updated`: Timestamp de la última sincronización.

### 4.2. Deep Links
- `foodtracker://scan_food`: Abre directamente la cámara de análisis de comida.
- `foodtracker://scan_barcode`: Abre directamente el lector de códigos de barras.
- `foodtracker://new_meal`: Abre el formulario de registro manual.

---

## 💾 5. Contrato de Respaldo Adaptativo y Auto-Reparación (`BackupNormalizer`)

### 5.1. Estructura Canónica de Exportación (v1.2.5)
- `app`: String ("Victor Engineer Food Tracker")
- `version`: String ("1.2.5")
- `schema_version`: Integer (2)
- `meals`: Array de comidas (`Meal`) con micronutrientes (`fiber`, `sodium`, `sugar`).
- `pantry_items`: Array de despensa (`PantryItem`) con porción y `package_weight`.
- `user_profile`: Objeto biométrico y metabólico.
- `weight_logs`: Array de pesajes cronológicos.

### 5.2. Motor de Auto-Reparación Sintáctica (`_tryRepairTruncatedJson`)
- Cierre automático de strings interrumpidos sin comilla de cierre (`FormatException: Unterminated string`).
- Recorte de tokens colgantes y separadores huérfanos (`:`, `,`).
- Conteo y balanceo LIFO de llaves `{` y corchetes `[` para garantizar decodificación determinista sin pérdida de datos válidos.

---

## 🔄 6. Contrato de Auto-Actualizador In-App (v1.3.0)

### 6.1. GitHub Releases API Contract
- **Endpoint:** `GET https://api.github.com/repos/VICTOREB13/App-Food-Tracker/releases/latest`
- **Headers:** `Accept: application/vnd.github.v3+json`, `User-Agent: VictorEngineer-FoodTracker`
- **Campos consumidos del Payload JSON:**
  - `tag_name`: String (ej. `"v1.3.0"`)
  - `name`: String (ej. `"Release v1.3.0: In-App Auto-Updater & Microinteractions"`)
  - `body`: String (Notas de la versión en markdown)
  - `published_at`: String ISO-8601
  - `html_url`: String (Enlace web del release en GitHub)
  - `assets`: Array de objetos. Filtro prioritario:
    - Buscar asset cuyo `name` termine en `.apk` (preferentemente `Victor-Engineer-Food-Tracker-Android.apk`).
    - Extraer `browser_download_url` y `size` (bytes).

### 6.2. Native Android MethodChannel Contract
- **Channel ID:** `com.victorengineer.foodtracker/app_installer`
- **Métodos expuestos:**
  1. `installApk(filePath: String)`:
     - Entrada: `{"filePath": "/data/user/0/.../app_flutter/updates/update_v1.3.0.apk"}`
     - Comportamiento: Valida existencia del archivo, obtiene URI segura con `FileProvider.getUriForFile`, configura `Intent.ACTION_VIEW` con `FLAG_ACTIVITY_NEW_TASK` y `FLAG_GRANT_READ_URI_PERMISSION`, y lanza la actividad del instalador del sistema.
     - Retorno: `true` en éxito, o lanza `PlatformException`.
  2. `canRequestPackageInstalls()`:
     - Comportamiento: Si Android API >= 26 (`Build.VERSION_CODES.O`), consulta `packageManager.canRequestPackageInstalls()`. Si es menor, retorna `true`.
     - Retorno: `Boolean`.
  3. `openInstallPermissionSettings()`:
     - Comportamiento: En Android API >= 26, despacha `Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName"))`.
     - Retorno: `null`.

### 6.3. Contrato de Descarga Resumible HTTP 206 & Range Header
- **Cabeceras de Petición:** `Range: bytes={existingBytes}-` (inyectada si `{destination}.part` ya existe en disco y tiene tamaño $> 0$).
- **Manejo de Respuestas HTTP:**
  - `HTTP 206 Partial Content`: El servidor acepta la reanudación de bytes. La escritura en disco opera en modo append (`FileMode.append`). El progreso reportado al callback acumula `existingBytes + chunkBytes` relativo a la longitud total esperada.
  - `HTTP 200 OK`: El servidor no soporta o ignoró la cabecera Range; el archivo `.part` se sobreescribe desde el byte 0 de forma transparente.
  - Otros códigos (4xx / 5xx): Retorna `FailureResult(NetworkFailure)` con mensaje sanitizado.
- **Finalización Atómica:** Únicamente al verificar la recepción del 100% de los bytes, el archivo temporal `.part` se renombra de manera atómica al `.apk` final, asegurando que nunca se entregue un binario corrupto o a medio descargar.

---

## 🤖 7. Contrato de Inferencia Causal Volumétrica Gemini Vision & Autovalidación (v1.3.3)

### 7.1. Schema JSON Desacoplado y Autovalidación (`mealAnalysisSchema`)
Para evitar alucinaciones autorregresivas y cuellos de botella de constrained grammar, el esquema JSON exige la siguiente secuencia causal estricta:

```json
{
  "razonamiento_volumetrico": "String (Pensamiento y deducción física libre: escala de vajilla, formas 3D, densidad, cocción, aceites y grasas ocultas)",
  "plato": "String (Nombre representativo del plato)",
  "porcentaje_certeza": "Integer (0-100: Certeza estimada de la IA basada en visibilidad, oclusión y nitidez)",
  "margen_error_kcal": "Integer (Margen de error calórico estimado en kilocalorías +/- kcal)",
  "items": [
    {
      "alimento": "String",
      "gramos_estimados": 130.0,
      "calorias": 165.0,
      "proteinas_g": 26.0,
      "carbohidratos_g": 0.0,
      "grasas_g": 6.8,
      "fibra_g": 0.0,
      "sodio_mg": 75.0,
      "azucar_g": 0.0
    }
  ],
  "totales": {
    "calorias": 165.0,
    "proteina_g": 26.0,
    "carbohidratos_g": 0.0,
    "grasas_g": 6.8,
    "fibra_g": 0.0,
    "sodio_mg": 75.0,
    "azucar_g": 0.0
  }
}
```

### 7.2. Contrato de Filtrado y Ranking de Modelos (`GeminiVisionFilter`)
- `gemini-3.8-flash`: Rank 1 (Recomendado, badge 'Fast', por defecto para escaneo diario).
- `gemini-3.1-pro`: Rank 2 (Recomendado, badge 'Think', alta precisión clínica con `thinking_budget: 1024`).
- `gemini-2.5-flash`: Rank 3 (Compatible y Fallback activo de alta capacidad).
- `gemini-1.5-pro`: Rank 4 (Compatible).
- `gemini-1.5-flash`: Rank 5 (Legado).
- `gemini-2.0-flash`: Rank 10 (Obsoleto / Demovido).

### 7.3. Contrato de Timeouts y Resiliencia
- `defaultTimeout`: 90 segundos para modelos Flash.
- `clinicalTimeout`: 120 segundos para modelos Pro o con `supportsThinking`.
- Manejo estructurado de `TimeoutException` retornando `AiServiceFailure.timeout(message)`.

### 7.4. Contrato de Streaming, Capacidad 16k y Thinking Level MEDIUM
- **Protocolo de Streaming Continuo:** Invocación vía `model.generateContentStream()` acumulando chunks progresivos en `StringBuffer`. La actividad de paquetes mantiene abierto el socket TCP/TLS, mitigando desconexiones de gateways NAT móviles (45–80s) durante fases de razonamiento latente.
- **Parámetros de `GenerationConfig`:**
  - `temperature`: 0.2
  - `responseMimeType`: "application/json"
  - `responseSchema`: `GeminiResilienceHelper.mealAnalysisSchema` (sin campo `justificacion_visual`)
  - `maxOutputTokens`: 16384 (eliminando truncamiento de tokens de razonamiento o JSON por `finishReason: MAX_TOKENS`)
- **Nivel de Inteligencia (`thinkingLevel`):** `MEDIUM` para `gemini-3.8-flash` y variantes Pro, omitido estrictamente en modelos Lite (`gemini-3.5-flash-lite`) para prevenir el error `HTTP 400 INVALID_ARGUMENT`.
- **Cascada de Respaldo Automática:**
  - Modelo Primario: Modelo seleccionado por el usuario o por defecto (`gemini-3.8-flash`).
  - Modelo de Fallback: `gemini-2.5-flash`.
  - Backoff Escalonado: Retardos progresivos en secuencia `[2s, 5s, 10s]` con jitter aleatorio adicional (0–500ms).
  - Clasificación de Reintento (`isRetriableError`): HTTP 500, 502, 504, `HttpException`, `HandshakeException`, `SocketException`, `FormatException`, respuestas vacías, terminaciones abruptas de red, y errores OS 104/10054.

### 7.5. Resiliencia ante Socket Cuts, Fallback Unario y Proveedor Desacoplado (v1.4.0)
- **Fallback Unario Inmediato:** Ante cualquier fallo durante el streaming en `GeminiVisionService.analyzeMeal` (ej. corte de socket `os error: 104` o `10054`), el servicio ejecuta de forma inmediata una llamada unaria con `model.generateContent([prompt])` antes de propagar un fallo o abortar la tarea.
- **Contrato `IVisionModelProvider`:** Abstracción unificada (`lib/core/interfaces/vision_model_provider_interface.dart`) para desacoplar el motor de visión de Gemini frente a proveedores futuros (ej. OpenRouter):
  - `Future<Result<MealAnalysisResult, Failure>> analyzeMeal({required Uint8List imageBytes, ...})`
  - `bool get supportsStreaming`
  - `void dispose()`

---

## 🔔 8. Contrato de Notificaciones Locales y Programadas (`INotificationService`) (v1.4.0)

- **Canal Android de Análisis de Comidas (`food_tracker_meal_analysis`):** Prioridad alta con sonido/vibración para alertar al usuario cuando su comida termina de procesarse en segundo plano o si se produce un error.
  - `Future<void> showMealAnalysisCompleted({required String mealId, required String dishName, required double calories})`
  - `Future<void> showMealAnalysisFailed({required String taskId, required String reason})`
- **Canal Android de Ayuno Intermitente (`food_tracker_fasting`):** Notificación de alarma exacta programada para dispararse en el momento en que se cumple la ventana de ayuno seleccionada:
  - `Future<void> scheduleFastingCompleted({required int notificationId, required DateTime scheduledDate, required double targetHours})`
  - `Future<void> cancelFastingReminder({required int notificationId})`

---

## 📄 9. Contrato de Reporte Clínico Dual PDF/CSV (v1.4.0)

- **Exportación CSV RFC 4180 (`ClinicalExcelExportService`):**
  - `Future<Result<String, Failure>> exportToExcelCsv({required List<Meal> meals, required DateTime startDate, required DateTime endDate, ...})`
  - Guarda en `/storage/emulated/0/Documents/FoodTracker` (o directorio accesible de documentos) con codificación UTF-8 BOM.
- **Exportación PDF Clínico (`IClinicalPdfExportService` / `ClinicalPdfExportService`):**
  - `Future<Result<String, Failure>> exportToClinicalPdf({required List<Meal> meals, required DateTime startDate, required DateTime endDate, ...})`
  - Genera documento binario con cabecera `%PDF-`, estructurado con tablas completas de macronutrientes, micronutrientes (fibra, sodio, azúcar), promedios diarios e historial secuencial de comidas, guardado en el mismo directorio `/Documents/FoodTracker`.



