# Project: Victor Engineer - Food Tracker (NutriTracker Local-First) - Phase 2

## Architecture
- **Framework**: Flutter 3.22+ / 3.27+, Dart 3.4+
- **Pattern**: Local-First, Modular Monolith (< 300 LoC per screen), Atomic Widgets in domain folders (`lib/widgets/<domain>/`), ChangeNotifier Controllers.
- **Persistence**: SQLite (sqflite) with WAL mode, memoized `_initFuture`, B-Tree indexes, immutable models with `_sentinel` pattern.
- **Security**: Hardware-backed encryption via `FlutterSecureStorage` (AES/RSA / EncryptedSharedPreferences).
- **External Services**:
  - Google Gemini REST API (`v1beta/models` dynamic querying + `google_generative_ai` SDK vision inference with Master Prompt).
  - USDA FoodData Central REST API (`https://api.nal.usda.gov/fdc/v1/`) with automatic fallback to Open Food Facts (`https://world.openfoodfacts.org`).

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Dynamic Gemini Models Querying | Query `v1beta/models`, filter `generateContent` & multimodal vision | M2 | R1, survey |
| 2 | Gemini Model Recommendations & Storage | Rank recommendations (`gemini-2.5-flash`, etc.), persist selection in secure storage | M2 | R1, survey |
| 3 | Gemini Model Selector UI | Reactive dropdown card in `SettingsScreen` with live status and refresh | M4 | R1, survey |
| 4 | Dynamic Vision Model Invocations | Use chosen model in `GeminiVisionService` and remove hardcoded strings | M4 | R1, survey |
| 5 | Master Prompt System Instruction Injection | Inject biometric context & goals into `GeminiVisionService` system instructions | M2 | R3, survey |
| 6 | USDA FDC API Key Management | Secure input card in `SettingsScreen`, store in `FlutterSecureStorage` (`usda_api_key`) | M4 | R2, survey |
| 7 | USDA FoodData Central Client Service | Typed client for `https://api.nal.usda.gov/fdc/v1/` (`/foods/search` & `/food/{fdcId}`) | M2 | R2, survey |
| 8 | Unified Nutrient Parser | Extract macros (Kcal, protein, fat, carbs) and micros with unit conversions | M2 | R2, survey |
| 9 | Cascading Barcode Scanner Fallback | Scanned barcode queries USDA FDC first, falls back to Open Food Facts | M2 | R2, survey |
| 10 | SQLite Version 2 Migration & `weight_logs` Table | DDL for `weight_logs` with B-Tree index on `date`, `onUpgrade` script in `DatabaseService` | M1 | R4, survey |
| 11 | `WeightLog` Model with `_sentinel` | Immutable model, `_sentinel` pattern for nullable notes, `ModelSanitizer` bounds | M1 | R4, survey |
| 12 | SQLite Range Queries & Concurrency | Fast indexed date-range queries (7d, 30d, 90d) directly in SQLite | M1 | R4, survey |
| 13 | `MealController` Weight Integration | Add weight logging and reactive range query methods to `MealController` (< 300 LoC) | M1 | R4, survey |
| 14 | SQLite `user_profile` Table & Persistence | Store biometric profile, BMR, TDEE, and Master Prompt in SQLite table | M1 | R3, survey |
| 15 | `UserProfile` Model with `_sentinel` | Immutable model, `_sentinel` pattern, JSON serialization for profile | M1 | R3, survey |
| 16 | Backup Pipeline Extension | Include `weight_logs` and `user_profile` in transactional JSON backup/restore | M1 | R4, survey |
| 17 | Clinical Mifflin-St Jeor Metabolic Engine | Implement BMR, activity multiplier TDEE, goal adjustment, macro distribution | M3 | R3, survey |
| 18 | Master Prompt Generator | Synthesize markdown prompt with biometrics and nutrition targets | M3 | R3, survey |
| 19 | `UserProfileScreen` Orchestrator | Dedicated profile screen (< 300 LoC) with biometric inputs and calculation | M3 | R3, survey |
| 20 | Profile Atomic Widgets | `biometric_inputs_card`, `activity_goal_selector_card`, `metabolic_summary_bento_card`, etc. | M3 | R3, survey |
| 21 | Automatic `DailyGoals` Synchronization | Sync calculated TDEE calories and macros into user daily goals | M3 | R3, survey |
| 22 | `MetricsScreen` Bento Dashboard | Dedicated metrics screen (< 300 LoC) with range filter and bento cards | M5 | R5, survey |
| 23 | Hardware-Accelerated Weight Line Chart | `WeightLineChartPainter` (`CustomPainter`) for 120 FPS trend chart | M5 | R5, survey |
| 24 | Calorie Intake Compliance Card | Daily calorie intake vs target bento card over selected date range | M5 | R5, survey |
| 25 | Macro Distribution Bento Card | Protein/Carb/Fat percentages vs calculated targets | M5 | R5, survey |
| 26 | Consistency Streak & Activity Card | Logging streak and step compliance card | M5 | R5, survey |
| 27 | Quick Weight Entry Modal Dialog | Dialog to record daily weight with validation and optional notes | M5 | R5, survey |
| 28 | Navigation Integration | Metrics icon in `VeAppBar` on `DashboardScreen` and settings links | M5 | R5, survey |
| 29 | Screen LoC Hard Constraint Trimming | Ensure all screens in `lib/screens/` including `meal_detail_screen` are < 300 LoC | M4 | A4, survey |
| 30 | Comprehensive Unit & E2E Testing Suite | Unit tests for TDEE, Gemini parsing, USDA parsing, SQLite queries, Sentinel tests | M6 | A1-A4 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | SQLite v2 & Persistence Layer | `weight_logs`, `user_profile`, `WeightLog`, `UserProfile`, `DatabaseService`, `MealController`, `BackupService` | none | DONE |
| M2 | External APIs & Credentials | `SecureStorageService`, `GeminiModelService`, `GeminiVisionService` Master Prompt injection, `UsdaFoodDataService`, Barcode fallback | none | DONE |
| M3 | Metabolic Engine & Profile Screen | `MetabolicCalculator`, Master Prompt synthesis, `UserProfileScreen`, widgets in `lib/widgets/profile/`, `DailyGoals` sync | M1, M2 | DONE |
| M4 | Settings Screen Cards & Model Selector | `gemini_model_selector_card`, `usda_api_key_card`, `SettingsScreen` integration, `DashboardScreen` dynamic model, LoC trimming | M2 | DONE |
| M5 | Metrics Screen & Bento Dashboard | `MetricsScreen`, `WeightLineChartPainter`, `weight_trend_bento_card`, macro/calorie cards, navigation buttons | M1, M3 | PLANNED |
| M6 | Final Verification & Quality Gate | E2E Testing Suite (`TEST_READY.md`), `flutter analyze` 0 warnings, LoC audit, acceptance criteria A1-A4 | M1, M2, M3, M4, M5 | PLANNED |

