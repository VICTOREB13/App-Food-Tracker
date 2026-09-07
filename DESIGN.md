---
tipo: design
proyecto: App_Food_Tracker
version: v1.0.0
estado: borrador
fecha: 2026-09-06
tags: [design-system, ui-ux, flutter, bento-grid, cal-ai, vitalis, speed-dial, obsidian-zinc, victor-engineer, local-first]
---

# 🎨 Especificación de Diseño: Victor Engineer Food Tracker (v1.0.0)

Documento maestro de interfaz de usuario (UI), experiencia de usuario (UX), sistema de tokens visuales y animaciones fluidas para la aplicación móvil **Victor Engineer Food Tracker**.

---

## 🏛️ 1. Filosofía de Diseño y Principios Rectores

1. **Local-First & Cero Latencia:** Toda la navegación, lectura de historial y visualización de macros es inmediata (< 16 ms / 60-120 fps) mediante SQLite en modo WAL. La conectividad solo se usa durante la llamada de visión a Gemini Flash o al consultar la API de códigos de barras.
2. **Claridad Visual Bento-Grid:** Densidad balanceada con tarjetas squircle (radio uniforme de 20 px), contraste suave y micro-indicadores visuales circulares (anillos de progreso).
3. **Animaciones con Física Orgánica:** Transiciones elásticas (`Curves.easeOutBack`) inspiradas en microinteracciones táctiles modernas, acompañadas de respuesta háptica (`HapticFeedback.lightImpact`).
4. **Identidad de Marca Victor Engineer:** Integración de los modos *Obsidian Zinc* (oscuro por defecto) y *Crisp Zinc* (claro), manteniendo el acento carmesí corporativo `#DC2626` complementado con una paleta funcional para macronutrientes.

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

## 📱 3. Anatomía y Estructura de Pantallas

### 3.1. Pantalla Principal: Dashboard Diario (`HomeScreen`)

1. **Header Superior:**
   * Marca: `VE FoodTracker` en tipografía `Outfit Bold`.
   * Badge de Racha (`🔥 3 días`) con animación de pulso sutil al registrar una comida.
2. **Carrusel Horizontal Semanal:**
   * Selector semanal estilo Cal AI. Días anteriores muestran estado de completitud.
   * Día seleccionado resaltado con fondo sólido (`#FFFFFF` en oscuro / `#09090B` en claro) y texto en alto contraste.
3. **Hero Card: Calorías Diarias (Bento Primario):**
   * Métrica en `Outfit Bold` 40 sp ("1,420 Calorías restantes" o "Consumidas").
   * Indicador circular de progreso (*Progress Ring*) dibujado con `CustomPainter`, con gradiente cónico suave.
4. **Bento Grid de Macronutrientes (3 Columnas):**
   * Tres tarjetas equilibradas para Proteína, Carbohidratos y Grasas.
   * Cada tarjeta incluye un mini-anillo circular con icono representativo (`🍗`, `🌾`, `🥑`) y gramaje restante/consumido.
5. **Feed Cronológico de Comidas:**
   * Desglose ordenado por `Desayuno`, `Almuerzo`, `Cena` y `Snacks`.
   * Tarjetas con miniatura de la foto, badge de verificación IA y resumen de macros.
   * **Estado vacío interactivo:** Ilustración minimalista de plato con mensaje *"Toca + para analizar tu primera comida"*.

---

### 3.2. Pantalla de Progreso y Analíticas (`AnalyticsScreen` — Estilo Vitalis)

1. **Tarjeta de Balance Semanal:**
   * Porcentaje de adherencia calórica y comparativa semanal (`+8% vs semana anterior`).
2. **Gráfico Sparkline de Ingesta Horaria:**
   * Curva suave que visualiza en qué momentos del día se concentró la ingesta calórica.
3. **Distribución Porcentual de Macros:**
   * Barras de progreso apiladas (Proteínas / Carbohidratos / Grasas) contra los ratios meta.
4. **Registro Rápido de Hidratación:**
   * Contador de vasos de agua (250 ml por toque) con animación de llenado líquido.

---

### 3.3. Pantalla de Perfil y Configuración (`ProfileScreen`)

1. **Ficha de Usuario:** Avatar circular con monograma `VE`, nombre completo, edad, peso y estatura.
2. **Ajuste de Metas Nutricionales:**
   * Cálculo de TDEE y meta diaria (Déficit, Mantenimiento, Volumen).
   * Distribución manual o guiada de macros.
3. **Gestión de IA (BYOK):**
   * Campo seguro (`flutter_secure_storage`) para la API Key de Gemini del usuario.
   * Selector de modelo (`gemini-2.5-flash`, `gemini-1.5-pro`).
   * Parámetro de estimación de aceite/grasa de cocción casera.
