---
title: "UI & Analytics Architectural Survey Report - Phase 2"
status: "approved"
tags: [ui-ux, flutter, bento-grid, analytics, gemini-vision, usda-fdc, tdee, mifflin-st-jeor, local-first, victor-engineer]
agent: "explorer_survey_3"
project: "VE_FoodTracker"
version: "v2.0.0-survey"
date: "2026-09-07"
---

# UI & Analytics Architectural Survey Report — Phase 2
**Victor Engineer - Food Tracker (NutriTracker Local-First)**

---

## Executive Summary

This report establishes the comprehensive UI architecture, widget decomposition strategy, design token adherence, and mathematical specifications for **Phase 2** of the **Victor Engineer Food Tracker**.

All proposed designs and decompositions strictly enforce:
1. **The < 300 LoC Hard Constraint** for every screen in `lib/screens/` (`flutter-production-engineering`).
2. **Victor Engineer Design System** (*Obsidian Zinc* `#09090B`, Surface `#121215`, Carmesí Accent `#DC2626`, Google Fonts `Outfit` and `Inter`).
3. **Flutter 3.27+ Production Standards** (`.withValues(alpha: ...)`, `initialValue:` in form dropdowns, strict async context guards).
4. **Mifflin-St Jeor TMB/TDEE Formulation** for automated, clinically-grounded caloric and macronutrient goal calculation.
5. **Zero Hardcoding** in AI model selection via live Generative Language API discovery.
6. **Bento Grid Analytics** for weight tracking, caloric compliance, and macronutrient balance.

---

## 1. Existing UI Architecture & Baseline Audit

### 1.1 Screen Line Count Audit (`lib/screens/`)

A strict line-count inspection of existing screens reveals:

| Screen File | Lines of Code | Status vs. < 300 LoC Limit | Architectural Role & Observation |
|---|---|---|---|
| `lib/screens/dashboard_screen.dart` | **287 LoC** | ⚠️ **Near Limit (95.6%)** | Daily dashboard coordinator. Renders `VeAppBar`, `DateSelectorBar`, `WeekCalendarStrip`, `DailyCalorieSummaryCard`, meal sections, and `DashboardFabMenu`. Compliant, but any new direct inline code will breach 300 LoC. |
| `lib/screens/meal_detail_screen.dart` | **301 LoC** | ❌ **Non-Compliant (+1 LoC)** | Meal editor/detail coordinator. Handles image picking, form fields, and item lists. Exceeds the 300 LoC hard constraint by 1 line; requires slight trimming/modularization. |
| `lib/screens/settings_screen.dart` | **208 LoC** | ✅ **Compliant (69.3%)** | Settings coordinator. Renders theme picker, API key card, daily goals card, DB maintenance, and backup cards. Has room for new feature cards if properly modularized. |

### 1.2 State Management & Navigation Pattern

* **State Management:** The application strictly uses reactive `ChangeNotifier` singletons:
  - `MealController.instance`: Encapsulates meal querying, selected date, daily totals (calories, protein, carbs, fat), and goal progress.
  - `SettingsController.instance`: Encapsulates API keys, daily goals persistence, DB optimization stats, and JSON backup/restore.
  - `ThemeManager.instance`: Encapsulates theme mode (`dark`, `light`, `system`) with `SharedPreferences` persistence.
  - *Pattern:* Screens register listeners in `initState()` via `_controller.addListener(_onControllerChange)` and unregister in `dispose()` via `_controller.removeListener(_onControllerChange)`.
* **Navigation:** Imperative Flutter navigation using `Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => Screen()))`. Modals and bottom sheets use `showModalBottomSheet<void>` and `showDialog<void>`.

### 1.3 Victor Engineer Design Tokens & Visual Specs

Defined in `DESIGN.md` and implemented in `lib/services/theme_manager.dart`:

