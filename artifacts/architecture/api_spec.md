---
tipo: api_spec
proyecto: App_Food_Tracker
version: v1.3.0
estado: activo
fecha: 2026-10-05
tags: [proyecto, api, backend, contratos, sqlite-v4, github-releases, methodchannel-installer, v1-3-0]
---

# 📡 Especificación de Contrato de Datos, Esquema SQLite v4 y Servicios Backend (v1.2.5)

> **Backend-Architect:** Este artefacto define formalmente el esquema relacional de base de datos local SQLite v4, los índices B-Tree de cobertura, los modelos de dominio inmutables (Sentinel), los contratos de servicios internos (DAOs, Service Locator, Result Pattern, BackupNormalizer con auto-reparación) y externos (Dynamic Gemini API, HomeWidget, USDA FoodData Central, Open Food Facts y Calculadora Metabólica).

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

