---
title: Especificación de API, Esquema SQLite v2 y Contratos Backend
status: active
tags: [proyecto, api, backend, database, sqlite, gemini, usda, contracts, mifflin-st-jeor]
agent: backend-architect
project: App_Food_Tracker
version: v0.2.0-alpha
date: 2026-09-07
---

# 📡 Especificación de Contrato de Datos, Esquema SQLite v2 y Servicios Backend

> **Backend-Architect:** Este artefacto define formalmente el esquema relacional de base de datos local SQLite v2, los índices B-Tree de cobertura, los modelos de dominio inmutables (Sentinel) y los contratos de servicios internos y externos (Dynamic Gemini API, USDA FoodData Central, Open Food Facts y Calculadora Metabólica).

---

## 🗄️ 1. Esquema Relacional de Base de Datos SQLite v2 (DDL)

La base de datos opera localmente bajo el archivo `app_food_tracker.db` en el directorio de documentos de la aplicación, configurada con WAL mode y llaves foráneas.

### 1.1. Tabla: `meals`
Almacena cada registro de comida (desayuno, almuerzo, cena, snack o hidratación).

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
  notes TEXT,
  ai_breakdown_json TEXT
);
```

### 1.2. Tabla: `pantry_items`
Almacena alimentos frecuentes, ingredientes recurrentes y productos escaneados por código de barras.

```sql
CREATE TABLE pantry_items (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  brand TEXT,
  category TEXT,
  calories REAL NOT NULL,
  protein REAL NOT NULL,
  carbs REAL NOT NULL,
  fat REAL NOT NULL,
  is_favorite INTEGER NOT NULL DEFAULT 0
);
```

### 1.3. Tabla: `weight_logs` (Introducida en v2)
Almacena el historial cronológico de peso corporal para tendencias biométricas y trazado de curvas.

```sql
CREATE TABLE weight_logs (
  id TEXT PRIMARY KEY,
  weight REAL NOT NULL,
  date TEXT NOT NULL,
  notes TEXT
);
```

### 1.4. Índices de Cobertura B-Tree y Rendimiento (Zero N+1)
Para garantizar lecturas masivas e históricos diarios en menos de **2 milisegundos**, se han creado los siguientes índices B-Tree:

```sql
-- Consultas filtradas por fecha en comidas (rango diario y selector semanal):
CREATE INDEX IF NOT EXISTS idx_meals_date ON meals(date);

-- Agrupaciones por categoría de comida:
CREATE INDEX IF NOT EXISTS idx_meals_meal_type ON meals(meal_type);

-- Cobertura compuesta para consultas combinadas de día y tipo:
CREATE INDEX IF NOT EXISTS idx_meals_date_type ON meals(date, meal_type);

-- Búsquedas textuales en despensa sin distinción de mayúsculas/minúsculas:
CREATE INDEX IF NOT EXISTS idx_pantry_name ON pantry_items(name COLLATE NOCASE);

-- Filtrado por categorías en despensa:
CREATE INDEX IF NOT EXISTS idx_pantry_category ON pantry_items(category);

-- Acceso inmediato a alimentos favoritos:
CREATE INDEX IF NOT EXISTS idx_pantry_favorite ON pantry_items(is_favorite);

