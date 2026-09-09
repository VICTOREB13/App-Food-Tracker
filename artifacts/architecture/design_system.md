---
tipo: design_system
proyecto: App_Food_Tracker
version: v0.2.0-alpha
estado: activo
fecha: 2026-09-09
tags: [proyecto, design-system, ui-ux, bento-grid, tokens]
---

# 🎨 Especificación de Diseño: Victor Engineer - Food Tracker (v0.2.0-alpha)

Documento maestro de interfaz de usuario (UI), experiencia de usuario (UX), sistema de tokens visuales y animaciones fluidas para la aplicación móvil y de escritorio **Victor Engineer - Food Tracker**.

---

## 🏛️ 1. Filosofía de Diseño y Principios Rectores

1. **Local-First & Cero Latencia:** Toda la navegación, lectura de historial y visualización de macros es inmediata (< 16 ms / 60-120 fps) mediante SQLite en modo WAL. La conectividad solo se usa durante la llamada de visión a Gemini Flash o al consultar la API de códigos de barras.
2. **Claridad Visual Bento-Grid:** Densidad balanceada con tarjetas squircle (radio uniforme de 20 px), contraste suave y micro-indicadores visuales circulares (anillos de progreso).
3. **Animaciones con Física Orgánica:** Transiciones elásticas (`Curves.easeOutBack`) inspiradas en microinteracciones táctiles modernas, acompañadas de respuesta háptica (`HapticFeedback.lightImpact`).
4. **Identidad de Marca Victor Engineer:** Integración de los modos *Obsidian Zinc* (oscuro por defecto) y *Crisp Zinc* (claro), manteniendo el acento carmesí corporativo `#DC2626` complementado con una paleta funcional para macronutrientes.
5. **Cero Deprecaciones y API Moderna:** Migración absoluta de `.withOpacity(...)` a `.withValues(alpha: ...)`.

---

## 🎨 2. Sistema de Tokens y Fundamentos Visuales

### 2.1. Paleta de Colores

#### Tema Oscuro — Obsidian Zinc (Predeterminado)
* **Background Primario:** `#09090B` (Zinc 950 ultraprofundo)
* **Superficie / Tarjetas (Card Surface):** `#121215` (Zinc 900 personalizado / Elevación 1)
* **Superficie Elevada (Modals / Dock / Popups):** `#18181B` (Elevación 2)
* **Bordes y Divisores:** `#27272A` (Zinc 800, 1px con opacidad sutil)
* **Texto Principal:** `#FAFAFA` (Zinc 50)
* **Texto Secundario / Muted:** `#A1A1AA` (Zinc 400)
* **Acento Primario (Victor Engineer):** `#DC2626` (Carmesí)
* **Acento Hover / Activo:** `#EF4444` (Rojo 500)

#### Tema Claro — Crisp Zinc
* **Background Primario:** `#FAFAFA` (Zinc 50)
* **Superficie / Tarjetas (Card Surface):** `#FFFFFF` (Blanco puro con sombra difusa sutil)
* **Superficie Elevada:** `#F4F4F5` (Zinc 100)
* **Bordes y Divisores:** `#E4E4E7` (Zinc 200)
* **Texto Principal:** `#09090B` (Zinc 950)
* **Texto Secundario / Muted:** `#71717A` (Zinc 500)
* **Acento Primario (Victor Engineer):** `#DC2626`

#### Paleta Semántica de Macronutrientes y Salud
* **Calorías / Energía (Flame):** `#F97316` (Naranja fuego) / Contenedor: `#F973161A`
* **Proteína (Chicken / Muscle):** `#EF4444` (Rojo coral suave) / Contenedor: `#EF44441A`
* **Carbohidratos (Wheat / Grain):** `#EAB308` (Ámbar dorado) / Contenedor: `#EAB3081A`
* **Grasas (Avocado / Lipid):** `#3B82F6` (Azul zafiro) / Contenedor: `#3B82F61A`
* **Hidratación (Agua):** `#06B6D4` (Cian eléctrico)
* **Meta Cumplida / Estado Positivo:** `#10B981` (Verde esmeralda)

---

### 2.2. Tipografía (Google Fonts)

