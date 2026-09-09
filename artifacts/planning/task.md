---
tipo: task_list
proyecto: App_Food_Tracker
iteracion: v0.2.0-alpha
estado: activo
fecha: 2026-09-09
tags: [proyecto, tasks, checklist, v7-teamwork]
---

# 📋 Checklist Maestro de Tareas de Agentes (v0.2.0-alpha)

> **Mesa de Control (Project-Planner):** Este checklist asigna la propiedad técnica de cada entregable a su respectivo agente de IA especializado. Todas las tareas de las Fases 1 y 2 han sido ejecutadas, auditadas y marcadas con `[x]`.

---

## 🧭 1. Project-Planner (Master Tech Lead)
- [x] (Project-Planner) Analizar requerimientos de negocio y alcance del MVP NutriTracker Local-First (v0.1.0).
- [x] (Project-Planner) Generar y estructurar el artefacto maestro `artifacts/project_overview.md` con enlaces Obsidian `[[PRJ_...]]`.
- [x] (Project-Planner) Definir el Tech Stack y crear el diagrama de componentes en `artifacts/architecture/architecture.md`.
- [x] (Project-Planner) Elaborar el plan de implementación iterativa en `artifacts/planning/implementation_plan.md`.
- [x] (Project-Planner) Inicializar y mantener el checklist de tareas por roles en `artifacts/planning/task.md`.
- [x] (Project-Planner) Registrar los cambios y notas de versión en `artifacts/planning/changelog_v1.md`.
- [x] (Project-Planner) Planificar la arquitectura de la Fase 2: Dynamic Gemini Discovery, USDA FoodData Central, Mifflin-St Jeor TDEE y Métricas Bento Grid.
- [x] (Project-Planner) Refactorizar y sincronizar todos los artefactos eliminando residuos y elevando la documentación a estándar de producción.

---

## 🗄️ 2. Backend-Architect (Datos, Modelos y Servicios)
- [x] (Backend-Architect) Documentar el esquema de base de datos relacional y contratos en `artifacts/architecture/api_spec.md`.
- [x] (Backend-Architect) Diseñar e implementar `ModelSanitizer` para clamp numérico, truncado de texto y sanitización de fechas.
- [x] (Backend-Architect) Implementar modelos inmutables con patrón Sentinel (`Meal`, `FoodItem`, `PantryItem`, `DailyGoals`).
- [x] (Backend-Architect) Diseñar e implementar `DatabaseService` con SQLite en modo WAL (`sqflite` / `sqflite_common_ffi`), claves foráneas y protección contra carreras en `_initFuture`.
- [x] (Backend-Architect) Crear índices compuestos de base de datos (`idx_meals_date`, `idx_meals_meal_type`, `idx_meals_date_type`, `idx_pantry_name`, etc.).
- [x] (Backend-Architect) Implementar `GeminiVisionService` con esquemas estrictos de salida JSON (`responseSchema`) e inyección de reglas clínicas volumétricas.
- [x] (Backend-Architect) Implementar `SecureStorageService` con cifrado de hardware para API Keys de Gemini y USDA.
- [x] (Backend-Architect) Implementar `OpenFoodFactsService` con control de timeout y extracción normalizada de macros.
- [x] (Backend-Architect) Implementar `BackupService` con serialización JSON y transacciones atómicas para importación.
- [x] (Backend-Architect) Implementar `ImageProcessingService` para redimensionar imágenes a un máximo de 1024x1024 px previo a la inferencia.
- [x] (Backend-Architect) Implementar `GeminiModelService` con introspección dinámica en vivo de `GET /v1beta/models` y modelo `GeminiModelInfo`.
- [x] (Backend-Architect) Implementar `UsdaFoodDataService` con factor de conversión energética $kJ \rightarrow kcal$ (4.184) y limitador de tasa de 1.000 req/hr.
- [x] (Backend-Architect) Implementar `BarcodeLookupService` con cascada resiliente (USDA prioritario, Open Food Facts fallback).
- [x] (Backend-Architect) Diseñar e implementar `MetabolicCalculator` con ecuaciones Mifflin-St Jeor (TMB/TDEE) y generador de Master Prompt.
- [x] (Backend-Architect) Actualizar `DatabaseService` a esquema v2 con tabla `weight_logs` e índice `idx_weight_logs_date`.
- [x] (Backend-Architect) Implementar modelo `WeightLog` y modelo `UserProfile` con patrón Sentinel inmutable.

