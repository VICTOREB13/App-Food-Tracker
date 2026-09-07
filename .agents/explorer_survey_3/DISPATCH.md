## 2026-09-07T16:06:48Z
You are the UI & Analytics Explorer for Phase 2 of Victor Engineer - Food Tracker (NutriTracker Local-First).
Your working directory is: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_survey_3
You MUST read the authoritative user request at: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\ORIGINAL_REQUEST.md before doing anything else.

Objective:
Investigate UI architecture, existing screens, and design specifications for Phase 2:
1. Existing UI structure (`lib/screens/`, `lib/widgets/`, `lib/theme/` or design tokens):
   - Current line count of all screens in `lib/screens/` (checking the < 300 LoC hard constraint).
   - How navigation and state management are handled across screens (e.g. `HomeScreen`, `SettingsScreen`, etc.).
   - Victor Engineer design system: `DESIGN.md`, colors (`#09090B`, `#121215`, Carmesí `#DC2626`, Google Fonts Outfit/Inter).
2. Requirement R1 UI:
   - `SettingsScreen` modifications for dynamic Gemini model selector (fetching models reactively when API key is present, dropdown with recommendations, refreshing models).
3. Requirement R2 UI:
   - `SettingsScreen` input for USDA FoodData Central API Key with secure storage and status indicator.
4. Requirement R3 UI & Logic:
   - `UserProfileScreen` / `OnboardingScreen` structure: biometric inputs (age, biological sex, height, weight, activity level, body goal).
   - Mifflin-St Jeor TMB/TDEE calculation formula and automatic goal recalculation (`DailyGoals`).
   - Master Prompt formulation and review UI.
   - Screen decomposition into atomic widgets in `lib/widgets/profile/` to keep the screen < 300 LoC.
5. Requirement R5 UI & Analytics:
   - `MetricsScreen` / `MetricsBentoCard` layout: Bento Grid layout, weight trend chart, daily calorie intake vs target, macro distribution, streak/step compliance.
   - Screen decomposition into atomic widgets in `lib/widgets/metrics/` to keep < 300 LoC.
   - Chart library or custom painting (check `pubspec.yaml` for `fl_chart` or similar dependencies).

Scope Boundaries:
- READ-ONLY exploration. DO NOT edit or create source code files.
- Write only to your working directory.

Output Requirements:
- Write your complete UI analysis and decomposition plan to: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_survey_3\survey_report.md
- Deliver your handoff and send a completion message to the orchestrator.