* **Display & Métricas Numéricas (`Outfit`):**
  * Números calóricos principales: `Outfit`, Bold (700), 38–44 sp, `tabularFigures`.
  * Títulos de sección: `Outfit`, SemiBold (600), 18–22 sp.
  * Etiquetas de macros: `Outfit`, Medium (500), 14–16 sp.
* **Cuerpo de Texto y Datos (`Inter`):**
  * Descripciones de platos, notas, ingredientes: `Inter`, Regular (400), 13–15 sp.
  * Botones y píldoras de navegación: `Inter`, Medium (500), 12–14 sp.
  * Badges, fechas y micro-textos: `Inter`, Regular/Medium, 10–11 sp.

---

### 2.3. Espaciado, Radios y Elevaciones

* **Radio de Tarjetas (Bento Cards):** `20.0 px`.
* **Radio de Píldoras / Floating Dock:** `32.0 px` (Cápsula continua).
* **Radio de Icon Containers:** `14.0 px`.
* **Padding de Pantalla:** Horizontal `16.0 px`, Vertical `12.0 px`.
* **Separación entre Tarjetas (Grid Gap):** `12.0 px`.
* **Bordes:** 1px sólido `#27272A` en tema oscuro; `#E4E4E7` en tema claro.

---

## 📱 3. Catálogo de Pantallas Maestras (< 300 LoC)

### 3.1. Dashboard Principal (`DashboardScreen` - 294 LoC)
- **Header Superior (`VeAppBar`):** Marca `VE FoodTracker`, racha de días, accesos directos a `MetricsScreen`, `UserProfileScreen` y `SettingsScreen`.
- **Selector Semanal (`WeekCalendarStrip`):** Días del calendario centrados en el día activo con indicadores de cumplimiento calórico.
- **Tarjeta Hero de Calorías (`CaloriesHeroRing` & `DailyCalorieSummaryCard`):** Anillo de progreso animado con calorías restantes y consumidas.
- **Bento de Macronutrientes (`MacroBentoCard`):** Desglose equilibrado en tres columnas para Proteínas, Carbohidratos y Grasas.
- **Feed de Comidas por Categoría (`MealSectionCard`):** Secciones organizadas para Desayuno, Almuerzo, Cena y Snacks.
- **Speed-Dial FAB (`DashboardFabMenu`):** Menú 2x3 con física elástica `Curves.easeOutBack`.

### 3.2. Detalle y Edición de Comida (`MealDetailScreen` - 287 LoC)
- **Tarjeta de Imagen (`MealImageCard`):** Miniatura del plato o selector de cámara/galería.
- **Fila de Macros (`MealMacroChipsRow`):** Chips de macronutrientes interactivos.
- **Formulario de Comida (`MealFormFields`):** Selector de categoría, nombre y notas.
- **Lista de Ingredientes (`FoodItemsListCard`):** Edición atómica y diálogo `FoodItemEditorDialog`.

### 3.3. Configuración y Ajustes (`SettingsScreen` - 262 LoC)
- **Gestión de Modelos Gemini (`GeminiModelSelectorCard`):** Selector reactivo con introspección dinámica de la API.
- **Credenciales USDA (`UsdaApiKeyCard`):** Entrada cifrada de API Key para USDA FoodData Central.
- **Clave API Gemini (`ApiKeyInputCard`):** Almacenamiento seguro BYOK.
- **Metas Diarias (`DailyGoalsCard`):** Ajuste de calorías y macronutrientes.
- **Mantenimiento y Respaldo (`DatabaseMaintenanceCard`, `BackupCard`):** Operaciones de `VACUUM` y respaldo JSON v2.

### 3.4. Perfil Nutricional & Onboarding (`UserProfileScreen` - 238 LoC)
- **Entrada Biométrica (`BiometricInputsCard`):** Peso, altura, edad y sexo biológico.
- **Actividad y Pasos (`ActivityGoalSelectorCard`):** Multiplicadores de estilo de vida y pasos diarios.
- **Resumen Metabólico (`MetabolicSummaryBentoCard`):** Cálculo instantáneo de TMB y TDEE mediante fórmula Mifflin-St Jeor.