4. **Mantenimiento y Respaldos:**
   * Exportación e importación de la base de datos completa en formato JSON.

---

## ⚡ 4. Dock Flotante y Animación Speed-Dial

Este componente reproduce el comportamiento del menú de acciones dinámico:

### 4.1. Coreografía de la Animación

1. **Estado Normal (Cerrado):**
   * Barra flotante desacoplada de los bordes inferiores (`FloatingPillDock`) con iconos de `Inicio`, `Progreso`, `Despensa` y `Perfil`.
   * Botón circular flotante `+` adyacente a la derecha con color de acento `#DC2626`.
2. **Transición al Tocar `+`:**
   * El icono interior rota **45 grados** en sentido horario transformándose en una `✕`.
   * Duración: `280 ms` con curva `Curves.fastOutSlowIn`.
3. **Despliegue del Grid Elástico:**
   * Un panel squircle emerge hacia arriba desde la posición del botón.
   * Interpolación combinada de escala (`0.85 -> 1.0`) y traslación vertical (`+30 px -> 0 px`) con rebote elástico mediante `Curves.easeOutBack`.
   * Fondo atenuado con desenfoque de cristal (`BackdropFilter` con `sigma: 16` y tinte oscuro semitransparente).
4. **Acciones Disponibles en la Cuadrícula 2x3:**
   * **📸 Foto IA:** Lanza la cámara con guías de encuadre para analizar el plato con Gemini Flash.
   * **🖼️ Galería:** Selecciona una fotografía del carrete del dispositivo.
   * **🏷️ Código de Barras:** Escáner para productos envasados vía Open Food Facts API.
   * **✍️ Registro Manual:** Entrada manual con búsqueda en la despensa SQLite local.
   * **💧 Añadir Agua:** Registro inmediato de +250ml sin ventanas intermedias.
   * **⚡ Comida Rápida:** Asignación rápida de calorías estimadas sin desglose detallado.

---

## 💻 5. Estructura del Código en Flutter

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart            # Tokens Obsidian Zinc, Crisp Zinc y semántica de macros
│   │   ├── app_typography.dart        # Fuentes Outfit e Inter
│   │   └── app_theme.dart             # ThemeData reactivo
│   ├── network/
│   │   └── resilient_http_client.dart # Cliente HTTP con reintentos defensivos
│   └── utils/
│       └── image_compressor.dart      # Redimensión nativa a 1024px
├── data/
│   ├── database/
│   │   ├── app_database.dart          # SQLite con WAL Mode
│   │   └── tables/                    # Meals, Ingredients, DailyGoals
│   ├── services/
│   │   ├── gemini_vision_service.dart # Inferencia directa con google_generative_ai
│   │   ├── open_food_facts_service.dart # Consulta de código de barras
│   │   └── secure_storage_service.dart # Almacenamiento cifrado de API Keys
│   └── models/
│       ├── meal.dart                  # Modelo inmutable con Sentinel copyWith
│       └── macro_nutrients.dart
├── controllers/
│   ├── dashboard_controller.dart      # Estado de calorías y fechas
│   ├── meal_logging_controller.dart   # Pipeline Foto -> IA -> SQLite
│   ├── analytics_controller.dart      # Métricas y resúmenes semanales
│   └── settings_controller.dart       # API Keys y perfil biométrico
└── views/
    ├── home/
    │   ├── home_screen.dart
    │   └── widgets/
    │       ├── week_calendar_strip.dart
    │       ├── calories_hero_ring.dart
    │       ├── macro_bento_card.dart
    │       └── meal_log_tile.dart
    ├── analytics/
    │   └── analytics_screen.dart
    ├── profile/
    │   └── profile_screen.dart
    └── navigation/
        ├── floating_pill_dock.dart    # Dock inferior desacoplado
        └── expandable_speed_dial.dart # FAB rotativo con panel elástico
```

---

## 📋 6. Checklist de Validación Visual

- [ ] Cargar tipografías `GoogleFonts.outfit` e `GoogleFonts.inter` en `pubspec.yaml`.
- [ ] Implementar la clase semántica `AppColors` con soporte para temas oscuro y claro.
- [ ] Construir el widget `CaloriesHeroRing` con `CustomPainter` animado mediante `AnimationController`.
- [ ] Implementar la tarjeta bento `MacroBentoCard` con mini-indicador circular por cada macronutriente.
- [ ] Crear el selector horizontal semanal `WeekCalendarStrip` con desplazamiento automático centrado en el día activo.
- [ ] Construir `FloatingPillDock` y el menú `ExpandableSpeedDial` con animación elástica `Curves.easeOutBack`.
- [ ] Integrar compresión de imagen previa al envío al modelo de visión (máximo 1024x1024 px).
