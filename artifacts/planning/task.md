---
tipo: task_list
proyecto: App_Food_Tracker
iteracion: v0.3.0-alpha
estado: activo
fecha: 2026-09-09
tags: [proyecto, tasks, checklist, v7-teamwork, v0-3-0-alpha]
---

# 📋 Checklist Maestro de Tareas de Agentes (v0.3.0-alpha)

> **Mesa de Control (Project-Planner):** Este checklist asigna la propiedad técnica de cada entregable de la iteración v0.3.0-alpha a su respectivo agente especializado. Al completar cada tarea, se marca con `[x]`.

---

## 🧭 1. Project-Planner (Master Tech Lead)
- [x] (Project-Planner) Analizar los 12 requerimientos de la iteración v0.3.0-alpha a partir de las capturas en `assets/images/test/`.
- [x] (Project-Planner) Actualizar la visión de proyecto en `artifacts/project_overview.md` a v0.3.0-alpha.
- [x] (Project-Planner) Estructurar el plan de implementación en `artifacts/planning/implementation_plan.md` bajo principio YAGNI.
- [x] (Project-Planner) Desglosar las tareas atómicas asignadas a subagentes en `artifacts/planning/task.md`.
- [x] (Project-Planner) Monitorear la ejecución de los subagentes, auditar artefactos y redactar notas de versión en `artifacts/planning/changelog_v1.md`.

---

## 🗄️ 2. Backend-Architect (Datos, Modelos y Servicios)
- [x] (Backend-Architect) Refactorizar `lib/services/gemini_model_service.dart` implementando un filtrado estricto de modelos multimodales (solo gemini con flash o pro, excluyendo `banana`, `nano`, `transcribe`, `omni`, `computer-use`, `robotics`, `live`, etc.).
- [x] (Backend-Architect) Actualizar la lista de modelos de fallback en `gemini_model_service.dart` con versiones canónicas de producción.
- [x] (Backend-Architect) Implementar función de mapeo de errores amigables en `lib/services/gemini_vision_service.dart` (`userFriendlyErrorMessage`) para conexión, tokens/cuotas, API keys y fallos de detección.
- [x] (Backend-Architect) Modificar `lib/services/image_processing_service.dart` para almacenar imágenes en la carpeta estándar `Pictures` del sistema operativo.
- [x] (Backend-Architect) Implementar `pruneOldMealPhotos` en `image_processing_service.dart` para depurar archivos del disco manteniendo intactos los registros de comidas en SQLite (`image_path = null`).
- [x] (Backend-Architect) Implementar `upsertMeal` en `lib/services/database_service.dart` para garantizar la inserción/reemplazo atómico de comidas analizadas.
- [x] (Backend-Architect) Añadir consulta histórica global de peso `getAllWeightLogs()` en `database_service.dart`.
- [x] (Backend-Architect) Actualizar `lib/controllers/meal_controller.dart` para soportar rango `days: 0` (período histórico) y método de depuración de fotos.
- [x] (Backend-Architect) Sincronizar el contrato de datos y abstracciones en `artifacts/architecture/api_spec.md` y `artifacts/architecture/abstractions.md`.

---

## 🎨 3. Frontend-UI (Diseño, Widgets Bento y Pantallas)
- [x] (Frontend-UI) Corregir `lib/widgets/profile/biometric_inputs_card.dart` evitando que el listener de edad reinicie el texto al vaciar temporalmente el campo para escribir.
- [x] (Frontend-UI) Actualizar `lib/widgets/profile/metabolic_summary_bento_card.dart` incorporando la pastilla biométrica visible (edad, altura, peso, sexo) y el editor de Master Prompt personalizado con restablecimiento.
- [x] (Frontend-UI) Crear `lib/widgets/settings/model_picker_bottom_sheet.dart` con búsqueda reactiva, chips de filtro (`Todos`, `Flash`, `Pro`), insignias de recomendación y detalles de contexto de tokens.
- [x] (Frontend-UI) Rediseñar `lib/widgets/settings/gemini_model_selector_card.dart` para eliminar desbordamientos de texto y abrir el nuevo `ModelPickerBottomSheet`.
- [x] (Frontend-UI) Corregir truncamiento de badges en `lib/widgets/metrics/calorie_compliance_bento_card.dart` y `streak_compliance_bento_card.dart`.
- [x] (Frontend-UI) Corregir colisión de texto entre título y subtítulo en `lib/widgets/metrics/macro_distribution_bento_card.dart`.
- [x] (Frontend-UI) Actualizar `lib/screens/metrics_screen.dart` añadiendo la pestaña "Histórico", eliminando el botón redundante de registro y agregando el historial con notas.
- [x] (Frontend-UI) Mostrar indicador y texto de notas en los tiles de comida de `lib/widgets/dashboard/meal_section_card.dart`.
- [x] (Frontend-UI) Añadir campos de macros opcionales (proteína, carbohidratos, grasas) en `lib/widgets/dashboard/quick_meal_dialog.dart`.
- [x] (Frontend-UI) Corregir `lib/screens/meal_detail_screen.dart` para usar `upsertMeal`, asegurando la persistencia de comidas analizadas con IA y guardado sin foto.
- [x] (Frontend-UI) Añadir la tarjeta de política de depuración de fotos en `lib/screens/settings_screen.dart`.
- [x] (Frontend-UI) Aplicar `TextAlign.justify` en bloques de texto informativos y explicativos en tarjetas de ajustes y modales.

---

## 🧪 4. Systems-Auditor (Quality Gatekeeper & Testing)
- [x] (Systems-Auditor) Actualizar y ejecutar pruebas unitarias para `gemini_model_service_test.dart` verificando el bloqueo del 100% de los modelos no aptos.
- [x] (Systems-Auditor) Crear pruebas unitarias para `pruneOldMealPhotos` y `upsertMeal` en `database_service_test.dart`.
- [x] (Systems-Auditor) Actualizar pruebas de widgets para las tarjetas rediseñadas (`GeminiModelSelectorCard`, `CalorieComplianceBentoCard`, `WeightHistoryBentoCard`, etc.).
- [x] (Systems-Auditor) Verificar que la totalidad de pruebas del repositorio pasen con 0 errores (38 suites / 248 tests).
- [x] (Systems-Auditor) Emitir veredicto formal de Quality Gate en `artifacts/audit_reports/audit_report.md` (`veredicto: PASS`).

---

## 🚀 5. DevOps-Engineer (CI/CD, Versioning & Release)
- [x] (DevOps-Engineer) Incrementar versión en `pubspec.yaml` a `0.3.0-alpha+1`.
- [x] (DevOps-Engineer) Verificar prerequisito de Quality Gate (`veredicto: PASS` en `audit_report.md`).
- [x] (DevOps-Engineer) Validar que los flujos de GitHub Actions (`ci.yml`, `build_apk.yml`, `release.yml`) se mantengan verdes.
- [x] (DevOps-Engineer) Publicar el Release `v0.3.0-alpha` con artefactos compilados.


