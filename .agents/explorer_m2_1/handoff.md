# Handoff Report: Gemini Dynamic Models & Master Prompt Injection
**Agent**: Explorer M2.1 (`explorer_m2_1`)
**Date**: 2026-09-07T16:32:30Z
**Milestone**: Phase 2 Milestone 2 — External APIs & Credentials

---

## 1. Observation

1. **`lib/services/gemini_vision_service.dart` Lines 89-91 & 114-117**:
   ```dart
   final String apiKey;
   final String modelName;
   static const String defaultModel = 'gemini-2.5-flash';
   ...
   GeminiVisionService({
     required this.apiKey,
     this.modelName = defaultModel,
   });
   ```
   The service defines a static `defaultModel = 'gemini-2.5-flash'`. Although `modelName` is accepted in the constructor, it is never passed dynamically by callers such as `dashboard_screen.dart:89`.
2. **`lib/services/gemini_vision_service.dart` Lines 93-112 & 161**:
   ```dart
   static const String systemInstruction = '''
   Eres un nutricionista clínico y experto en estimación volumétrica visual de alimentos sin báscula para comidas caseras latinoamericanas y familiares.
   ...
   ''';
   ...
   systemInstruction: Content.system(systemInstruction),
   ```
   The system instruction is a static compile-time string. It cannot incorporate dynamic user profile information or Master Prompt goals.
3. **`test/services/gemini_vision_service_test.dart` Lines 104-106**:
   ```dart
   test('Instrucciones del sistema contienen reglas de cubicaje casero latinoamericano', () {
     const prompt = GeminiVisionService.systemInstruction;
     expect(prompt, contains('Puño cerrado'));
   ```
   Any refactoring of `systemInstruction` must keep the symbol `GeminiVisionService.systemInstruction` valid as a const/getter to avoid breaking existing regression tests.
4. **Google Generative Language API Schema (`spec_miner_survey_2/survey_report.md` Lines 48-123)**:
   - Endpoint: `GET https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}`.
   - Models array includes `name` (with prefix `'models/'`), `displayName`, `supportedGenerationMethods` (must include `'generateContent'`), and `inputModalities` (must include `'IMAGE'`).
   - Non-vision models (`text-embedding-004`, `imagen-3.0`) lack either `'generateContent'` or `'IMAGE'` input modality.
5. **`pubspec.yaml` Lines 18 & 24**:
   Contains `google_generative_ai: ^0.4.6` and `http: ^1.3.0`. `package:http/testing.dart` (`MockClient`) is natively available for unit tests without additional dependencies.

---

## 2. Logic Chain

1. **Model Discovery without Hardcoding**:
   - Calling `GET https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}` allows NutriTracker to query real-time account-accessible models from Google AI Studio.
   - Normalizing model IDs by removing `models/` ensures compatibility with `google_generative_ai` SDK (`GenerativeModel(model: 'gemini-2.5-flash', ...)`).
2. **Resilient Multimodal Filtering**:
   - Filtering on `supportedGenerationMethods.contains('generateContent')` safely drops embeddings and task-specific counters.
   - Primary vision check: `inputModalities.contains('IMAGE')`.
   - Secondary resilient fallback: if Google's API proxy or version omits `inputModalities`, inspecting `name.contains('gemini')` while excluding `embedding`, `imagen`, `tts`, `audio`, `text-bison`, `chat-bison`, `learnlm`, `aqa`, `veo` prevents text-only PaLM or embedding models from appearing in the vision selector.
3. **Tiered Recommendations**:
   - Prioritizing `gemini-2.5-flash` (Top recommendation / `RECOMENDADO (Ultrarrápido)`), `gemini-2.0-flash` (Rank 2 / `ESTABLE (Alta Velocidad)`), and `gemini-2.5-pro` (Rank 3 / `MÁXIMA PRECISIÓN (Razonamiento)`) ensures users are guided toward the fastest, most cost-effective and accurate models.
   - Providing `fallbackModels` ensures the UI has valid models even in offline or airplane mode.
4. **Dynamic Master Prompt Injection**:
   - Refactoring `systemInstruction` into `baseSystemInstruction` plus `buildSystemInstruction([String? masterPrompt])` preserves all clinical volumetric rules (puño cerrado, grasa oculta 5-10g, etc.) while cleanly appending the user's biological context and TDEE deficit/surplus goals.
   - Setting `systemInstruction = baseSystemInstruction` ensures 100% backward compatibility for existing tests.
5. **Decoupled Architecture & Unit Testability**:
   - Accepting an optional `http.Client` in `GeminiModelService` allows offline testing using `MockClient`.

---

## 3. Caveats

1. **UI Integration Scope**:
   - The UI widget `gemini_model_selector_card.dart` and settings wiring are allocated to Milestone 4 (`M4`). This investigation scopes the model and service layers (`GeminiModelInfo`, `GeminiModelService`, and `GeminiVisionService`).
2. **Master Prompt Generation Source**:
   - Milestone 1 implemented `UserProfile.masterPrompt` and stored it in SQLite (`DatabaseService.instance.getUserProfile()`). Milestone 3 will implement `MetabolicCalculator` to synthesize this prompt from biometric inputs. In Milestone 2, `GeminiVisionService` must accept `masterPrompt` as an injected string regardless of whether it originates from SQLite, `SecureStorageService`, or memory.
3. **Offline Invalidation**:
   - Real-world API calls require an internet connection. If the user is offline when loading Settings, `GeminiModelService.fallbackModels` should be presented rather than an empty list.

---

## 4. Conclusion

- `GeminiModelInfo` should be created in `lib/models/gemini_model_info.dart` with normalization (stripping `models/`), recommendation flags, semantic badges, and JSON serialization.
- `GeminiModelService` should be created in `lib/services/gemini_model_service.dart` with injectable `http.Client`, 10-second timeout, resilient filtering (`generateContent` + `IMAGE` / gemini fallback), tiered sorting, and `fallbackModels`.
- `GeminiVisionService` should be updated in `lib/services/gemini_vision_service.dart` with dynamic `modelName`, `masterPrompt` injection via `buildSystemInstruction([String? masterPrompt])`, and preservation of `systemInstruction`.
- Unit test suite `test/services/gemini_model_service_test.dart` and additions to `test/services/gemini_vision_service_test.dart` provide 100% offline verification using `MockClient`.

Detailed specifications, code listings, and mock fixtures are located in:
`C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_m2_1\report.md`.

---

## 5. Verification Method

Once implemented by a worker agent, verification is performed with:

1. **Unit Tests**:
   ```bash
   flutter test test/services/gemini_model_service_test.dart
   flutter test test/services/gemini_vision_service_test.dart
   ```
2. **Static Analysis**:
   ```bash
   flutter analyze
   ```
3. **Manual Code Inspection**:
   - Verify `GeminiModelInfo` is immutable and normalizes model names.
   - Verify `GeminiModelService` handles 400, 403, 429, timeouts, and missing `inputModalities`.
   - Verify `GeminiVisionService.buildSystemInstruction` retains all volumetric cubic rules and appends Master Prompt.
