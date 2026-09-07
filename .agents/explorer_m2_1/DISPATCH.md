## 2026-09-07T16:30:06Z
You are Explorer 1 for Phase 2 Milestone 2: External APIs & Credentials.
Your working directory is: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_m2_1
You MUST read the authoritative user request at: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\ORIGINAL_REQUEST.md before doing anything else.
Read the project plan at: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\orchestrator_1\PROJECT.md
Read the spec report at: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\spec_miner_survey_2\survey_report.md

Milestone 2 Scope (Gemini Dynamic Models):
1. `lib/services/gemini_model_service.dart`:
   - Query endpoint: `GET https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}`.
   - Parse JSON response: list models, filter where `supportedGenerationMethods.contains('generateContent')` and `inputModalities.contains('IMAGE')` (or model name contains 'gemini' and does not match non-vision models).
   - Strip `models/` prefix.
   - Tiered recommendations logic: `gemini-2.5-flash` (Top recommendation), `gemini-2.0-flash` (Estable), `gemini-2.5-pro` (Máxima Precisión).
   - Model info class: `GeminiModelInfo` with `name`, `displayName`, `description`, `isRecommended`, `recommendationLabel`, `inputTokenLimit`.
2. `lib/services/gemini_vision_service.dart`:
   - Allow dynamic `modelName` parameter during construction or execution.
   - Implement dynamic `_buildSystemInstruction([String? masterPrompt])` to inject user Master Prompt alongside existing volumetric cubic estimation guidelines.

Task:
- Inspect `lib/services/gemini_vision_service.dart`.
- Recommend the exact Dart code structure, error handling (offline/timeouts), and mock data for unit tests.
- DO NOT implement changes. Write your report to: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\explorer_m2_1\report.md.
- Write handoff.md and notify orchestrator via send_message.
