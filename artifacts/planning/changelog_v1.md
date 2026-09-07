---
title: Registro de Cambios (Changelog) - Victor Engineer Food Tracker
status: active
tags: [proyecto, changelog, versiones, keepachangelog, semver]
agent: project-planner
project: VE_FoodTracker
version: v1.0.0
date: 2026-09-06
---

# 📜 Registro de Cambios (Changelog) - Victor Engineer Food Tracker

Todos los cambios notables de este proyecto se documentarán en este archivo.
El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/) y este proyecto se adhiere a [Semantic Versioning](https://semver.org/lang/es/).

---

## [Unreleased]

### Planned
- **AnalyticsScreen:** Gráficos de tendencias semanales y curvas horarias de ingesta estilo Vitalis.
- **Sincronización P2P:** Respaldo y replicación directa entre dispositivos de la misma red local sin servidores centrales.
- **Widgets de Escritorio:** Micro-widgets nativos para Windows y Android con acceso directo a registro de agua.

---

## [1.0.0] - 2026-09-06

### Added
- **Arquitectura Local-First:** Base de datos SQLite local (`sqflite` y `sqflite_common_ffi`) configurada con `PRAGMA journal_mode = WAL;`, `PRAGMA synchronous = NORMAL;` y `PRAGMA foreign_keys = ON;` para lecturas y escrituras no bloqueantes con latencia inferior a 16 ms.
- **Inferencia de Visión con IA (Gemini 2.5 Flash):** Servicio `GeminiVisionService` con esquemas estrictos de salida JSON (`responseSchema`) e inyección de reglas clínicas de estimación volumétrica sin báscula (puño cerrado ~ 1 taza, palma ~ 100-130g carne, falange ~ 10-15g grasa, merma de cocción y grasa oculta en comidas caseras).
- **Seguridad Criptográfica BYOK (Bring Your Own Key):** Custodia de la clave de API de Gemini provista por el usuario en `flutter_secure_storage` con `EncryptedSharedPreferences` en Android y Keychain en iOS.
- **Modelos Inmutables y Patrón Sentinel:** Modelos `Meal`, `FoodItem`, `PantryItem` y `DailyGoals` diseñados con inmutabilidad estricta y método `copyWith` que permite desasociar valores opcionales pasando `null` explícito gracias a un objeto centinela privado.
- **Sanitización Defensiva Centralizada (`ModelSanitizer`):** Clamp de números en rangos plausibles (`0.0` a `9999.0` para macros), truncamiento de strings (255 chars para nombres, 2000 chars para notas, 100000 chars para JSON) y parseo seguro de fechas ISO 8601.
- **Sistema de Diseño Victor Engineer:**
  - Tema Oscuro *Obsidian Zinc* (`#09090B`, `#121215`, `#18181B`, `#27272A`, `#DC2626`).
  - Tema Claro *Crisp Zinc* (`#FAFAFA`, `#FFFFFF`, `#F4F4F5`, `#E4E4E7`, `#DC2626`).
  - Paleta semántica de macronutrientes: Calorías (`#F97316`), Proteínas (`#EF4444`), Carbohidratos (`#EAB308`), Grasas (`#3B82F6`), Hidratación (`#06B6D4`).
  - Tipografía `Outfit` para métricas numéricas display (40 sp, `tabularFigures`) y títulos; `Inter` para cuerpos de texto.
  - Bento Grid con tarjetas squircle de radio 20px y espaciado de 12px.
- **Speed-Dial Flotante y Acciones Dinámicas:** Botón de acción flotante desacoplado con rotación elástica de 45° (`Curves.easeOutBack`) y menú 2x3 para escaneo con cámara, galería, código de barras, entrada manual, +250ml de agua y comida rápida estimada.
- **Despensa Local y Escáner de Códigos de Barras:** Integración de `mobile_scanner` con `OpenFoodFactsService` para consulta y guardado local de alimentos envasados.
- **Exportación e Importación de Respaldos:** Servicio `BackupService` con serialización JSON indentada y transacción atómica en SQLite para restauración sin riesgo de corrupción.
- **Mantenimiento de Base de Datos:** Ejecución de `VACUUM` y monitoreo de estadísticas de almacenamiento (conteo de registros y peso en KB) en `SettingsScreen`.
- **Descomposición Atómica de UI (< 300 LoC):** 25 widgets modulares y 3 pantallas maestras cumpliendo estrictamente la directriz de menos de 300 líneas de código.
- **Batería de Pruebas Automatizadas:** 15 archivos de prueba cubriendo modelos, controladores, lógica de negocio de servicios y renderizado de widgets.
- **Pipelines de Integración Continua (CI/CD):** Flujos de GitHub Actions para Quality Gate (`ci.yml`), compilación de APK Android (`build_apk.yml`), binario de Windows (`build_windows.yml`) y publicación de releases oficiales (`release.yml`).

### Fixed
- **Compatibilidad Flutter 3.22+ y 3.27+:** Implementada extensión ColorCompat para soportar .withValues(alpha: ...) en Flutter 3.22 sin fallas de compilación.
- **Extracción Resiliente de JSON en Visión AI:** MealAnalysisResult soporta respuestas con texto conversacional previo o posterior a bloques Markdown y nombres alternativos de campos.
- **Condiciones de Carrera en Base de Datos:** Resuelto problema potencial en arranques simultáneos mediante cacheo de `_initFuture` en el singleton `DatabaseService`.
- **Rutas de Workflows de GitHub Actions:** Eliminada la asunción heredada de carpeta subyacente `./app`, normalizando la ejecución desde la raíz del repositorio.
- **Recálculo de Macros en Comidas:** `recalculateFromItems` mantiene las macros manuales existentes si la lista de items está vacía, evitando reseteos accidentales a cero.

### Security
- Cero exposición de claves de API en repositorios o logs.
- Sanitización de entradas contra desbordamiento de búfer y campos excesivamente largos.
- Transacciones atómicas de base de datos para prevenir registros huérfanos.