```
Paleta Obsidian Zinc (Dark Mode - Predeterminado):
- Background Primario:    #09090B  (Zinc 950 ultraprofundo)
- Card Surface:           #121215  (Zinc 900 personalizado / Elevación 1)
- Card Surface Elevated:  #18181B  (Elevación 2 - Modals, Dialogs, Dropdowns)
- Bordes y Divisores:     #27272A  (Zinc 800, 1px)
- Texto Principal:        #FAFAFA  (Zinc 50)
- Texto Secundario:       #A1A1AA  (Zinc 400)
- Texto Muted:            #71717A  (Zinc 500)
- Acento Victor Engineer: #DC2626  (Carmesí)
- Acento Hover / Activo:  #EF4444  (Rojo coral)

Paleta Semántica de Macronutrientes:
- Calorías (Energía):     #F97316  (Naranja llama) / #DC2626 (Carmesí)
- Proteína (Músculo):     #10B981  (Verde esmeralda) / #EF4444 (Coral)
- Carbohidratos:          #F59E0B  / #EAB308 (Ámbar dorado)
- Grasas (Lípidos):       #0EA5E9  / #3B82F6 (Azul zafiro)
- Hidratación:            #06B6D4  (Cian eléctrico)

Geometría y Radios:
- Bento Card Radius:      20.0 px
- Pill / Dock Radius:     32.0 px
- Icon Container Radius:  14.0 px

Tipografía (Google Fonts):
- Display & Métricas:     Outfit (Bold 700, SemiBold 600, tabular figures)
- Cuerpo y Controles:     Inter (Regular 400, Medium 500, SemiBold 600)
```

---

## 2. Requirement R1 UI: Dynamic Gemini Model Selector (Zero Hardcoding)

### 2.1 Problem & Requirement Analysis
Currently, `GeminiVisionService` has a hardcoded default model (`gemini-2.5-flash`), and `dashboard_screen.dart` hardcodes `'Analizando con Gemini 2.5 Flash...'`. If Google restricts `gemini-2.5-flash` for new API keys or releases newer models (e.g. `gemini-3.x`), the user cannot switch without editing source code.

### 2.2 Endpoint & Model Discovery Logic
* **Endpoint:** `GET https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}`
* **Response Payload Parsing:**
  - Parse `models` list.
  - Filter by `supportedGenerationMethods` containing `"generateContent"`.
  - Filter for multimodal capabilities: models with names containing `gemini-` (excluding embedding models like `text-embedding-004` or `aqa`).
  - Clean model identifier: strip `models/` prefix if present to pass clean model IDs (e.g., `gemini-2.5-flash`, `gemini-2.5-pro`, `gemini-2.0-flash`).
* **Priority & Recommendation Ranking:**
  1. `gemini-2.5-flash`: **RECOMENDADO** (Máxima velocidad y precisión volumétrica).
  2. `gemini-2.5-pro`: **ALTA PRECISIÓN** (Razonamiento profundo para platos complejos).
  3. `gemini-2.0-flash`: **ESTABLE** (Fallback de alta disponibilidad).
  4. `gemini-1.5-flash` / `gemini-1.5-pro`: **COMPATIBILIDAD**.
  5. Any newly detected Gemini model returned by the API.

### 2.3 UI Component Specification: `GeminiModelSelectorCard`
* **File Location:** `lib/widgets/settings/gemini_model_selector_card.dart` (~130 LoC).
* **UI States:**
  1. **No API Key:** Card shows info message: *"Ingresa tu Gemini API Key arriba para consultar los modelos disponibles en tu cuenta."*
  2. **Loading Models:** Shows subtle progress spinner with text *"Consultando modelos activos en Google AI..."*.
  3. **Models Loaded:**
     - `DropdownButtonFormField<String>` using modern `initialValue: currentModel`.
     - Dropdown items display formatted model names, version, and recommended badge (`⚡ RECOMENDADO`).
     - Refresh icon button (`Icons.refresh`) to re-query the Google API endpoint.
  4. **Error / Offline:** Shows error banner with *"No se pudieron consultar los modelos"* and a *"Reintentar"* button, keeping the last saved model or default fallback.

```dart
// Blueprint: lib/widgets/settings/gemini_model_selector_card.dart
class GeminiModelSelectorCard extends StatelessWidget {
  final bool hasApiKey;
  final bool isLoading;
  final List<String> availableModels;
  final String selectedModel;
  final ValueChanged<String> onModelSelected;
  final VoidCallback onRefreshModels;
  // Encapsulated UI keeping SettingsScreen < 250 LoC
}
```

### 2.4 Persistence & Propagation
* Store model name in `SecureStorageService` key `'selected_gemini_model'` (default: `'gemini-2.5-flash'`).
* Expose in `SettingsController`: `selectedGeminiModel`, `availableModels`, `fetchAvailableModels()`.
* Pass `selectedGeminiModel` to `GeminiVisionService` upon image analysis.
* Update `dashboard_screen.dart` loading dialog to display: `'Analizando con ${controller.selectedGeminiModel}...'`.

