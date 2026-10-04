# Handoff Report — Explorer Frontend (Food Tracker v1.2.4)

## 1. Observation

A deep static and architectural investigation was conducted across the Flutter UI codebase to address requirements **R2** (Ergonomic Relocation & Redesign of "¿Qué Debería Comer Hoy?") and **R3** (Dashboard Reorganization, Intermittent Fasting Positioning, and Metrics Overflow Fixes).

### 1.1 Line of Code (LoC) Metrics Audit
All 12 related files were audited against the project standard of `< 300 LoC`:

| File Path | Current LoC | Modularity Risk |
|---|---|---|
| `lib/screens/dashboard_screen.dart` | 271 | Safe (<300) |
| `lib/widgets/dashboard/what_to_eat_banner_card.dart` | 123 | Safe |
| `lib/widgets/dashboard/dashboard_fab_menu.dart` | **291** | **High (9 lines to limit)** |
| `lib/widgets/recommendations/what_to_eat_sheet.dart` | **282** | **High (18 lines to limit)** |
| `lib/widgets/dashboard/fasting_window_bento_card.dart` | **286** | **High (14 lines to limit)** |
| `lib/widgets/recommendations/recommendation_diagnostic_card.dart` | 239 | Safe |
| `lib/screens/metrics_screen.dart` | 225 | Safe |
| `lib/widgets/metrics/weekly_digest_card.dart` | **288** | **High (12 lines to limit)** |
| `lib/widgets/metrics/calorie_compliance_bento_card.dart` | 179 | Safe |
| `lib/widgets/metrics/streak_compliance_bento_card.dart` | 202 | Safe |
| `lib/widgets/metrics/macro_distribution_bento_card.dart` | 258 | Safe |
| `lib/controllers/fasting_controller.dart` | 145 | Safe |

Four files (`dashboard_fab_menu.dart`, `what_to_eat_sheet.dart`, `fasting_window_bento_card.dart`, `weekly_digest_card.dart`) are within 9-18 lines of the 300 LoC threshold. Any refactoring must extract sub-widgets into dedicated components to avoid exceeding the modular limit.

---

### 1.2 Dashboard Navigation & "¿Qué Debería Comer Hoy?" Relocation (R2)
- **Current Placement in Dashboard**:
  - `lib/screens/dashboard_screen.dart`: lines 249–251
    ```dart
    const SizedBox(height: 12),
    WhatToEatBannerCard(selectedDate: _mealController.selectedDate),
    const SizedBox(height: 12),
    const FastingWindowBentoCard(),
    ```
    `WhatToEatBannerCard` is rendered as an uncollapsible, fixed card in the main `ListView` above `FastingWindowBentoCard`. It occupies ~120px of vertical height unconditionally, adding cognitive noise and pushing meal cards below the fold.
- **SpeedDial Navigation**:
  - `lib/widgets/dashboard/dashboard_fab_menu.dart`: lines 51–211
    - Opened via `showModalBottomSheet(isScrollControlled: true)`.
    - Features a 2-column grid (`GridView.count(crossAxisCount: 2)`) with 8 actions: 'Foto con IA', 'Galería', 'Código Barras', 'Manual', '+250ml Agua', 'Rápida', 'Voz / Audio', 'Video Pan'.
    - Currently lacks any entry point for "¿Qué debería comer hoy?".

---

### 1.3 Modal Sheet Inspection (`Screenshot_20261004-172008.jpg` / R2)
- **Visual Defect Observed**:
  - In `Screenshot_20261004-172008.jpg`, the sheet invades the Android system status bar (5:20, battery 95%, Wi-Fi).
  - The header title "¿Qué debería comer hoy?" and the top green icon container are physically cut off by the status bar indicators and device notch area.
  - There is **no close button** (`IconButton(icon: Icon(Icons.close))`) anywhere in the sheet.
  - The entire body is a single `SingleChildScrollView` without bounded height constraints.
- **Root Code Cause**:
  - `lib/widgets/recommendations/what_to_eat_sheet.dart`: lines 107–162
    ```dart
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: ... SingleChildScrollView(
        child: Column(
          children: [
            // Drag handle
            // Row with Icon + Expanded(Title + Subtitle) -> NO CLOSE BUTTON
    ```
    When opened with `isScrollControlled: true` without `SafeArea(top: true)` and without `BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88)`, the container expands to 100% of the screen height under the status bar.

---

### 1.4 Intermittent Fasting Card Inspection (R3)
- **State Management**:
  - `lib/controllers/fasting_controller.dart`: 145 LoC. Manages `isFastingActive`, `targetHours`, `progressRatio`, `fastingDurationFormatted`, `remainingDurationFormatted`, `startFast()`, `stopActiveFast()`.
