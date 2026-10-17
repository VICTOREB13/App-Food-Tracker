---
tipo: implementation_plan
proyecto: App_Food_Tracker
iteracion: v1.5.0
estado: activo
fecha: 2026-10-13
tags: [proyecto, planning, v1-5-0, ui-ux, visual-design, bento-grid, flutter, microinteractions, design-evolution]
---

# 🎨 Plan de Implementación v1.5.0: Evolución Visual Integral, Patrones Bento Grid de Alta Gama y Microinteracciones Premium

> **Mesa de Control (Investigación & Planificación de Diseño):** Este documento consolida el análisis forense individual de los 26 recursos multimedia de la carpeta `Diseño` (imágenes y videos) y establece el plan maestro para transformar la interfaz y experiencia de usuario de **Victor Engineer - Food Tracker**, elevando la calidad estética, jerarquía visual y accesibilidad al nivel de productos de salud y estilo de vida de primer nivel.

---

## 🔬 1. Análisis Exhaustivo Individual de los Recursos de Referencia (`Diseño/`)

A continuación se detalla la disección técnica y formal de cada una de las 26 piezas encontradas en la carpeta de diseño:

### 📱 Grupo 1: Dashboards de Salud, Fitness y Productividad

#### 1. `@Caleb__Adeosun.jpg` — Bloomfit: Calm, Guided Fitness
* **Composición y Jerarquía:**
  * Cabecera con saludo empático ("Good afternoon, Tiana 💪") y avatar circular.
  * Selector de categoría superior en cápsula de fondo chartreuse/lima con pestañas tipo píldora (`Activity`, `Nutrition`, `Recovery`), donde la pestaña activa es una cápsula blanca con borde y sombra suave.
  * **Tarjeta Hero Chartreuse (`#E2F952`):** Alto contraste, estadística prominente de pasos ("5,430 / 10000"), badge circular negro con silueta de corredor, subtítulo motivacional y chip de tiempo activo ("Active time: 45 min").
  * **Bento Grid de Métricas (2 Columnas):** Tarjetas blancas con esquinas redondeadas de 20dp, iconos en círculo de fondo tonal ("Calories Burned 4,200 kcal", "Distance Covered 22.8 km").
  * **Acciones Rápidas con Affordance Diagonal:** Tarjetas con icono circular pastel, título, subtítulo explicativo y flecha externa diagonal `↗` en la esquina derecha ("Hydration", "Quick Workout").
  * **Barra de Navegación Flotante en Cápsula:** Barra oscura (`#111111`) con extremos completamente redondeados y pestaña activa en píldora amarilla ("Home").
* **Lección para el Tracker:** La tarjeta hero en color de acento energético, el Bento Grid simétrico de métricas con iconos tonales y la barra de navegación flotante son patrones directamente aplicables al Dashboard.

#### 2. `@andrewgurio (2).jpg` — Focusly: Dashboard y Calendario de Tareas
* **Composición y Jerarquía:**
  * Banner hero "En progreso" con suave degradado turquesa/menta, barra de progreso en cápsula gruesa y chip de estado.
  * Buscador integrado con bordes de píldora e icono de filtros a la derecha.
  * **Franja de Calendario Semanal:** Días representados en columna (letra + número); el día seleccionado se renderiza como una **cápsula vertical negra sólida con texto blanco y un punto verde indicador luminoso debajo**; el día actual no seleccionado mantiene un borde sutil.
  * **Tarjetas con Franja de Acento Lateral:** Tarjetas de tareas con una línea de color vertical en el borde izquierdo (naranja, verde, morado) que codifica la categoría sin saturar el interior de la tarjeta.
  * Barra de navegación inferior con iconos y puntos indicadores activos.
* **Lección para el Tracker:** `WeekCalendarStrip` debe adoptar el diseño de cápsula invertida con punto indicador, y las comidas en `MealSectionCard` deben incorporar franjas laterales de color (Desayuno = Ámbar, Almuerzo = Naranja, Cena = Índigo, Snacks = Esmeralda).

