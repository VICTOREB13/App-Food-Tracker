---
tipo: arquitectura
proyecto: App_Food_Tracker
version: v1.0.4
estado: activo
fecha: 2026-09-13
stack_principal: [Flutter, SQLite WAL v2, Google Gemini API, USDA FoodData Central, Open Food Facts, FlutterSecureStorage, GetIt, Flutter Localizations]
diagrama_html: PRJ_App_Food_Tracker_architecture_diagram.html
tags: [proyecto, arquitectura, tech-stack, archify, local-first, get-it, l10n, result-pattern]
---

# 🏗️ Arquitectura del Sistema: Victor Engineer - Food Tracker (v1.0.4)

> **Mesa de Control & Backend-Architect:** Este documento establece los componentes fundamentales, el Tech Stack tecnológico, las decisiones arquitectónicas estructurales y el flujo de datos integral de la aplicación **Victor Engineer - Food Tracker**.

---

## 🛠️ 1. Tech Stack Oficial

- **Frontend:** Flutter 3.22+ / 3.27+ (Dart SDK `>=3.4.0 <4.0.0`), Google Fonts (Outfit, Inter), CustomPainter (`WeightLineChartPainter` y `VeLoadingRing` a 60 FPS).
- **Backend & Lógica de Dominio:** Dart Core, Clean Monolith modular (<300 LoC por archivo), Inmutabilidad con Patrón Sentinel, `ModelSanitizer`.
- **Inyección de Dependencias & Service Locator:** `get_it: ^7.7.0` centralizado en `lib/core/di/service_locator.dart`, registrando contratos abstractos (`IDatabaseService`, `IImageProcessingService`, `IMealDao`, `IWeightLogDao`, `IUserProfileDao`, `IPantryDao`) con inyección por constructor y compatibilidad transparente con accesores estáticos `.instance`.
- **Manejo Funcional de Errores (Result / Either):** Tipo suma sellado en Dart 3 `Result<T, Failure>` (`Success`, `FailureResult`) en `lib/core/errors/result.dart` con combinadores funcionales (`fold`, `map`, `flatMap`, `guardAsync`) y jerarquía exhaustiva `Failure` en `lib/core/errors/failures.dart`.
- **Internacionalización y Localización Multi-idioma:** `flutter_localizations`, `intl` y `l10n.yaml` con contratos tipados en `AppLocalizations` (`lib/l10n/app_es.arb` y `lib/l10n/app_en.arb`) desacoplados de los widgets.
- **Base de Datos & Cache (Local-First):** SQLite v2 mediante `sqflite` (móvil) y `sqflite_common_ffi` (escritorio/tests):
  - `PRAGMA journal_mode = WAL;` (Concurrencia óptima de lecturas y escrituras simultáneas).
  - `PRAGMA synchronous = NORMAL;` (Persistencia confiable y latencia < 16 ms).
  - `PRAGMA foreign_keys = ON;` (Integridad referencial estricta).
  - Tablas: `meals`, `meal_items`, `pantry_items`, `weight_logs`, `user_profile`, `analysis_queue`.
  - Capa de DAOs atómicos: `MealDao`, `WeightLogDao`, `UserProfileDao`, `PantryDao`, `DatabaseConnectionFactory` y `DatabaseSchema`.
- **Inferencia IA & Visión Multimodal:** Google Generative AI SDK (`google_generative_ai: ^0.4.6`) con consulta en vivo para descubrimiento dinámico de modelos (`GET https://generativelanguage.googleapis.com/v1beta/models`), generación estructurada JSON (`responseSchema`), temperatura 0.2, timeout defensivo de 35s, rescate de JSON truncado (`JsonRepairHelper`), salvaguarda de condimentos (`isSeasoningOrHerb`) e inyección de Master Prompt biométrico.
- **Procesamiento Asíncrono en Background:** Cola de tareas SQLite `AnalysisQueueService` desacoplada del hilo de UI, con anillo de carga dinámico `VeLoadingRing` y banner reactivo en Dashboard.
- **Bases de Datos Nutricionales (Cascada Híbrida):**
  - **Primaria:** USDA FoodData Central API (`https://api.nal.usda.gov/fdc/v1/`) con coincidencia exacta GTIN (`padLeft(14, '0')`), normalización energética ($kJ \rightarrow kcal$ factor 4.184) y control de tasa (1.000 req/hr).
  - **Fallback:** Open Food Facts API v2 con timeout defensivo de 10s.