- **Current UI Behavior**:
  - `lib/widgets/dashboard/fasting_window_bento_card.dart`: lines 147–284
  - Always renders a full 56px progress ring (`VeLoadingRing`), multi-line text ("Sin ayuno activo / Inicia para dar seguimiento..."), and an "Iniciar" button (~90-100px height) even when the user is not fasting.
  - Does not collapse to a discreet state.

---

### 1.5 Nutritional Recommendation Dialog (`Screenshot_20261004-172027.jpg` / R3)
- **Visual Defect Observed**:
  - In `Screenshot_20261004-172027.jpg`, the "Cerrar" text button in the dialog actions is rendered directly on top of the text lines of "Sustituciones Inteligentes Sugeridas" ("Salsas cremosas y mayonesa -> Yogur...").
  - The suggestions are partially occluded and not cleanly scrollable above the action button.
- **Root Code Cause**:
  - `lib/widgets/dashboard/what_to_eat_banner_card.dart`: lines 26–50
    ```dart
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: RecommendationDiagnosticCard(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cerrar', ...),
          ),
        ],
      ),
    );
    ```
  - In Material 3 `AlertDialog`, when `SingleChildScrollView` content has unbounded height inside `AlertDialog` and exceeds viewport height, `actions` overlays the bottom padding area of the scroll view.
  - `RecommendationDiagnosticCard` (lines 120–125) renders swaps without bottom inset padding, causing direct collision with the overlay action button.

---

### 1.6 MetricsScreen & WeeklyDigestCard (`Screenshot_20261004-172452.jpg` / R3)
- **Defect A: Badge Horizontal Overflow**:
  - In `Screenshot_20261004-172452.jpg`, the badge "1/7 días con registro" overflows the right margin of `WeeklyDigestCard`.
  - In `lib/widgets/metrics/weekly_digest_card.dart`: lines 82–116
    ```dart
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_graph_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('RESUMEN SEMANAL (7 DÍAS)', ...),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text('$loggedDaysCount / 7 días con registro', ...),
        ),
      ],
    )
    ```
    Neither the title `Row` nor the badge `Container` is wrapped in `Expanded` or `Flexible`.
    Width required: Icon(20) + gap(8) + Title(175) + gap(8) + Badge(141) = ~352dp.
    Available width on 360dp phone inside card: `360 - 32 (screen margin) - 32 (card padding) = 296dp`.
    The content overflows by ~56dp, clipping the badge and triggering RenderFlex overflow.
- **Defect B: Clipped Top Container over Macro Distribution Card**:
  - In `Screenshot_20261004-172452.jpg`, at the top of the viewport above `MacroDistributionBentoCard`, a rounded white card bottom is cut off on the right, while the left side is empty.
  - In `lib/screens/metrics_screen.dart`: lines 126–152
    ```dart
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: CalorieComplianceBentoCard(...)),
        const SizedBox(width: 12),
        Expanded(child: StreakComplianceBentoCard(...)),
      ],
    )
    ```
    `StreakComplianceBentoCard` (lines 164 & 188) includes a multi-line consistency subtitle and a 3-line motivational message ("Registra tus comidas para crear el hábito"), making it ~45px taller than `CalorieComplianceBentoCard`.
    Because `CrossAxisAlignment.start` is used, the right card dangles ~45px lower than the left card. When scrolled, `StreakComplianceBentoCard` sticks down into the gap above `MacroDistributionBentoCard` as an asymmetric clipped container.

---

## 2. Logic Chain

1. **R2 Relocation Reasoning**:
   - `WhatToEatBannerCard` in `dashboard_screen.dart` is static. Removing it from the main `ListView` frees 120px of vertical space, placing actual meals higher on the screen.
   - `DashboardFabMenu` is the primary entry point for food and nutrition tracking actions. Adding a highlighted hero banner (`onWhatToEat`) right above the 2-column grid in `DashboardFabMenu` elevates "¿Qué debería comer hoy?" as an ergonomic, intentional action without dashboard clutter.
2. **R2 Modal Sheet Redesign Reasoning**:
   - By enclosing `WhatToEatSheet` in `SafeArea(top: true, bottom: true)` with `constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88)`, the modal will never collide with the Android status bar or notch.
   - Separating the sheet into a **pinned header** (drag handle + icon + title/subtitle + `IconButton(icon: Icon(Icons.close))`) and a **scrollable body** (`Expanded(child: ListView(...))`) guarantees that the close button is always visible and accessible, while dish options scroll smoothly with fluid bouncing physics.
