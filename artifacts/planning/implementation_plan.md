---
tipo: implementation_plan
proyecto: App_Food_Tracker
iteracion: v1.4.2
estado: ejecutado
fecha: 2026-10-10
tags: [proyecto, planning, v1-4-2, ui-ux, widgets, layout-fixes, master-prompt, nothing-os-widgets]
---

# 🎯 Plan de Implementación v1.4.2: Pulido de UX/UI, Corrección de Inconsistencias, Rediseño del Master Prompt y Evolución de Widgets Nativos (Estilo Nothing OS)

> **Mesa de Control (Project-Planner):** Este documento establece el diagnóstico técnico pericial y el catálogo estructurado de mejoras para la iteración **v1.4.2** de **Victor Engineer - Food Tracker**, basado en el análisis cuadro a cuadro del video de grabación (`Screen_Recording_20261010_172029.mp4`), la inspección de la captura del prompt maestro (`Screenshot_20261010-171930.jpg`) y el estudio estético de los widgets de inspiración (`Screenshot_20261010-130545.jpg`, `130547.jpg`, `172154.jpg`).

---

## 🔬 1. Diagnóstico Forense y Causa Raíz de Problemas Reportados

### 1.1 Salto de Layout Oscilatorio en Diálogo de Exportación Clínica
* **Ubicación en Código:** [[PRJ_App_Food_Tracker_abstractions|clinical_export_dialog.dart]] (`lib/widgets/metrics/clinical_export_dialog.dart` L120-L142).
* **Mecanismo del Fallo (Análisis Cuadro a Cuadro):**
  * En dispositivos de 360dp de ancho lógico con padding de `AlertDialog` (40dp margin + 24dp padding por lado), el ancho libre interior es de solo **232dp**.
  * Los dos chips de formato (`CSV (Excel)` y `Clinical PDF`) reposan habitualmente en **DOS filas**.
  * Al pulsar un chip, el chip previamente seleccionado desvanece su checkmark (`-26dp`) antes de que el nuevo complete su animación. Durante ~100ms (fotogramas 98 a 100), el ancho combinado baja a ~243dp (umbral límite), provocando que el widget `Wrap` los agrupe momentáneamente en **UNA sola fila** (la altura colapsa de 133px a 113px).
  * Inmediatamente después, el nuevo chip despliega su checkmark (`+26dp`), superando los 232dp y **expulsando con un salto violento** al segundo chip de vuelta a una segunda fila.
  * El mismo comportamiento ocurre con el selector de rango temporal (7, 30, 90 días, Todo el tiempo) donde la altura oscila bruscamente de 159px a 111px.
* **Solución Arquitectónica:**
  * Reemplazar el `Wrap` de formato por un `Row` expandido (`Expanded`) con ancho 50%/50% y `showCheckmark: false`.
  * Estructurar el rango temporal en una cuadrícula determinista 2x2 fija (`Column` con dos `Row` y dos `Expanded` cada uno) con `showCheckmark: false`. Elimina el 100% de los saltos y oscilaciones dinámicas.

### 1.2 Flash Verde en Animaciones de Selección (Material 3 Token Leak)
* **Ubicación en Código:** `lib/services/theme_manager.dart` (L107-L114 y L179-L186).
* **Mecanismo del Fallo:**
  * En `AppTheme`, `ColorScheme.light` y `ColorScheme.dark` definen `secondary: Color(0xFF10B981)` (verde esmeralda), pero **no definen `secondaryContainer`**. En Material 3, `secondaryContainer` adopta por defecto el color de `secondary`.
  * Cuando un `ChoiceChip` recibe el estado presionado (`WidgetState.pressed`), Flutter aplica la capa de tinta y resaltado desde `secondaryContainer` si no hay un `chipTheme` explícito.
  * Al tocar, el fondo se tiñe inmediatamente en verde `#10B981` y luego transiciona a rojo `#DC2626` (color de selección).
  * **Alcance:** Este comportamiento afecta a 9 archivos con chips en toda la app.