### 3.5. Métricas y Analíticas (`MetricsScreen` - 198 LoC)
- **Tendencia de Peso (`WeightTrendBentoCard`):** Gráfico interactivo a 60 FPS dibujado con `WeightLineChartPainter` (curvas Bézier, gradiente de área y líneas meta).
- **Adherencia Calórica (`CalorieComplianceBentoCard`):** Gráficos de barras y ratios de cumplimiento.
- **Distribución de Macros (`MacroDistributionBentoCard`):** Porcentajes relativos vs metas del usuario.
- **Racha y Consistencia (`StreakComplianceBentoCard`):** Historial semanal de registro continuo.
- **Registro Rápido de Peso (`QuickWeightEntryDialog`):** Modal con validación numérica y protección anti-NaN.

---

## ⚡ 4. Speed-Dial Flotante y Coreografía de Microinteracciones

1. **Estado Cerrado:** Botón circular con icono `+` y acento carmesí `#DC2626`.
2. **Apertura:** Rotación de 45° a cruz `✕` en 280 ms con `Curves.fastOutSlowIn`.
3. **Despliegue del Grid:** Panel squircle con interpolación combinada de escala (`0.85 -> 1.0`) y rebote elástico `Curves.easeOutBack`.
4. **Acciones 2x3:**
   - 📸 **Foto IA:** Cámara con guías de encuadre para análisis con Gemini.
   - 🖼️ **Galería:** Selección de imagen del carrete.
   - 🏷️ **Código de Barras:** Escáner con búsqueda en cascada USDA + Open Food Facts.
   - ✍️ **Registro Manual:** Inserción guiada con autocompletado en despensa local.
   - 💧 **+250ml Agua:** Incremento instantáneo sin modales intermedios.
   - ⚡ **Comida Rápida:** Diálogo express de calorías estimadas.

---

## 💻 5. Estructura Real del Código en Flutter

```
lib/
├── controllers/
│   ├── meal_controller.dart
│   └── settings_controller.dart
├── models/
│   ├── daily_goals.dart
│   ├── food_item.dart
│   ├── gemini_model_info.dart
│   ├── meal.dart
│   ├── model_sanitizer.dart
│   ├── pantry_item.dart
│   ├── usda_food_item.dart
│   ├── user_profile.dart
│   └── weight_log.dart
├── screens/
│   ├── dashboard_screen.dart          # 294 LoC
│   ├── meal_detail_screen.dart        # 287 LoC
│   ├── metrics_screen.dart            # 198 LoC
│   ├── settings_screen.dart           # 262 LoC
│   └── user_profile_screen.dart       # 238 LoC
├── services/
│   ├── backup_service.dart
│   ├── barcode_lookup_service.dart
│   ├── database_service.dart
│   ├── gemini_model_service.dart
│   ├── gemini_vision_service.dart
│   ├── image_processing_service.dart
│   ├── metabolic_calculator.dart
│   ├── open_food_facts_service.dart
│   ├── secure_storage_service.dart
│   ├── theme_manager.dart
│   └── usda_food_data_service.dart
└── widgets/
    ├── common/                        # VeAppBar, VeCard, VeLogo, etc.
    ├── dashboard/                     # CaloriesHeroRing, Bento, FAB Menu, etc.
    ├── meal_detail/                   # ImageCard, ChipsRow, FormFields, etc.
    ├── metrics/                       # WeightTrendBento, WeightLineChartPainter, etc.
    ├── profile/                       # BiometricInputsCard, MetabolicSummary, etc.
    └── settings/                      # GeminiModelSelector, UsdaApiKeyCard, etc.
```

---

## 📋 6. Checklist de Validación Visual Certificado

- [x] Carga de tipografías `Outfit` e `Inter` en `pubspec.yaml` mediante `google_fonts`.
- [x] Implementación semántica de temas `ThemeManager` (*Obsidian Zinc* y *Crisp Zinc*).
- [x] Sustitución del 100% de llamadas `.withOpacity` por `.withValues(alpha: ...)`.
- [x] Renderizado de `CaloriesHeroRing` animado y `MacroBentoCard` de tres columnas.
- [x] Selector horizontal semanal `WeekCalendarStrip` con centrado automático.
- [x] `DashboardFabMenu` con física elástica `Curves.easeOutBack`.
- [x] Trazador vectorial acelerado por hardware `WeightLineChartPainter` a 60 FPS.
- [x] Descomposición de las 5 pantallas maestras cumpliendo la directriz < 300 LoC.