#### 3. `@nizamdesign (9).jpg` — Executive "Today" Dashboard
* **Composición y Jerarquía:**
  * Fondo con gradiente sutil superior (azul gélido desvaneciéndose hacia blanco), eliminando la monotonía de fondos planos.
  * Métrica hero "Money at stake / $56.9K" con punto indicador verde de balance.
  * Sección "Needs you" con tarjetas agrupadas que incluyen iconos en **cuadrados redondeados de tonos pastel** (verde menta, melocotón, rosa palo) con chevrons a la derecha.
  * Sección "Coming up" con fechas alineadas limpiamente en el margen derecho.
  * **Dock Flotante Translúcido:** 3 pestañas de texto e icono con un **FAB circular `+` independiente y separado a la derecha**.
* **Lección para el Tracker:** Gradiente atmosférico sutil en el fondo del Dashboard, iconos en cajas redondeadas pastel para los tipos de comidas y muelle de navegación flotante con botón circular para agregar comidas.

#### 4. `@nizamdesign (10).jpg` — Food Prep Kitchen Tracker ("Today")
* **Composición y Jerarquía:**
  * Cabecera con fecha y pronóstico de actividad.
  * **Tarjeta Hero de Progreso en Micro-Píldoras:** Muestra "18 of 47 items done" con una barra compuesta por una hilera de ~30 micro-cápsulas verticales (negro = completado, naranja = en progreso, gris claro = pendiente) con leyenda inferior.
  * Sección "Needs attention" con badge circular rojo de conteo `3` y tarjetas de alerta.
  * Listado "Up next" con **fotografías reales de platos en miniatura redondeada**, porción, horario y botones de acción rápida en píldora negra ("Start").
  * Barra flotante inferior con pestaña activa y botón flotante de cámara fotográfica.
* **Lección para el Tracker:** Directamente idéntico a las necesidades de `App-Food-Tracker`: listado de comidas con miniaturas fotográficas generosas (52x52dp), barra de micro-píldoras para registrar el cumplimiento de comidas del día y botón flotante de cámara para escaneo IA.

---

### 🥗 Grupo 2: Visualización de Comidas, Desglose de Alimentos e Ingredientes

#### 5. `@nizamdesign (11).jpg` — Categorized Food Prep List
* **Composición y Jerarquía:**
  * Conmutador segmentado en cápsula unificada: `To do 25`, `In progress 4` (píldora blanca activa), `Done 18`.
  * Filas de ingredientes y platos con fotografía real del alimento, título en peso seminegrita, gramaje/hora con separador de punto medio (`·`), estado en terracota ("late"), porcentaje de avance a la derecha y chevron.
* **Lección para el Tracker:** Rediseño del listado de ingredientes dentro de `FoodItemsListCard` y en `PantryScreen`, con tipografía limpia, fotos/iconos nítidos y badges de estado.

#### 6. `@nizamdesign (12).jpg` — Food Item Detail & Recipe Tracking
* **Composición y Jerarquía:**
  * Tarjeta de cabecera con fotografía del ingrediente a la izquierda, total preparado en tipografía grande ("32 of 38 kg"), barra de micro-píldoras y píldora de prioridad "• High".
  * Tarjeta de instrucciones/ingredientes estructurada como un **checklist interactivo**:
    * Paso completado: círculo con check negro.
    * Paso en curso: botón radio con punto interior y badge "• Now".
    * Paso pendiente: círculo con contorno tenue.
  * Banner de advertencia en fondo rojo salmón tenue con icono de alerta ("Yield below expected: You need 1.4 kg more...").
  * **Barra de Acciones Fija Inferior (Sticky Bottom Dock):** Botón secundario "⚠ Problem" y botón primario "+ Log batch" anclados al fondo de la pantalla.
* **Lección para el Tracker:** `MealDetailScreen` debe desacoplar el botón de guardado del scroll del formulario, anclándolo en una barra inferior fija con soporte para Safe Area, e incorporar banners tenues de advertencia nutricional (ej. "Excede el objetivo de grasas por 12g").

#### 7. `@nizamdesign (13).jpg` — Smart Suggestion Modal (Shortage & Rebalance)
* **Composición y Jerarquía:**
  * Modal Bottom Sheet con tirador de arrastre superior.
  * Cabecera con icono en caja redondeada de color ("Tomatoes are 12 kg short").
  * Tarjeta de alimento con fotografía, precio y cantidad.
  * **Tarjeta de Sugerencia Inteligente IA (Fondo Azul Pastel con Sparkles):** "Mise suggests 15 kg: One case covers the shortage and leaves 3 kg for Wednesday".
  * Botones de acción dual: primario oscuro ("Send request") y secundario en gris claro ("Adjust the prep plan instead").