---

## 🎨 3. Frontend-UI (Diseño, Tokens y Widgets Atómicos)
- [x] (Frontend-UI) Certificar fidelidad visual al sistema de diseño `DESIGN.md` (Obsidian Zinc `#09090B`, Crisp Zinc `#FAFAFA` y acento carmesí `#DC2626`).
- [x] (Frontend-UI) Configurar tokens de color semánticos de macronutrientes (Calorías `#F97316`, Proteína `#EF4444`, Carbohidratos `#EAB308`, Grasas `#3B82F6`, Hidratación `#06B6D4`).
- [x] (Frontend-UI) Implementar tipografía `Outfit` para números principales y títulos, e `Inter` para cuerpos de texto.
- [x] (Frontend-UI) Implementar `ThemeManager` para cambio en caliente y persistencia de tema.
- [x] (Frontend-UI) Construir widgets atómicos del Dashboard (< 300 LoC): `VeAppBar`, `CaloriesHeroRing`, `MacroBentoCard`, `DailyCalorieSummaryCard`, `WeekCalendarStrip`, `DateSelectorBar`, `StreakBadge`, `DashboardFabMenu`, `QuickMealDialog`, `ApiKeyPromptDialog`, `MealSectionCard`.
- [x] (Frontend-UI) Construir widgets atómicos de Detalle de Comida (< 300 LoC): `MealImageCard`, `MealMacroChipsRow`, `MealFormFields`, `FoodItemsListCard`, `FoodItemEditorDialog`.
- [x] (Frontend-UI) Construir widgets atómicos de Ajustes (< 300 LoC): `ApiKeyInputCard`, `DailyGoalsCard`, `DatabaseMaintenanceCard`, `BackupCard`, `GeminiModelSelectorCard`, `UsdaApiKeyCard`.
- [x] (Frontend-UI) Construir widgets atómicos de Perfil Nutricional (< 300 LoC): `BiometricInputsCard`, `ActivityGoalSelectorCard`, `MetabolicSummaryBentoCard`.
- [x] (Frontend-UI) Construir widgets atómicos de Métricas y Progreso (< 300 LoC): `WeightTrendBentoCard`, `CalorieComplianceBentoCard`, `MacroDistributionBentoCard`, `StreakComplianceBentoCard`, `QuickWeightEntryDialog`.
- [x] (Frontend-UI) Desarrollar `WeightLineChartPainter` con trazado suave de curvas Bézier a 60 FPS acelerado por hardware.
- [x] (Frontend-UI) Ensamblar las 5 pantallas maestras bajo el límite de 300 LoC:
  - `DashboardScreen`: 294 LoC
  - `MealDetailScreen`: 287 LoC
  - `MetricsScreen`: 198 LoC
  - `SettingsScreen`: 262 LoC
  - `UserProfileScreen`: 238 LoC

---

