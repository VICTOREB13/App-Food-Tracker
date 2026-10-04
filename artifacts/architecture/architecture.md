---
tipo: arquitectura
proyecto: App_Food_Tracker
version: v1.1.0
estado: activo
fecha: 2026-10-04
stack_principal: [Flutter, SQLite WAL v3, Google Gemini API, USDA FoodData Central, Open Food Facts, FlutterSecureStorage, GetIt, Flutter Localizations, HomeWidget]
diagrama_html: PRJ_App_Food_Tracker_architecture_diagram.html
tags: [proyecto, arquitectura, tech-stack, archify, local-first, get-it, l10n, result-pattern, android-widgets, sqlite-v3]
---

# 🏗️ Arquitectura del Sistema: Victor Engineer - Food Tracker (v1.1.0)

> **Mesa de Control & Backend-Architect:** Este documento establece los componentes fundamentales, el Tech Stack tecnológico, las decisiones arquitectónicas estructurales y el flujo de datos integral de la aplicación **Victor Engineer - Food Tracker** en su versión `v1.1.0` (Generación Omnicanal de Precisión Visual, Volumétrica y Nutricional).

---

## 🛠️ 1. Tech Stack Oficial

- **Frontend:** Flutter 3.22+ / 3.27+ (Dart SDK `>=3.4.0 <4.0.0`), Google Fonts (Outfit, Inter), CustomPainter (`WeightLineChartPainter` y `VeLoadingRing` a 60 FPS).
- **Backend & Lógica de Dominio:** Dart Core, Clean Monolith modular (<300 LoC por archivo), Inmutabilidad con Patrón Sentinel, `ModelSanitizer`.
- **Inyección de Dependencias & Service Locator:** `get_it: ^7.7.0` centralizado en `lib/core/di/service_locator.dart`, registrando contratos abstractos (`IDatabaseService`, `IImageProcessingService`, `IMealDao`, `IWeightLogDao`, `IUserProfileDao`, `IPantryDao`, `IDishwareDao`, `IMealTemplateDao`, `IFastingDao`) con inyección por constructor y compatibilidad transparente con accesores estáticos `.instance`.
- **Manejo Funcional de Errores (Result / Either):** Tipo suma sellado en Dart 3 `Result<T, Failure>` (`Success`, `FailureResult`) en `lib/core/errors/result.dart` con combinadores funcionales (`fold`, `map`, `flatMap`, `guardAsync`) y jerarquía exhaustiva `Failure` en `lib/core/errors/failures.dart`.
- **Internacionalización y Localización Multi-idioma:** `flutter_localizations`, `intl` y `l10n.yaml` con contratos tipados en `AppLocalizations` (`lib/l10n/app_es.arb` y `lib/l10n/app_en.arb`) desacoplados de los widgets, con selector dinámico en caliente sin reiniciar la app.
- **Base de Datos & Cache (Local-First):** SQLite v3 mediante `sqflite` (móvil) y `sqflite_common_ffi` (escritorio/tests):
  - `PRAGMA journal_mode = WAL;` (Concurrencia óptima de lecturas y escrituras simultáneas).
  - `PRAGMA synchronous = NORMAL;` (Persistencia confiable y latencia < 16 ms).
  - `PRAGMA foreign_keys = ON;` (Integridad referencial estricta).
  - Tablas v3: `meals`, `meal_items`, `pantry_items`, `weight_logs`, `user_profile`, `analysis_queue`, `calibrated_dishware`, `meal_templates`, `fasting_logs`.
  - Columnas de micronutrientes: `fiber`, `sodium`, `sugar` en `meals` y `meal_items`.
  - Capa de DAOs atómicos: `MealDao`, `WeightLogDao`, `UserProfileDao`, `PantryDao`, `DishwareDao`, `MealTemplateDao`, `FastingDao`, `DatabaseConnectionFactory` y `DatabaseSchema`.
- **Widgets Nativos de Android (AppWidgets):** `home_widget: ^0.7.0` con sincronización en SharedPreferences y layouts XML nativos en `res/layout/`:
  - **Widget Compacto (2x2):** Anillo de progreso calórico, calorías restantes vs meta, y botón de acción directa `[+ Registrar]`.
  - **Widget Extendido (4x2):** Anillo de calorías a la izquierda, desglose tri-columna de macronutrientes (Proteína, Carbohidratos, Grasas), y botones táctiles interactivos de 1 toque con deep links directos (`foodtracker://scan_food` para cámara IA y `foodtracker://scan_barcode` para escáner USDA).
  - **Doble Tema Nativo:** `res/values/colors.xml` (Modo Claro) y `res/values-night/colors.xml` (Modo Oscuro Zinc/Carmesí con esquinas redondeadas de 24dp).
- **Inferencia IA & Visión Multimodal:** Google Generative AI SDK (`google_generative_ai: ^0.4.6`):
  - Inyección de Escala Métrica de Vajilla: Inyección del diámetro en cm de la vajilla calibrada en el prompt del sistema para cálculo volumétrico de alta precisión.
  - Inyección de Contexto de Despensa: Reconocimiento inteligente de marcas del usuario (`PantryItem`).
  - Resiliencia Defensiva: `GeminiResilienceHelper` con reintentos exponenciales, jitter y conmutación automática de modelo (`gemini-2.5-flash` $\rightarrow$ `gemini-1.5-flash`).
  - Esquema JSON estructurado (`responseSchema`), temperatura 0.2, timeout defensivo de 35s y rescate de JSON truncado (`JsonRepairHelper`).
