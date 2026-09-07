---
title: Checklist Maestro de Tareas de Agentes (v1.0.0)
status: active
tags: [proyecto, tasks, checklist, subagents, roles]
agent: project-planner
project: VE_FoodTracker
version: v1.0.0
date: 2026-09-06
---

# 📋 Checklist Maestro de Tareas de Agentes (v1.0.0)

> **Mesa de Control (Project-Planner):** Este checklist asigna la propiedad técnica de cada entregable a su respectivo agente de IA especializado. Las tareas completadas se marcan con `[x]`.

---

## 🧭 1. Project-Planner (Master Tech Lead)
- [x] (Project-Planner) Analizar requerimientos de negocio y alcance del MVP NutriTracker Local-First.
- [x] (Project-Planner) Generar y estructurar el artefacto maestro `artifacts/project_overview.md` con enlaces Obsidian `[[PRJ_...]]`.
- [x] (Project-Planner) Definir el Tech Stack y crear el diagrama de componentes en `artifacts/architecture/architecture.md`.
- [x] (Project-Planner) Elaborar el plan de implementación iterativa en `artifacts/planning/implementation_plan.md`.
- [x] (Project-Planner) Inicializar y mantener el checklist de tareas por roles en `artifacts/planning/task.md`.
- [x] (Project-Planner) Registrar los cambios y notas de la versión en `artifacts/planning/changelog_v1.md`.

---

## 🗄️ 2. Backend-Architect (Datos, Modelos y Servicios)
- [x] (Backend-Architect) Documentar el esquema de base de datos relacional y contratos en `artifacts/architecture/api_spec.md`.
- [x] (Backend-Architect) Diseñar e implementar `ModelSanitizer` para clamp numérico, truncado de texto y sanitización de fechas.
- [x] (Backend-Architect) Implementar modelos inmutables con patrón Sentinel (`Meal`, `FoodItem`, `PantryItem`, `DailyGoals`).
- [x] (Backend-Architect) Diseñar e implementar `DatabaseService` con SQLite en modo WAL (`sqflite` / `sqflite_common_ffi`), claves foráneas y protección contra carreras en `_initFuture`.
- [x] (Backend-Architect) Crear índices compuestos de base de datos (`idx_meals_date`, `idx_meals_meal_type`, `idx_meals_date_type`, `idx_pantry_name`, etc.).
- [x] (Backend-Architect) Implementar `GeminiVisionService` con esquemas estrictos de salida JSON (`responseSchema`) e inyección de reglas clínicas volumétricas.
- [x] (Backend-Architect) Implementar `SecureStorageService` con cifrado de hardware para la API Key de Gemini y metas.
- [x] (Backend-Architect) Implementar `OpenFoodFactsService` con control de timeout y extracción normalizada de macros.
- [x] (Backend-Architect) Implementar `BackupService` con serialización JSON y transacciones atómicas para importación.
- [x] (Backend-Architect) Implementar `ImageProcessingService` para redimensionar imágenes a un máximo de 1024x1024 px previo a la inferencia.

---

## 🎨 3. Frontend-UI (Diseño, Tokens y Widgets Atómicos)
- [x] (Frontend-UI) Certificar fidelidad visual al sistema de diseño `DESIGN.md` (Obsidian Zinc `#09090B`, Crisp Zinc `#FAFAFA` y acento carmesí `#DC2626`).
- [x] (Frontend-UI) Configurar tokens de color semánticos de macronutrientes (Calorías `#F97316`, Proteína `#EF4444`, Carbohidratos `#EAB308`, Grasas `#3B82F6`, Hidratación `#06B6D4`).
- [x] (Frontend-UI) Implementar tipografía `Outfit` para números principales y títulos, e `Inter` para cuerpos de texto.
- [x] (Frontend-UI) Implementar `ThemeManager` para cambio en caliente y persistencia de tema.
- [x] (Frontend-UI) Construir widgets atómicos del Dashboard (< 300 LoC): `VeAppBar`, `CaloriesHeroRing`, `MacroBentoCard`, `DailyCalorieSummaryCard`, `WeekCalendarStrip`, `DateSelectorBar`, `StreakBadge`, `DashboardFabMenu`, `QuickMealDialog`, `ApiKeyPromptDialog`, `MealSectionCard`.
- [x] (Frontend-UI) Construir widgets atómicos de Detalle de Comida (< 300 LoC): `MealImageCard`, `MealMacroChipsRow`, `MealFormFields`, `FoodItemsListCard`, `FoodItemEditorDialog`.
- [x] (Frontend-UI) Construir widgets atómicos de Ajustes (< 300 LoC): `ApiKeyInputCard`, `DailyGoalsCard`, `DatabaseMaintenanceCard`, `BackupCard`.
- [x] (Frontend-UI) Ensamblar las tres pantallas maestras bajo el límite de 300 LoC: `DashboardScreen` (267 LoC), `MealDetailScreen` (283 LoC) y `SettingsScreen` (208 LoC).
- [x] (Frontend-UI) Implementar microinteracciones táctiles y menú Speed-Dial elástico (`Curves.easeOutBack`).

---

## 🧪 4. Systems-Auditor (Quality Gatekeeper & Testing)
- [x] (Systems-Auditor) Crear suite de pruebas unitarias para modelos: `test/models/meal_model_test.dart`, `food_item_test.dart`, `pantry_item_test.dart`.
- [x] (Systems-Auditor) Crear suite de pruebas para servicios: `test/services/database_service_test.dart` (en memoria, concurrencia, PRAGMAs, CRUD, límites de fecha), `backup_service_test.dart`, `gemini_vision_service_test.dart`.
- [x] (Systems-Auditor) Crear suite de pruebas para widgets: `test/widgets/calories_hero_ring_test.dart`, `daily_calorie_summary_card_test.dart`, `dashboard_fab_menu_test.dart`, `week_calendar_strip_test.dart`, `ve_logo_test.dart`, `meal_form_fields_test.dart`, `quick_meal_dialog_test.dart`.
- [x] (Systems-Auditor) Auditar consultas de base de datos para garantizar cero N+1 queries.
- [x] (Systems-Auditor) Auditar seguridad de API Keys (almacenamiento encriptado, cero exposición en logs).
- [x] (Systems-Auditor) Auditar presupuesto de nodos DOM / widgets (< 800 nodos por vista).
- [x] (Systems-Auditor) Emitir veredicto formal del Quality Gate en `artifacts/audit_reports/audit_report.md` (`Status: PASS`).

---

## 🚀 5. DevOps-Engineer (CI/CD, Workflows & Release)
- [x] (DevOps-Engineer) Verificar prerequisito de Quality Gate (`Status: PASS` en `audit_report.md`).
- [x] (DevOps-Engineer) Asegurar el pipeline principal de CI en `.github/workflows/ci.yml` (Flutter analyze, test con coverage, upload de reporte).
- [x] (DevOps-Engineer) Corregir y normalizar flujos de compilación `.github/workflows/build_apk.yml` y `.github/workflows/build_windows.yml` eliminando rutas erróneas a carpetas inexistentes `./app`.
- [x] (DevOps-Engineer) Corregir y normalizar `.github/workflows/release.yml` para empaquetar APK de Android y ZIP de Windows con el nombre correcto `Victor-Engineer-Food-Tracker`.
- [x] (DevOps-Engineer) Corregir `.github/workflows/sync-docs.yml` con el prefijo de proyecto `App_Food_Tracker` y `PRJ_VEFoodTracker_`.
- [x] (DevOps-Engineer) Asegurar versionamiento semántico v1.0.0+1 en `pubspec.yaml` y release notes.
