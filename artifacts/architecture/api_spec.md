---
title: Especificación de API, Esquema SQLite y Contratos Backend
status: active
tags: [proyecto, api, backend, database, sqlite, gemini, contracts]
agent: backend-architect
project: App_Food_Tracker
version: v1.0.0
date: 2026-09-06
---

# 📡 Especificación de Contrato de Datos, Esquema SQLite y Servicios Backend

> **Backend-Architect:** Este artefacto define formalmente el esquema relacional de base de datos local SQLite, los índices de cobertura, los modelos de datos inmutables y los contratos de servicios internos y externos (Gemini AI Vision y Open Food Facts).

---

## 🗄️ 1. Esquema Relacional de Base de Datos SQLite (DDL)

La base de datos opera localmente bajo el archivo `app_food_tracker.db` en el directorio de documentos de la aplicación, configurada con WAL mode y claves foráneas.

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

### 1.3. Índices de Cobertura y Rendimiento (Zero N+1)
Para garantizar consultas de día completo e historiales en menos de **2 milisegundos**, se han creado los siguientes índices:

```sql
-- Consultas filtradas por fecha (rango diario y selector semanal):
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
```

---

## 🧬 2. Modelos de Dominio y Sanitización Defensiva

### 2.1. Modelo `Meal`
- **Atributos:**
  - `id` (String): UUID v4 único. Truncado a 128 chars.
  - `name` (String): Nombre del plato. Sanitizado a 255 chars máx. Fallback: `'Comida'`.
  - `mealType` (String): Uno de `['Desayuno', 'Almuerzo', 'Cena', 'Snack']`.
  - `date` (DateTime): Fecha y hora del consumo. Fallback: `DateTime.now()`.
  - `imagePath` (String?): Ruta absoluta a la fotografía redimensionada (o `null`). Truncado a 1024 chars máx.
  - `calories` (double): Calorías netas. Clamped `[0.0, 9999.0]`.
  - `protein` (double): Gramos de proteína. Clamped `[0.0, 9999.0]`.
  - `carbs` (double): Gramos de carbohidratos. Clamped `[0.0, 9999.0]`.
  - `fat` (double): Gramos de grasa. Clamped `[0.0, 9999.0]`.
  - `notes` (String?): Comentarios o contexto del usuario. Truncado a 2000 chars máx.
  - `aiBreakdownJson` (String?): Payload JSON generado por Gemini Vision con el cubicaje detallado. Truncado a 100000 chars máx.
- **Propiedad Computada `items`:** Deserializa de forma segura `aiBreakdownJson` retornando `List<FoodItem>`. Maneja estructuras corruptas sin generar excepciones no capturadas.
- **Método `recalculateFromItems(List<FoodItem> newItems)`:** Recalcula la suma de macros y regenera el payload JSON manteniendo la coherencia entre el desglose y el resumen del plato.
- **Método `copyWith` con Patrón Sentinel:** Permite resetear explícitamente `imagePath: null`, `notes: null` y `aiBreakdownJson: null`.

### 2.2. Modelo `FoodItem`
- **Atributos:**
  - `id` (String): Identificador único (UUID v4).
  - `name` (String): Nombre del alimento/ingrediente. Sanitizado a 255 chars máx.
  - `estimatedGrams` (double): Peso en gramos estimado visualmente. Clamped `[0.0, 50000.0]`.
  - `calories`, `protein`, `carbs`, `fat` (double): Macronutrientes. Clamped `[0.0, 9999.0]`.
  - `visualJustification` (String?): Razón volumétrica (ej: "Aproximadamente 1 puño cerrado ~ 150g"). Truncado a 1000 chars.

### 2.3. Modelo `PantryItem`
- Representa artículos de alacena o alimentos escaneados con soporte para marcas, categorías y favoritos (`isFavorite: bool`).

### 2.4. Modelo `DailyGoals`
- Almacena metas nutricionales del usuario con valores por defecto científicamente fundamentados (`calories: 2000.0`, `protein: 140.0`, `carbs: 220.0`, `fat: 65.0`). Clamped para evitar metas inconsistentes.

---

## 🤖 3. Contrato de Inferencia de Visión con Google Gemini

### 3.1. Endpoint & Modelo
- **Modelo:** `gemini-2.5-flash` (baja latencia y alta precisión visual).
- **MIME Type de Respuesta:** `application/json`.
- **Temperatura:** `0.2` (determinismo y estabilidad estructural).
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

### 3.2. Reglas Clínicas Inyectadas en el System Prompt
1. **Referencias Anatómicas de Volumen:**
   - Puño cerrado ~ 1 taza de volumen (~150-200g de arroz, frijoles o pastas cocidas).
   - Palma de la mano (grosor del meñique) ~ 100-130g de carne, pollo o pescado cocido.
   - Pulgar / Falange distal ~ 1 cucharada o ~10-15g de aceite, mantequilla o grasa.
   - Dos manos ahuecadas ~ 50-80g de ensalada de hojas crudas.
2. **Conversión Cocido vs Crudo:**
   - Arroz y pasta: multiplicar por 2.5 a 3 su peso en crudo.
   - Carnes y aves: aplicar merma por cocción del 20% al 25%.
   - Legumbres: absorben agua duplicando o triplicando peso.
3. **Regla de Grasa Oculta:**
   - En guisos, sofritos y salsas caseras latinoamericanas, añadir entre 5g y 10g adicionales de grasa oculta por ración.
4. **Porciones Compartidas:**
   - Si el usuario especifica fracción (ej. "me comí 1/3 de la fuente"), calcular únicamente la porción individual.

---

## 🏷️ 4. Contrato de Consulta Open Food Facts API v2

- **URL Base:** `https://world.openfoodfacts.org/api/v2/product/{barcode}.json`
- **Cabeceras:** `User-Agent: VictorEngineerFoodTracker - Flutter - Version 1.0`
- **Timeout:** 10 segundos continuos (protección contra conexiones lentas).
- **Mapeo de Nutrientes:**
  - Extrae `energy-kcal_100g` (fallback a `energy-kcal` o `energy-kcal_serving`).
  - Extrae `proteins_100g`, `carbohydrates_100g`, `fat_100g`.
  - Normaliza los nombres multilingües con prioridad en español (`product_name_es` -> `product_name` -> `generic_name_es`).

---

## 💾 5. Contrato del Servicio de Respaldos (`BackupService`)

- **Exportación:** Serializa la base de datos completa en JSON formateado con indentación de 2 espacios, conteniendo metadatos de aplicación, versión, fecha ISO y colecciones `meals` y `pantry_items`.
- **Importación:** Valida la estructura del JSON y ejecuta una transacción atómica única (`txn.insert` con `ConflictAlgorithm.replace`) garantizando que si el archivo está corrupto, la base de datos no queda en estado inconsistente.
