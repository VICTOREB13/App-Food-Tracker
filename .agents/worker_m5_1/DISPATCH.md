## 2026-09-07T17:18:37Z

You are Worker M5.1 (teamwork_preview_worker) implementing Phase 2 Milestone 5: Metrics Screen & Bento Dashboard for Victor Engineer - Food Tracker (NutriTracker Local-First).

Authoritative user request:
C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\ORIGINAL_REQUEST.md
You MUST read this file first before taking any action.

Your assigned working directory:
C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\worker_m5_1
All your logs, progress notes, and handoff report must be written in this directory.

PROJECT ARTIFACTS & STANDARDS TO READ:
1. C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\orchestrator_1\PROJECT.md
2. C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\lib\models\weight_log.dart
3. C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\lib\services\database_service.dart (see getWeightLogsByRange, getWeightLogsLastDays, insertWeightLog, deleteWeightLog)
4. C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\lib\controllers\meal_controller.dart (see loadWeightLogs, recordWeight, deleteWeight, weightLogs, latestWeightLog, dailyGoals)
5. C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\lib\screens\dashboard_screen.dart (286 LoC -> must remain strictly < 300 LoC)
6. Skill instructions:
   - C:\Users\vmesp\.gemini\config\skills\flutter-production-engineering\SKILL.md
   - C:\Users\vmesp\.gemini\config\skills\sqlite-local-first-flutter\SKILL.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

EXCLUSIVE FILE WRITE OWNERSHIP:
You have exclusive write ownership for:
- lib/screens/metrics_screen.dart
- lib/widgets/metrics/weight_line_chart_painter.dart
- lib/widgets/metrics/weight_trend_bento_card.dart
- lib/widgets/metrics/calorie_compliance_bento_card.dart
- lib/widgets/metrics/macro_distribution_bento_card.dart
- lib/widgets/metrics/streak_compliance_bento_card.dart
- lib/widgets/metrics/quick_weight_entry_dialog.dart
- lib/screens/dashboard_screen.dart
- test/widgets/weight_line_chart_painter_test.dart
- test/widgets/quick_weight_entry_dialog_test.dart
- test/screens/metrics_screen_test.dart

TECHNICAL & ARCHITECTURAL REQUIREMENTS:
1. `lib/widgets/metrics/weight_line_chart_painter.dart`:
   - Hardware-accelerated `CustomPainter` for smooth 60/120 FPS weight trend visualization.
   - Takes `List<WeightLog> logs`, `Color lineColor`, `Color gradientColor`, `Color gridColor`, `TextStyle labelStyle`.
   - Handles edge cases safely: 0 logs (draws subtle empty placeholder/text), 1 log (draws single distinct marker and baseline), 2+ logs (calculates min/max Y with padding, maps points to canvas, draws smooth cubic Bézier or connected line, subtle horizontal grid lines at min/mid/max, and gradient fill beneath the curve with `AppColors.primary.withValues(alpha: 0.15)` to `alpha: 0.0`).
   - Pure painting logic without crashes, NaN, or infinite coordinates.

2. `lib/widgets/metrics/quick_weight_entry_dialog.dart`:
   - Standalone modal dialog: `Future<void> showQuickWeightEntryDialog(BuildContext context, {double? initialWeight})`.
   - Obsidian Zinc theme with Carmesí accent (`AppColors.primary`).
   - Fields: Weight in kg (numeric TextField with 1 decimal point, e.g. `78.5`), optional notes, date picker (defaults to today).
   - Validation: Weight must be between 20.0 and 350.0 kg. Shows inline error if invalid.
   - Saves via `MealController.instance.recordWeight(weight, notes: notes, date: selectedDate)`.
   - Mounted context checks on all async callbacks. All TextControllers disposed properly.

3. Atomic Bento Cards in `lib/widgets/metrics/`:
   - `weight_trend_bento_card.dart`:
     - Embeds `CustomPaint(painter: WeightLineChartPainter(...))` with height ~160-180px.
     - Header: Current weight (`${current.toStringAsFixed(1)} kg`), start weight, net delta (e.g. `-${delta.abs().toStringAsFixed(1)} kg` in `AppColors.protein` or `+...` in `AppColors.carbs`), trend icon (`trending_down`, `trending_up`, `trending_flat`).
     - Quick action button: "Registrar Peso" button invoking `showQuickWeightEntryDialog`.
   - `calorie_compliance_bento_card.dart`:
     - Shows daily average calorie intake over selected range vs daily target (`MealController.instance.dailyGoals.calories`).
     - Progress bar / circular indicator with compliance percentage and status ("Déficit saludable", "Mantenimiento", "Superávit").
   - `macro_distribution_bento_card.dart`:
     - Shows average intake of Protein, Carbs, Fat in grams and percentage distribution.
     - Color-coded indicators with `AppColors.protein` (Emerald), `AppColors.carbs` (Amber), `AppColors.fat` (Rose).
   - `streak_compliance_bento_card.dart`:
     - Shows active streak (e.g. "Racha de 7 días"), consistency metric (e.g. "5 de 7 días registrados"), motivational status badge.

4. `lib/screens/metrics_screen.dart` (< 300 LoC):
   - Dedicated screen with `VeAppBar` (Title: "Métricas y Progreso", Subtitle: "Analítica Local-First").
   - Segmented selector or ChoiceChips for time range: `7 días`, `30 días`, `90 días`.
   - Selecting a range calls `_mealController.loadWeightLogs(days: selectedDays)`.
   - Reactive to `MealController.instance` with `addListener` in `initState()` and `removeListener` in `dispose()`.
   - Bento layout (`ListView` with 16px padding) embedding:
     1. Time range filter
     2. `WeightTrendBentoCard`
     3. Row / Bento grid with `CalorieComplianceBentoCard` and `StreakComplianceBentoCard`
     4. `MacroDistributionBentoCard`
   - FloatingActionButton to quickly log weight via `showQuickWeightEntryDialog`.
   - Strictly keep `< 300 LoC`.

5. `lib/screens/dashboard_screen.dart` (< 300 LoC):
   - Add a Metrics button in `VeAppBar.actions`:
     `IconButton(icon: const Icon(Icons.insights_outlined), tooltip: 'Métricas', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MetricsScreen())))`
   - Strictly keep `< 300 LoC` (currently 286 lines).

6. Tests:
   - `test/widgets/weight_line_chart_painter_test.dart` (unit test for chart painter with 0, 1, and N points, bounds validation).
   - `test/widgets/quick_weight_entry_dialog_test.dart` (widget test for dialog validation, valid submission, and cancellation).
   - `test/screens/metrics_screen_test.dart` (widget test for MetricsScreen range switching and card rendering).
   - Write a self-contained empirical verification script `scripts/empirical_worker_m5_harness.py` to verify line counts, AST tokens, zero `.withOpacity`, and business logic hermetically without needing external SDKs.

YOUR DELIVERABLES:
1. Implement all files with clean, production-ready code.
2. Run build and tests (or your empirical test harness).
3. Document commands run, test pass/fail results, and verified files in `C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\worker_m5_1\handoff.md`.
4. Send a message back to the orchestrator reporting completion with the path to your handoff.md.