---

## 3. Requirement R2 UI: USDA FoodData Central API Key Integration

### 3.1 Problem & Requirement Analysis
To enhance ingredient verification, barcode recognition, and official food data beyond Open Food Facts, users need to provide their official USDA FoodData Central API key (`https://fdc.nal.usda.gov/api-key-signup.html`).

### 3.2 UI Component Specification: `UsdaApiKeyCard`
* **File Location:** `lib/widgets/settings/usda_api_key_card.dart` (~120 LoC).
* **Card Architecture:**
  - Header: `Row` with `Icons.eco_outlined` (color: `AppColors.protein`), title `USDA FOODDATA CENTRAL (FDC)`.
  - Status Badge:
    - If configured: `CONFIGURADA` (green background `AppColors.protein.withValues(alpha: 0.15)`, green text).
    - If not configured: `NO CONFIGURADA (FALLBACK OPEN FOOD FACTS)` (amber background `AppColors.carbs.withValues(alpha: 0.15)`).
  - Informative Description:
    *"Permite consultar la base de datos oficial del Departamento de Agricultura de EE.UU. (USDA FoodData Central) para obtener perfiles clínicos de nutrientes y códigos de barras."*
  - Obscured `TextField`:
    - `hintText: 'DemOKeY...'`
    - Visibility toggle icon button (`Icons.visibility_outlined` / `Icons.visibility_off_outlined`).
  - Action Row:
    - If configured: "Eliminar" outlined button.
    - "Guardar Key" elevated button (`AppColors.primary`).
    - Optional "Probar Conexión" test button that performs a lightweight ping to `https://api.nal.usda.gov/fdc/v1/foods/list?pageSize=1&api_key={KEY}`.

### 3.3 Persistence & Controller Integration
* Key: `SecureStorageService` key `'usda_api_key'`.
* Expose in `SettingsController`: `usdaApiKey`, `hasUsdaApiKey`, `saveUsdaApiKey(String key)`.

---

## 4. Requirement R3 UI & Logic: User Profile, Mifflin-St Jeor TDEE & Master Prompt

### 4.1 Mifflin-St Jeor Scientific Formulation

The Mifflin-St Jeor equation is the clinical gold standard for Basal Metabolic Rate (BMR / TMB):

#### 1. Basal Metabolic Rate (TMB / BMR)
$$\text{TMB}_{\text{Hombre}} = (10 \times \text{peso}_{\text{kg}}) + (6.25 \times \text{altura}_{\text{cm}}) - (5 \times \text{edad}_{\text{años}}) + 5$$
$$\text{TMB}_{\text{Mujer}} = (10 \times \text{peso}_{\text{kg}}) + (6.25 \times \text{altura}_{\text{cm}}) - (5 \times \text{edad}_{\text{años}}) - 161$$

#### 2. Total Daily Energy Expenditure (TDEE)
$$\text{TDEE} = \text{TMB} \times \text{Factor de Actividad Física}$$

| Activity Level | Multiplier | Physical Activity & Daily Steps Baseline |
|---|---|---|
| **Sedentario** | `1.200` | Trabajo de escritorio, poco/nada de ejercicio, < 5,000 pasos/día |
| **Ligero** | `1.375` | Ejercicio ligero 1–3 días/semana, 5,000–7,499 pasos/día |
| **Moderado** | `1.550` | Ejercicio moderado 3–5 días/semana, 7,500–9,999 pasos/día |
| **Muy Activo** | `1.725` | Ejercicio intenso 6–7 días/semana, $\ge$ 10,000 pasos/día |

#### 3. Target Caloric Goal (Meta Calórica)
- **Pérdida de grasa (Déficit calórico):** $\text{TargetKcal} = \text{TDEE} - 500\text{ kcal}$
- **Mantenimiento:** $\text{TargetKcal} = \text{TDEE}$
- **Ganancia de masa muscular (Superávit):** $\text{TargetKcal} = \text{TDEE} + 300\text{ kcal}$

#### 4. Automated Macro Goal Distribution
- **Proteína:** $2.0\text{ g por kg de peso corporal}$ (ej. $75\text{ kg} \times 2.0 = 150\text{ g} \rightarrow 600\text{ kcal}$).
- **Grasas:** $25\%$ del total calórico ($\text{TargetKcal} \times 0.25 / 9\text{ kcal/g}$).
- **Carbohidratos:** Calorías restantes divididas entre $4\text{ kcal/g}$ ($(\text{TargetKcal} - \text{ProtKcal} - \text{FatKcal}) / 4$).