- **Motor Biométrico & Metabólico:** `MetabolicCalculator` implementando la ecuación clínica internacional **Mifflin-St Jeor** para TMB y TDEE según pasos diarios y actividad física, incorporando la fórmula clínica de Peso Corporal Ajustado ($ABW$) para usuarios con IMC $\ge 30$.
- **Seguridad Criptográfica & BYOK:** `flutter_secure_storage` con `AndroidOptions(encryptedSharedPreferences: true)` en Android y Keychain en iOS para custodia local de las claves de API de Gemini y USDA.
- **Procesamiento y Compresión de Imágenes:** Paquete `image: ^4.5.2` con compresión en Isolate secundario (`compressAndResizeAsync`) a un límite máximo de 1024x1024 píxeles y codificación JPEG al 85% de calidad, estandarización de nombres en `MealImageFileNamer` y resolución de directorios en `MealImageStorageResolver`.
- **Persistencia de Preferencias de UI:** `shared_preferences: ^2.3.5` para el modo de tema y perfil.

---

## 📐 2. Diagrama de Arquitectura Interactivo (Archify)

El diagrama interactivo de componentes, límites de seguridad y flujos de red/persistencia del sistema se mantiene como archivo HTML autónomo con SVG vectorial de alta fidelidad:

🔗 **Ver Diagrama:** [[PRJ_App_Food_Tracker_architecture_diagram.html|Abrir Diagrama de Arquitectura Interactivo]]

*(Ubicación en disco: `artifacts/architecture/architecture_diagram.html` | Archivo fuente JSON: `artifacts/architecture/src/architecture_diagram.json`)*

---

## 🏛️ 3. Principios y Decisiones Clave de Diseño

### 3.1. Local-First & Cero Dependencia de Red para Operaciones Básicas
- Todas las operaciones CRUD de comidas, despensa, metas calóricas, registros de peso e historial son ejecutadas de manera síncrona/inmediata en SQLite local.
- La red únicamente se invoca bajo demanda explícita: al fotografiar un plato para estimación visual con Gemini, consultar modelos en vivo o escanear un código de barras. La pérdida de conectividad no interrumpe ninguna función de visualización o registro.

### 3.2. Concurrencia y Resiliencia en SQLite v2 (Modo WAL)
- Se activa `PRAGMA journal_mode = WAL;` y `PRAGMA synchronous = NORMAL;`.
- Permite que múltiples llamadas asíncronas lean datos concurrentemente sin bloqueos de escritura.
- La migración a la versión 2 crea la tabla `weight_logs`, `user_profile` y los índices correspondientes dentro de transacciones.
- Bloqueo de inicialización mediante `_initFuture` en `DatabaseConnectionFactory` contra arranques en frío simultáneos.

### 3.3. Inmutabilidad y Patrón Sentinel
- Los modelos (`Meal`, `FoodItem`, `PantryItem`, `DailyGoals`, `UserProfile`, `WeightLog`, `GeminiModelInfo`) son inmutables.
- Para distinguir entre "no actualizar un campo" y "limpiar un campo asignándole `null`", el método `copyWith` utiliza una instancia privada centinela:
  ```dart
  static const Object _sentinel = Object();
  Meal copyWith({Object? imagePath = _sentinel, ...}) {
    return Meal(
      imagePath: identical(imagePath, _sentinel) ? this.imagePath : (imagePath as String?),
      ...
    );
  }
  ```

### 3.4. Sanitización Defensiva Centralizada (`ModelSanitizer`)
- Protección contra strings gigantescos (nombres acotados a 255 caracteres, notas a 2000 caracteres, JSON a 100000 caracteres).
- Valores numéricos acotados contra `NaN`, infinitos y límites plausibles (`clampDouble(val, min: 0.0, max: 9999.0)`).
- Fechas deserializadas con fallback a `DateTime.now()` en caso de formatos corruptos.

