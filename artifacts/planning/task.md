---
tipo: task_list
proyecto: App_Food_Tracker
iteracion: v0.4.0-alpha
estado: activo
fecha: 2026-09-10
tags: [proyecto, tasks, checklist, v7-teamwork, v0-4-0-alpha]
---

# 📋 Checklist Maestro de Tareas de Agentes (v0.4.0-alpha)

> **Mesa de Control (Project-Planner):** Este checklist asigna y verifica los entregables atómicos de la iteración v0.4.0-alpha. Cada tarea completada se marca con `[x]`.

---

## 🧭 1. Project-Planner (Master Tech Lead)
- [x] (Project-Planner) Identificar y priorizar requerimientos finales para el cierre de la versión 0.4.0-alpha.
- [x] (Project-Planner) Actualizar visión de proyecto en `artifacts/project_overview.md` a v0.4.0-alpha.
- [x] (Project-Planner) Formalizar el plan de implementación en `artifacts/planning/implementation_plan.md`.
- [x] (Project-Planner) Mantener actualizado el checklist maestro en `artifacts/planning/task.md`.
- [x] (Project-Planner) Registrar los cambios en `artifacts/planning/changelog_v1.md` bajo `[0.4.0-alpha] - 2026-09-10`.

---

## 🗄️ 2. Backend-Architect (Datos, Modelos y Lógica)
- [x] (Backend-Architect) Extender el constructor del modelo `Meal` (`lib/models/meal.dart`) para aceptar parámetro opcional `items: List<FoodItem>?`, codificando automáticamente `aiBreakdownJson`.
- [x] (Backend-Architect) Sincronizar `DashboardScreen._handleAiPhotoScan` pasando `items: analysis.items` y encadenando `.recalculateFromItems(analysis.items)` para poblar automáticamente los ingredientes analizados en `MealDetailScreen`.
- [x] (Backend-Architect) Añadir prueba unitaria en `test/models/meal_model_test.dart` verificando que `Meal(items: ...)` preserve y exponga fielmente los alimentos.
- [x] (Backend-Architect) Implementar sincronización bidireccional reactiva entre Metas Nutricionales Diarias (`SettingsController.saveDailyGoals`) y Perfil / Resumen Metabólico (`MetabolicCalculator.saveAndSynchronizeProfile`).

---

## 🎨 3. Frontend-UI (Diseño, Ergonomía y Pantallas)
- [x] (Frontend-UI) Rediseñar la distribución de macronutrientes en `FoodItemEditorDialog` (`lib/widgets/meal_detail/food_item_editor_dialog.dart`): Fila 1 para Proteína y Carbohidratos, Fila 2 para Grasas a ancho completo.
- [x] (Frontend-UI) Mejorar la tipografía (13px) y espaciado/padding confortable (12px) en `FoodItemEditorDialog` para lectura y manipulación táctil en móviles.
- [x] (Frontend-UI) Implementar `_reanalyzeWithAi()` en `MealDetailScreen` para re-analizar la foto original con Gemini Vision incorporando nombre, notas e ingredientes corregidos.
- [x] (Frontend-UI) Diseñar componente accesible `MealAiReanalyzeButton` (`lib/widgets/meal_detail/meal_ai_reanalyze_button.dart`) con icono `auto_awesome` y estado reactivo de carga.
- [x] (Frontend-UI) Crear componente `MealSaveButton` (`lib/widgets/meal_detail/meal_save_button.dart`) para desacoplar el botón de guardado.
- [x] (Frontend-UI) Crear helper modular `pickAndSaveMealImage` (`lib/widgets/meal_detail/meal_image_picker.dart`) y acciones modulares `confirmAndDeleteMeal` y `saveMealEntry` (`lib/widgets/meal_detail/meal_detail_actions.dart`).
- [x] (Frontend-UI) Mantener `MealDetailScreen` (296 LoC) y `DashboardScreen` (299 LoC) estrictamente por debajo del umbral de 300 LoC.

---