* **Lección para el Tracker:** Blueprint exacto para `what_to_eat_sheet.dart` (Recomendación inteligente de comidas para cubrir el déficit de proteínas/calorías restante del día).

---

### 📊 Grupo 3: Métricas, Gráficos y Distribución de Macros

#### 8. `@nizamdesign (4).jpg` — Subscriptions & Segmented Macro Distribution
* **Composición y Jerarquía:**
  * Selector segmentado de 3 posiciones (`Active 16`, `Trials 2`, `Cancelled 4`) en riel unificado de cápsula.
  * **Barra Horizontal Multi-Segmentada Apilada:** Barra corrida donde cada color (coral, naranja, gris, durazno, verde) representa el porcentaje de cada grupo con puntos de leyenda.
  * Tarjeta de alerta con contorno sutil coral-rojo, icono circular y botón "Review".
  * Modal comparativo lado a lado con tarjeta explicativa "Por qué lo detectamos".
* **Lección para el Tracker:** La barra horizontal apilada multi-segmentada es infinitamente superior a 3 barras lineales independientes para comprender de un vistazo la proporción de calorías provenientes de Proteínas (verde), Carbohidratos (ámbar) y Grasas (azul).

#### 9. `@nizamdesign (5).jpg` — Vertical Capsule Bar Chart & Countdown Dials
* **Composición y Jerarquía:**
  * **Gráfico de Barras en Cápsulas Verticales:** Barras ubicadas dentro de contenedores de cápsula gris (`#F4F4F5`); las barras rellenas en coral-naranja ascienden con extremos redondeados, y sobre cada barra flota una **píldora negra con el valor exacto numérico** (`$84.93`, `$82.45`, `$34.16`).
  * Feed de hallazgos "What we noticed" con filas de tarjetas con iconos de flecha, etiqueta y pregunta.
  * **Calibre Circular con Marcas Radiales de Reloj (Ticks Ring):** Círculo exterior compuesto por marcas de reloj (ticks) y el tiempo restante en el centro (`26h`, `2d`).
* **Lección para el Tracker:**
  * El gráfico de cápsulas verticales con píldoras de valor flotantes es el patrón óptimo para el cumplimiento calórico de los 7 días de la semana en `calorie_compliance_bento_card.dart`.
  * El calibre circular con marcas de ticks es el diseño ideal para `fasting_window_bento_card.dart` durante el ayuno intermitente activo.

#### 10. `@nizamdesign (3).jpg` — 2x2 Bento Metric Grid
* **Composición y Jerarquía:**
  * Tarjeta hero de celebración en verde lima con pegatina circular índigo "Approved".
  * **Bento Grid 2x2:** 4 tarjetas blancas independientes con espaciado uniforme, números en tipografía display grande y etiquetas claras (Tasa, Mensualidad, Plazo, Vencimiento).
* **Lección para el Tracker:** Estructura limpia para métricas del perfil metabólico (TDEE, BMR, Déficit Calórico y Meta de Agua).

---

### ⚙️ Grupo 4: Pantalla de Ajustes y Formularios Agrupados

#### 11. `@HelalHossain09 (3).jpg` — Grouped iOS-Style Settings
* **Composición y Jerarquía:**
  * Tarjeta superior hero de suscripción con degradado suave y estrellas.
  * Tarjeta de uso mensual con calibre circular de porcentaje (`75% Monthly Usage`).
  * **Contenedores Agrupados con Divisores Hairline:** Un único contenedor blanco redondeado (20dp) que alberga múltiples opciones separadas por divisores de 0.5dp, con iconos en círculo de fondo gris suave, etiquetas principales, subtítulos explicativos, switches iOS y valores alineados a la derecha con chevron (`English (US) >`, `1.0.0 (24) >`).
* **Lección para el Tracker:** Reestructuración radical de `settings_screen.dart`, eliminando los 11 bloques gigantes independientes y agrupándolos en 2-3 contenedores limpios.

