---
tipo: implementation_plan
proyecto: App_Food_Tracker
iteracion: v0.2.0-alpha
estado: activo
fecha: 2026-09-09
tags: [proyecto, planning, mvp, yagni, local-first]
---

# 🎯 Plan de Implementación: Victor Engineer - Food Tracker (v0.2.0-alpha)

> **Mesa de Control (Project-Planner):** Este plan desglosa la construcción iterativa de "Victor Engineer - Food Tracker" siguiendo la metodología de Prototipado Evolutivo, el principio YAGNI (You Aren't Gonna Need It) y la descomposición atómica de responsabilidades entre subagentes especializados.

---

## 🎯 1. Objetivos de las Iteraciones v0.1.0 y v0.2.0-alpha

1. **Iteración v0.1.0 (Fundación MVP Local-First):**
   - Establecer la arquitectura SQLite con modo WAL y transacciones seguras.
   - Desarrollar la estimación volumétrica visual mediante IA (Gemini Vision) y BYOK seguro.
   - Construir el sistema de diseño Victor Engineer (Obsidian Zinc / Crisp Zinc) y las 3 pantallas maestras bajo el límite de 300 LoC.
   - Implementar escáner de despensa (Open Food Facts) y respaldo atómico JSON.
2. **Iteración v0.2.0-alpha (Precisión Clínica, Dinamismo Multimodal & Analíticas):**
   - Eliminar hardcoding de modelos de Gemini mediante introspección en vivo del endpoint de la API.
   - Integrar la base de datos oficial del USDA FoodData Central con fallback automático a Open Food Facts.
   - Implementar motor metabólico Mifflin-St Jeor con cálculo de TMB/TDEE y generación del Master Prompt para Gemini.
   - Actualizar el esquema SQLite a versión 2 con tabla indexada de peso (`weight_logs`).
   - Crear el panel de analíticas Bento Grid (`MetricsScreen`) con trazado de curvas Bézier a 60 FPS.
   - Configurar Keystore permanente RSA 2048 con validez hasta 2056 para distribución continua sin reinstalaciones.

---

## 🛠️ 2. Fases de Construcción Ejecutadas

### Fase 1: Fundaciones de Datos y Modelos Inmutables (v0.1.0) — [COMPLETADO]
- [x] Crear `ModelSanitizer` para clamp numérico, truncamiento de texto y deserialización defensiva.
- [x] Implementar modelos de datos con inmutabilidad y patrón Sentinel para eliminación explícita (`Meal`, `FoodItem`, `PantryItem`, `DailyGoals`).
- [x] Implementar `DatabaseService` sobre SQLite con `PRAGMA journal_mode = WAL;`, `PRAGMA synchronous = NORMAL;`, `PRAGMA foreign_keys = ON;`, e índices compuestos para fechas y tipos de comida.
- [x] Resolver condiciones de carrera en la inicialización asíncrona de la base de datos mediante caching de `_initFuture`.

### Fase 2: Servicios de Dominio, Seguridad & Visión por Computadora (v0.1.0) — [COMPLETADO]
- [x] Implementar `SecureStorageService` para almacenar la API Key de Gemini y las metas diarias de forma encriptada.
- [x] Implementar `ImageProcessingService` para redimensionamiento en memoria (máximo 1024x1024 px) y compresión JPEG 85%.
- [x] Diseñar el prompt clínico nutricional e implementar `GeminiVisionService` con esquemas estrictos de salida JSON (`responseSchema`) y reglas volumétricas.
- [x] Implementar `OpenFoodFactsService` con timeouts defensivos y mapeo resiliente de macronutrientes.
- [x] Implementar `BackupService` para exportación e importación transaccional en JSON.

### Fase 3: Controladores de Estado y Arquitectura UI Atómica (v0.1.0) — [COMPLETADO]
- [x] Crear `ThemeManager` reactivo con persistencia en `SharedPreferences` y soporte dinámico para Obsidian Zinc y Crisp Zinc.
- [x] Implementar `MealController` y `SettingsController` con `ChangeNotifier`.
- [x] Diseñar y construir widgets atómicos reutilizables (< 300 LoC cada uno) para Dashboard, Detalle de Comida y Ajustes.
- [x] Ensamblar las 3 pantallas maestras: `DashboardScreen`, `MealDetailScreen` y `SettingsScreen`.

### Fase 4: Descubrimiento Dinámico de Modelos Gemini (v0.2.0-alpha) — [COMPLETADO]
- [x] Crear modelo inmutable `GeminiModelInfo` con patrón Sentinel y parsing de nombres canónicos (`models/...`).
- [x] Implementar `GeminiModelService` con llamada en vivo a `GET /v1beta/models?key={API_KEY}` y filtrado estricto por capacidad `generateContent` y multimodalidad de imagen.
- [x] Crear `GeminiModelSelectorCard` en `SettingsScreen` con categorías semánticas (Recomendado, Pro, Balanceado).
- [x] Conectar la selección activa persistida en `SecureStorageService` directamente al flujo de análisis de comidas en `GeminiVisionService`.

### Fase 5: Integración USDA FoodData Central & Cascada Híbrida (v0.2.0-alpha) — [COMPLETADO]
- [x] Crear modelo `UsdaFoodItem` con parsing tolerante para esquemas `/foods/search` y `/food/{id}`.
- [x] Implementar `UsdaFoodDataService` con factor de conversión energética ($kJ \rightarrow kcal$ de 4.184), búsqueda por UPC/código de barras y limitador de tasa de 1.000 req/hr.
- [x] Crear `UsdaApiKeyCard` en `SettingsScreen` con almacenamiento seguro en hardware (`flutter_secure_storage`).
- [x] Diseñar `BarcodeLookupService` como orquestador de cascada: consulta primaria a USDA y fallback transparente a Open Food Facts.

### Fase 6: Motor Metabólico Mifflin-St Jeor & Onboarding (v0.2.0-alpha) — [COMPLETADO]
- [x] Crear modelo `UserProfile` con atributos biométricos (sexo, peso, altura, edad, nivel de actividad física, pasos diarios y objetivo nutricional).
- [x] Implementar `MetabolicCalculator` con fórmulas Mifflin-St Jeor para TMB y factores multiplicadores de TDEE.
- [x] Construir generador de **Master Prompt** que contextualiza las peticiones de visión IA de acuerdo a las características biométricas del usuario.
- [x] Crear pantalla modular `UserProfileScreen` (238 LoC) con widgets desacoplados (`BiometricInputsCard`, `ActivityGoalSelectorCard`, `MetabolicSummaryBentoCard`).
- [x] Sincronizar automáticamente el cálculo del TDEE con `DailyGoals` y persistencia atómica en SQLite.

### Fase 7: Persistencia SQLite v2 & Métricas Bento Grid (v0.2.0-alpha) — [COMPLETADO]
- [x] Actualizar esquema de base de datos a versión 2 con tabla `weight_logs` e índice B-Tree `idx_weight_logs_date`.
- [x] Migrar `BackupService` a versión 2 con serialización transaccional de registros de peso y perfil biométrico.
- [x] Implementar métodos en `DatabaseService` y `MealController` para consulta de peso por rangos (7, 30, 90 días).
- [x] Diseñar `WeightLineChartPainter` con trazado de curvas Bézier a 60 FPS, sombreado de gradiente, líneas meta y puntos interactivos.
- [x] Construir pantalla modular `MetricsScreen` (198 LoC) y widgets Bento: `WeightTrendBentoCard`, `CalorieComplianceBentoCard`, `MacroDistributionBentoCard`, `StreakComplianceBentoCard` y `QuickWeightEntryDialog`.

### Fase 8: Automatización de Pruebas, Quality Gate & CI/CD Permanente (v0.2.0-alpha) — [COMPLETADO]
- [x] Expandir suite de pruebas a 37 archivos con 237 pruebas unitarias, de integración y de widgets 100% en verde.
- [x] Generar clave de firma Keystore RSA 2048 permanente con validez hasta el año 2056 para Android.
- [x] Inyectar script de inicialización Gradle en CI para compatibilidad estricta con `compileSdk 34` y fijar versión segura de `sqflite`.
- [x] Publicar Release oficial en GitHub Actions: `v0.2.0-alpha` con APK de Android y ZIP de Windows x64.

---

## 🔮 3. Hoja de Ruta para Iteraciones Futuras (v0.3.0+)

1. **Sincronización Local P2P Segura:**
   - Replicación cifrada punto a punto entre dispositivos en la misma red local Wi-Fi sin servidores centrales.
2. **Exportación de Reportes Clínicos:**
   - Generación de informes en PDF y hojas de cálculo Excel con gráficos de composición corporal y adherencia para profesionales de la nutrición.
3. **Micro-Widgets de Escritorio y Notificaciones del Sistema:**
   - Widgets flotantes compactos para Windows y notificaciones enriquecidas en Android para registro de agua en un solo clic.

