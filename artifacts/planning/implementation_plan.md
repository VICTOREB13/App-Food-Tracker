---
tipo: implementation_plan
proyecto: VE_FoodTracker
iteracion: v1.0.0
estado: completado
fecha: 2026-09-06
tags: [proyecto, planning, mvp, local-first, evolutionary-prototyping]
---

# 🎯 Plan de Implementación: Victor Engineer Food Tracker (MVP v1.0.0)

> **Mesa de Control (Project-Planner):** Este plan desglosa la construcción iterativa del MVP de "Victor Engineer - Food Tracker" siguiendo la metodología de Prototipado Evolutivo y el principio YAGNI (You Aren't Gonna Need It).

---

## 🎯 1. Objetivo de la Iteración v1.0.0

Construir un Producto Mínimo Viable (MVP) completamente funcional, offline-first y con fidelidad visual de grado comercial, que permita a un usuario:
1. Analizar fotografías de comidas caseras latinoamericanas y estimar automáticamente calorías y macronutrientes usando IA (Gemini 2.5 Flash) sin necesidad de una báscula.
2. Custodiar su propia clave de API (BYOK) de forma segura con cifrado a nivel de hardware (`flutter_secure_storage`).
3. Registrar, editar, eliminar y consultar comidas organizadas cronológicamente en SQLite local de cero latencia (< 16 ms) con modo WAL.
4. Escanear productos envasados por código de barras mediante Open Food Facts.
5. Exportar e importar respaldos completos de la base de datos en formato JSON.
6. Disfrutar de una interfaz de usuario Obsidian Zinc / Crisp Zinc, tipografía Outfit e Inter, y componentes Bento Grid desacoplados en widgets atómicos (< 300 LoC).

---

## 🛠️ 2. Fases de Construcción Ejecutadas

### Fase 1: Fundaciones de Datos y Modelos Inmutables
- [x] Crear `ModelSanitizer` para clamp numérico, truncamiento de texto y deserialización defensiva.
- [x] Implementar modelos de datos con inmutabilidad y patrón Sentinel para eliminación explícita (`Meal`, `FoodItem`, `PantryItem`, `DailyGoals`).
- [x] Implementar `DatabaseService` sobre SQLite con `PRAGMA journal_mode = WAL;`, `PRAGMA synchronous = NORMAL;`, `PRAGMA foreign_keys = ON;`, e índices compuestos para fechas y tipos de comida.
- [x] Resolver condiciones de carrera en la inicialización asíncrona de la base de datos mediante caching de `_initFuture`.

### Fase 2: Servicios de Dominio, Seguridad & Visión por Computadora
- [x] Implementar `SecureStorageService` para almacenar la API Key de Gemini y las metas diarias de forma encriptada.
- [x] Implementar `ImageProcessingService` para redimensionamiento en memoria (máximo 1024x1024 px) y compresión JPEG 85% para optimizar payloads hacia Gemini.
- [x] Diseñar el prompt clínico nutricional e implementar `GeminiVisionService` con esquemas estrictos de salida JSON (`responseSchema`) y reglas volumétricas (puño, palma, falange, grasa oculta, merma de cocción).
- [x] Implementar `OpenFoodFactsService` con timeouts defensivos y mapeo resiliente de macronutrientes.
- [x] Implementar `BackupService` para exportación e importación transaccional en JSON.

### Fase 3: Controladores de Estado y Arquitectura UI Atómica
- [x] Crear `ThemeManager` reactivo con persistencia en `SharedPreferences` y soporte dinámico para Obsidian Zinc (oscuro) y Crisp Zinc (claro).
- [x] Implementar `MealController` y `SettingsController` con `ChangeNotifier`.
- [x] Diseñar y construir widgets atómicos reutilizables (< 300 LoC cada uno):
  - `VeAppBar`, `VeCard`, `VeLogo`, `MacroIndicatorChip`, `ConfirmationDialog`, `BarcodeScannerDialog`.
  - `CaloriesHeroRing`, `DailyCalorieSummaryCard`, `MacroBentoCard`, `WeekCalendarStrip`, `DateSelectorBar`, `StreakBadge`, `DashboardFabMenu`, `QuickMealDialog`, `ApiKeyPromptDialog`, `MealSectionCard`.
  - `MealImageCard`, `MealMacroChipsRow`, `MealFormFields`, `FoodItemsListCard`, `FoodItemEditorDialog`.
  - `ApiKeyInputCard`, `DailyGoalsCard`, `DatabaseMaintenanceCard`, `BackupCard`.
- [x] Ensamblar las 3 pantallas maestras bajo el límite de 300 LoC:
  - `DashboardScreen` (267 LoC).
  - `MealDetailScreen` (283 LoC).
  - `SettingsScreen` (208 LoC).

### Fase 4: Automatización de Pruebas y Quality Gate
- [x] Crear batería completa de pruebas unitarias para modelos (deserialización, límites defensivos, sentinel copyWith).
- [x] Crear suite de pruebas para servicios (`DatabaseService` en memoria, concurrencia de 50 llamadas, filtros de fecha, PRAGMAs e índices; `BackupService` export/import; `GeminiVisionService` parseo de JSON plano y con bloques Markdown).
- [x] Crear suite de pruebas para widgets clave (`CaloriesHeroRing`, `DailyCalorieSummaryCard`, `DashboardFabMenu`, `WeekCalendarStrip`, `VeLogo`, `MealFormFields`, `QuickMealDialog`).
- [x] Ejecutar la auditoría del Quality Gate y generar `audit_report.md` con veredicto `Status: PASS`.

### Fase 5: Infraestructura, DevOps & Automatización CI/CD
- [x] Auditar y reconfigurar los flujos de GitHub Actions (`ci.yml`, `build_apk.yml`, `build_windows.yml`, `release.yml`, `sync-docs.yml`).
- [x] Eliminar dependencias erróneas a carpetas `./app` y normalizar la compilación desde la raíz del repositorio.
- [x] Establecer disparadores de release por etiquetas Git (`v*`) y generación automatizada de binarios (APK y Windows x64).

---

## 🔮 3. Hoja de Ruta para Iteraciones Futuras (v1.1.0+)

1. **Analíticas Avanzadas (Estilo Vitalis):**
   - Pantalla dedicada `AnalyticsScreen` con gráficos de adherencia semanal y curvas de ingesta por franja horaria.
2. **Sincronización P2P Opcional:**
   - Sincronización local-first cifrada punto a punto entre dispositivos sin pasar por servidores centrales.
3. **Widget de Escritorio / Notificaciones de Hidratación:**
   - Recordatorios periódicos con registro de agua en un toque.
