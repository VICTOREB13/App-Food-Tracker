---
tipo: implementation_plan
proyecto: App_Food_Tracker
iteracion: v1.4.6
estado: activo
fecha: 2026-11-15
tags: [proyecto, planning, v1-4-6, refactor-untangle, modular-monolith, vertical-slice, mvc, services-relocation]
---

# 📐 Plan de Implementación v1.4.6 (Fase Definitiva): Reubicación Canónica de 'lib/services/' y Purga Estructural Total

> **Mesa de Control & Systems-Auditor / Project-Planner:** Este documento formaliza la reubicación final de la carpeta `lib/services/`. Tras la erradicación de `screens/`, `controllers/`, `widgets/` y `models/`, la existencia de `services/` en la raíz de `lib/` representaba el último remanente horizontal. Este plan distribuye los 33 servicios técnicos y de dominio entre **`lib/core/` (motores de infraestructura)** y **`lib/features/<slice>/` (lógica específica de caso de uso)**, dejando la raíz del proyecto en su **topología canónica perfecta de 3 conceptos maestros: `core/`, `features/`, `l10n/`**.

---

## 🎯 1. Mapa de Distribución Canónica de los 33 Servicios

```text
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                   DISTRIBUCIÓN CANÓNICA DE LOS CONTENIDOS DE 'lib/services/'                     │
├─────────────────────────────────────────────────┬────────────────────────────────────────────────┤
│ 1. INFRAESTRUCTURA COMPARTIDA ('lib/core/')     │ 2. LÓGICA DE NEGOCIO ('lib/features/<slice>/') │
├─────────────────────────────────────────────────┼────────────────────────────────────────────────┤
│ • Base de Datos SQLite ('core/database/'):      │ • Biometrics & Weight:                         │
│   - 'database_service.dart'                       - 'metabolic_calculator.dart'                  │
│   - 'daos/' (7 DAOs atómicos + schema)            - 'metabolic_prompt_generator.dart'            │
│ • Motores de IA ('core/services/ai/'):          │ • Data Backup:                                 │
│   - 'gemini_vision_service.dart'                  - 'backup_normalizer.dart'                     │
│   - 'gemini_resilience_helper.dart'               - 'backup_service.dart'                        │
│   - 'gemini_model_service.dart'                 │ • Dashboard:                                   │
│   - 'gemini_vision_filter.dart'                   - 'nutritional_recommendation_service.dart'    │
│ • Catálogos Nutricionales ('core/services/'):    - 'recommendations/' (algoritmos y catálogo)   │
│   - 'usda_food_data_service.dart'               │ • Food Entry & Meals:                          │
│   - 'open_food_facts_service.dart'                - 'image_processing_service.dart'              │
│   - 'nutrition_label_scanner_service.dart'        - 'meal_image_file_namer.dart'                 │
│ • Plataforma y Hardware ('core/services/'):       - 'meal_image_storage_resolver.dart'           │
│   - 'home_widget_service.dart'                    - 'barcode_lookup_service.dart'                │
│   - 'home_widget_strings.dart'                    - 'analysis_queue_service.dart'                │
│   - 'notification_service.dart'                   - 'offline_food_estimator_service.dart'         │
│   - 'app_update_service.dart'                     - 'food_search_coordinator.dart'               │
│   - 'app_installer_service.dart'                │                                                │
│ • Seguridad y Storage ('core/services/'):       │                                                │
│   - 'secure_storage_service.dart'               │                                                │
│   - 'accessible_storage_resolver.dart'          │                                                │
│ • Exportación Clínica ('core/services/'):       │                                                │
│   - 'clinical_pdf_export_service.dart'          │                                                │
│   - 'clinical_excel_export_service.dart'        │                                                │
│   - 'clinical_share_service.dart'               │                                                │
│ • Tema Global ('core/services/'):               │                                                │
│   - 'theme_manager.dart'                        │                                                │
└─────────────────────────────────────────────────┴────────────────────────────────────────────────┘
```

---

## 🛠️ 2. Fases de Ejecución Paso a Paso

