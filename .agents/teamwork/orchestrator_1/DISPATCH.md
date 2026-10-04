# Dispatch Log

## 2026-10-04T21:43:29Z

Sender: 9f9eef05-029f-4f27-935a-37e530dfe186 (Sentinel)
Content:
You are the Project Orchestrator for the workspace C:\Users\vmesp\Documents\Cositas\App-Food-Tracker.
Your working directory is: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\teamwork\orchestrator_1

Read the authoritative user request in:
C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\teamwork\ORIGINAL_REQUEST.md
(Pay particular attention to the newest requests dated 2026-10-04T21:41:59Z and 2026-10-04T21:42:58Z).

Summary of Scope:
- Target Version: 1.2.4 (version 1.2.4+1 in pubspec.yaml, entry [1.2.4] in artifacts/planning/changelog_v1.md, and aligned Gradle configuration).
- R1. Native OS File Picker & Resilient Retrocompatible JSON Normalization:
  - Integrate native OS file picker (file_picker / SAF) for JSON backups to choose files visually from Downloads, Drive, or internal storage with one tap, removing manual file path text input.
  - Adaptive normalizer in BackupService supporting legacy backups (v1.0.4 and prior) with key translations (meals/comidas/raw array, pantry_items/despensa, user_profile/perfil, weight_logs/pesos).
  - Parse and decode in secondary Isolate (Isolate.run) and persist via SQLite batch operations (batch.commit()) for smooth 60 FPS import without UI thread stutter.
- R2. Ergonomic Relocation & Redesign of "¿Qué Debería Comer Hoy?":
  - Remove intrusive fixed card from Dashboard; relocate into floating '+' action menu.
  - Redesign modal sheet with SafeArea, explicit close header button, height constraints, and fluid scrolling.
- R3. Dashboard Reorganization & Intermittent Fasting Positioning:
  - Transform Intermittent Fasting card into compact collapsible Bento card (subtle default, expands when active fasting or tapped).
  - Fix recommendation dialog text overlap with scrollable suggestions.
  - Fix MetricsScreen WeeklyDigestCard badge horizontal overflow ("1/7 días con registro") and clipped top container over macro distribution card.
- R4. Pantry Item Reference Grammage & Automatic Portion Scaling:
  - Add reference portion in grams (e.g. per 100g) and package net weight to PantryItem and PantryItemEditorDialog.
  - Automatically calculate and scale calories and macronutrients when logging pantry items into a meal based on grams consumed.
- Quality Gates:
  - flutter analyze with 0 errors and 0 warnings.
  - 100% unit and widget tests pass.
  - Strict modularity: all created and modified files must be < 300 LoC.

## 2026-10-04T21:56:48Z

Sender: 9f9eef05-029f-4f27-935a-37e530dfe186 (Sentinel)
Content:
## Directiva Prioritaria: Requerimiento Adicional v1.2.4

Se ha recibido una especificación adicional del usuario registrada en `.agents/teamwork/ORIGINAL_REQUEST.md`:

**Problema Reportado**: El widget nativo 4x2 (`FoodTrackerWideWidgetProvider`) no carga en el dispositivo del usuario (`InflateException: Class not allowed to be inflated in RemoteViews: android.view.View`).
**Causa Raíz**: Uso de etiquetas genéricas `<View>` como separadores/espaciadores (líneas 96, 129 y 197) en `android/app/src/main/res/layout/food_tracker_widget_wide.xml` y `lib/assets/android_widgets/food_tracker_widget_wide.xml`.
**Acción Requerida**:
- Incorporar esta tarea en la planificación (Milestone de Frontend/Android en `task.md` e `implementation_plan.md`).
- Sustituir las etiquetas `<View>` prohibidas en `RemoteViews` por `<FrameLayout>` o `<ImageView>` compatibles para que el widget 4x2 se infle correctamente.
- Validar su inclusión en el Quality Gate de la v1.2.4.

