## 2026-10-04T22:16:56Z

You are Frontend-UI for Food Tracker v1.2.4.
Your working directory is:
C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\teamwork\frontend_ui_1

Read the authoritative requirements and architecture:
1. C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\teamwork\ORIGINAL_REQUEST.md (pay attention to all requests up to 2026-10-04T21:56:31Z).
2. C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\teamwork\explorer_frontend\handoff.md
3. C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\teamwork\explorer_pantry\handoff.md
4. C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\teamwork\backend_architect_1\handoff.md
5. C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\artifacts\planning\task.md
6. C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\artifacts\planning\implementation_plan.md
7. Relevant skills: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\skills\frontend-ui\SKILL.md and C:\Users\vmesp\.gemini\config\skills\flutter-production-engineering\SKILL.md

Exclusive Write Boundaries:
- lib/widgets/settings/json_file_picker_dialog.dart
- lib/screens/dashboard_screen.dart
- lib/widgets/dashboard/dashboard_fab_menu.dart
- lib/widgets/recommendations/what_to_eat_sheet.dart
- lib/widgets/dashboard/fasting_window_bento_card.dart
- lib/widgets/recommendations/recommendation_diagnostic_card.dart (or dialog)
- lib/widgets/metrics/weekly_digest_card.dart
- lib/screens/metrics_screen.dart
- lib/widgets/pantry/pantry_item_editor_dialog.dart (new file, < 200 LoC)
- lib/widgets/pantry/pantry_consumption_dialog.dart (new file, < 200 LoC)
- lib/screens/pantry_screen.dart
- lib/widgets/food/food_item_editor_dialog.dart
- android/app/src/main/res/layout/food_tracker_widget_wide.xml
- lib/assets/android_widgets/food_tracker_widget_wide.xml
- test/widgets/... (frontend widget tests)

Tasks to Implement:
1. R1 UI - Native File Picker Dialog:
   - In `lib/widgets/settings/json_file_picker_dialog.dart` (< 250 LoC): replace manual text input with a prominent 1-tap button using `FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'])`. When a file is selected, automatically trigger import or display the selected file path/name with a confirm button.
2. R2 UI - "¿Qué Debería Comer Hoy?" Reorganization & Modal Redesign:
   - In `lib/screens/dashboard_screen.dart`: remove the fixed `WhatToEatBannerCard` from the main scroll list (line ~250).
   - In `lib/widgets/dashboard/dashboard_fab_menu.dart`: add "¿Qué Debería Comer Hoy?" as a prominent action button/banner at the top of the SpeedDial/floating menu. Keep file < 300 LoC (extract helper widget if needed).
   - In `lib/widgets/recommendations/what_to_eat_sheet.dart`: wrap the modal in `SafeArea`, add an explicit top app bar/header with `IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.of(context).pop())`, apply height constraint (`maxHeight: MediaQuery.of(context).size.height * 0.85`), and ensure fluid scrolling without invading the status bar.
3. R3 UI - Dashboard & Metrics Fixes:
   - In `lib/widgets/dashboard/fasting_window_bento_card.dart` (< 280 LoC): transform into a compact collapsible Bento card. By default in inactive state show a compact pill/card (~44px), expanding smoothly with animation when active fasting or when tapped.
   - In `lib/widgets/recommendations/recommendation_diagnostic_card.dart` / dialog: fix text overlap by bounding dialog size and wrapping recommendations list in a scrollable view separate from the close button.
   - In `lib/widgets/metrics/weekly_digest_card.dart`: wrap badge in `Flexible`/`Expanded` to prevent horizontal overflow of "1/7 días con registro" on narrow screens.
   - In `lib/screens/metrics_screen.dart`: ensure `IntrinsicHeight` on streak/calorie row to prevent clipped container over macro card.
4. R4 UI - Pantry Grammage & Portion Scaling:
   - Create `lib/widgets/pantry/pantry_item_editor_dialog.dart` (< 200 LoC) extracted from `pantry_screen.dart`, including fields for reference portion in grams (`servingSize`, default 100g) and package net weight (`packageWeight`, e.g., 500g).
   - Create `lib/widgets/pantry/pantry_consumption_dialog.dart` (< 200 LoC) to log pantry items to meals with live macro scaling based on consumed grams using `pantryItem.toScaledFoodItem(gramsConsumed: grams)`.
   - In `lib/screens/pantry_screen.dart`: keep < 250 LoC by using the extracted dialogs.
   - In `lib/widgets/food/food_item_editor_dialog.dart`: ensure pantry item selection scales macros dynamically when grams are typed.
5. Android RemoteViews Fix (Priority Directive):
   - In `android/app/src/main/res/layout/food_tracker_widget_wide.xml` and `lib/assets/android_widgets/food_tracker_widget_wide.xml`:
     Replace forbidden `<View>` tags (lines 96, 129, 197) with `<FrameLayout>` (with matching layout_width, layout_height, background) to resolve `InflateException: Class not allowed to be inflated in RemoteViews: android.view.View`.
6. Modularity & Quality Gate:
   - Every created or modified file MUST be strictly < 300 LoC.
   - Run `flutter analyze` ensuring 0 errors and 0 warnings.
   - Run widget tests ensuring 100% pass.
