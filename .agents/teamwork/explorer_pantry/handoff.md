# Handoff Report: Explorer Pantry — R4 Investigation
**Artifact**: `.agents/teamwork/explorer_pantry/handoff.md`  
**Date**: 2026-10-04T21:50:00Z  
**Author**: Explorer Pantry (`explorer_pantry`)  
**Target Milestone**: Food Tracker v1.2.4  
**Target Agents**: Parent Orchestrator (`d92ea854-ebb3-4169-84f6-b9300cd637b1`), Backend-Architect, Frontend-UI, Systems-Auditor  

---

## 1. Observation

### 1.1. PantryItem Model & Persistence Today
- **Model File**: `lib/models/pantry_item.dart` (158 LoC)
  - Existing fields (lines 5-23):
    - `id` (`String`): UUID v4 generated via `Uuid().v4()`, truncated to 128 characters.
    - `name` (`String`): Product name, fallback `'Alimento despensa'`.
    - `brand` (`String?`), `category` (`String?`)
    - `calories`, `protein`, `carbs`, `fat`: Base macronutrients (`double`), clamped via `ModelSanitizer.clampDouble`.
    - `servingSize` (`double`): Defaults to `100.0`, clamped `min: 0.1, fallback: 100.0`.
    - `servingUnit` (`String`): Defaults to `'g'`, truncated to 32 characters.
    - `fiber`, `sodium`, `sugar`: Micronutrients (`double`).
    - `barcode`, `nutritionLabelImagePath`, `isVerifiedByUser`, `matchKeywords`, `isFavorite`.
  - **Lacking Fields**:
    - There is currently **no field for package net weight** (e.g., 500g total packaging weight).
    - `servingSize` is present in code and DB, but is hardcoded to 100g in the UI and never exposed for user editing.
- **SQLite Database Schema**:
  - `lib/services/daos/database_schema.dart` (lines 58-80):
    ```sql
    CREATE TABLE IF NOT EXISTS pantry_items (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      brand TEXT,
      category TEXT,
      calories REAL NOT NULL,
      protein REAL NOT NULL,
      carbs REAL NOT NULL,
      fat REAL NOT NULL,
      serving_size REAL DEFAULT 100.0,
      serving_unit TEXT DEFAULT 'g',
      fiber REAL DEFAULT 0.0,
      sodium REAL DEFAULT 0.0,
      sugar REAL DEFAULT 0.0,
      barcode TEXT,
      nutrition_label_image_path TEXT,
      is_verified_by_user INTEGER DEFAULT 0,
      match_keywords TEXT,
      is_favorite INTEGER NOT NULL DEFAULT 0
    )
    ```
  - `DatabaseConnectionFactory.openFoodTrackerDatabase()` (`lib/services/daos/database_connection_factory.dart` line 54) is currently on **version: 3**.
  - `DatabaseSchema.onUpgrade` (`lib/services/daos/database_schema.dart` lines 184-217) handles `oldVersion < 2` and `oldVersion < 3`, but does not yet have an `oldVersion < 4` migration.
- **JSON Serialization & Backwards Compatibility**:
  - `toSqliteMap()` and `toJson()` in `PantryItem` export a flat map.
  - `fromSqliteMap()` and `fromJson()` parse keys with null-coalescing and `ModelSanitizer`.
  - In `lib/services/backup_service.dart` (lines 196-208), backups restore pantry items through `PantryItem.fromJson(item)` within a database transaction `txn.insert('pantry_items', pantryItem.toSqliteMap())`.