### 🚀 Paso 1: Reubicación de Motores de Infraestructura en `lib/core/`
1. Mover `database_service.dart` y `daos/` a `lib/core/database/`.
2. Mover los motores de IA (`gemini_*`) a `lib/core/services/ai/`.
3. Mover los conectores nutricionales (`usda_*`, `open_food_facts_*`, `nutrition_label_*`) a `lib/core/services/nutrition/`.
4. Mover servicios de plataforma (`home_widget_*`, `notification_*`, `app_*`) a `lib/core/services/platform/`.
5. Mover servicios de seguridad y almacenamiento a `lib/core/services/storage/`.
6. Mover exportadores clínicos a `lib/core/services/export/`.
7. Mover `theme_manager.dart` a `lib/core/services/theme/`.

### 🧩 Paso 2: Reubicación de Servicios de Dominio en `lib/features/`
1. Reubicar calculadora metabólica en `lib/features/biometrics_weight/services/`.
2. Reubicar motor de respaldos SAF e Isolate en `lib/features/data_backup/services/`.
3. Reubicar catálogos de recomendaciones en `lib/features/dashboard/services/`.
4. Reubicar procesadores de imágenes de comida, cola de tareas y estimador offline en `lib/features/food_entry/services/`.

### 🗑️ Paso 3: Eliminación Definitiva de `lib/services/`
- Suprimir físicamente el directorio raíz `lib/services/`.

### 🔄 Paso 4: Sincronización Global de Imports
- Actualizar todas las importaciones en `lib/core/adapters/`, `lib/core/di/service_locator.dart`, `lib/features/`, y `lib/main.dart` para apuntar a las nuevas rutas.

### 🛡️ Paso 5: Certificación de Quality Gate Final
- Ejecutar `bun run validate` (9 artefactos vivos/deltas + 7 heurísticas FIFO).
- Ejecutar `bun run lint:contracts` (SDD Contract Guard).
- Ejecutar `bun test` (100% verde sin regresiones).
- Auditar que ningún archivo exceda las **300 LoC**.

---

## 🗺️ 3. Topología Definitiva Canónica de `lib/`

```text
lib/
├── assets/                     # Recursos visuales y widgets nativos Nothing OS
├── core/                       # Núcleo compartido del sistema
│   ├── adapters/               # Adaptadores concretos (SQLite, Gemini, USDA, SAF, HomeWidget)
│   ├── constants/              # Constantes de la aplicación (AppConstants)
│   ├── database/               # DatabaseService y DAOs de SQLite WAL v4
│   ├── di/                     # Inyección de dependencias (service_locator.dart)
│   ├── errors/                 # Result<T, Failure> y jerarquía de errores
│   ├── models/                 # DTOs transversales de infraestructura
│   ├── ports/                  # Puertos abstractos (Hexagonal Boundary)
│   ├── services/               # Servicios de bajo nivel (ai, nutrition, platform, storage, export, theme)
│   └── ui/                     # Primitivas de interfaz (VeLoadingRing, NothingBottomSheet, etc.)
├── features/                   # Las 7 Rebanadas Verticales Autosuficientes (Micro-MVC + TDD)
│   ├── biometrics_weight/      # Vista, controlador, modelo, widgets, servicios de TMB y tests
│   ├── dashboard/              # Bento Grid, controlador diario, widgets, recomendaciones y tests
│   ├── data_backup/            # Respaldo JSON en Isolate, selector SAF, servicios, vista y tests
│   ├── fasting_tracker/        # Temporizador de ayuno intermitente, vista y tests
│   ├── food_entry/             # Cámara IA, catálogo, porciones, procesamiento de imágenes y tests
│   ├── pantry_inventory/       # Gestión de stock, marcas, alertas de caducidad y tests
│   └── settings_profile/       # Perfil clínico, llaves BYOK Keystore, temas, widgets y tests
├── l10n/                       # Localización multilingüe modular por dominios (ES / EN)
└── main.dart                   # Inicialización y arranque directo
```