## Interface Contracts
### DatabaseService (v2) ↔ Controllers
- `Future<List<WeightLog>> getWeightLogsByRange(DateTime start, DateTime end)`
- `Future<void> insertWeightLog(WeightLog log)`
- `Future<void> deleteWeightLog(String id)`
- `Future<UserProfile?> getUserProfile()`
- `Future<void> saveUserProfile(UserProfile profile)`

### GeminiModelService / SecureStorageService ↔ SettingsScreen / GeminiVisionService
- `Future<List<GeminiModelInfo>> fetchAvailableModels(String apiKey)`
- `Future<String?> getSelectedGeminiModel()`
- `Future<void> saveSelectedGeminiModel(String modelName)`
- `Future<String?> getUsdaApiKey()`
- `Future<void> saveUsdaApiKey(String key)`

### MetabolicCalculator ↔ UserProfileScreen & MealController
- `MetabolicProfile calculateMetabolicProfile({required int age, required BiologicalSex sex, required double heightCm, required double weightKg, required ActivityLevel activity, required BodyGoal goal})`
- `String generateMasterPrompt(MetabolicProfile profile)`
- `DailyGoals toDailyGoals(MetabolicProfile profile)`

## Code Layout
- `lib/models/weight_log.dart`
- `lib/models/user_profile.dart`
- `lib/services/database_service.dart` (v2 migration)
- `lib/services/gemini_model_service.dart`
- `lib/services/usda_food_data_service.dart`
- `lib/services/metabolic_calculator.dart`
- `lib/screens/user_profile_screen.dart` (< 300 LoC)
- `lib/screens/metrics_screen.dart` (< 300 LoC)
- `lib/widgets/settings/gemini_model_selector_card.dart`
- `lib/widgets/settings/usda_api_key_card.dart`
- `lib/widgets/profile/*.dart`
- `lib/widgets/metrics/*.dart`
- `test/services/metabolic_calculator_test.dart`
- `test/services/usda_food_data_service_test.dart`
- `test/services/gemini_model_service_test.dart`
- `test/models/weight_log_test.dart`
- `test/services/database_service_v2_test.dart`