### 1.2. Pantry Editing UI Today
- **File**: `lib/screens/pantry_screen.dart` (275 LoC).
  - The editor dialog `_showEditDialog([PantryItem? item])` is defined inline inside `_PantryScreenState` (lines 76-146).
  - Form fields currently present:
    - `nameCtrl` ("Nombre del producto *")
    - `brandCtrl` ("Marca (opcional)")
    - `calCtrl` ("Calorías", suffix: `kcal`)
    - `protCtrl` ("Proteína", suffix: `g`)
    - `carbsCtrl` ("Carbos", suffix: `g`)
    - `fatCtrl` ("Grasas", suffix: `g`)
  - At line 122, `PantryItem` is instantiated without passing `servingSize` or `servingUnit`, letting them fall back to `100.0` and `'g'`. Neither `servingSize` nor `packageWeight` are exposed to the user.
  - Line count warning: `pantry_screen.dart` has **275 lines**; adding more inputs inline would breach the 300 LoC ceiling.

### 1.3. Flow for Adding/Logging Pantry Items to Meals
- **Current Entry Points**:
  1. `lib/screens/dashboard_screen.dart` (lines 110-128):
     `_handleBarcodeScan` looks up `PantryItem? item` from `showBarcodeScannerDialog(context)`, but hardcodes `FoodItem(estimatedGrams: 100, calories: item.calories, ... visualJustification: 'Escaneado por código de barras (100g base)')`. It does not adjust for the item's actual serving size.
  2. `lib/widgets/meal_detail/food_item_editor_dialog.dart` (lines 76-97):
     Typing queries `FoodSearchCoordinator.instance.search(query)`. However, `FoodSearchCoordinator` (`lib/services/food_search_coordinator.dart`) only queries `OfflineFoodEstimatorService`, `OpenFoodFactsService`, and `UsdaFoodDataService`. **It does not search user pantry items from `PantryDao`.**
     Furthermore, line 83 computes `final ratio = grams / 100.0;`, assuming all items have a 100g base.
  3. `lib/screens/pantry_screen.dart` (lines 241-274):
     `_buildItemTile(PantryItem item)` only allows tapping to edit or deleting. There is **no UI action** to log the pantry item to a meal (Breakfast, Lunch, Dinner, Snack).

### 1.4. Existing Test Suites
- `test/models/pantry_item_test.dart` (50 LoC): Verifies SQLite map serialization, `copyWith`, and sentinel nullification.
- `test/services/pantry_prompt_context_test.dart` (91 LoC): Verifies formatting of pantry items into Gemini Vision prompt context.
- **Absence**: There are no widget tests for `pantry_screen.dart`, nor are there unit tests verifying portion scaling calculations.

### 1.5. Current Line Counts of Investigated Files
| File Path | Current LoC | Modularity Margin (< 300 LoC) |
|---|---|---|
| `lib/screens/meal_detail_screen.dart` | 297 | ⚠️ **3 lines remaining** |
| `lib/widgets/dashboard/dashboard_fab_menu.dart` | 291 | ⚠️ **9 lines remaining** |
| `lib/services/database_service.dart` | 290 | ⚠️ **10 lines remaining** |
| `lib/widgets/meal_detail/food_item_editor_dialog.dart` | 287 | ⚠️ **13 lines remaining** |
| `lib/screens/pantry_screen.dart` | 275 | ⚠️ **25 lines remaining** |
| `lib/screens/dashboard_screen.dart` | 271 | 29 lines remaining |
| `lib/services/daos/database_schema.dart` | 219 | 81 lines remaining |
| `lib/models/food_item.dart` | 172 | 128 lines remaining |
| `lib/models/pantry_item.dart` | 158 | 142 lines remaining |
| `lib/services/daos/pantry_dao.dart` | 139 | 161 lines remaining |
| `lib/services/daos/database_connection_factory.dart` | 81 | 219 lines remaining |
| `lib/services/food_search_coordinator.dart` | 77 | 223 lines remaining |
| `lib/models/food_search_suggestion.dart` | 41 | 259 lines remaining |

---

## 2. Logic Chain

