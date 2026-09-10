---
tipo: implementation_plan
proyecto: App_Food_Tracker
iteracion: v1.0.1
estado: completado
fecha: 2026-09-10
tags: [proyecto, planning, v1-0-1, yagni, local-first, ui-ux, gemini-ai]
---

# 🎯 Plan de Implementación: Victor Engineer - Food Tracker (v1.0.1)

> **Mesa de Control (Project-Planner):** Este plan formaliza la construcción y cierre de la versión **v1.0.1**, enfocada en el inicio completamente limpio (Clean Slate Onboarding), la sincronización bidireccional total de macros (calorías + proteínas, carbohidratos y grasas), la auto-actualización del peso biométrico desde métricas, la deduplicación de gramos en ingredientes y la corrección del guardado transaccional de comidas.

---

## 🎯 1. Objetivos de la Iteración v0.4.0-alpha

1. **Detección Automática de Ingredientes IA (`DashboardScreen`):**
   - Asegurar que `Meal` se inicialice con `items: analysis.items` y `recalculateFromItems(analysis.items)` en `_handleAiPhotoScan`.
   - Garantizar que la lista de ingredientes identificados por la IA aparezca automáticamente en la lista de `MealDetailScreen` sin requerir reingreso manual.
2. **Re-análisis Inteligente con Correcciones de Usuario (`MealDetailScreen`):**
   - Implementar `_reanalyzeWithAi()`: si `_imagePath != null`, leer bytes, obtener la API key de `SecureStorageService` y llamar a `gemini.analyzeMealPhoto` inyectando el contexto de correcciones (plato, notas e ingredientes corregidos).
   - Actualizar reactivamente `_items`, macros y totales al recibir el resultado de Gemini.
3. **Botón Accesible de Re-análisis IA (`MealAiReanalyzeButton`):**
   - Diseñar componente accesible `OutlinedButton.icon` con `Icons.auto_awesome` y spinner reactivo cuando la comida tiene foto asociada.
4. **Rediseño Ergonómico de Macros (`FoodItemEditorDialog`):**
   - Desglosar la fila de 3 macros en dos filas confortables:
     - Fila 1: Proteína (`Expanded`) y Carbohidratos (`Expanded`) con espaciado amplio.
     - Fila 2: Grasas (ancho completo con indicador circular y sufijo 'g').
   - Incrementar fuente de etiquetas a 13px y padding cómodo (12px) para máxima legibilidad móvil.
5. **Modularización Arquitectónica (< 300 LoC):**
   - Mantener las pantallas maestras (`MealDetailScreen` a 298 LoC y `DashboardScreen` a 298 LoC) desacoplando lógica y componentes auxiliares (`meal_image_picker.dart`, `meal_detail_actions.dart`, `meal_save_button.dart`, `meal_ai_reanalyze_button.dart`).
6. **Incremento de Versión y Cierre:**
   - Elevar versión de `pubspec.yaml` a `0.4.0-alpha+1`.
   - Formalizar notas de versión en `changelog_v1.md` y sincronizar artefactos maestros.

---

## 🛠️ 2. Fases de Construcción para Subagentes

### Fase 1: Datos y Modelos (`Backend-Architect`)
1. **Constructor `Meal` con Soporte de `items`:**
   - Habilitar parámetro opcional `items` en el constructor de `Meal` con serialización automática a `aiBreakdownJson`.
2. **Sincronización en `DashboardScreen`:**
   - Inyectar `items: analysis.items` y encadenar `.recalculateFromItems(analysis.items)` en el scan fotográfico.

### Fase 2: Interfaz, Componentes y Modularización (`Frontend-UI`)
1. **Rediseño de `FoodItemEditorDialog`:**
   - Distribuir campos en 2 filas y tipografía a 13px.
2. **Motor de Re-análisis y Botón IA en `MealDetailScreen`:**
   - Desarrollar `_reanalyzeWithAi` y el widget `MealAiReanalyzeButton`.
3. **Desacoplamiento Modular:**
   - Extraer `pickAndSaveMealImage`, `confirmAndDeleteMeal`, `saveMealEntry` y `MealSaveButton` para garantizar pantallas < 300 LoC.