-- Consultas de tendencias de peso por rangos (7, 30, 90 días):
CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);
```

---

## 🧬 2. Modelos de Dominio Inmutables y Patrón Sentinel

Todos los modelos incorporan el patrón privado `_sentinel = Object()` en `copyWith` para distinguir la omisión de un parámetro de la asignación explícita de `null`.

### 2.1. Modelo `Meal`
- `id` (String): UUID v4 único. Truncado a 128 chars.
- `name` (String): Nombre del plato. Sanitizado a 255 chars máx. Fallback: `'Comida'`.
- `mealType` (String): Uno de `['Desayuno', 'Almuerzo', 'Cena', 'Snack']`.
- `date` (DateTime): Fecha y hora del consumo. Fallback: `DateTime.now()`.
- `imagePath` (String?): Ruta local de la fotografía redimensionada (o `null`). Truncado a 1024 chars.
- `calories`, `protein`, `carbs`, `fat` (double): Clamped `[0.0, 9999.0]`.
- `notes` (String?): Comentarios del usuario. Truncado a 2000 chars máx.
- `aiBreakdownJson` (String?): Payload JSON de inferencia volumétrica. Truncado a 100000 chars.
- Getter `items`: Deserialización resiliente retornando `List<FoodItem>`.
- Método `recalculateFromItems(List<FoodItem> newItems)`: Recálculo síncrono de macros y regeneración del JSON.

### 2.2. Modelo `FoodItem`
- `id` (String): Identificador único (UUID v4).
- `name` (String): Nombre del ingrediente. Sanitizado a 255 chars máx.
- `estimatedGrams` (double): Gramaje estimado. Clamped `[0.0, 50000.0]`.
- `calories`, `protein`, `carbs`, `fat` (double): Clamped `[0.0, 9999.0]`.
- `visualJustification` (String?): Razón volumétrica. Truncado a 1000 chars.

### 2.3. Modelo `WeightLog`
- `id` (String): UUID v4.
- `weight` (double): Peso corporal en kilogramos. Clamped `[20.0, 500.0]`.
- `date` (DateTime): Fecha y hora del registro.
- `notes` (String?): Notas del registro. Truncado a 500 chars.

### 2.4. Modelo `UserProfile`
- `sex` (String): `'male'` o `'female'`.
- `weight` (double): Peso actual en kg.
- `height` (double): Altura en cm.
- `age` (int): Edad en años.
- `activityLevel` (ActivityLevel): Factor de actividad sedentario a muy activo.
- `dailySteps` (int): Pasos diarios estimados.
- `goal` (NutritionalGoal): Déficit, mantenimiento o superávit.
- `masterPrompt` (String): Instrucciones contextualizadas inyectadas en Gemini Vision.

### 2.5. Modelo `GeminiModelInfo`
- `name` (String): Identificador de recurso (ej. `'models/gemini-2.5-flash'`).
- `displayName` (String): Nombre amigable del modelo.
- `description` (String): Descripción de capacidades.
- `supportedGenerationMethods` (List<String>): Métodos habilitados (`generateContent`).
- `inputTokenLimit` & `outputTokenLimit` (int): Límites de contexto.

### 2.6. Modelo `UsdaFoodItem`
- `fdcId` (int): Identificador en base de datos USDA.
- `description` (String): Nombre oficial del alimento.
- `brandOwner` (String?): Fabricante o marca comercial.
- `calories`, `protein`, `carbs`, `fat` (double): Nutrientes normalizados por 100g.
- `servingSize` (double?) & `servingSizeUnit` (String?): Ración estándar declarada.

---

## 🤖 3. Contratos de Inferencia y Descubrimiento Dinámico de Google Gemini

### 3.1. Descubrimiento Dinámico de Modelos (`GeminiModelService`)
- **Endpoint:** `GET https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}`
- **Criterio de Filtrado:** Modelos que contengan `'generateContent'` en `supportedGenerationMethods` y soporten modalidades multimodales de entrada.
- **Categorización Semántica en UI:**
  - *Recomendado (Rápido):* `gemini-2.5-flash`, `gemini-2.0-flash`.
  - *Recomendado (Pro):* `gemini-1.5-pro`.
  - *Equilibrado:* `gemini-1.5-flash`.

### 3.2. Contrato de Inferencia de Visión (`GeminiVisionService`)
- **MIME Type:** `application/json`.
- **Temperatura:** `0.2` (determinismo).
- **Inyección Contextual:** Se antepone el **Master Prompt** generado desde el perfil biométrico del usuario.
- **Esquema JSON Obligatorio (`responseSchema`):**
  ```json
  {
    "type": "OBJECT",
    "properties": {
      "plato": { "type": "STRING", "description": "Nombre representativo del plato" },
      "items": {
        "type": "ARRAY",
        "description": "Lista de ingredientes o alimentos identificados",
        "items": {
          "type": "OBJECT",
          "properties": {
            "alimento": { "type": "STRING" },
            "gramos_estimados": { "type": "NUMBER" },
            "calorias": { "type": "NUMBER" },
            "proteinas_g": { "type": "NUMBER" },
            "carbohidratos_g": { "type": "NUMBER" },
            "grasas_g": { "type": "NUMBER" },
            "justificacion_visual": { "type": "STRING" }
          },
          "required": ["alimento", "gramos_estimados", "calorias", "proteinas_g", "carbohidratos_g", "grasas_g"]
        }
      },
      "totales": {
        "type": "OBJECT",
        "properties": {
          "calorias": { "type": "NUMBER" },
          "proteina_g": { "type": "NUMBER" },
          "carbohidratos_g": { "type": "NUMBER" },
          "grasas_g": { "type": "NUMBER" }
        },
        "required": ["calorias", "proteina_g", "carbohidratos_g", "grasas_g"]
      }
    },
    "required": ["plato", "items", "totales"]
  }
  ```

---

## 🏛️ 4. Contratos de Consulta Nutricional en Cascada

### 4.1. USDA FoodData Central API (`UsdaFoodDataService`)
- **Búsqueda por Código de Barras / UPC:**
  - `GET https://api.nal.usda.gov/fdc/v1/foods/search?api_key={KEY}&query={UPC}&dataType=Branded,Foundation`