* **Solución Arquitectónica:**
  * Configurar en `AppTheme` un `chipTheme: ChipThemeData(...)` global y definir explícitamente `secondaryContainer: const Color(0xFFDC2626).withValues(alpha: 0.15)`.

### 1.3 Fricción y Pérdida de Selección en el Prompt Maestro
* **Ubicación en Código:** `lib/widgets/profile/metabolic_summary_bento_card.dart` L208-L263 (embebido en `user_profile_screen.dart`).
* **Mecanismo del Fallo:**
  * El acordeón despliega un `TextFormField` restringido a solo 6 líneas de altura (`maxLines: 6`) para renderizar un prompt de más de 50 líneas estructurado en Markdown.
  * **Conflicto de Gestos (Gesture Arena Conflict):** El scroll del campo de texto compite contra el `ListView` de la pantalla de perfil. Cualquier movimiento diagonal cancela la selección de texto en Android.
  * **Falta de Acción 1-Tap:** No existe un botón para copiar el prompt completo al portapapeles.
* **Solución Arquitectónica:**
  * En la tarjeta Bento: Mostrar un resumen compacto con botón de **Copiado Rápido** directo (`Icons.copy_rounded`) y botón para abrir un **Modal Dedicado** (`Icons.open_in_full_rounded`).
  * En el Modal: Pestaña 1 (Markdown formateado de lectura clara) y Pestaña 2 (Editor a pantalla completa con herramientas "Copiar todo", "Restaurar" y "Guardar").

### 1.4 Inconsistencias Críticas en Home Widgets de Android (Detectadas en Auditoría)
* **Bug de Sobrescritura Histórica:** En `meal_controller.dart` (L139), `loadMeals()` dispara `_syncNativeWidgets()`. Si el usuario navega a un día pasado o futuro en el Dashboard, el widget de Android en la pantalla de inicio del teléfono se sobrescribe con las calorías de esa fecha en lugar de las de hoy.
* **Inversión de Colores:** En `android/app/src/main/res/values/colors.xml`, Proteína es azul (`#2563EB`) y Grasa es verde (`#059669`), exactamente al revés que en Flutter (`AppColors`).

---

## 📦 2. Catálogo de Mejoras Propuestas para v1.4.2

### 🔴 Bloque 1: Correcciones Mandatorias de Estabilidad y UX
1. **Fix de Layout en Exportación:** Cuadrícula 2x2 fija para rango de días y `Row` expandido para formatos, con `showCheckmark: false`.
2. **Erradicación Global del Flash Verde:** Definición de `chipTheme` y `secondaryContainer` en `AppTheme` (unifica el comportamiento en las 9 pantallas/widgets con chips).
3. **Corrección de Sincronización en Home Widget:** Forzar que `_syncNativeWidgets()` siempre consulte y persista métricas de `DateTime.now()`.
4. **Armonización Cromática de Macros:** Alinear `colors.xml` en Android para que coincida exactamente con la paleta de Flutter.

### 🟡 Bloque 2: Rediseño del Prompt Maestro
1. **Acción Rápida en Tarjeta Bento:** Botón de 1-tap para copiar el prompt completo con feedback háptico y SnackBar.
2. **Modal Desacoplado de Edición e Inspección:**
   - Vista previa renderizada en Markdown estructurado (resaltando calorías, IMC, TDEE y reglas clínicas).
   - Editor a pantalla completa desacoplado del scroll del perfil con botón de guardado y restauración a valores por defecto.

### 🟢 Bloque 3: Rediseño Estético de Widgets Nativos Existentes (Estilo Nothing OS)
1. **Widget Compacto 2x2 (Hero Ring Gauge):**
   - Calibre circular grueso de progreso calórico (inspirado en el widget `91%` de Nothing OS).
   - Calorías restantes en tipografía bold de gran escala en el centro (`1,420 kcal rest.`).
   - Botón inferior sutil de acceso rápido (`+ Registrar`).
2. **Widget Amplio 4x2 (Bento Dashboard):**
   - Lado izquierdo: Calibre circular de calorías.
   - Centro: Tres barras horizontales en cápsula con los colores exactos de Proteínas, Carbohidratos y Grasas con porcentaje.
   - Lado derecho: Píldoras táctiles con deep links a escáner de alimentos y código de barras.