### Fase 3: Pruebas y Validación (`Systems-Auditor`)
1. Actualizar pruebas unitarias en `meal_model_test.dart` verificando la instanciación de `Meal(items: ...)` y la prevención de resurrección de items al vaciar.
2. Extender pruebas en `gemini_vision_service_test.dart` verificando claves multilingües (`ingredientes`, `alimentos`).
3. Crear pruebas de widgets en `meal_ai_reanalyze_button_test.dart` y `food_item_editor_dialog_test.dart`.
4. Asegurar ausencia de errores de linter y sintaxis.

### Fase 4: Despliegue y Release (`DevOps-Engineer`)
1. Actualizar `pubspec.yaml` a `0.4.0-alpha+1`.
2. Formalizar changelog y actualizar checklist de tareas.

### Fase 5: Optimización de CI y Firma Permanente de Release (`DevOps-Engineer`)
1. **Desactivación de CI en push a `main` (`.github/workflows/ci.yml`):**
   - Eliminar `push: branches: [main]` para evitar ejecuciones redundantes de CI en cada commit a la rama principal, manteniendo el Quality Gate unificado dentro del pipeline de release oficial (`release.yml`) y en `pull_request`.
2. **Firma Criptográfica Permanente de Release (Resolución de Conflicto de Paquete):**
   - Eliminar la dependencia en `~/.android/debug.keystore` (el cual AGP regeneraba con una clave efímera aleatoria en cada runner de Ubuntu debido a que el subject no era `CN=Android Debug`).
   - Inyectar la configuración formal `signingConfigs.release` en `android/app/build.gradle.kts` (y `build.gradle`), configurando `storeFile = file("release.keystore")`, `storeType = "PKCS12"`, `keyAlias = "androiddebugkey"`, `keyPassword = "android"`, `storePassword = "android"`, y asociándolo a `buildTypes.release.signingConfig = signingConfigs.getByName("release")`.
   - Incluir `lib/assets/keystore/release.keystore` en el control de versiones como fallback permanente para que el fingerprint SHA-256 (`3af69b6dc7c40fdfd42b27591d8b525b37bc30caf15d10650a5f4303583106b8`) sea 100% determinista e inmutable en todas las actualizaciones de la app.

### Fase 6: Flujo de Inicio y Onboarding Nutricional Personalizado (`Frontend-UI`)
1. **Detección de Primer Arranque (`lib/main.dart`):**
   - Comprobar en el arranque `await SecureStorageService.instance.hasCompletedOnboarding()`.
   - Si no se ha completado (`false`), desplegar `OnboardingScreen` como pantalla inicial.
   - Si ya se completó (`true`), dirigir de inmediato a `DashboardScreen`.
2. **Pantalla de Bienvenida y Asistente por Pasos (`lib/screens/onboarding_screen.dart`):**
   - Implementar flujo guiado mediante `PageView` interactivo con barra de progreso superior e indicadores de paso:
     - **Paso 1 (Bienvenida & Identidad):** Logo VE, mensaje introductorio y campo de Nombre del usuario.
     - **Paso 2 (Biometría Clínica):** Género Biológico (Mifflin-St Jeor), Edad (años), Estatura (cm), Peso Actual (kg).
     - **Paso 3 (Actividad & Pasos):** Nivel de actividad física (Sedentario a Muy Activo) y Pasos diarios estimados (6,000 a 12,000).
     - **Paso 4 (Objetivo & Plan Nutricional):** Meta corporal (Pérdida de Grasa, Mantenimiento, Ganancia Muscular) con cálculo instantáneo en vivo de BMR, TDEE, Presupuesto Calórico y distribución de Macros.
     - **Paso 5 (Confirmación y Comienzo):** Resumen de metas calculadas y botón principal de guardado.
3. **Persistencia y Transición:**
   - Invocar `MetabolicCalculator.calculateAndSaveProfile(...)`, persistir en SQLite, sincronizar `DailyGoals` en SecureStorage, marcar `hasCompletedOnboarding = true` y ejecutar `Navigator.of(context).pushReplacement` hacia `DashboardScreen`.
4. **Revisita desde Ajustes:**
   - Añadir en `SettingsScreen` la opción de reiniciar o volver a ejecutar el onboarding para reconfigurar el perfil si el usuario lo desea.


