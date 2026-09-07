# Handoff Report — UI & Analytics Explorer (Phase 2)
**Victor Engineer - Food Tracker (NutriTracker Local-First)**

---

## 1. Observation

1. **Existing Screen Line Counts:**
   - `lib/screens/dashboard_screen.dart`: Exactly 287 lines.
     - Line 79 verbatim: `'Analizando con Gemini 2.5 Flash...\nCubicando volumen y macros.'`
     - Lines 220–234: `VeAppBar` with `StreakBadge(streakDays: 3)` and Settings button.
   - `lib/screens/meal_detail_screen.dart`: Exactly 301 lines.
     - **Constraint violation:** Exceeds the 300 LoC threshold by 1 line (301 > 300).
   - `lib/screens/settings_screen.dart`: Exactly 208 lines.
     - Lines 8–11: Imports existing cards `api_key_input_card.dart`, `backup_card.dart`, `daily_goals_card.dart`, `database_maintenance_card.dart`.
2. **Design Tokens & System (`DESIGN.md` & `lib/services/theme_manager.dart`):**
   - Obsidian Zinc palette: `#09090B` (scaffold background), `#121215` (card surface), `#18181B` (elevated surface), `#27272A` (border), `#DC2626` (Carmesí accent), `#FAFAFA` (text primary).
   - Macros: `#F97316` / `#DC2626` (calorías), `#10B981` / `#EF4444` (proteína), `#F59E0B` / `#EAB308` (carbs), `#0EA5E9` / `#3B82F6` (grasas).
   - Geometry: Bento card radius `20.0 px`, pill radius `32.0 px`, icon container `14.0 px`.
   - Typography: Google Fonts `Outfit` (display, metrics, headers) and `Inter` (body, inputs).
   - Modern standard compatibility: `lib/services/theme_manager.dart` lines 228–232 defines extension `ColorCompat` on `Color` for `.withValues(alpha: ...)`.
3. **Dependencies (`pubspec.yaml`):**
   - Lines 10–29: `fl_chart` is **NOT** present in `pubspec.yaml`.
   - Drawing custom graphics is already proven in the codebase by `lib/widgets/dashboard/calories_hero_ring.dart` (lines 65–114) using a hardware-accelerated `_CaloriesRingPainter` (`CustomPainter`).
4. **Current Gemini & Storage Implementation:**
   - `lib/services/gemini_vision_service.dart` line 91: `static const String defaultModel = 'gemini-2.5-flash';`. No dynamic listing endpoint query exists.
   - `lib/services/secure_storage_service.dart` lines 13–14: Only stores `gemini_api_key` and `daily_goals_json`. No keys for `selected_gemini_model`, `usda_api_key`, `user_profile_json`, or `master_prompt_text`.
   - `lib/widgets/settings/daily_goals_card.dart` lines 41–77: Only allows raw numeric manual goal inputs, without any connection to biometrics or Mifflin-St Jeor formulas.

---

## 2. Logic Chain

1. **Screen Monolith Prevention (< 300 LoC):**
   - *Premise:* Based on Observation 1, `dashboard_screen.dart` is at 287 LoC (95.6% of limit) and `meal_detail_screen.dart` is at 301 LoC.
   - *Inference:* New features (R3 User Profile and R5 Metrics) CANNOT be implemented inside existing screens or as monolithic new screens.
   - *Action:* We must create separate dedicated screens (`lib/screens/user_profile_screen.dart` and `lib/screens/metrics_screen.dart`) and strictly decompose their sub-sections into atomic widgets under `lib/widgets/profile/` and `lib/widgets/metrics/`. This ensures each screen stays between 140 and 180 LoC.
2. **Zero Hardcoding Gemini Models (R1):**
   - *Premise:* Observation 4 shows hardcoded `'gemini-2.5-flash'` in `GeminiVisionService` and `DashboardScreen`.
   - *Inference:* Querying `GET https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}`, filtering for `generateContent` and multimodal support, and storing the selected model in `SecureStorageService` allows total decoupling from Google's backend model lifecycle.
   - *UI Design:* Rather than bloating `SettingsScreen` (208 LoC), encapsulate the dropdown, loading, and refresh logic in `lib/widgets/settings/gemini_model_selector_card.dart`.