### 3.5. Monolito Modular (< 300 LoC por Archivo)
- Ninguna pantalla, widget o servicio en `lib/` excede las 300 líneas de código:
  - `DashboardScreen`: 294 LoC
  - `MealDetailScreen`: 287 LoC
  - `MetricsScreen`: 198 LoC
  - `SettingsScreen`: 262 LoC
  - `UserProfileScreen`: 238 LoC
  - `DatabaseService`: 217 LoC (delegando a DAOs especializados)
  - `ImageProcessingService`: 265 LoC (delegando a namer y storage resolver)
- Se extraen tarjetas, diálogos, barras y gráficos en widgets especializados (`widgets/common/`, `widgets/dashboard/`, `widgets/meal_detail/`, `widgets/settings/`, `widgets/profile/`, `widgets/metrics/`).

### 3.6. Seguridad Criptográfica y Firma Permanente de Producción
- Claves de Gemini y USDA almacenadas mediante `FlutterSecureStorage` en `EncryptedSharedPreferences` (Android) y Keychain (iOS).
- Clave Keystore permanente RSA 2048 con alias `foodtracker` y validez hasta 2056 inyectada en CI/CD mediante secretos de GitHub.

### 3.7. Inyección de Dependencias Formal y Service Locator (`GetIt`)
- Desacoplamiento de componentes concretos mediante la interfaz abstracta `IDatabaseService`, `IImageProcessingService` y DAOs en `lib/core/interfaces/`.
- Configuración centralizada en `service_locator.dart` permitiendo `setupServiceLocator({bool isTesting = false})` y `resetServiceLocator()` para tests unitarios aislados.
- Inyección por constructor en `MealController(databaseService, imageProcessingService)` y `SettingsController` con preservación de singletons `.instance` para compatibilidad transparente.

### 3.8. Capa de DAOs Especializados (< 300 LoC) y Separación de Esquema/Conexión
- `MealDao` (220 LoC): Persistencia y consultas de `meals` y `meal_items`.
- `WeightLogDao` (185 LoC): Consultas de peso e inserción por lotes (`batchUpsertWeightLogs`).
- `UserProfileDao` (83 LoC): Perfil biométrico y metas calculadas.
- `PantryDao` (119 LoC): Alimentos de despensa y favoritos.
- `DatabaseConnectionFactory` (81 LoC): Conexión de plataforma, WAL pragmas e inicialización memoizada.
- `DatabaseSchema` (116 LoC): DDL relacional, índices B-Tree de cobertura y migraciones.

### 3.9. Manejo Funcional de Errores con Tipo Suma Sellado (`Result<T, Failure>`)
- Reemplazo de excepciones no controladas por el tipo monádico `Result<T, Failure>` en Dart 3 con subclases `Success<T, E>` y `FailureResult<T, E>`.
- Manejo exhaustivo con pattern matching y combinadores funcionales (`fold`, `map`, `flatMap`, `guardAsync`).
- Jerarquía sellada `Failure` tipada por dominio (`DatabaseFailure`, `AiServiceFailure`, `NetworkFailure`, `ValidationFailure`, `StorageFailure`, `ImageProcessingFailure`).

### 3.10. Internacionalización y Localización Multi-idioma (`AppLocalizations`)
- Soporte bilingüe completo (español e inglés) mediante archivos de recursos ARB (`app_es.arb` y `app_en.arb`).
- Clase generada `AppLocalizations` registrada en `NutriTrackerApp` con soporte para detección automática de idioma del dispositivo y fallback a español.

### 3.11. Procesamiento Desacoplado de Fotos (`MealImageFileNamer` y `MealImageStorageResolver`)
- `MealImageFileNamer` (229 LoC): Formato canónico `YYYY_MM_DD_{TYPE}_{INDEX}.jpg`, inferencia de tiempo de comida por hora del día, y parseo regex.
- `MealImageStorageResolver` (153 LoC): Detección resiliente del directorio de imágenes (`Pictures/FoodTrackerMeals` en Android) y fallback a `Documents`.
- Abstracciones detalladas documentadas en [[PRJ_App_Food_Tracker_abstractions|Abstracciones del Sistema y Arquitectura de Código]].