#### 12. `@nizamdesign (7).jpg` — Form Bottom Sheet Modal
* **Composición y Jerarquía:**
  * Modal bottom sheet con tirador de arrastre (drag handle), botón `✕` de cierre, campos agrupados en formato lista con chevrons y botón primario en píldora oscura.
* **Lección para el Tracker:** Estandarización de modales de edición de alimentos y peso.

---

### 🎙️ Grupo 5: Dictado por Voz y Microinteracciones Dynamic Island

#### 13. `@HelalHossain09 (2).jpg` — Wavelogs Audio Recording Modal
* **Composición y Jerarquía:**
  * Badge superior `• RECORDING` parpadeante.
  * Onda acústica orgánica animada con gradiente coral/naranja.
  * Cronómetro digital en números gigantes con espaciado monoespaciado (`00:32:07`).
  * Tarjeta de transcripción en tiempo real con etiqueta `LIVE TRANSCRIPTION`.
  * Botones inferiores duales en cápsula ("Pause" y "Stop").
* **Lección para el Tracker:** Transforma `voice_meal_recording_dialog.dart` en un diálogo/sheet de alta gama para dictado de comidas con Gemini.

#### 14. `STkg5_6kPb_EWeXG.mp4` — Dynamic Island Dot Matrix & Live Timer
* **Composición y Jerarquía:**
  * Cápsula flotante negra ultra-pulida (`#000000`).
  * A la izquierda: matriz de puntos LED rojos que oscilan en altura y brillo simulando frecuencias de voz.
  * A la derecha: cronómetro numérico digital de alta precisión (`0:00 -> 0:05`).
* **Lección para el Tracker:** Componente interactivo para:
  1. Indicador flotante tipo Dynamic Island para análisis de IA en curso en segundo plano (`analysis_progress_banner.dart`).
  2. Píldora de estado de ayuno activo en el Dashboard.
  3. Dictado por voz compacto.

---

### 🚀 Grupo 6: Onboarding, Pre-Permisos y Bucles de Hábito

#### 15. `@andrewgurio.jpg` — MindfulMe Welcome & Habit Reassurance
* **Composición y Jerarquía:**
  * Fondo marfil cálido (`#FAF8F5`). Tipografía display serif ("You just chose yourself").
  * Gráfico 3D de cuentas ensartadas (bead progress) que refuerza el progreso sin castigar omisiones.
  * Botones en píldora con flechas de acción directa.
* **Lección para el Tracker:** Copia empática y refuerzo positivo en la racha de comidas.

#### 16. `@andrewgurio (3).jpg` — Mindly Welcome & Feature Overview
* **Composición y Jerarquía:**
  * Ilustración zen superior. Lista de características con iconos circulares en colores pastel suaves (lila, menta, durazno, azul cielo).
* **Lección para el Tracker:** Iconografía tonal en el Onboarding de métricas metabólicas.

#### 17. `@baskeykoer (1)-(3).jpg` — Permissions Pre-Prompt
* **Composición y Jerarquía:**
  * Gráfico 3D de interruptor táctil saliendo de la pantalla con sombra profunda.
  * Tarjeta agrupada con 3 permisos explicados por su beneficio de usuario (Cámara, Notificaciones, Segundo plano) con checks verdes.
  * Botón ancho verde lima ("Continue").
* **Lección para el Tracker:** Pantalla previa de explicación de permisos de Cámara y Notificaciones en `onboarding_screen.dart` para maximizar la tasa de aceptación.

#### 18. `@jaydwivedi_.mp4` — 8-Step Animated Onboarding Flow
* **Composición y Jerarquía:**
  * Barra superior de progreso segmentada estilo Stories.
  * Rueda vertical de números deslizantes suaves para selección de edad (`17 -> 22`).
  * Contadores numéricos que ruedan suavemente en pantalla para estadísticas de impacto (`VeAnimatedCounter`).
  * Anillo radial animado de carga ("Connecting... 70%").
* **Lección para el Tracker:** Ruedas selectoras táctiles suaves para edad, peso y estatura en el Onboarding en lugar de campos de texto estándar.

#### 19. `@jaydwivedi_ (2).mp4` — Miko Delight Loop & Milestone Stamp
* **Composición y Jerarquía:**
  * Tarjetas táctiles tipo notas adhesivas.
  * Dial circular interactivo con marcas perimetrales para fijar hábitos diarios.
  * Pantalla de celebración y recompensa con sello postal coleccionable ("Your first stamp").