### 4.2 Contextual Master Prompt Formulation
The generated Master Prompt is stored in local storage and injected directly into `GeminiVisionService`'s system instruction, providing the AI with biological context for every meal scan:

```text
Perfil metabólico y contexto del usuario comensal:
- Nombre: {name}
- Sexo biológico: {sex}, Edad: {age} años
- Estatura: {height} cm, Peso actual: {weight} kg
- Nivel de actividad física: {activityLevel} (~{estimatedSteps} pasos/día)
- Objetivo nutricional: {goal} ({goalKcalDelta})
- Meta calórica diaria: {targetCalories} kcal (TMB: {bmr} kcal, TDEE: {tdee} kcal)
- Metas de macronutrientes: Proteína: {protein}g | Carbohidratos: {carbs}g | Grasas: {fat}g

Directriz de estimación personalizada:
Ten en cuenta que este usuario sigue un plan de {goal}. Evalúa las porciones visibles considerando su contextura y metas nutricionales. Si el plato es denso en calorías o grasas no evidentes, haz énfasis en el cubicaje preciso y destaca el aporte relativo hacia sus metas diarias.
```

### 4.3 Screen Architecture & Atomic Decomposition (< 300 LoC)

To prevent monolithic bloat and keep `UserProfileScreen` under 220 LoC, all sub-sections are decomposed into atomic widgets under `lib/widgets/profile/`:

```
lib/
├── screens/
│   └── user_profile_screen.dart       # ~180 LoC (Orchestrator only)
└── widgets/
    └── profile/
        ├── biometric_inputs_card.dart         # ~110 LoC (Age, Sex, Height, Weight)
        ├── activity_goal_selector_card.dart   # ~120 LoC (Activity factor, Body goal)
        ├── metabolic_summary_bento_card.dart  # ~90 LoC (Live TMB, TDEE, Macros)
        ├── master_prompt_review_card.dart     # ~100 LoC (Prompt preview & custom notes)
        └── profile_sync_button.dart           # ~60 LoC (CTA to sync DailyGoals)
```

#### Detailed Widget Specifications:
1. `biometric_inputs_card.dart`:
   - Inputs for Name (`TextFormField`), Age (`int`), Biological Sex (`SegmentedButton<BiologicalSex>`: Hombre / Mujer), Height (`double` in cm), Weight (`double` in kg).
   - Real-time reactive notification on change so summary updates instantly.
2. `activity_goal_selector_card.dart`:
   - Activity level selector using styled selection tiles (Sedentario, Ligero, Moderado, Muy Activo) with step guidelines.
   - Body goal segmented pills: Pérdida de Grasa (-500 kcal) | Mantenimiento | Ganancia Muscular (+300 kcal).
3. `metabolic_summary_bento_card.dart`:
   - 2x2 mini Bento Grid:
     - Tile 1: **TMB (BMR)**: `1,745 kcal/día`.
     - Tile 2: **TDEE**: `2,705 kcal/día`.
     - Tile 3 (Hero): **Meta Calórica**: `2,205 kcal/día` (Déficit -500).
     - Tile 4: **Distribución de Macros**: Mini chips for Prot (`156g`), Carbs (`245g`), Grasas (`61g`).
4. `master_prompt_review_card.dart`:
   - Expandable card with preview of the generated prompt.
   - Copy-to-clipboard button.
   - Optional custom dietary notes field (e.g. "intolerancia a lactosa", "vegetariano", "preparación sin sal").
5. `profile_sync_button.dart`:
   - Primary button: "Guardar Perfil y Sincronizar Metas Diarias".
   - Automatically writes to `UserProfile`, formats and stores `MasterPrompt`, updates `DailyGoals`, and calls `MealController.refreshGoals()`.

---

## 5. Requirement R5 UI & Analytics: Dedicated Metrics Screen & Bento Grid

### 5.1 Charting Engine Decision Analysis

A thorough dependency analysis of `pubspec.yaml` shows:
- **`fl_chart` is currently NOT in `pubspec.yaml`.**

