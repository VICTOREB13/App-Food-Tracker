# Victor Engineer - Food Tracker (NutriTracker Local-First)

Aplicación móvil multiplataforma de registro y control nutricional de comidas caseras y compartidas sin báscula, desarrollada en **Flutter 3.22+** bajo una arquitectura **100% Local-First** con persistencia SQLite y visión multimodal potenciada por **Google Gemini 2.5 Flash** bajo el modelo **BYOK (Bring Your Own Key)**.

---

## 1. Principios Arquitectónicos y Estándares de Calidad

1. **Arquitectura 100% Local-First:**
   - Persistencia local en SQLite mediante `sqflite` y `sqflite_common_ffi` con modo WAL (`PRAGMA journal_mode = WAL;`), sincronización normal (`PRAGMA synchronous = NORMAL;`) e integridad referencial (`PRAGMA foreign_keys = ON;`).
   - Arranque instantáneo (0 ms cold start), privacidad total y funcionamiento 100% offline.
2. **Modularización Estricta (< 300 LoC por archivo):**
   - Ningún archivo de pantalla supera las 300 líneas de código.
   - UI dividida en widgets atómicos por dominio:
     - `lib/widgets/dashboard/`
     - `lib/widgets/meal_detail/`
     - `lib/widgets/settings/`
     - `lib/widgets/common/`
   - Las pantallas en `lib/screens/` operan exclusivamente como orquestadores y controladores puros.
3. **Patrón Sentinel en Modelos:**
   - Implementado en `Meal`, `FoodItem` y `PantryItem`. Garantiza que al pasar `null` explícito en `copyWith` se eliminen los campos opcionales sin restaurar datos anteriores ni provocar ambigüedad con valores no suministrados.
4. **Límites Defensivos de Memoria (`ModelSanitizer`):**
   - Sanitización transparente en constructores: títulos acotados a 255 caracteres, notas a 2000 caracteres, y macros numéricos restringidos con `.clamp(0.0, 9999.0)`.
5. **Código Limpio Anti-Slop:**
   - Cero comentarios obvios o redundantes. Tipado estricto, inmutabilidad y Dart idiomático.

---

## 2. Sistema de Diseño Victor Engineer

- **Identidad de Marca:** Acento Rojo Carmesí Canónico (`#DC2626`).
- **Modo Oscuro (Obsidian Zinc):**
  - Fondo `#09090B`, Tarjetas `#121215`, Bordes `#27272A`, Texto `#FAFAFA`.
- **Modo Claro (Crisp Zinc):**
  - Fondo `#FAFAFA`, Tarjetas `#FFFFFF`, Bordes `#E4E4E7`, Texto `#09090B`.
- **Tipografías:**
  - `Outfit` para títulos, logotipos y marca.
  - `Inter` para cuerpo de texto y métricas numéricas.
- **Semántica de Macros:**
  - Calorías: Rojo Carmesí (`#DC2626`)
  - Proteínas: Verde Esmeralda (`#10B981`)
  - Carbohidratos: Ámbar Cálido (`#F59E0B`)
  - Grasas: Azul Celeste (`#0EA5E9`)
- **Ergonomía Móvil:**
  - Dropdowns con `menuMaxHeight` acotado (280 dp).
  - Floating Action Button ergonómico con safe area.
  - Feedback visual con `.withValues(alpha: ...)`.

---

## 3. Modelo de Datos SQLite

### Tabla `meals`
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
CREATE INDEX IF NOT EXISTS idx_meals_date ON meals(date);
CREATE INDEX IF NOT EXISTS idx_meals_meal_type ON meals(meal_type);
CREATE INDEX IF NOT EXISTS idx_meals_date_type ON meals(date, meal_type);
```

### Tabla `pantry_items` (Base 100g)
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
CREATE INDEX IF NOT EXISTS idx_pantry_name ON pantry_items(name COLLATE NOCASE);
CREATE INDEX IF NOT EXISTS idx_pantry_category ON pantry_items(category);
CREATE INDEX IF NOT EXISTS idx_pantry_favorite ON pantry_items(is_favorite);
```

---

## 4. Visión Multimodal con Gemini 2.5 Flash

- SDK oficial `google_generative_ai` con salida forzada en JSON estructurado vía `GenerationConfig(responseMimeType: 'application/json', responseSchema: ...)`.
- Redimensión en memoria a un máximo de 1024x1024 y compresión JPEG al 85% para baja latencia.
- **Reglas de Cubicaje Visual Clínico:**
  1. *Referencias Anatómicas:* Puño ~ 1 taza (150-200g cocido), Palma ~ 100-130g carne/pollo cocido, Pulgar ~ 10-15g grasa.
  2. *Conversión Cocido vs Crudo:* Arroz/pastas triplican volumen; carnes sufren 20-25% de merma.
  3. *Regla de Grasa Oculta:* Adición de 5 a 10g de grasa por ración casera (sofrito, aceite integrado).
  4. *Comidas Compartidas:* Cálculo ajustado a la fracción consumida por el usuario.

---

## 5. Estructura de Archivos del Proyecto

```
App-Food-Tracker/
├── .github/
│   └── workflows/
│       └── ci.yml
├── lib/
│   ├── main.dart
│   ├── controllers/
│   │   ├── meal_controller.dart
│   │   └── settings_controller.dart
│   ├── models/
│   │   ├── daily_goals.dart
│   │   ├── food_item.dart
│   │   ├── meal.dart
│   │   ├── model_sanitizer.dart
│   │   └── pantry_item.dart
│   ├── screens/
│   │   ├── dashboard_screen.dart
│   │   ├── meal_detail_screen.dart
│   │   └── settings_screen.dart
│   ├── services/
│   │   ├── backup_service.dart
│   │   ├── database_service.dart
│   │   ├── gemini_vision_service.dart
│   │   ├── image_processing_service.dart
│   │   ├── open_food_facts_service.dart
│   │   ├── secure_storage_service.dart
│   │   └── theme_manager.dart
│   └── widgets/
│       ├── common/
│       │   ├── barcode_scanner_dialog.dart
│       │   ├── confirmation_dialog.dart
│       │   ├── macro_indicator_chip.dart
│       │   ├── ve_app_bar.dart
│       │   └── ve_card.dart
│       ├── dashboard/
│       │   ├── daily_calorie_summary_card.dart
│       │   ├── dashboard_fab_menu.dart
│       │   ├── date_selector_bar.dart
│       │   └── meal_section_card.dart
│       ├── meal_detail/
│       │   ├── food_item_editor_dialog.dart
│       │   ├── food_items_list_card.dart
│       │   ├── meal_image_card.dart
│       │   └── meal_macro_chips_row.dart
│       └── settings/
│           ├── api_key_input_card.dart
│           ├── backup_card.dart
│           ├── daily_goals_card.dart
│           └── database_maintenance_card.dart
├── test/
│   ├── models/
│   │   ├── food_item_test.dart
│   │   ├── meal_model_test.dart
│   │   └── pantry_item_test.dart
│   ├── services/
│   │   ├── backup_service_test.dart
│   │   ├── database_service_test.dart
│   │   └── gemini_vision_service_test.dart
│   └── widgets/
│       └── daily_calorie_summary_card_test.dart
├── analysis_options.yaml
└── pubspec.yaml
```