* **Lección para el Tracker:** Recompensa visual (sello/medalla) al registrar la primera comida del usuario o al alcanzar un hito de racha.

---

### 🛡️ Grupo 7: Estados, Auditoría y Flujos Transaccionales

#### 20-26. `@HelalHossain09 (1)`, `@nizamdesign (1), (2), (3), (6), (8)`
* **Composición y Jerarquía:**
  * Steppers verticales limpios para seguimiento de estado (`nizamdesign (6)`).
  * Tarjetas de insights de IA con fondo lavanda suave y etiqueta de confianza (`nizamdesign (8)`).
  * Botones de acción duales fijos al fondo.
* **Lección para el Tracker:** Presentación de análisis nutricional de Gemini como tarjetas de insight de alta confianza con fondo lavanda y sparkles.

---

## ⚖️ 2. Matriz de Decisión: Qué Incorporar vs Qué Mantener o Descartar

| Aspecto de Diseño | Referencia Visual | Decisión | Fundamento Técnico y UX |
| :--- | :--- | :--- | :--- |
| **Barra de Navegación Flotante en Cápsula** | `@Caleb__Adeosun`, `@HelalHossain09`, `@nizamdesign (9)` | ✅ **INCORPORAR** | Elimina la necesidad de estirar el pulgar hasta los iconos del AppBar superior para ir a Métricas o Ajustes. Ergonomía táctil moderna y aspecto de app premium. |
| **Sombras Difusas Multinivel y Esquinas 20dp** | Todas las capturas | ✅ **INCORPORAR** | La app actual es completamente plana con bordes de 1px. La adición de sombras difusas tenues (`blurRadius: 18`, opacidad 4-6%) aporta profundidad táctil sin recargar. |
| **Barra de Macros Multi-Segmentada Apilada** | `@nizamdesign (4)` | ✅ **INCORPORAR** | Permite visualizar la distribución de calorías entre Proteínas, Carbohidratos y Grasas en una sola barra proporcional apilada en lugar de 3 barras aisladas. |
| **Franja Semanal con Cápsula Invertida y Punto** | `@andrewgurio (2)` | ✅ **INCORPORAR** | Hace que el día seleccionado en `WeekCalendarStrip` resalte con nitidez absoluta y un indicador luminoso verde/primario debajo. |
| **Tarjetas de Comidas con Acento Lateral y Fotos 52dp** | `@andrewgurio (2)`, `@nizamdesign (10)` | ✅ **INCORPORAR** | Aumenta el tamaño de miniaturas de 44dp a 52dp con radio de 12dp y asigna una franja de acento en el borde izquierdo para cada momento del día (Desayuno, Almuerzo, Cena, Snack). |
| **Sticky Bottom Action Dock en Detalle de Comidas** | `@nizamdesign (12)` | ✅ **INCORPORAR** | Los botones de "Guardar Comida" y "Eliminar" se fijan en la parte inferior sobre el Safe Area, evitando que el usuario deba desplazarse al final de una lista larga de ingredientes para guardar. |
| **Ajustes en Contenedores Agrupados estilo iOS** | `@HelalHossain09 (3)` | ✅ **INCORPORAR** | Reduce los 11 bloques dispersos de `SettingsScreen` a 2-3 contenedores limpios con divisores y valores a la derecha con chevron. |
| **Modal de Grabación de Voz con Onda y Cronómetro** | `@HelalHossain09 (2)`, `STkg5_6kPb_EWeXG` | ✅ **INCORPORAR** | Sustituye el AlertDialog rígido por un Bottom Sheet interactivo con onda acústica animada, cronómetro tabular y visualización de transcripción en tiempo real. |
| **Dial Circular con Ticks para Ayuno Intermitente** | `@nizamdesign (5)` | ✅ **INCORPORAR** | Mejora sustancial en la visualización del tiempo de ayuno restante en `FastingWindowBentoCard`. |
| **Onboarding con Ruedas Numéricas y Barra de Stories** | `@jaydwivedi_.mp4`, `@baskeykoer (1)-(3)` | ✅ **INCORPORAR** | Reemplaza los campos de texto estándar de biometría por selectores táctiles suaves e incorpora una pre-solicitud de permisos con valor explicado. |
| **Fotografías de Modelos Fitness en Tarjetas Hero** | `@Caleb__Adeosun.jpg` | ❌ **DESCARTAR** | Desvía el foco de una app de nutrición local-first y añade peso innecesario a los assets sin aportar valor funcional al usuario promedio. |
| **Efectos Neumórficos Extremos (Bisel y Doble Sombra)** | Neumorfismo clásico | ❌ **DESCARTAR** | Problemas de contraste y accesibilidad bajo la luz del sol o en pantallas de bajo brillo. Se mantiene elevación limpia mediante bordes y sombras difusas. |
| **Alertas Calóricas Punitivas en Rojo Saturado** | Patrones tradicionales | ❌ **DESCARTAR** | El lenguaje visual debe ser motivacional y empático; los excesos calóricos se señalan con acentos cálidos terracota/ámbar sin tonos alarmistas. |