## 🧪 4. Systems-Auditor (Quality Gatekeeper & Testing)
- [x] (Systems-Auditor) Crear suite de pruebas unitarias para modelos: `test/models/meal_model_test.dart`, `food_item_test.dart`, `pantry_item_test.dart`, `model_sanitizer_test.dart`, `user_profile_model_test.dart`, `weight_log_model_test.dart`.
- [x] (Systems-Auditor) Crear suite de pruebas para servicios: `database_service_test.dart`, `database_service_v2_test.dart`, `backup_service_test.dart`, `backup_service_v2_test.dart`, `gemini_vision_service_test.dart`, `gemini_model_service_test.dart`, `usda_food_data_service_test.dart`, `barcode_lookup_service_test.dart`, `metabolic_calculator_test.dart`, `secure_storage_service_test.dart`.
- [x] (Systems-Auditor) Crear suite de pruebas adversarias: `metabolic_calculator_adversarial_test.dart`, `settings_controller_adversarial_test.dart`, `usda_adversarial_test.dart`, `gemini_and_storage_adversarial_test.dart`.
- [x] (Systems-Auditor) Crear suite de pruebas para pantallas y widgets: `metrics_screen_test.dart`, `user_profile_screen_test.dart`, `weight_line_chart_painter_test.dart`, `quick_weight_entry_dialog_test.dart`, `gemini_model_selector_card_test.dart`, `usda_api_key_card_test.dart`, `nutri_tracker_app_test.dart`.
- [x] (Systems-Auditor) Verificar que la totalidad de las 37 suites de prueba (237 tests) se ejecuten con éxito (0 fallas).
- [x] (Systems-Auditor) Auditar consultas de base de datos para garantizar cero N+1 queries.
- [x] (Systems-Auditor) Auditar seguridad de API Keys (almacenamiento encriptado, cero exposición en logs).
- [x] (Systems-Auditor) Auditar presupuesto de nodos DOM / widgets (< 800 nodos por vista).
- [x] (Systems-Auditor) Emitir veredicto formal del Quality Gate en `artifacts/audit_reports/audit_report.md` (`Status: PASS`).

---

## 🚀 5. DevOps-Engineer (CI/CD, Workflows & Release)
- [x] (DevOps-Engineer) Verificar prerequisito de Quality Gate (`Status: PASS` en `audit_report.md`).
- [x] (DevOps-Engineer) Asegurar el pipeline principal de CI en `.github/workflows/ci.yml` (Flutter analyze, test con coverage, upload de reporte).
- [x] (DevOps-Engineer) Corregir y normalizar flujos de compilación `.github/workflows/build_apk.yml` y `.github/workflows/build_windows.yml`.
- [x] (DevOps-Engineer) Inyectar script de inicialización Gradle (`~/.gradle/init.gradle`) para forzar versiones de AndroidX compatibles con `compileSdk 34`.
- [x] (DevOps-Engineer) Bloquear la versión de `sqflite: '>=2.3.3+1 <2.4.0'` para evitar incompatibilidades de Java 21 / Android 16.
- [x] (DevOps-Engineer) Generar Keystore permanente RSA 2048 con alias `foodtracker` y validez de 30 años (hasta 2056).
- [x] (DevOps-Engineer) Configurar `.github/workflows/release.yml` para empaquetado y firma con Keystore seguro mediante GitHub Secrets.
- [x] (DevOps-Engineer) Publicar exitosamente el Release oficial `v0.2.0-alpha` con artefactos APK de Android y ZIP de Windows x64.
- [x] (DevOps-Engineer) Asegurar versionamiento semántico `0.2.0-alpha+1` en `pubspec.yaml` y sincronización de documentación.

---

## 🏗️ 6. Migración a V7 Teamwork & Estandarización de Artefactos
- [x] (Project-Planner) Estandarizar frontmatter YAML en todos los artefactos según `artifact-standards` (claves minúsculas, fechas ISO, propiedades planas).
- [x] (Backend-Architect) Generar `artifacts/architecture/abstractions.md` documentando modelos inmutables, servicios, funciones puras y data seams.
- [x] (Project-Planner) Convertir diagrama Mermaid a especificación Archify JSON (`artifacts/architecture/src/architecture_diagram.json`) y compilar diagrama interactivo (`artifacts/architecture/architecture_diagram.html`).
- [x] (Project-Planner) Actualizar `artifacts/architecture/architecture.md` eliminando el bloque Mermaid y vinculando el diagrama Archify.
- [x] (Project-Planner) Verificar estado y umbral de líneas de `artifacts/planning/changelog_v1.md` (< 300 LoC).
- [x] (Systems-Auditor) Auditar el cumplimiento integral del Quality Gate y consistencia de artefactos en `artifacts/audit_reports/audit_report.md`.