- **Mapeo de Nutrientes Oficiales (Nutrient IDs):**
  - Calorías: ID `1008` (`Energy` en kcal) o ID `1062` (`Energy` en kJ, convertida dividiendo por 4.184).
  - Proteína: ID `1003`.
  - Grasas totales: ID `1004`.
  - Carbohidratos por diferencia: ID `1005`.
- **Control de Frecuencia:** Limitador pasivo que respeta la cuota de 1.000 solicitudes por hora de la API del USDA.

### 4.2. Fallback Transparente a Open Food Facts (`BarcodeLookupService`)
- Cuando la búsqueda en USDA no arroja resultados (`totalHits == 0`) o la API Key no está configurada, el servicio conmuta automáticamente a `https://world.openfoodfacts.org/api/v2/product/{barcode}.json` garantizando cero fricción para el usuario.

---

## 🧮 5. Motor Metabólico Mifflin-St Jeor (`MetabolicCalculator`)

### 5.1. Ecuaciones Clínicas de TMB
- **Hombres:** $TMB = (10 \times \text{peso}_{\text{kg}}) + (6.25 \times \text{altura}_{\text{cm}}) - (5 \times \text{edad}) + 5$
- **Mujeres:** $TMB = (10 \times \text{peso}_{\text{kg}}) + (6.25 \times \text{altura}_{\text{cm}}) - (5 \times \text{edad}) - 161$

### 5.2. Multiplicadores de TDEE y Pasos
- Multiplicador base según actividad: Sedentario (1.2), Ligero (1.375), Moderado (1.55), Intenso (1.725), Muy Intenso (1.9).
- Bonus por pasos: $\frac{\text{pasos}}{10000} \times 0.15$ al factor de actividad.
- Ajuste por objetivo: Déficit (-500 kcal), Mantenimiento (0 kcal), Superávit (+350 kcal).

---

## 💾 6. Contrato de Respaldo v2 (`BackupService`)

- **Exportación:** Genera un JSON estructurado con `version: 2`, `timestamp` ISO 8601, metadatos de aplicación, y colecciones completas de `meals`, `pantry_items`, `weight_logs` y `user_profile`.
- **Importación Atómica:** Ejecución en una única transacción SQLite (`txn.insert` con `ConflictAlgorithm.replace`), revirtiendo automáticamente cualquier cambio si el archivo JSON está truncado o corrompido.