3. **R3 Fasting Bento Card Reasoning**:
   - `FastingController` already exposes `isFastingActive`.
   - When `!isFastingActive`: render a sleek, compact Bento pill (~42-46px height) showing "Ayuno Intermitente • Sin ayuno activo" with a subtle timer icon and tap-to-start affordance.
   - When tapped or when `isFastingActive == true`: smoothly animate (`AnimatedSize` / `AnimatedCrossFade`, ~250ms) into the expanded view with circular progress ring, duration counter, and action controls.
4. **R3 Nutrition Diagnostic Dialog Reasoning**:
   - Replacing `AlertDialog`'s default layout with a structured `Dialog` containing a pinned title header (with `IconButton(icon: Icon(Icons.close))`) and wrapping `RecommendationDiagnosticCard` inside `Flexible(child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(16, 12, 16, 24), child: ...))` ensures that the content can be scrolled fully without any text hidden behind action buttons.
5. **R3 Metrics Screen Overflow Fix Reasoning**:
   - In `WeeklyDigestCard`: wrapping the title in `Expanded(child: ...)` with `TextOverflow.ellipsis`, and using a compact/responsive badge (`$loggedDaysCount/7 días` or `Flexible` layout), guarantees that the header fits within 296dp on 360dp mobile viewports without horizontal clipping.
   - In `MetricsScreen`: wrapping the Calorie & Streak compliance `Row` in `IntrinsicHeight` with `CrossAxisAlignment.stretch`, and harmonizing the footer height of `StreakComplianceBentoCard` to match `CalorieComplianceBentoCard`, ensures both cards end at the exact same horizontal baseline, completely eliminating the dangling clipped artifact above `MacroDistributionBentoCard`.

---

## 3. Caveats

1. **File Length Discipline (<300 LoC)**:
   - `dashboard_fab_menu.dart` currently has 291 lines. Adding the hero banner for "¿Qué debería comer hoy?" directly could push the file over 300 lines. The action button builder should be kept lean or extracted into a private helper widget.
   - `what_to_eat_sheet.dart` (282 lines) and `fasting_window_bento_card.dart` (286 lines) must also be edited with concise widget decomposition so they remain strictly <300 LoC.
2. **Backward Compatibility with Widget Tests**:
   - `test/widgets/recommendations_widgets_test.dart` checks for specific text strings ('¿Qué debería comer hoy?', 'Margen restante de hoy:', 'Pechuga de Pollo con Quinoa y Espárragos', 'MOTOR DE RECOMENDACIÓN NUTRICIONAL', etc.). All text anchors must be preserved.
3. **Device Scaling**:
   - Font scaling (Android accessibility settings) can increase text height by up to 1.3x. All header labels must use `overflow: TextOverflow.ellipsis` with `maxLines: 1`.

---

## 4. Conclusion & Technical Design

### Proposal 1: Dashboard Reorganization & FAB Menu Integration (R2)
- In `lib/screens/dashboard_screen.dart`:
  - Remove line 250: `WhatToEatBannerCard(selectedDate: _mealController.selectedDate)`.
  - Pass `onWhatToEat: () => _openWhatToEatSheet(context)` to `DashboardFabMenu`.
  - Implement `_openWhatToEatSheet(BuildContext context)`:
    ```dart
    void _openWhatToEatSheet(BuildContext context) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => WhatToEatSheet(date: _mealController.selectedDate),
      );
    }
    ```
- In `lib/widgets/dashboard/dashboard_fab_menu.dart`:
  - Add parameter `final VoidCallback? onWhatToEat;`.
  - In `_openSpeedDialSheet()`, render a prominent action card right above the `GridView`:
    ```dart
    if (widget.onWhatToEat != null) ...[
      _buildWhatToEatHeroAction(sheetContext),
      const SizedBox(height: 12),
    ],
    ```
  - Style `_buildWhatToEatHeroAction` with `AppColors.protein.withValues(alpha: 0.12)` background, `Icons.auto_awesome` icon, title "¿Qué debería comer hoy?", and subtitle "Sugerencias según tus macros".

### Proposal 2: WhatToEatSheet SafeArea & Header Redesign (R2)
- In `lib/widgets/recommendations/what_to_eat_sheet.dart`:
  - Wrap the root container in `SafeArea(top: true, bottom: true)` with:
    ```dart
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.88,
    ),
    ```
  - Structure as a `Column(mainAxisSize: MainAxisSize.min)`:
    1. Drag handle (`Container(width: 36, height: 4, ...)`).
    2. Pinned Header `Row`:
       - Utensils icon container
       - `Expanded(child: Column(title, subtitle))`
       - `IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop())`
    3. `const Divider(height: 1)`
    4. Scrollable Body inside `Flexible(child: SingleChildScrollView(padding: ..., child: Column(...)))` with remaining macros strip, general advice, and recommended dish cards.
    5. Action button for opening the diagnostic dialog (`RecommendationDiagnosticCard`).

