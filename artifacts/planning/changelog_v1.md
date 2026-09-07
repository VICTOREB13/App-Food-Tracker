---
title: Registro de Cambios (Changelog) - Victor Engineer Food Tracker
status: active
tags: [proyecto, changelog, versiones, keepachangelog, semver, gemini, usda, mifflin-st-jeor]
agent: project-planner
project: App_Food_Tracker
version: v0.2.0-alpha
date: 2026-09-07
---

# 📜 Registro de Cambios (Changelog) - Victor Engineer Food Tracker

Todos los cambios notables de este proyecto se documentarán en este archivo.
El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/) y este proyecto se adhiere a [Semantic Versioning](https://semver.org/lang/es/).

---

## [Unreleased]

### Planned
- **Sincronización P2P Segura:** Replicación local cifrada punto a punto entre dispositivos en la misma red Wi-Fi sin intermediarios de nube.
- **Exportación de Informes Clínicos:** Generación de informes en PDF y Excel para seguimiento nutricional con gráficos de evolución.
- **Widgets de Escritorio y Bandeja:** Micro-widgets compactos para Windows y notificaciones enriquecidas de hidratación para Android.

---

## [0.2.0-alpha] - 2026-09-07

### Added
- **Descubrimiento Dinámico de Modelos de Google Gemini:**
  - Servicio `GeminiModelService` con llamada en vivo a `GET https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}` para introspección de modelos disponibles sin hardcoding.
  - Filtrado estricto por soporte de generación de contenido (`generateContent`) y modalidad de imagen/multimodal.
  - Componente `GeminiModelSelectorCard` en ajustes con insignias semánticas (*Recomendado Rápido*, *Recomendado Pro*, *Equilibrado*) y persistencia segura en `SecureStorageService`.
- **Integración con USDA FoodData Central:**
  - Servicio `UsdaFoodDataService` con factor de conversión $kJ \rightarrow kcal$ (4.184), soporte para búsqueda por código de barras / UPC y control de tasa (1.000 req/hr).
  - Componente `UsdaApiKeyCard` con toggle de visibilidad y almacenamiento cifrado en hardware (`flutter_secure_storage`).
- **Cascada Resiliente de Alimentos (`BarcodeLookupService`):**
  - Motor de cascada nutricional: consulta prioritaria al USDA FoodData Central y fallback automático y transparente a Open Food Facts API v2 ante ausencias o fallas.
- **Motor Metabólico Clínico Mifflin-St Jeor:**
  - `MetabolicCalculator` para cálculo de Tasa Metabólica Basal (TMB) y Gasto Energético Total Diario (TDEE) ajustado por nivel de actividad y pasos diarios.
  - Sincronización automática del TDEE con las metas calóricas y de macronutrientes en `DailyGoals`.
  - Generador de **Master Prompt**: contextualización dinámica inyectada en las instrucciones de `GeminiVisionService` con el perfil del usuario.
- **Pantalla de Perfil Nutricional (`UserProfileScreen`):**
  - Pantalla atómica (238 LoC) con widgets: `BiometricInputsCard`, `ActivityGoalSelectorCard` y `MetabolicSummaryBentoCard`.
- **Persistencia Relacional SQLite v2:**
  - Migración automática a base de datos v2 incorporando la tabla `weight_logs` e índice B-Tree `idx_weight_logs_date`.
  - Consultas indexadas por rangos de fecha (7, 30 y 90 días) con latencia < 2 ms.
  - Soporte de respaldo v2 en `BackupService` para exportación e importación atómica de registros de peso y perfil.
- **Panel de Analíticas Bento Grid (`MetricsScreen`):**
  - Pantalla atómica (198 LoC) accesible desde `VeAppBar`.
  - Dibujado vectorial de curvas Bézier a 60 FPS acelerado por hardware con `WeightLineChartPainter`.
  - Tarjetas Bento Grid: `WeightTrendBentoCard`, `CalorieComplianceBentoCard`, `MacroDistributionBentoCard`, `StreakComplianceBentoCard`.
  - Diálogo modal `QuickWeightEntryDialog` con validación y clamp defensivo anti-NaN/Inf.
- **Firma Permanente de Android (Keystore RSA 2048):**
  - Generación de Keystore con alias `foodtracker` y validez de 30 años (hasta 2056) permitiendo actualizaciones continuas sin desinstalar la app.

### Changed
- **Migración Integral de Deprecaciones de Color:**
  - Eliminadas el 100% de las llamadas a `.withOpacity(...)`, sustituidas por `.withValues(alpha: ...)` compatibles con Flutter 3.22+ y 3.27+.
- **Monolito Modular Estricto (< 300 LoC):**
  - Todas las pantallas cumplen la cota de modularidad: `DashboardScreen` (294 LoC), `MealDetailScreen` (287 LoC), `MetricsScreen` (198 LoC), `SettingsScreen` (262 LoC), `UserProfileScreen` (238 LoC).
- **Incremento de Versión Semántica:**
  - Actualización en `pubspec.yaml` a versión `0.2.0-alpha+1`.

### Fixed
- **Incompatibilidad Gradle / Android 16 con `sqflite`:**
  - Fijada la dependencia `sqflite: '>=2.3.3+1 <2.4.0'` para evitar que `sqflite_android-2.4.3` intente compilar contra APIs incompatibles de Java 21 / Android 16 (`Locale.of`, `Thread.threadId`, `BAKLAVA`).
- **Resolución de Dependencias AndroidX en CI:**
  - Inyección de script de inicialización Gradle (`~/.gradle/init.gradle`) en el flujo de GitHub Actions para forzar versiones compatibles con `compileSdk 34` (`androidx.core: 1.13.1`, `androidx.activity: 1.9.3`, `androidx.fragment: 1.8.5`).
- **Aislamiento de Pruebas Unitarias y Widgets con FFI:**
  - Uso de `databaseFactoryFfiNoIsolate` para evitar colisiones y carreras con `FakeAsync` en entornos de prueba.
- **Dimensionamiento de Viewport en Pruebas de Widgets:**
  - Configuración de tamaño de renderizado virtual a `800x2400` en pruebas de pantallas con desplazamiento (`UserProfileScreen`) garantizando la presencia de todos los elementos en el árbol.

### Security
- Custodia criptográfica en hardware (`EncryptedSharedPreferences` / Keychain) para las API Keys de Google Gemini y USDA FoodData Central.
- Firma de releases de producción automatizada en GitHub Actions mediante secretos cifrados.
- Sanitización estricta mediante `ModelSanitizer` contra desbordamientos numéricos, cadenas gigantescas e inyecciones.

---

## [0.1.0-alpha] - 2026-09-06

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
