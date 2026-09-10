---
tipo: arquitectura
proyecto: App_Food_Tracker
version: v1.0.1
estado: activo
fecha: 2026-09-10
stack_principal: [Flutter, SQLite WAL v2, Google Gemini API, USDA FoodData Central, Open Food Facts, FlutterSecureStorage]
diagrama_html: PRJ_App_Food_Tracker_architecture_diagram.html
tags: [proyecto, arquitectura, tech-stack, archify, local-first]
---

# 🏗️ Arquitectura del Sistema: Victor Engineer - Food Tracker (v1.0.1)

> **Mesa de Control & Backend-Architect:** Este documento establece los componentes fundamentales, el Tech Stack tecnológico, las decisiones arquitectónicas estructurales y el flujo de datos integral de la aplicación **Victor Engineer - Food Tracker**.

---

## 🛠️ 1. Tech Stack Oficial

- **Frontend:** Flutter 3.22+ / 3.27+ (Dart SDK `>=3.4.0 <4.0.0`), Google Fonts (Outfit, Inter), CustomPainter (WeightLineChartPainter a 60 FPS).
- **Backend & Lógica de Dominio:** Dart Core, Clean Monolith modular (<300 LoC por pantalla), Inmutabilidad con Patrón Sentinel, `ModelSanitizer`.
- **Base de Datos & Cache (Local-First):** SQLite v2 mediante `sqflite` (móvil) y `sqflite_common_ffi` (escritorio/tests):
  - `PRAGMA journal_mode = WAL;` (Concurrencia óptima de lecturas y escrituras simultáneas).
  - `PRAGMA synchronous = NORMAL;` (Persistencia confiable y latencia < 16 ms).
  - `PRAGMA foreign_keys = ON;` (Integridad referencial estricta).
  - Tablas: `meals`, `pantry_items`, `weight_logs`, `user_profile`.
- **Inferencia IA & Visión Multimodal:** Google Generative AI SDK (`google_generative_ai: ^0.4.6`) con consulta en vivo para descubrimiento dinámico de modelos (`GET https://generativelanguage.googleapis.com/v1beta/models`), generación estructurada JSON (`responseSchema`), temperatura 0.2 e inyección de Master Prompt biométrico.
- **Bases de Datos Nutricionales (Cascada Híbrida):**
  - **Primaria:** USDA FoodData Central API (`https://api.nal.usda.gov/fdc/v1/`) con normalización energética ($kJ \rightarrow kcal$ factor 4.184) y control de tasa (1.000 req/hr).
  - **Fallback:** Open Food Facts API v2 con timeout defensivo de 10s.
- **Motor Biométrico & Metabólico:** `MetabolicCalculator` implementando la ecuación clínica internacional **Mifflin-St Jeor** para TMB y TDEE según pasos diarios y actividad física.
- **Seguridad Criptográfica & BYOK:** `flutter_secure_storage` con `AndroidOptions(encryptedSharedPreferences: true)` en Android y Keychain en iOS para custodia local de las claves de API de Gemini y USDA.
- **Procesamiento y Compresión de Imágenes:** Paquete `image: ^4.5.2` con redimensionamiento defensivo a un límite máximo de 1024x1024 píxeles y codificación JPEG al 85% de calidad previa al envío al modelo de visión.
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
- Bloqueo de inicialización mediante `_initFuture` en el singleton `DatabaseService` contra arranques en frío simultáneos.

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

### 3.5. Monolito Modular (< 300 LoC por Pantalla)
- Ninguna pantalla o widget en `lib/` excede las 300 líneas de código:
  - `DashboardScreen`: 294 LoC
  - `MealDetailScreen`: 287 LoC
  - `MetricsScreen`: 198 LoC
  - `SettingsScreen`: 262 LoC
  - `UserProfileScreen`: 238 LoC
- Se extraen tarjetas, diálogos, barras y gráficos en widgets especializados (`widgets/common/`, `widgets/dashboard/`, `widgets/meal_detail/`, `widgets/settings/`, `widgets/profile/`, `widgets/metrics/`).

### 3.6. Seguridad Criptográfica y Firma Permanente de Producción
- Claves de Gemini y USDA almacenadas mediante `FlutterSecureStorage` en `EncryptedSharedPreferences` (Android) y Keychain (iOS).
- Clave Keystore permanente RSA 2048 con alias `foodtracker` y validez hasta 2056 inyectada en CI/CD mediante secretos de GitHub.
- Abstracciones detalladas documentadas en [[PRJ_App_Food_Tracker_abstractions|Abstracciones del Sistema y Arquitectura de Código]].