### Proposal 3: Intermittent Fasting Compact & Expandable Bento Card (R3)
- In `lib/widgets/dashboard/fasting_window_bento_card.dart`:
  - Add state `bool _isManuallyExpanded = false;`.
  - When `!controller.isFastingActive && !_isManuallyExpanded`:
    - Render a compact Bento row (~44px height):
      - Icon: `Icon(Icons.timer_outlined, size: 18, color: AppColors.primary)`
      - Text: "Ayuno Intermitente" • "Sin ayuno activo"
      - Trailing: Subtle "Iniciar" chip or `Icons.keyboard_arrow_down`
      - `onTap`: `setState(() => _isManuallyExpanded = true)` or `_showStartFastDialog()`.
  - When `controller.isFastingActive || _isManuallyExpanded`:
    - Render full Bento card with `VeLoadingRing`, active timer, goal status, and "Terminar" button.
    - If `_isManuallyExpanded` while inactive, include a collapse toggle (`Icons.keyboard_arrow_up`).
  - Wrap transition in `AnimatedSize(duration: Duration(milliseconds: 240), curve: Curves.easeInOut)`.

### Proposal 4: RecommendationDiagnosticCard Dialog Fix (R3)
- In `lib/widgets/dashboard/what_to_eat_banner_card.dart` (or helper function `showRecommendationDiagnosticDialog(context)`):
  - Replace default `AlertDialog` with a bounded `Dialog`:
    ```dart
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.border(context))),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 400, maxHeight: MediaQuery.of(context).size.height * 0.82),
        child: Column(
          children: [
            // Pinned header with title + IconButton(Icons.close)
            // Flexible(child: SingleChildScrollView(padding: EdgeInsets.all(16), child: RecommendationDiagnosticCard(...)))
          ],
        ),
      ),
    )
    ```
  - This guarantees that suggested substitutions (`fatReductionSwaps`) never overlap with a close button and are 100% scrollable.

### Proposal 5: WeeklyDigestCard & MetricsScreen Fixes (R3)
- In `lib/widgets/metrics/weekly_digest_card.dart`:
  - Replace line 82 header with:
    ```dart
    Row(
      children: [
        const Icon(Icons.auto_graph_rounded, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'RESUMEN SEMANAL (7 DÍAS)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.textSecondary(context)),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(
            '$loggedDaysCount/7 días',
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
      ],
    )
    ```
- In `lib/screens/metrics_screen.dart`:
  - Wrap the Calorie & Streak compliance `Row` with `IntrinsicHeight`:
    ```dart
    IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: CalorieComplianceBentoCard(...)),
          const SizedBox(width: 12),
          Expanded(child: StreakComplianceBentoCard(...)),
        ],
      ),
    )
    ```
  - In `lib/widgets/metrics/streak_compliance_bento_card.dart`:
    - Ensure the footer container has consistent height with `CalorieComplianceBentoCard`, preventing asymmetric downward dangling.

---

## 5. Verification Method

1. **Inspection of Visual Anchors**:
   - Inspect `WhatToEatSheet` header for `SafeArea`, `BoxConstraints(maxHeight: ...)`, and `IconButton(icon: Icon(Icons.close))`.
   - Inspect `DashboardFabMenu` for `onWhatToEat` hero card integration.
   - Inspect `FastingWindowBentoCard` for compact inactive state and animated expansion.
   - Inspect `WeeklyDigestCard` header for `Expanded` title and responsive badge.
   - Inspect `MetricsScreen` Bento Row for `IntrinsicHeight`.
2. **Automated Unit & Widget Tests**:
   - Run widget test suite:
     ```bash
     flutter test test/widgets/recommendations_widgets_test.dart
     flutter test test/widgets/weekly_digest_card_test.dart
     ```
   - Add new widget test cases:
     - `WhatToEatSheet` displays close button and closes on tap.
     - `FastingWindowBentoCard` renders compact bar when inactive and expands when tapped.
     - `WeeklyDigestCard` renders on narrow viewport (e.g., 320x640) without `RenderFlex` overflow.
3. **Static Analysis & LoC Compliance**:
   ```bash
   flutter analyze
   ```
   Verify that all modified files have `< 300 LoC`.