1. **Model & Schema Evolution (Backwards Compatibility)**:
   - `PantryItem` already possesses `servingSize` (double, default 100.0) and `servingUnit` (String, default 'g'). These represent the reference portion (e.g. 100g, or 30g scoop).
   - Adding `packageWeight` (`double? packageWeight`) allows storing the total net weight of the package (e.g. 500g). Because `packageWeight` is nullable, all existing database rows and JSON files without this property will evaluate to `null` without throwing errors.
   - For SQLite: We bump `version: 4` in `DatabaseConnectionFactory.openFoodTrackerDatabase()`, add `package_weight REAL` to `createPantryTable`, and add `_safeAddColumn(db, 'pantry_items', 'package_weight REAL')` in `DatabaseSchema.onUpgrade` when `oldVersion < 4`.
   - In `PantryItem.fromSqliteMap`: Support both `'package_weight'` and legacy/Spanish keys (`map['package_weight'] ?? map['peso_neto'] ?? map['peso_paquete']`).

2. **Modularity Preservation for UI (< 300 LoC)**:
   - Since `pantry_screen.dart` is at 275 LoC, expanding the edit dialog within the same file will violate the `< 300 LoC` threshold.
   - Therefore, the dialog must be extracted to `lib/widgets/pantry/pantry_item_editor_dialog.dart` (~170 LoC).
   - This reduces `pantry_screen.dart` from 275 to ~160 LoC, creating plenty of headroom.

3. **Ergonomic Placement in Editor Dialog**:
   - The editor form should follow a natural nutritional label reading order:
     1. **Identificación**: Nombre del producto (`nameCtrl`) y Marca (`brandCtrl`).
     2. **Gramaje y Empaque (Nuevo)**:
        - Row with 2 fields:
          - `servingSizeCtrl`: "Porción de referencia" (Valor base, ej. `100`, sufijo `g`, helper: "Ej. 100g o 30g porción").
          - `packageWeightCtrl`: "Peso neto empaque" (Opcional, ej. `500`, sufijo `g`, helper: "Ej. 500g paquete").
        - Helper text: *"Nutrientes expresados por cada porción de referencia indicada."*
     3. **Macronutrientes**:
        - Row: Calorías (`calCtrl`, `kcal`) y Proteína (`protCtrl`, `g`).
        - Row: Carbohidratos (`carbsCtrl`, `g`) y Grasas (`fatCtrl`, `g`).

4. **Mathematical Scaling and Portion Logging Flow**:
   - The scaling formula required is:
     $$\text{scaledValue} = \left(\frac{\text{gramsConsumed}}{\text{referenceServingGrams}}\right) \times \text{baseMacroValue}$$
   - We introduce a helper method on `PantryItem`:
     ```dart
     FoodItem toScaledFoodItem({required double gramsConsumed, String? justification}) {
       final refGrams = servingSize > 0 ? servingSize : 100.0;
       final ratio = gramsConsumed / refGrams;
       return FoodItem(
         name: brand != null && brand!.isNotEmpty ? '$name ($brand)' : name,
         estimatedGrams: gramsConsumed,
         calories: ModelSanitizer.clampDouble(calories * ratio),
         protein: ModelSanitizer.clampDouble(protein * ratio),
         carbs: ModelSanitizer.clampDouble(carbs * ratio),
         fat: ModelSanitizer.clampDouble(fat * ratio),
         fiber: ModelSanitizer.clampDouble(fiber * ratio),
         sodium: ModelSanitizer.clampDouble(sodium * ratio),
         sugar: ModelSanitizer.clampDouble(sugar * ratio),
         visualJustification: justification ?? 'Despensa: ${gramsConsumed.toStringAsFixed(0)}g (ref. ${refGrams.toStringAsFixed(0)}g)',
       );
     }
     ```
   - Two ergonomic user flows must be implemented:
     - **Flow 1: Direct Consumption from `PantryScreen`**:
       On each `PantryItem` tile in `pantry_screen.dart`, add a "Registrar" icon button (`Icons.add_shopping_cart` or `Icons.restaurant_outlined`).
       Tapping it opens `showPantryConsumptionDialog(context, item)` (`lib/widgets/pantry/pantry_consumption_dialog.dart`), which:
       - Displays target meal selector (Desayuno, Almuerzo, Cena, Snack).
       - Shows grams slider/input (pre-filled with `item.servingSize`).
       - Displays live interactive previews of scaled calories, protein, carbs, and fat.
       - Tapping "Añadir a Comida" logs the food item to today's meal via `MealController.instance`.
     - **Flow 2: Autocomplete in `FoodSearchCoordinator` & `showFoodItemEditorDialog`**:
       In `FoodSearchCoordinator`, add user pantry querying so typing in `FoodItemEditorDialog` includes pantry items with badge `FoodSourceBadge.pantry`.
       When chosen, the dialog sets `_gramsController.text = suggestion.referenceServingGrams` and applies scaling automatically whenever grams are adjusted.