## 🧪 4. Systems-Auditor (Testing y Quality Gate)
- [x] (Systems-Auditor) Crear prueba de widget `test/widgets/meal_ai_reanalyze_button_test.dart` para validar renderizado, callbacks y estado loading.
- [x] (Systems-Auditor) Crear prueba de widget `test/widgets/food_item_editor_dialog_test.dart` para validar layout ergonómico, edición, cancelación y persistencia de ingredientes.
- [x] (Systems-Auditor) Validar sintaxis, tipos estáticos, importaciones y ausencia de errores de compilación en todos los archivos modificados.
- [x] (Systems-Auditor) Verificar que todas las suites de prueba continúen pasando limpiamente.

---

## 🚀 5. DevOps-Engineer (CI/CD, Versioning & Release)
- [x] (DevOps-Engineer) Incrementar versión en `pubspec.yaml` a `0.4.0-alpha+1`.
- [x] (DevOps-Engineer) Verificar integridad del árbol de trabajo para el cierre oficial de la versión `0.4.0-alpha`.
- [x] (DevOps-Engineer) Resolver advertencias de linter y desbordamiento de widgets en el Quality Gate de GitHub Actions.
- [x] (DevOps-Engineer) Compilar, firmar y empaquetar APK release `Victor-Engineer-Food-Tracker-Android.apk`.
- [x] (DevOps-Engineer) Publicar exitosamente el release oficial `v0.4.0-alpha` en GitHub Releases.

---

## ⚙️ 6. DevOps-Engineer (Optimización CI & Firma Criptográfica Permanente)
- [x] (DevOps-Engineer) Desactivar trigger automático `push: branches: [main]` en `.github/workflows/ci.yml`.
- [x] (DevOps-Engineer) Configurar `signingConfigs.release` explícito en `android/app/build.gradle.kts` y `android/app/build.gradle` en `.github/workflows/release.yml` y `build_apk.yml`.
- [x] (DevOps-Engineer) Asegurar la permanencia del keystore `release.keystore` en `android/app/release.keystore` con SHA-256 fingerprint inmutable (`3af69b6dc7c40fdfd42b27591d8b525b37bc30caf15d10650a5f4303583106b8`).
- [x] (DevOps-Engineer) Probar y verificar que la firma de release sea aplicada fielmente sin regeneración efímera.
- [x] (DevOps-Engineer) Actualizar `pubspec.yaml` a `0.4.0-alpha+2` (o re-tag) y publicar release verificado para pruebas de actualización sin colisiones.

---

## 🚀 7. Frontend-UI & Systems-Auditor (Flujo de Inicio y Onboarding de Primer Uso)
- [x] (Frontend-UI) Crear `lib/screens/onboarding_screen.dart` (< 300 LoC) con navegación interactiva por pasos (`PageView`), barra de progreso superior, feedback táctil y animaciones suaves.
- [x] (Frontend-UI) Diseñar subcomponentes modulares en `lib/widgets/onboarding/` (< 300 LoC cada uno):
  - `onboarding_welcome_step.dart`: Bienvenida visual, presentación de Food Tracker e ingreso de nombre.
  - `onboarding_biometrics_step.dart`: Selector de género biológico (Mifflin-St Jeor), edad, estatura y peso.
  - `onboarding_activity_step.dart`: Nivel de actividad física diaria y meta estimada de pasos.
  - `onboarding_goal_step.dart`: Objetivo corporal (pérdida de grasa, mantenimiento, hipertrofia) y cálculo dinámico de BMR, TDEE, calorías y macros.
- [x] (Frontend-UI) Conectar la persistencia con `MetabolicCalculator.calculateAndSaveProfile(...)`, marcando `SecureStorageService.instance.setCompletedOnboarding(true)` y navegando al `DashboardScreen`.
- [x] (Frontend-UI) Modificar `lib/main.dart` para verificar `hasCompletedOnboarding()` al arrancar la app y redirigir condicionalmente a `OnboardingScreen` o `DashboardScreen`.
- [x] (Frontend-UI) Añadir botón de reinicio/revisita del Asistente de Inicio en `SettingsScreen` o `UserProfileScreen`.
- [x] (Systems-Auditor) Crear suite de pruebas `test/screens/onboarding_screen_test.dart` verificando la navegación por pasos, validaciones y guardado del perfil.
- [x] (Systems-Auditor) Asegurar que todos los tests continúen pasando y cero advertencias de linter.
