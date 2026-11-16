---
tipo: implementation_plan
proyecto: App_Food_Tracker
iteracion: v1.5.1
estado: activo
fecha: 2026-11-15
tags: [proyecto, planning, v1-5-1, material-ui, cupertino-ui, quality-gate, linter-cleanup]
---

# 🧠 Plan de Implementación v1.5.1: Modernización a Material UI Oficial y Saneamiento de Quality Gate

> **Mesa de Control & Architecture Lead:** Este documento formaliza el plan de ejecución determinista para la versión **v1.5.1** de **Victor Engineer - Food Tracker**. Resuelve las 234 incidencias detectadas en el Quality Gate de GitHub Actions (Run 43783552723), migrando de forma oficial a `package:material_ui` y `package:cupertino_ui` (desacoplados por Google en Flutter 3.47+), incorporando el puente `MaterialUiCompatibilityBridge`, saneando los 8 errores de compilación pendientes en el working tree, resolviendo dependencias de tests VSA sin directivas `ignore` y certificando un pase del 100% en `flutter analyze` y `flutter test`.

---

## 🎯 1. Objetivos Técnicos Fundamentales

1. **Saneamiento del Working Tree & Compilación Core:**
   - Consolidar e incorporar en commit los 7 archivos con cambios locales pendientes:
     - `lib/core/services/nutrition/nutrition_label_scanner_service.dart`: migración a `GeminiRestClient` y remoción de `google_generative_ai`.
     - `lib/features/food_entry/models/meal.dart`: remoción de clave duplicada `'calorias'`.
     - `test/services/gemini_rest_client_test.dart`: remoción de `const` en `http.ClientException`.
     - `test/models/meal_analysis_result_test.dart`: remoción de import no usado `food_item.dart`.
     - `lib/core/di/service_locator.dart`, `decision_gate_service_interface.dart`, `decision_gate_service.dart`: depuración de imports no usados.
   - Eliminar los 8 errores fatales y 2 warnings de compilación en CI.

2. **Modernización Oficial a `material_ui` y `cupertino_ui` (Flutter 3.47+ / 3.50+):**
   - Incorporar dependencias oficiales de Google (`flutter.dev`) en `pubspec.yaml`:
     ```yaml
     material_ui: ^1.11.0
     cupertino_ui: ^1.11.0
     ```
   - Migrar programáticamente todos los imports en `lib/` y `test/`:
     - Reemplazar `import 'package:flutter/material.dart';` por `import 'package:material_ui/material_ui.dart';`.
     - En `lib/l10n/app_localizations.dart`, enlazar `GlobalMaterialLocalizations` y `GlobalCupertinoLocalizations` desde los paquetes dedicados.
   - Envolver `MaterialApp` en `lib/main.dart` con `MaterialUiCompatibilityBridge` para garantizar compatibilidad retroactiva transparente con librerías de terceros (`google_fonts`, `flutter_svg`, `pdf`, `home_widget`).

3. **Resolución Limpia de Dependencias de Testing en VSA:**
   - Para resolver las 8 advertencias de `depend_on_referenced_packages` causadas por la co-locación de pruebas en `lib/features/<slice>/<slice>_test.dart`, declarar:
     ```yaml
     dependencies:
       flutter_test:
         sdk: flutter
     ```
   - Dado que la aplicación tiene `publish_to: 'none'`, esto satisface formalmente las reglas del linter de Dart sin requerir directivas `ignore` en `analysis_options.yaml`.

4. **Depuración de Imports Redundantes y Constructores `const`:**
   - Eliminar los 43 `unnecessary_import` originados por la importación duplicada de modelos individuales y barriles de rebanadas.
   - Añadir `const` a las declaraciones estáticas de `Schema` en `gemini_resilience_helper.dart` para resolver los 16 `prefer_const_constructors` restantes.

5. **Pinning Determinista en CI & Publicación v1.5.1:**
   - Configurar `channel: 'stable'` en los workflows de GitHub Actions para compatibilidad continua con la última versión oficial de Flutter.
   - Incrementar versión semántica a `1.5.1+1` en `pubspec.yaml`.
   - Actualizar `artifacts/planning/changelog_v1.md` con sección `## [1.5.1] - 2026-11-15`.
   - Certificar Quality Gate con 0 errores, 0 warnings y 0 deprecaciones.

---

## 🛠️ 2. Fases de Implementación y Asignación de Agentes

### Fase 1: Consolidación del Core & Respaldo Working Tree (Swarm: `domain` & `audit`)
- **Tareas:**
  - Validar sintaxis de `nutrition_label_scanner_service.dart` y `meal.dart`.
  - Asegurar que el 100% de los archivos modificados cumplan el límite estricto `< 300 LoC`.
  - Ejecutar `bun test`, `bun run lint:contracts` y `bun run validate`.

### Fase 2: Inyección de `material_ui` y Transformación de Imports (Swarm: `engine` & `bridge`)
- **Tareas:**
  - Actualizar `pubspec.yaml` con `material_ui`, `cupertino_ui` y `flutter_test`.
  - Ejecutar script determinista de migración de imports (`package:flutter/material.dart` -> `package:material_ui/material_ui.dart`) en todas las vistas, componentes y tests.
  - Implementar `MaterialUiCompatibilityBridge` en `lib/main.dart`.
  - Ajustar delegados en `lib/l10n/app_localizations.dart`.

### Fase 3: Sanitización de Linter sin Supresiones (Swarm: `audit`)
- **Tareas:**
  - Depurar imports redundantes en controladores y widgets.
  - Aplicar `const` a esquemas en `gemini_resilience_helper.dart`.
  - Verificar que `analysis_options.yaml` se mantenga limpio sin supresiones `ignore`.

### Fase 4: Quality Gate, Release Notes y Publicación GitHub (Orquestador / `release-pipeline`)
- **Tareas:**
  - Actualizar `changelog_v1.md`, `project_overview.md` y `audit_report.md`.
  - Commit semántico: `chore(release): v1.5.1 - Official Material UI modernization and zero-lint Quality Gate`.
  - Crear tag anotado `v1.5.1` y desplegar a GitHub.
  - Monitorear GitHub Actions hasta compilación exitosa del APK.