---

## 3. Caveats

1. **Non-gram Units**: Some pantry items might have liquid units like `'ml'` or arbitrary units like `'pieza'` / `'porción'`. To keep the mathematical scaling deterministic and adhere strictly to R4 ("gramaje de referencia"), non-gram units should default to 1:1 density equivalent for grams or be treated with their numerical quantity.
2. **Backwards Compatibility with Legacy Backups**: Legacy JSON backups might lack `'package_weight'` and `'serving_size'`. Both are handled gracefully (`package_weight = null`, `serving_size = 100.0`).
3. **Database Version Migration**: Upgrading database version to 4 requires `_safeAddColumn(db, 'pantry_items', 'package_weight REAL')`. Existing user databases will not be wiped or affected.

---

## 4. Conclusion

- **PantryItem Model & SQLite Migration**:
  - Add `packageWeight` (`double?`) to `PantryItem` in `lib/models/pantry_item.dart`.
  - Add helper `toScaledFoodItem({required double gramsConsumed})` to `PantryItem`.
  - Bump DB version to 4 in `DatabaseConnectionFactory.dart`.
  - Add `oldVersion < 4` migration in `DatabaseSchema.dart` with `ALTER TABLE pantry_items ADD COLUMN package_weight REAL`.
- **UI Architecture**:
  - Extract dialogs from `pantry_screen.dart` into:
    1. `lib/widgets/pantry/pantry_item_editor_dialog.dart` (Form with reference portion and package weight inputs).
    2. `lib/widgets/pantry/pantry_consumption_dialog.dart` (Live portion scaling and direct logging to meals).
  - Add `FoodSourceBadge.pantry` to `FoodSearchSuggestion` and incorporate `PantryDao` lookup into `FoodSearchCoordinator.dart`.
- **Modularity Guarantee**:
  - All modified and new files remain well below 300 LoC.

---

## 5. Verification Method

1. **Unit Testing**:
   - In `test/models/pantry_item_test.dart`:
     - Test that `PantryItem` with `packageWeight: 500.0` and `servingSize: 30.0` serializes and deserializes properly.
     - Test `toScaledFoodItem(gramsConsumed: 60.0)` produces exact 2x scaled values for calories and macros (`(60.0 / 30.0) * base = 2.0 * base`).
     - Test deserializing map with missing `package_weight` results in `packageWeight == null` and `servingSize == 100.0`.
   - In `test/services/v3_daos_and_migration_test.dart` (or new test):
     - Test upgrading DB schema from version 3 to version 4 alters `pantry_items` table without data loss.
2. **Widget Testing**:
   - Create `test/widgets/pantry_item_editor_dialog_test.dart`:
     - Test entering 50g reference portion, 250g package weight, and saving returns expected `PantryItem`.
   - Create `test/widgets/pantry_consumption_dialog_test.dart`:
     - Test entering 150g for a 100g reference item dynamically multiplies displayed calories by 1.5.
3. **Code Quality Command**:
   - Check line counts: `Get-Content <file> | Measure-Object -Line` must be `< 300` for every file.