---

## 🛠️ 3. Fases de Ejecución Arquitectónica

```text
Fase 1: Sistema de Diseño & Tokens (ThemeManager, VeCard elevación, Paleta Pastel & Acentos)
  │
  ├──> Fase 2: Navegación & Shell Principal (Floating Bottom Dock, AppBar minimalista)
  │
  ├──> Fase 3: Dashboard & Resumen Calórico (Macro apilado, WeekCalendar Cápsula, Bento Cards)
  │
  ├──> Fase 4: Listado de Comidas & Detalle (Acentos laterales, Sticky Bottom Dock en MealDetail)
  │
  ├──> Fase 5: Ajustes Agrupados & Dictado por Voz de Alta Gama (Wavelogs style, Waveform)
  │
  └──> Fase 6: Onboarding Táctil & Pre-Permisos (Stories Progress, Ruedas Biométricas, Dial)
```

### 🎨 Fase 1: Tokens de Diseño y Profundidad Táctil (`ThemeManager` & `VeCard`)
1. **Elevación y Sombras Difusas:**
   * En `lib/widgets/common/ve_card.dart`, añadir parámetro de elevación táctil con `boxShadow` sutil:
     * Modo Claro: `BoxShadow(color: Color(0x06000000), blurRadius: 18, offset: Offset(0, 4))`.
     * Modo Oscuro: Borde sutil `Color(0xFF27272A)` y fondo `Color(0xFF121215)` con ligera luminancia superficial en hover/tap.
   * Aumentar `AppColors.cardRadius` de 20.0 a 22.0dp para suavizar contornos.
2. **Paleta de Acentos de Comidas y Badges:**
   * Desayuno: Ámbar cálido (`#F59E0B`).
   * Almuerzo: Naranja vibrante (`#F97316`).
   * Cena: Índigo profundo (`#6366F1`).
   * Snacks / Agua: Esmeralda (`#10B981`) / Cian agua (`#06B6D4`).
   * Fondos pastel de iconos: Versiones con opacidad 0.12 para contenedores redondeados de 12dp.

### 🧭 Fase 2: Navegación y Shell Principal (`FloatingBottomDock`)
1. **Construcción del Widget `VeFloatingBottomDock`:**
   * Componente flotante anclado sobre el Safe Area inferior.
   * Fondo translúcido con desenfoque de cristal (`BackdropFilter` sigma 16) o píldora sólida con sombra difusa profunda.
   * 4 destinos de navegación:
     * 🏠 **Hoy (Dashboard)**
     * 📈 **Métricas**
     * 🥫 **Despensa**
     * ⚙️ **Ajustes**
   * Pestaña activa renderizada como cápsula sólida con icono y etiqueta contrastada.
   * FAB circular flotante anclado a la derecha del dock para el escáner rápido / registro de comida.
2. **Reorganización del AppBar:**
   * Retirar los iconos de navegación redundantemente ubicados en el AppBar superior de `dashboard_screen.dart`.
   * Mantener únicamente el saludo empático, la fecha y el badge de racha (`StreakBadge`).

### 🍱 Fase 3: Dashboard y Resumen Diario (`DailyCalorieSummaryCard` & `WeekCalendarStrip`)
1. **Barra Multi-Segmentada de Macros en `DailyCalorieSummaryCard`:**
   * Integrar sobre o bajo las tarjetas de macros una barra horizontal apilada que refleje la proporción calórica real de Proteínas, Carbohidratos y Grasas.
   * Incorporar micro-píldoras de estado de cumplimiento para las comidas del día.