3. **USDA FDC API Key (R2):**
   - *Premise:* Observation 4 shows `SecureStorageService` only manages Gemini key and DailyGoals.
   - *Inference:* A modular card `lib/widgets/settings/usda_api_key_card.dart` keeps `SettingsScreen` clean while providing encrypted storage (`usda_api_key`) and visual status badges (`CONFIGURADA` / `NO CONFIGURADA`).
4. **Mifflin-St Jeor TDEE & Master Prompt Formulation (R3):**
   - *Premise:* Observation 4 shows goals are currently entered as disconnected static numbers in `DailyGoalsCard`.
   - *Inference:* By capturing biometrics (age, sex, height, weight) and activity factor, Mifflin-St Jeor determines clinical BMR and TDEE. Body goals (-500 kcal for fat loss, +300 kcal for muscle gain) calculate target calories, and the 2.0g/kg protein formula derives daily macro gram targets.
   - *Action:* The Master Prompt synthesized from these biometrics injected into `GeminiVisionService` ensures the AI understands the user's bodily frame and dietary goals on every photo scan.
5. **Chart Implementation Strategy for R5:**
   - *Premise:* Observation 3 shows `fl_chart` is absent from `pubspec.yaml`, whereas `CustomPainter` is already proven in `calories_hero_ring.dart`.
   - *Inference:* Implementing `WeightLineChartPainter` and `CalorieIntakeBarPainter` using pure Flutter canvas eliminates dependency version conflicts, avoids build breakages across platforms, guarantees 120 FPS hardware-accelerated rendering, and matches the Victor Engineer Obsidian Zinc gradient aesthetic seamlessly.

---

## 3. Caveats

1. **No External Chart Library Currently Installed:**
   - If the orchestrator or implementer insists on using `fl_chart`, `pubspec.yaml` will need to be modified with `fl_chart: ^0.68.0` and `flutter pub get` must be run. However, the custom painter approach is completely self-contained and avoids all external package risks.
2. **MealDetailScreen Pre-existing Violation:**
   - `lib/screens/meal_detail_screen.dart` is at 301 LoC. While not directly modified in Phase 2 feature requirements, the implementation team should trim 2–5 lines (e.g. factoring out `_buildSaveButton`) to restore 100% project-wide compliance with the < 300 LoC constraint.
3. **Offline Mode for Gemini Model Discovery:**
   - When the user device has no internet connection, dynamic fetching of Gemini models will fail; the system must gracefully fall back to cached models or the default `'gemini-2.5-flash'` without crashing.

---

## 4. Conclusion

1. **Architecture Ready for Implementation:**
   - Comprehensive UI survey report delivered at: `C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_survey_3\survey_report.md`.
2. **Atomic Decomposition Plan:**
   - `lib/screens/user_profile_screen.dart` (~180 LoC) supported by 5 atomic widgets in `lib/widgets/profile/`.
   - `lib/screens/metrics_screen.dart` (~140 LoC) supported by 7 atomic widgets in `lib/widgets/metrics/`.
   - `SettingsScreen` extended via 2 standalone cards in `lib/widgets/settings/` (`gemini_model_selector_card.dart` and `usda_api_key_card.dart`).
3. **Zero Hardcoding & Full Local-First Integration:**
   - Reactive discovery of Gemini models.
   - Encrypted hardware storage for USDA and Gemini keys.
   - Automated Mifflin-St Jeor TMB/TDEE calculation and Master Prompt generation.

---

## 5. Verification Method

1. **Inspect Survey Report:**
   ```bash
   # View survey report
   view_file: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_survey_3\survey_report.md
   ```
2. **Verify Screen Line Counts:**
   ```powershell
   # In PowerShell, count lines of existing screens:
   Get-Content lib\screens\dashboard_screen.dart | Measure-Object -Line
   Get-Content lib\screens\meal_detail_screen.dart | Measure-Object -Line
   Get-Content lib\screens\settings_screen.dart | Measure-Object -Line
   ```
3. **Verify Static Analysis & Flutter Environment:**
   ```powershell
   flutter analyze
   ```
   Ensures zero warnings or deprecations when new files are introduced.
4. **Invalidation Conditions:**
   - If any new screen in `lib/screens/` exceeds 300 lines of code.
   - If hardcoded Gemini model strings remain in `dashboard_screen.dart` or `gemini_vision_service.dart`.
   - If `DailyGoals` fails to update automatically after saving the user profile.