### 🔵 Bloque 4: Nuevos Widgets Nativos Candidatos (A Elección del Usuario)
* **Candidato W1 - Matriz de Racha y Hábitos (Habit Dot Matrix 4x2 o 2x2):**
   - Inspirado directamente en el widget "YEAR PROGRESS" de las capturas de Nothing OS.
   - Indicador de racha activa (`🔥 7 DÍAS`) y cuadrícula de puntos: puntos iluminados representan días en los que se cumplió la meta calórica y puntos tenues días pendientes.
* **Candidato W2 - Hub de Acciones Rápidas (Quick Action Matrix 2x2 o 4x1):**
   - 4 disparadores táctiles Nothing OS con deep links directos:
     - 📸 **Cámara IA** (`foodtracker://scan_food`)
     - 🔍 **Código de Barras** (`foodtracker://scan_barcode`)
     - ⚡ **Comida Rápida** (`foodtracker://quick_meal`)
     - 💧 **Agua +250ml** (`foodtracker://add_water`, registra agua en background sin levantar la app completa).
* **Candidato W3 - Temporizador de Ayuno Intermitente y Fecha (2x2):**
   - Tipografía Nothing OS imponente para fecha (`10 SATURDAY OCT`).
   - Calibre circular de horas de ayuno transcurridas (`14h 20m`) y botón para romper o iniciar ayuno.

### 🟣 Bloque 5: Mejoras Complementarias de Experiencia Clínica
1. **Compartir Directo de Reportes (Share Intent):** Botón "Compartir" en `clinical_export_dialog.dart` tras exportar PDF o CSV para enviarlo directamente a WhatsApp, Drive o Correo vía `share_plus` / Android Intent nativo.
2. **Previsualización Rápida In-App de PDF:** Botón para abrir el PDF generado de inmediato con el visor del sistema operativo.
3. **Feedback Háptico Táctil Sistemático:** Respuesta táctil sutil (`HapticFeedback.selectionClick()`) al pulsar chips de formato, filtros y botones de acción.

---

## 🗺️ 3. Matriz de Fases de Ejecución

```text
Fase 1: Correcciones Mandatorias (Export layout, Chip Theme global, Sync bug, Color parity)
  │
  ├──> Fase 2: Rediseño Master Prompt (Bento card 1-tap copy, Modal Markdown/Editor)
  │
  ├──> Fase 3: Rediseño Estético de Widgets Nativos Existentes (Compacto 2x2 Ring, Amplio 4x2 Bento)
  │
  ├──> Fase 4: Nuevos Widgets Nativos Seleccionados (Acciones Rápidas / Racha Dot Matrix / Ayuno)
  │
  └──> Fase 5: Mejoras Complementarias (Compartir reporte, Previsualización PDF, Hápticos)
```

---

## ❓ 4. Puntos de Decisión para el Usuario

Antes de que los subagentes ejecuten el código de la versión **v1.4.2**, define:
1. **Nuevos Widgets:** ¿Deseas incorporar los 3 nuevos widgets propuestos (Acciones Rápidas, Matriz de Puntos de Racha, y Temporizador de Ayuno), o prefieres seleccionar solo alguno(s) de ellos?
Answer: Esta perfecto incorporar los 3 nuevos widgets, me encanta la idea.
2. **Formato del Master Prompt:** ¿Prefieres el modal como un **Bottom Sheet al 90%** con pestañas (Markdown + Editor), o como una **pantalla completa dedicada** en la navegación?
Answer: Sí, excelente idea de calidad de vida
3. **Mejoras Complementarias:** ¿Aprobamos incluir el botón de **Compartir Reporte (Share Intent)** y la **Previsualización de PDF** en el diálogo de exportación clínica?
Answer: Prefiero un boton sheet, aunque quizas al 90% sea mucho, que mantenga la misma coherencia o tamaño que el bottom sheet de AI model // Select Gemini Model