2. **Franja Semanal `WeekCalendarStrip` Rediseñada:**
   * Implementar la cápsula vertical oscura con texto blanco de alto contraste y punto indicador luminoso verde para el día seleccionado (patrón `Focusly`).
   * Micro-animación de transición entre días con `AnimatedContainer`.
3. **Calibre de Ayuno con Ticks Radiales en `FastingWindowBentoCard`:**
   * Dibujar el dial circular con marcas de reloj perimetrales inspiradas en `nizamdesign (5)`.

### 🍽️ Fase 4: Listado de Comidas y Detalle (`MealSectionCard` & `MealDetailScreen`)
1. **Rediseño de Ítems en `MealSectionCard`:**
   * Franja vertical de acento de 4dp en el borde izquierdo de la tarjeta para identificar el momento del día.
   * Miniatura de foto ampliada a 52x52dp con `BorderRadius.circular(12)`.
   * Formato de macros unificado: `420 kcal · 32g P · 45g C · 12g G`.
2. **Sticky Bottom Action Dock en `MealDetailScreen`:**
   * Desacoplar el botón de guardar comida del final del scroll.
   * Crear una barra fija inferior con botón secundario de eliminar/cancelar y botón primario de píldora para guardar.
   * Añadir banner de advertencia nutricional suave con icono informativo.

### ⚙️ Fase 5: Ajustes Agrupados y Grabación de Voz Interactiva
1. **Agrupación de Ajustes en `SettingsScreen`:**
   * Agrupar las opciones en 3 contenedores redondeados:
     * *Grupo 1: Conexión IA y Cuota:* Estado de API Key Gemini, modelo seleccionado, y medidor de cuota de solicitudes.
     * *Grupo 2: Preferencias y Metas:* Metas calóricas diarias, tema visual y selector de idioma.
     * *Grupo 3: Almacenamiento y Sistema:* Copias de seguridad locales, mantenimiento de base de datos y versión de la app.
2. **Rediseño de `VoiceMealRecordingDialog`:**
   * Transformar el modal en un Bottom Sheet con onda acústica orgánica animada, cronómetro tabular (`00:05`) y tarjeta de transcripción en vivo continua.

### 🌟 Fase 6: Onboarding Táctil y Pre-Permisos
1. **Barra de Progreso Segmentada tipo Stories:**
   * Reemplazar la barra lineal continua del AppBar por 4 segmentos horizontales animados.
2. **Paso de Pre-Permisos Contextual:**
   * Explicar el valor del acceso a la Cámara (para visión artificial de alimentos) y Notificaciones (para recordatorios de ayuno y comidas) antes de solicitar los permisos nativos del SO.
3. **Ruedas Selectoras Biométricas y Dial de Metas:**
   * Selectores suaves para edad, peso y estatura, eliminando la fricción de escribir números con el teclado virtual.

---

## 📋 4. Asignación de Roles por Agente Especializado

* **`Frontend-UI` (Tier Flash):**
  * Maquetación de `VeFloatingBottomDock` y su integración en `DashboardScreen`.
  * Rediseño de `WeekCalendarStrip` con cápsula invertida y punto indicador.
  * Implementación de la barra multi-segmentada apilada en `DailyCalorieSummaryCard`.
  * Rediseño de tarjetas de comidas en `MealSectionCard` y Sticky Action Dock en `MealDetailScreen`.
  * Reestructuración agrupada de `SettingsScreen`.
  * Modernización de `VoiceMealRecordingDialog` con onda acústica y cronómetro.
  * Pulido del flujo de `OnboardingScreen`.
* **`Backend-Architect` (Tier Flash):**
  * Asegurar que los modelos de cálculo de proporciones de macros (porcentajes calóricos de P/C/G) se expongan de forma reactiva y limpia en `MealController`.
* **`Systems-Auditor` (Tier Flash):**
  * Ejecutar suite de pruebas unitarias y de widgets (`flutter test`).
  * Verificar cumplimiento de contrastes WCAG AA en modo claro y modo oscuro.
  * Auditar que no existan desbordamientos de renderizado (Overflow RenderFlex) en pantallas pequeñas (360dp).