- **Estimación Local Zero-Tokens:** `OfflineFoodEstimatorService` con catálogo normalizado de 50+ alimentos base por 100g para autocompletado y cálculo instantáneo sin coste de red ni consumo de tokens.
- **Procesamiento Asíncrono en Background (Zero-Freeze):** Cola de tareas SQLite `AnalysisQueueService` con encolamiento en milisegundo 0 antes de la compresión en isolate (`compressAndResizeAsync`), preservación garantizada de fotos en disco ante errores y anillo interactivo `VeLoadingRing`.
- **Bases de Datos Nutricionales (Cascada Híbrida):**
  - **Primaria:** USDA FoodData Central API (`https://api.nal.usda.gov/fdc/v1/`) con coincidencia exacta GTIN (`padLeft(14, '0')`), normalización energética ($kJ \rightarrow kcal$ factor 4.184) y control de tasa.
  - **Fallback:** Open Food Facts API v2 con timeout defensivo de 10s.
- **Motor Biométrico & Metabólico:** `MetabolicCalculator` implementando Mifflin-St Jeor para TMB/TDEE con ajuste por pasos y fórmula clínica de Peso Corporal Ajustado ($ABW$) para IMC $\ge 30$.
- **Seguridad Criptográfica & BYOK:** `flutter_secure_storage` con `AndroidOptions(encryptedSharedPreferences: true)` y Keystore permanente RSA 2048 con alias `foodtracker`.

---

## 📐 2. Diagrama de Arquitectura Interactivo (Archify)

El diagrama interactivo de componentes, límites de seguridad, widgets nativos de Android y flujos de red/persistencia del sistema se mantiene como archivo HTML autónomo con SVG vectorial de alta fidelidad:

🔗 **Ver Diagrama:** [[PRJ_App_Food_Tracker_architecture_diagram.html|Abrir Diagrama de Arquitectura Interactivo]]

*(Ubicación en disco: `artifacts/architecture/architecture_diagram.html` | Archivo fuente JSON: `artifacts/architecture/src/architecture_diagram.json`)*

---

## 🏛️ 3. Principios y Decisiones Clave de Diseño v1.1.0

### 3.1. Local-First & Cero Dependencia de Red para Operaciones Básicas
- Todas las operaciones CRUD de comidas, despensa, calibración de platos, registros de ayuno, metas calóricas, registros de peso e historial son ejecutadas de manera síncrona/inmediata en SQLite local.
- La red únicamente se invoca bajo demanda explícita: estimación visual con Gemini, consulta de modelos en vivo o escaneo de códigos de barras. La pérdida de conectividad no interrumpe ninguna función de visualización o registro.

### 3.2. Concurrencia y Resiliencia en SQLite v3 (Modo WAL)
- Se activa `PRAGMA journal_mode = WAL;` y `PRAGMA synchronous = NORMAL;`.
- Migración v3 sin pérdida de datos: alteración idempotente de tablas existentes (`meals`, `meal_items`, `pantry_items`) y creación de `calibrated_dishware`, `meal_templates` y `fasting_logs` con sus respectivos índices B-Tree.
- Bloqueo de inicialización mediante `_initFuture` en `DatabaseConnectionFactory` contra arranques en frío simultáneos.

### 3.3. Arquitectura de Widgets Nativos Android (Glance / RemoteViews)
- Los widgets de pantalla de inicio operan de forma desacoplada de la VM de Flutter mediante `SharedPreferences` compartidas y `AppWidgetProvider` nativo de Android.
- `HomeWidgetService` actualiza los estados atómicamente tras cada inserción o edición de comida.
- El deep linking con esquemas `foodtracker://scan_food` y `foodtracker://scan_barcode` ofrece atajos de latencia cero desde el launcher del sistema operativo.
- Soporte nativo para modo claro y modo oscuro según la configuración del sistema de Android a través de carpetas de recursos `values` y `values-night`.

### 3.4. Resiliencia de IA y Cero-Pérdida de Capturas
- Las imágenes tomadas por el usuario se guardan de forma permanente antes de cualquier llamada a la API de Gemini.
- En caso de fallo de red, cuota (429) o indisponibilidad (503), la foto física NUNCA se elimina. La tarea queda en estado `failed` en el banner del Dashboard, permitiendo reintentar con backoff exponencial o editar manualmente precargando la captura.
- Cascada automática a modelos de respaldo para garantizar continuidad del servicio.

### 3.5. Monolito Modular (< 300 LoC por Archivo)
- Toda pantalla, widget o servicio en `lib/` respeta el umbral estricto de menos de 300 líneas de código:
  - DAOs atómicos (`MealDao`, `WeightLogDao`, `UserProfileDao`, `PantryDao`, `DishwareDao`, `MealTemplateDao`, `FastingDao`).
  - Servicios auxiliares desacoplados (`GeminiResilienceHelper`, `OfflineFoodEstimatorService`, `HomeWidgetService`, `MealImageFileNamer`, `MealImageStorageResolver`).
  - Widgets Bento modulares en `lib/widgets/`.

### 3.6. Estimación Inteligente Local Zero-Tokens
- `OfflineFoodEstimatorService` resuelve búsquedas como "carne molida 100g" en menos de 5 milisegundos sin consumir tokens de IA ni realizar peticiones HTTP, reduciendo la latencia de usuario y los costes operativos.
