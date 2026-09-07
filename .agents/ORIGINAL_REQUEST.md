# Original User Request

## 2026-09-07T16:04:57Z

# Teamwork Project Prompt

Construir la Fase 2 de **Victor Engineer - Food Tracker (NutriTracker Local-First)** incorporando capacidades avanzadas de IA multimodal dinámica, integración con USDA FoodData Central, onboarding con perfil metabólico personalizado (Master Prompt & TDEE) y panel de analíticas y métricas históricas.

Working directory: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker
Integrity mode: development

---

## Contexto y Estándares de Calidad
- **`sqlite-local-first-flutter`**: Persistencia 100% offline en SQLite WAL, inicialización memoizada (`_initFuture`), consultas con índices B-Tree, cero filtrado masivo en memoria RAM, patrón `_sentinel` en modelos inmutables y migraciones atómicas.
- **`flutter-production-engineering`**: Monolito modular (< 300 LoC por pantalla), widgets atómicos desacoplados en `lib/widgets/<dominio>/`, controladores gestionados en `StatefulWidget` (`initState`/`dispose`) sin fugas de memoria, `.withValues(alpha: ...)`, `initialValue` en Dropdowns, y paso limpio de Quality Gate en CI/CD.

---

## Requerimientos

### R1. Consulta Dinámica y Selector de Modelos de Google Gemini (Zero Hardcoding)
- Integrar consulta al endpoint oficial `GET https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}` para listar los modelos disponibles en la cuenta del usuario en tiempo real.
- Filtrar los modelos que soportan `generateContent` e inferencia multimodal (visión).
- Proveer un selector reactivo en la UI de Ajustes (`SettingsScreen`) mostrando los modelos disponibles, destacando recomendaciones predeterminadas (`gemini-2.5-flash`, `gemini-2.5-pro`, `gemini-2.0-flash` o `gemini-3.x-flash` según disponibilidad del servidor).
- Persistir la selección en almacenamiento seguro/preferencias para usar el modelo elegido en todas las solicitudes de visión.

### R2. Integración de Credenciales USDA FoodData Central
- Añadir campo de entrada seguro en `SettingsScreen` para la API Key de FoodData Central (`https://fdc.nal.usda.gov`).
- Almacenar la clave de forma segura mediante `FlutterSecureStorage` (`usda_api_key`).
- Crear servicio cliente `UsdaFoodDataService` con fallback automático a Open Food Facts para enriquecer la biblioteca de alimentos y códigos de barras.

### R3. Pantalla de Onboarding y Perfil Nutricional ("Master Prompt" & Metas TDEE)
- Crear pantalla interactiva de onboarding / perfil de usuario (`UserProfileScreen` / `OnboardingScreen`):
  - Datos biométricos: Nombre, edad, género biológico, altura (cm), peso actual (kg).
  - Nivel de actividad física: Pasos diarios estimados, frecuencia de entrenamiento (sedentario, ligero, moderado, muy activo).
  - Objetivo corporal: Pérdida de grasa (-500 kcal), mantenimiento, o ganancia de masa muscular (+300 kcal).
- Cálculo metabólico automático basado en el estándar internacional **Mifflin-St Jeor** para TMB (Tasa Metabólica Basal) multiplicado por factor de actividad (TDEE).
- Generación y almacenamiento del **Master Prompt** contextual que se inyecta en `GeminiVisionService` para que el modelo IA siempre conozca la composición, contexto biológico y metas del usuario en cada análisis fotográfico.
- Botón para aplicar y actualizar automáticamente las metas diarias (`DailyGoals`) a partir del cálculo biométrico.

### R4. Persistencia de Métricas y Registro Histórico de Peso
- Nueva tabla SQLite `weight_logs`:
  - `id TEXT PRIMARY KEY`, `date TEXT NOT NULL`, `weight REAL NOT NULL`, `notes TEXT`.
  - Índice en `date`.
- Integración en `DatabaseService` y `MealController` con transacciones seguras y soporte de consultas indexadas por rango de fechas (7 días, 30 días, 90 días).

### R5. Panel de Analíticas y Métricas de Progreso (`MetricsScreen` / `MetricsBentoCard`)
- Vista dedicada de métricas y gráficos Bento Grid:
  - Evolución del peso a lo largo del tiempo (gráfico de línea / barras).
  - Ingesta calórica diaria vs. meta de mantenimiento/déficit.
  - Distribución media de macronutrientes (Proteínas, Carbs, Grasas).
  - Cumplimiento de pasos y constancia de registro (racha activa).
- Respetar la identidad visual Victor Engineer (*Obsidian Zinc* `#09090B`, `#121215`, Carmesí `#DC2626`, tipografías Google Fonts `Outfit` e `Inter`).

---

## Criterios de Aceptación (Acceptance Criteria)

### A1. Dynamic Gemini Models
- [ ] La aplicación consulta la API de Google al ingresar la API Key y lista los modelos reales del servidor.
- [ ] Si la API de Google bloquea un modelo para nuevos usuarios (ej. 2.5 flash), el usuario puede seleccionar cualquier otro modelo activo sin cambiar una sola línea de código.
- [ ] Inferencia fotográfica usa exitosamente el modelo seleccionado.

### A2. USDA API Support
- [ ] La API Key de FoodData Central se valida y persiste con cifrado de hardware.
- [ ] Cliente HTTP tipado consulta `https://api.nal.usda.gov/fdc/v1/` con manejo de errores y timeouts.

### A3. Master Prompt & TDEE Calculation
- [ ] El cálculo de TMB y TDEE sigue rigurosamente la fórmula Mifflin-St Jeor según género, edad, peso, altura y factor de pasos/actividad.
- [ ] El Master Prompt se ensambla y se incluye en la instrucción de sistema de `GeminiVisionService`.
- [ ] Las metas diarias calculadas se sincronizan automáticamente con `DailyGoals`.

### A4. Architecture & Production Standards
- [ ] Ningún archivo nuevo o modificado en `lib/screens/` supera las 300 LoC.
- [ ] Todos los modelos implementan el patrón `_sentinel` para borrado con `null`.
- [ ] `flutter analyze` pasa con 0 errores y 0 advertencias.
- [ ] Suites de pruebas unitarias cubren el cálculo de TDEE, persistencia de peso y parseo de modelos de Google.
