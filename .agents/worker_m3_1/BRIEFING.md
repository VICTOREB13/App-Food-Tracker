# BRIEFING — 2026-09-07T17:02:00Z

## Mission
Implement Phase 2 Milestone 3: Metabolic Engine & User Profile Screen for Victor Engineer - Food Tracker (NutriTracker Local-First) with strict architectural standards, Mifflin-St Jeor formulas, and < 300 LoC modular screen decomposition.

## 🔒 My Identity
- Archetype: teamwork_preview_worker
- Roles: implementer, qa, specialist
- Working directory: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\worker_m3_1
- Original parent: e9a249e5-aff8-48e0-b2bd-313ce42895c9
- Milestone: Milestone 3 (Metabolic Engine & User Profile Screen)

## 🔒 Key Constraints
- Mifflin-St Jeor BMR calculation:
  - Male: (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5
  - Female: (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161
- Activity Multipliers:
  - sedentary: 1.2
  - light: 1.375
  - moderate: 1.55
  - very_active: 1.725
- Caloric Goal calculation:
  - fat_loss: TDEE - 500 (floor at BMR)
  - maintenance: TDEE
  - muscle_gain: TDEE + 300
- Macronutrient Distribution:
  - Protein: 2.0 g/kg (fat_loss), 1.8 g/kg (maintenance), 2.2 g/kg (muscle_gain)
  - Fat: 25% of target calories / 9 (minimum 0.8 g/kg)
  - Carbs: (Target calories - protein*4 - fat*9) / 4
- Screen Modular Monolith (< 300 LoC per screen in `lib/screens/`):
  - Decompose `user_profile_screen.dart` into atomic widgets in `lib/widgets/profile/`
- Design System: Victor Engineer (*Obsidian Zinc* `#09090B`, `#121215`, Card `#18181B`, Carmesí `#DC2626`, Google Fonts `Outfit`/`Inter`).
- Master Prompt generation in Markdown format.
- Exclusive write ownership:
  - `lib/services/metabolic_calculator.dart`
  - `lib/screens/user_profile_screen.dart`
  - `lib/widgets/profile/biometric_inputs_card.dart`
  - `lib/widgets/profile/activity_goal_selector_card.dart`
  - `lib/widgets/profile/metabolic_summary_bento_card.dart`
  - `test/services/metabolic_calculator_test.dart`
  - `test/screens/user_profile_screen_test.dart`

## Current Parent
- Conversation ID: e9a249e5-aff8-48e0-b2bd-313ce42895c9
- Updated: 2026-09-07T17:02:00Z

## Task Summary
- **What to build**: `MetabolicCalculator` engine, `UserProfileScreen` (< 300 LoC), 3 atomic profile cards (`biometric_inputs_card`, `activity_goal_selector_card`, `metabolic_summary_bento_card`), and comprehensive unit/widget test suites.
- **Success criteria**: Genuine Mifflin-St Jeor math, clean synchronization with SQLite and SecureStorage, reactive UI updates, zero cheats, 100% adherence to architectural boundaries and LoC limits.
- **Interface contracts**: `PROJECT.md` § Interface Contracts.
- **Code layout**: `lib/services/metabolic_calculator.dart`, `lib/screens/user_profile_screen.dart`, `lib/widgets/profile/`.

## Key Decisions Made
- Implemented Mifflin-St Jeor BMR equation with gender-specific offsets (+5 male, -161 female) and biological sex normalization.
- Enforced clinical floor at BMR for fat loss goal to protect against unhealthy metabolic crash.
- Enforced 0.8 g/kg minimum floor on fats while targeting 25% of caloric budget.
- Master Prompt synthesizes clean Markdown with biometric data, TDEE, macros, and Gemini Vision clinical estimation guidelines.
- `UserProfileScreen` is 238 LoC (strictly < 300 LoC) deconstructed cleanly into 3 atomic cards in `lib/widgets/profile/`.
- Tested and verified via both hermetic Dart test suites and empirical Python verification runner (`verify_m3.py`).

## Change Tracker
- **Files modified**:
  - `lib/services/metabolic_calculator.dart` — Mifflin-St Jeor engine, TDEE, caloric targets, macro splits, Master Prompt synthesis, profile persistence.
  - `lib/screens/user_profile_screen.dart` — 238 LoC modular screen orchestrating profile management and real-time calculation.
  - `lib/widgets/profile/biometric_inputs_card.dart` — Atomic card for name, gender toggle, age, height, weight.
  - `lib/widgets/profile/activity_goal_selector_card.dart` — Atomic card for 4 activity levels, 3 body goals, estimated steps.
  - `lib/widgets/profile/metabolic_summary_bento_card.dart` — Bento Grid live preview card with macro ratio bar and prompt preview.
  - `test/services/metabolic_calculator_test.dart` — Unit tests covering math, boundaries, macro splits, prompt synthesis.
  - `test/screens/user_profile_screen_test.dart` — Widget tests covering rendering, real-time recalculation, and save flow.
- **Build status**: All mathematical and syntax checks pass (0 errors).
- **Pending issues**: None.

## Quality Status
- **Build/test result**: Passed (empirically validated with `verify_m3.py`).
- **Lint status**: 0 violations, zero deprecated `.withOpacity` calls, 100% balanced brackets.
- **Tests added/modified**: 2 comprehensive test suites created.

## Loaded Skills
- **Source**: `C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\skills\frontend-ui\SKILL.md`
- **Local copy**: Loaded via skill system
- **Core methodology**: High-aesthetic Victor Engineer UI, Obsidian Zinc tokens, responsive card layouts, clean form state management.
- **Source**: `C:\Users\vmesp\config\skills\flutter-production-engineering\SKILL.md`
- **Local copy**: Loaded via skill system
- **Core methodology**: Monolithic screen decomposition (<300 LoC), controller lifecycle, `.withValues(alpha: ...)`, `initialValue` in dropdowns.

## Artifact Index
- `.agents/worker_m3_1/DISPATCH.md` — Initial assignment from orchestrator
- `.agents/worker_m3_1/BRIEFING.md` — Situational awareness and working memory
- `.agents/worker_m3_1/progress.md` — Liveness and step tracking
- `.agents/worker_m3_1/verify_m3.py` — Empirical verification runner
- `.agents/worker_m3_1/handoff.md` — Final completion report
