---
tipo: changelog
proyecto: App_Food_Tracker
version: v1
estado: activo
fecha: 2026-09-10
tags: [proyecto, changelog, versiones]
---

# 📜 Registro de Cambios (Changelog) - Victor Engineer Food Tracker

Todos los cambios notables de este proyecto se documentarán en este archivo.
El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/) y este proyecto se adhiere a [Semantic Versioning](https://semver.org/lang/es/).

---

## [Unreleased]

---

## [1.0.2] - 2026-09-12

### Fixed
- **Desglose Anatómico Individual de Ingredientes y Fin de Duplicación del Plato:** Corrección estricta en las reglas del sistema de `GeminiVisionService` y en `reanalyzeMealWithAi`, prohibiendo explícitamente agrupar o duplicar el nombre del plato como un único ingrediente. Cada componente (arroz, legumbres, carnes, aguacate, grasa oculta) se desglosa individualmente en `items` con sus propios macronutrientes y calorías editables.
- **Eliminación del Peso Genérico de 200g:** Erradicación del valor comodín de 200g tanto en las instrucciones del modelo Gemini como en el fallback de cálculo volumétrico de `MealAnalysisResult`, implementando estimaciones realistas basadas en densidad calórica y volumen visible de porción.

### Added
- **Procesamiento Asíncrono No Bloqueante con Cola en SQLite (`AnalysisQueueService`):** Implementación de worker asíncrono con persistencia en tabla `analysis_queue` de SQLite. Al escanear fotos desde el Dashboard, la interfaz ya no se congela con diálogos modales sincrónicos; el análisis se despacha en segundo plano permitiendo navegar, cambiar fechas y registrar comidas libremente.
- **Anillo de Carga Animado Premium (`VeLoadingRing`):** Nuevo widget con `CustomPainter` inspirado en los bocetos (`anillo de carga.mp4` y `anillo de carga (1).mp4`), con pista circular de fondo, terminales redondeadas (`StrokeCap.round`), rotación continua suave y arco dinámico pulsante.
- **Banner de Estado de Análisis en Dashboard (`AnalysisProgressBanner`):** Componente reactivo en la pantalla principal que visualiza el progreso del análisis en tiempo real (preparación, consulta a Gemini, cubicaje de ingredientes y cálculo de macros) con el anillo animado `VeLoadingRing` y acceso directo al plato completado.
- **Retroalimentación Visual Progresiva en Detalle de Comida (`MealImageCard`):** Superposición animada con `VeLoadingRing` y descripción paso a paso durante el análisis y re-análisis con correcciones en `MealDetailScreen`.

---

## [1.0.1] - 2026-09-10

### Fixed
- **Error Crítico de Foreign Key al Guardar Comidas:** Corrección del orden transaccional en `DatabaseService.upsertMeal`, `insertMeal` y `updateMeal` insertando la tupla de `meals` antes de sus ingredientes `meal_items`, eliminando el fallo `DatabaseException(FOREIGN KEY constraint failed (code 787 SQLITE_CONSTRAINT_FOREIGNKEY))`.
- **Desbordamiento de Texto en Botón de Onboarding:** Rediseño responsivo en `OnboardingBottomNav` con `FittedBox(fit: BoxFit.scaleDown)` y texto conciso `"Guardar y Comenzar"`, evitando desbordamientos en pantallas móviles estrechas.
- **Sobrescritura Involuntaria de Metas Personalizadas:** Corrección en `UserProfileScreen._loadProfile` y `_onMealControllerChanged` para respetar los objetivos calóricos y de macronutrientes personalizados previamente guardados, impidiendo que se recalculen automáticamente con la fórmula teórica de Mifflin-St Jeor salvo modificación explícita de biometría.
- **Fluidez y Precisión en Entradas Numéricas Decimales:** Corrección de `didUpdateWidget` y soporte de separador decimal en `OnboardingBiometricsStep` y `BiometricInputsCard`, evitando saltos de cursor y permitiendo registrar pesos con alta precisión (ej. 74.85 kg) sin truncamiento.

### Added
- **Sincronización Automática Registro de Peso ⟷ Perfil Biométrico:** Vinculación reactiva en `MealController.recordWeight` y `MealController.addWeightLog` para actualizar automáticamente el peso del `UserProfile` en SQLite, recalcular BMR/TDEE y Master Prompt, y notificar a los oyentes tras persistir en base de datos para reflejar el cambio inmediato en tarjetas y campos biométricos sin reingreso manual.
- **Deduplicación Visual de Gramos en Lista de Ingredientes:** Eliminación de la píldora/badge duplicada al lado del nombre del ingrediente en `FoodItemsListCard`, consolidando la visualización de gramos de forma única y limpia en el chip de macronutrientes (`MacroIndicatorChip(label: 'Gramos')`, `AppColors.portion`) junto con Cal, P, C y G.
- **Onboarding de Pizarra Limpia (Clean Slate):** Inicialización de todos los campos de entrada de usuario (`nombre`, `edad`, `estatura`, `peso`) completamente vacíos con placeholders ilustrativos (`Ej: Carlos`, `Ej: 25`, `Ej: 175`, `Ej: 75`), eliminando datos pre-poblados personales y reforzando validaciones estrictas antes de avanzar o completar.

---

## [1.0.0] - 2026-09-10

### Added
- **Flujo de Inicio y Onboarding de Primer Uso (`OnboardingScreen`):** Asistente interactivo guiado de 4 pasos para nuevos usuarios:
  - *Paso 1 (Bienvenida & Identidad):* Presentación de privacidad local-first y campo de nombre del comensal.
  - *Paso 2 (Biometría Clínica):* Selector de género biológico (Mifflin-St Jeor), edad, estatura y peso.
  - *Paso 3 (Actividad & Movimiento):* Selector de nivel de actividad (1.2x a 1.725x) y chips de pasos diarios estimados (6,000 a 15,000).
  - *Paso 4 (Objetivo & Plan Metabólico):* Meta corporal con cálculo dinámico en tiempo real de BMR, TDEE, presupuesto calórico diario y desglose de macronutrientes (proteínas, carbohidratos, grasas).
- **Enrutamiento Inteligente de Primer Arranque:** Detección en `lib/main.dart` mediante `SecureStorageService.hasCompletedOnboarding()`, asegurando que la pantalla inicial aparezca una sola vez y dirija fluidamente al dashboard tras completarse.
- **Acceso a Reconfiguración en Ajustes:** Botón en `SettingsScreen` para relanzar o reconfigurar el perfil metabólico con el asistente en cualquier momento.
- **Visor de Inspección de Comida en Pantalla Completa (`FoodImageViewerScreen`):** Visualizador inmersivo con zoom táctil y pan (`InteractiveViewer`, 0.5x a 5.0x) accesible desde `MealImageCard`.
- **Nomenclatura Dinámica de Fotos:** Algoritmo en `ImageProcessingService` que renombra y sincroniza automáticamente las imágenes (`YYYY_MM_DD_{Type}_{Index}`) al cambiar el tipo de comida (Desayuno `B`, Almuerzo `L`, Cena `D`, Snack `S`).

### Changed
- **Sincronización Bidireccional Total (Metas Diarias ⟷ Resumen Metabólico):** Conexión reactiva entre `SettingsController.saveDailyGoals` (que actualiza `UserProfile`, `MasterPrompt` y SQLite) y `MetabolicCalculator.saveAndSynchronizeProfile` (que actualiza `SettingsController.dailyGoals` en memoria de inmediato).
- **Nuevo Icono Oficial del Sistema (Launcher Icon):** Diseño exterior exclusivo con plato fitness balanceado (filete sellado, mitades de aguacate con cavidad, tajadas de plátano y puré con hierbas) sobre squircle carmesí (`#C31723`) con canal alfa antialiased en todas las densidades mipmap de Android (`mdpi` a `xxxhdpi`).
- **Nombre Oficial en Android:** Actualizado el nombre de la app en el sistema Android a `"Food Tracker"`.
- **Consolidación de Assets:** Eliminación de la carpeta raíz `assets/` y centralización exclusiva en `lib/assets/` (`images/`, `keystore/`, `launcher_icons/`).
- **Cohesión Visual en Dashboard:** Eliminación de la línea divisoria gris redundante en `MealSectionCard` para una integración visual limpia.

### Security
- **Firma Permanente Inmutable de Android:** Inyección de `release.keystore` permanente en pipelines de CI/CD para compilaciones y actualizaciones continuas de APK sin conflicto de paquetes (SHA-256 inmutable `3af69b6d...`).
- **Custodia de Marca Personal:** Preservación estricta del logo de marca personal `VE` (`icon.svg`, `VeLogo`) en los componentes internos de la aplicación.


## [0.4.0-alpha] - 2026-09-10

### Added
- **Detección y Carga Automática de Ingredientes IA:** Sincronización en `DashboardScreen._handleAiPhotoScan` inicializando `Meal` con `items: analysis.items` y `recalculateFromItems`, garantizando que todos los ingredientes volumétricos detectados por Gemini Vision se carguen de inmediato en `MealDetailScreen`.
- **Re-análisis Inteligente con Correcciones (`_reanalyzeWithAi`):** Motor de ajuste nutricional en `MealDetailScreen` que re-envía la foto original a Gemini Vision incorporando correcciones del usuario (nombre, notas, lista de alimentos editados) para un cálculo volumétrico refinado.
- **Botón Accesible de Re-análisis IA (`MealAiReanalyzeButton`):** Componente interactivo `OutlinedButton.icon` con `Icons.auto_awesome` y feedback de progreso visual (`CircularProgressIndicator`) activo cuando hay foto del plato.
- **Constructor `Meal` con Inyección de `items`:** Soporte de primer orden para `Meal(items: ...)` con serialización robusta hacia `aiBreakdownJson` y totalizadores coherentes.
- **Módulos de UI y Lógica Desacoplados:** `MealAiReanalyzeButton`, `MealSaveButton`, `meal_image_picker` y `meal_detail_actions` para mantener las pantallas maestras estrictamente por debajo de 300 LoC.

### Changed
- **Rediseño Ergonómico de Macros en `FoodItemEditorDialog`:** Sustitución de la fila comprimida de 3 campos por una distribución en dos filas: Fila 1 (Proteína y Carbohidratos) y Fila 2 (Grasas a ancho completo).
- **Tipografía y Padding Móvil Confortable:** Etiquetas elevadas a 13px con padding vertical y horizontal holgado (12px) garantizando cumplimiento de ergonomía táctil en Android/iOS.
- **Optimización Modular de `MealDetailScreen`:** Descomposición modular estricta alcanzando 296 LoC, 100% alineada con las directrices de ingeniería Flutter (< 300 LoC).

### Fixed
- **Resurrección de Ingredientes Eliminados:** Corrección en `saveMealEntry` para asignar explícitamente `aiBreakdownJson: null` cuando el usuario vacía la lista de ingredientes, evitando que persistan datos previos.
- **Soporte de Claves Multilingües en Inferencia IA:** Extensión en `MealAnalysisResult.fromJsonString` para aceptar claves en español (`ingredientes` y `alimentos`) además de `items`, garantizando cero pérdida de alimentos identificados por Gemini.
- **Seguridad en Ciclo de Vida y Concurrencia:** Inyección de verificación `mounted` antes de emitir SnackBars de archivos no encontrados y bloqueos contra ejecuciones simultáneas en `_reanalyzeWithAi` y `_saveMeal`.

---

## [0.3.0-alpha] - 2026-09-09

### Added
- **Master Prompt Personalizable:** Editor interactivo en `MetabolicSummaryBentoCard` que permite al usuario modificar, guardar y restablecer las directrices inyectadas a Gemini Vision.
- **Selector de Modelos con Búsqueda y Filtros:** `ModelPickerBottomSheet` con buscador reactivo y chips semánticos (`Todos`, `Flash`, `Pro`).
- **Rango "Histórico" en Métricas:** Pestaña global para visualizar el progreso y peso desde el primer día de uso en `MetricsScreen`.
- **Historial de Pesajes con Notas:** Sección para inspeccionar pesajes históricos y notas adjuntas.
- **Vista Previa de Notas en Dashboard:** Indicador de notas en los tiles de comidas registradas (`MealSectionCard`).
- **Política de Depuración de Fotos:** Selector de retención (`Para siempre`, `90 días`, `30 días`, `15 días`) para liberar almacenamiento en disco sin alterar estadísticas de SQLite.
- **Macros en Comida Rápida:** Soporte para registrar proteína, carbohidratos y grasas opcionales en `QuickMealDialog` sin necesidad de foto.

### Changed
- **Enfoque Móvil Exclusivo y Retiro de Windows:** Eliminación completa de workflows y tareas de compilación para Windows Desktop (`build_windows.yml`, jobs y empaquetado ZIP en `release.yml`), enfocando la aplicación de forma nativa y exclusiva en dispositivos móviles (Android / iOS).
- **Filtrado Estricto de Modelos Multimodales Gemini:** Exclusión rigurosa de modelos no aptos para visión nutricional (`nano-banana`, `transcribe`, `omni`, `robotics`, `computer-use`, etc.), limitando el catálogo a `flash` y `pro` multimodales.
- **Directorio de Imágenes Estándar:** Migración del guardado de imágenes al directorio estándar `Pictures` del sistema operativo.
- **Diseño de Métricas Bento:** Reorganización de tarjetas `CalorieComplianceBentoCard`, `StreakComplianceBentoCard` y `MacroDistributionBentoCard` para prevenir truncamientos y colisiones de texto.
- **Justificación Tipográfica:** Alineación justificada en textos explicativos en tarjetas de ajustes y modales.

### Fixed
- **Persistencia Crítica de Comidas Analizadas con IA:** Implementación de `upsertMeal` en `DatabaseService` y `MealDetailScreen` resolviendo el bug donde comidas nuevas se intentaban actualizar en lugar de insertar.
- **Controlador de Edad en Perfil Metabólico:** Corrección del listener en `BiometricInputsCard` que reseteaba la edad involuntariamente al vaciar el campo para editar.
- **Mapeo de Errores Amigables de IA:** Traducción de excepciones crudas de red, tokens y cuota en mensajes claros y empáticos en español.

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