| Evaluation Criterion | Option A: Add `fl_chart: ^0.68.0` | Option B: Lightweight `CustomPainter` (Recommended) |
|---|---|---|
| **External Dependencies** | Adds large third-party package. | **Zero external dependencies.** |
| **Compatibility Risk** | Risk of version friction between Flutter 3.22/3.27 and Windows MSVC builds. | **100% stable, pure Flutter canvas.** |
| **Performance (FPS)** | 60 FPS with overhead on deep widget trees. | **Buttery smooth 120 FPS hardware-accelerated.** |
| **Brand Customization** | Requires overriding themes, paddings, and styles. | **Pixel-perfect match with Victor Engineer Bento Cards & Obsidian Zinc gradients.** |
| **Precedent in Project** | None. | Already established by `CaloriesHeroRing` (`_CaloriesRingPainter`). |

**Architecture Recommendation:**
Build high-performance, purpose-built `CustomPainter` widgets (`WeightLineChartPainter`, `CalorieIntakeBarPainter`, `MacroDistributionBarPainter`). If the team later chooses `fl_chart`, the widget interface remains identical because the data layer is isolated.

### 5.2 Bento Grid Layout Specification for `MetricsScreen`

```
┌─────────────────────────────────────────────────────────────┐
│  VeAppBar: "Métricas & Progreso" | "Victor Engineer"        │
├─────────────────────────────────────────────────────────────┤
│  [ 7 DÍAS ]       [ 30 DÍAS (Activo) ]       [ 90 DÍAS ]    │
├─────────────────────────────────────────────────────────────┤
│  HERO BENTO CARD: EVOLUCIÓN DE PESO                         │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Último: 74.8 kg   Delta: -1.4 kg   Meta: 72.0 kg      │  │
│  │ ───────────────────────────────────────────────────── │  │
│  │  ╭───╮                                                │  │
│  │ ╱     ╲      ╭───╮         [ Gráfico de Línea Suave   │  │
│  │        ╲    ╱     ╲          con Relleno Carmesí      │  │
│  │         ╰──╯       ╲         y Curva Bézier ]         │  │
│  │ ───────────────────────────────────────────────────── │  │
│  │ [+ Registrar Peso Hoy]                                │  │
│  └───────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│  BENTO CARD: INGESTA CALÓRICA VS META DIARIA                │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Promedio: 2,120 kcal/día | Balance: -280 kcal (Déficit)│  │
│  │ █  █  █  █  █  █  █  (Barras diarias vs línea de meta)│  │
│  └───────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│  BENTO CARD: DISTRIBUCIÓN MEDIA DE MACRONUTRIENTES          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ [ Proteína: 30% | Carbohidratos: 45% | Grasas: 25% ]  │  │
│  │ Barra segmentada horizontal con colores semánticos    │  │
│  └───────────────────────────────────────────────────────┘  │
├──────────────────────────────┬──────────────────────────────┤
│  BENTO CARD: RACHA ACTIVA    │  BENTO CARD: PASOS & HÁBITO  │
│  ┌────────────────────────┐  │  ┌────────────────────────┐  │
│  │ 🔥 7 Días Seguidos     │  │  │ 👟 8,420 pasos/día prom│  │
│  │ 92% adherencia de reg. │  │  │ Adherencia constante   │  │
│  └────────────────────────┘  │  └────────────────────────┘  │
└──────────────────────────────┴──────────────────────────────┘
```

### 5.3 Screen Architecture & Atomic Decomposition (< 300 LoC)

```
lib/
├── screens/
│   └── metrics_screen.dart            # ~140 LoC (Orchestrator only)
└── widgets/
    └── metrics/
        ├── metrics_range_selector.dart         # ~60 LoC (7D / 30D / 90D pills)
        ├── weight_trend_bento_card.dart        # ~130 LoC (Weight hero card)
        ├── weight_chart_painter.dart           # ~110 LoC (Bézier canvas painter)
        ├── calorie_compliance_bento_card.dart  # ~110 LoC (Daily bar chart)
        ├── macro_distribution_bento_card.dart  # ~90 LoC (Segmented bar)
        ├── streak_compliance_bento_card.dart   # ~75 LoC (Streak & steps)
        └── weight_log_dialog.dart              # ~120 LoC (Weight entry modal)
```

---

## 6. Seamless Navigation Integration Plan

To connect the new screens without cluttering `dashboard_screen.dart` (which is already at 287 LoC):

