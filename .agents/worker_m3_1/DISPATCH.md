## 2026-09-07T16:56:22Z

You are Worker M3.1 (teamwork_preview_worker) implementing Phase 2 Milestone 3: Metabolic Engine & User Profile Screen for Victor Engineer - Food Tracker (NutriTracker Local-First).

Authoritative user request:
C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\ORIGINAL_REQUEST.md
You MUST read this file first before taking any action.

Your assigned working directory:
C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\worker_m3_1
All your logs, progress notes, and handoff report must be written in this directory.

PROJECT ARTIFACTS TO READ:
1. C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\orchestrator_1\PROJECT.md
2. Existing models and services:
   - lib/models/user_profile.dart (already created in M1 with Mifflin-St Jeor fields and dailyGoals converter)
   - lib/models/daily_goals.dart
   - lib/services/database_service.dart (has saveUserProfile, getUserProfile)
   - lib/services/secure_storage_service.dart (has setUserMasterPrompt, setCompletedOnboarding, saveDailyGoals)
   - lib/services/gemini_vision_service.dart (buildSystemInstruction)

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

EXCLUSIVE FILE WRITE OWNERSHIP:
You have exclusive write ownership for:
- lib/services/metabolic_calculator.dart
- lib/screens/user_profile_screen.dart
- lib/widgets/profile/biometric_inputs_card.dart
- lib/widgets/profile/activity_goal_selector_card.dart
- lib/widgets/profile/metabolic_summary_bento_card.dart
- test/services/metabolic_calculator_test.dart
- test/screens/user_profile_screen_test.dart

TECHNICAL & ARCHITECTURAL REQUIREMENTS:
1. `lib/services/metabolic_calculator.dart`:
   - Mifflin-St Jeor BMR calculation:
     - Male: (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5
     - Female: (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161
   - Activity Multipliers for TDEE:
     - sedentary: 1.2
     - light: 1.375
     - moderate: 1.55
     - very_active: 1.725
   - Caloric Goal calculation:
     - fat_loss: TDEE - 500 (with floor at BMR)
     - maintenance: TDEE
     - muscle_gain: TDEE + 300
   - Macronutrient Distribution:
     - Protein: 2.0 g/kg (fat_loss), 1.8 g/kg (maintenance), 2.2 g/kg (muscle_gain)
     - Fat: 25% of target calories / 9 (minimum 0.8 g/kg)
     - Carbs: (Target calories - protein*4 - fat*9) / 4
   - Master Prompt Generation:
     - `static String generateMasterPrompt(UserProfile profile)`
     - Generates Markdown string with user biometrics, metabolic targets (BMR, TDEE, Caloric goal), macronutrient split, and clinical instruction for Gemini visual analysis.
   - Profile calculation & persistence helper:
     - `static UserProfile calculateProfile(...)`
     - Save profile to SQLite (`DatabaseService.instance.saveUserProfile(profile)`), sync `DailyGoals` to `SecureStorageService.instance.saveDailyGoals(profile.dailyGoals)`, store prompt in `SecureStorageService.instance.setUserMasterPrompt(prompt)`, and mark `setCompletedOnboarding(true)`.

2. `lib/screens/user_profile_screen.dart` (< 300 LoC):
   - Interactive screen in Victor Engineer theme (*Obsidian Zinc* `#09090B`, `#121215`, Card `#18181B`, Carmesí `#DC2626`, `Outfit`/`Inter` fonts).
   - Form inputs for: Name, Age, Gender, Height, Weight, Activity Level, Body Goal, Estimated Steps.
   - Real-time metabolic summary preview updating as user edits inputs.
   - Button "Guardar Perfil y Sincronizar Metas" that saves and updates daily goals.
   - Deconstruct into atomic cards in `lib/widgets/profile/` to keep `user_profile_screen.dart` strictly < 300 LoC:
     - `lib/widgets/profile/biometric_inputs_card.dart`
     - `lib/widgets/profile/activity_goal_selector_card.dart`
     - `lib/widgets/profile/metabolic_summary_bento_card.dart`

3. Unit & Widget Tests:
   - `test/services/metabolic_calculator_test.dart`:
     - Mifflin-St Jeor math for male & female across boundary ages, weights, heights.
     - Activity multipliers & calorie targets.
     - Macro calories balance validation.
     - Master prompt markdown contents check.
   - `test/screens/user_profile_screen_test.dart`:
     - Widget rendering, input interactions, and calculation updates.