1. **Dashboard App Bar Actions (`lib/screens/dashboard_screen.dart`):**
   - Replace or complement the existing header icons:
   ```dart
   actions: [
     const Center(child: StreakBadge(streakDays: 3)),
     IconButton(
       icon: const Icon(Icons.insights_rounded),
       tooltip: 'Métricas y Progreso',
       onPressed: () => Navigator.of(context).push(
         MaterialPageRoute<void>(builder: (_) => const MetricsScreen()),
       ),
     ),
     IconButton(
       icon: const Icon(Icons.settings_outlined),
       tooltip: 'Ajustes',
       onPressed: () => Navigator.of(context).push(
         MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
       ),
     ),
   ]
   ```
2. **Settings Screen Links (`lib/screens/settings_screen.dart`):**
   - Add two navigation cards/tiles in `SettingsScreen`:
     - *"Perfil Metabólico y Master Prompt"* -> navigates to `UserProfileScreen`.
     - *"Panel de Métricas y Analíticas"* -> navigates to `MetricsScreen`.
3. **Daily Calorie Summary Card Interaction:**
   - Add an `onTap` listener on `DailyCalorieSummaryCard` to directly navigate to `MetricsScreen`.
4. **First-Run Onboarding Flow:**
   - In `main.dart` or `DashboardScreen.initState()`, if `UserProfile` is not yet configured, automatically navigate to `UserProfileScreen` or display an onboarding invite banner.

---

## 7. Quality Gate & Production Readiness Verification

1. **Monolithic Decomposition Compliance:**
   - `UserProfileScreen`: Projected ~180 LoC (< 300 LoC).
   - `MetricsScreen`: Projected ~140 LoC (< 300 LoC).
   - Existing `DashboardScreen`: 287 LoC (preserves < 300 LoC).
   - Refactor recommendation: Trim `MealDetailScreen` (301 LoC -> ~260 LoC).
2. **Memory Leak Defenses:**
   - All dialogs (`WeightLogDialog`, `ApiKeyPromptDialog`) are self-contained `StatefulWidget` instances with strict `initState` and `dispose` lifecycle overrides.
3. **Async Context Safety:**
   - All asynchronous calls guarded with `if (!mounted) return;` or `if (!context.mounted) return;`.
4. **Modern Flutter Tokens:**
   - Use `.withValues(alpha: ...)` via `theme_manager.dart`'s `ColorCompat`.
   - Use `initialValue:` in all `DropdownButtonFormField`.

---

## 8. Summary of Proposed Files for Phase 2 Implementation

```
lib/
├── models/
│   ├── user_profile.dart                 # (R3) Immutable profile model with Mifflin-St Jeor
│   └── weight_log.dart                   # (R4) Immutable weight log model with sentinel
├── services/
│   ├── gemini_models_service.dart        # (R1) Dynamic GET models fetcher
│   ├── usda_food_data_service.dart       # (R2) Typed USDA FDC client with fallback
│   └── secure_storage_service.dart       # (R1/R2/R3) Extended with model, USDA key, profile keys
├── controllers/
│   ├── settings_controller.dart          # (R1/R2) Extended for dynamic models & USDA
│   └── meal_controller.dart              # (R4/R5) Extended with weight logs & range queries
├── screens/
│   ├── user_profile_screen.dart          # (R3) < 300 LoC profile orchestrator
│   └── metrics_screen.dart               # (R5) < 300 LoC analytics orchestrator
└── widgets/
    ├── settings/
    │   ├── gemini_model_selector_card.dart # (R1) Reactive model dropdown
    │   └── usda_api_key_card.dart          # (R2) USDA key card with status
    ├── profile/
    │   ├── biometric_inputs_card.dart      # (R3) Age, sex, height, weight
    │   ├── activity_goal_selector_card.dart# (R3) Activity factor & body goal
    │   ├── metabolic_summary_bento_card.dart# (R3) TMB, TDEE, Macros preview
    │   ├── master_prompt_review_card.dart  # (R3) Master prompt preview & notes
    │   └── profile_sync_button.dart        # (R3) Sync DailyGoals CTA
    └── metrics/
        ├── metrics_range_selector.dart        # (R5) 7D, 30D, 90D range filter
        ├── weight_trend_bento_card.dart       # (R5) Weight evolution hero card
        ├── weight_chart_painter.dart          # (R5) Bézier curve line chart painter
        ├── calorie_compliance_bento_card.dart # (R5) Daily calorie bars vs target
        ├── macro_distribution_bento_card.dart # (R5) Segmented macro ratios
        ├── streak_compliance_bento_card.dart  # (R5) Streak & step metrics
        └── weight_log_dialog.dart             # (R4/R5) Weight entry dialog
```
