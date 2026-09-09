---
tipo: implementation_plan
proyecto: App_Food_Tracker
iteracion: v0.3.0-alpha
estado: activo
fecha: 2026-09-09
tags: [proyecto, planning, v0-3-0-alpha, yagni, local-first, ui-ux]
---

# 🎯 Plan de Implementación: Victor Engineer - Food Tracker (v0.3.0-alpha)

> **Mesa de Control (Project-Planner):** Este plan desglosa la construcción de la iteración **v0.3.0-alpha**, atendiendo los 12 requerimientos clínicos, visuales y de persistencia detectados a partir de las pruebas con usuarios y capturas en `assets/images/test/`. Sigue la metodología de Prototipado Evolutivo, el principio YAGNI y la asignación atómica a subagentes especializados.

---

## 🎯 1. Objetivos de la Iteración v0.3.0-alpha

1. **Perfil Metabólico & Biometría:** Permitir edición fluida de la edad sin reinicios involuntarios y desplegar la ficha biométrica clara en la tarjeta de resumen metabólico.
2. **Master Prompt Personalizable:** Permitir al usuario editar el Master Prompt generado por la app, guardarlo para su inyección en Gemini Vision o restablecerlo a valores calculados por defecto.
3. **Filtrado Estricto de Modelos Multimodales:** Depurar el catálogo de la API de Google AI Studio para admitir exclusivamente modelos `flash` y `pro` aptos para visión nutricional, excluyendo modelos incompatibles (`nano-banana`, `gemini-3.5-transcribe`, `gemini-omni`, `robotics`, `computer-use`, etc.).
4. **Selector Interactivo de Modelos:** Reemplazar el dropdown con desbordamiento por una hoja modal interactiva (`ModelPickerBottomSheet`) con buscador en tiempo real y chips de filtro (`Todos`, `Flash`, `Pro`).
5. **Corrección de Textos Desbordados:** Resolver colisiones visuales entre título, badge de recomendación y ventana de contexto de tokens en `GeminiModelSelectorCard`.
6. **Justificación Tipográfica:** Aplicar `TextAlign.justify` en textos explicativos e informativos en tarjetas y diálogos.
7. **Refinamiento de Métricas y Bento Grid:** Corregir textos truncados ("Sin regist", "Comie...", colisión en distribución de macros) y unificar el botón de pesaje.
8. **Rango "Histórico" en Gráfica de Progreso:** Incorporar opción de visualización histórica global desde el primer pesaje registrado en SQLite.
9. **Visualización de Notas en Dashboard y Métricas:** Mostrar vista previa de notas de comida en los tiles del Dashboard y acordeón/historial de notas de pesaje en Métricas.
10. **Política de Depuración de Fotos (Ahorro de Espacio):** Configuración de retención de fotos (`Para siempre`, `90 días`, `30 días`, `15 días`) que elimina imágenes pesadas de disco pero preserva 100% las calorías, macros e historial en base de datos.
11. **Persistencia de Fotos, Directorio Pictures & Macros en Comida Rápida:**
    - Corregir el bug crítico en `MealDetailScreen` donde las comidas analizadas con IA no se guardaban en SQLite debido a la confusión entre inserción y actualización (implementación de `upsertMeal`).
    - Guardar fotos en la carpeta estándar `Pictures` del sistema para evitar errores de sandbox.
    - Soportar macros opcionales (proteína, carbohidratos, grasa) en `QuickMealDialog` y permitir guardado sin imagen (`imagePath == null`).
12. **Manejo de Errores Amigables para IA:** Capturar excepciones de red, cuota o seguridad de Gemini y traducirlas a mensajes empáticos en español.

---

## 🛠️ 2. Fases de Construcción para Subagentes

### Fase 1: Arquitectura Backend, Datos y Servicios (`Backend-Architect`)
1. **Actualizar `lib/services/gemini_model_service.dart`:**
   - Regla estricta de filtro multimodal: nombre que contenga `gemini`, contenga `flash` o `pro`, y exclusión de palabras no aptas (`banana`, `nano`, `transcribe`, `omni`, `computer-use`, `robotics`, `live`, `custom`, `preview-10-2025`, `embedding`, `imagen`, `tts`, `audio`, `veo`, `bison`).
   - Requiere capacidad `generateContent`.
   - Actualizar lista de respaldo offline con modelos canónicos estables.
2. **Actualizar `lib/services/gemini_vision_service.dart`:**
   - Inyectar función de mapeo de errores humanos `userFriendlyErrorMessage(dynamic error)` cubriendo fallos de red (`SocketException`), timeout, 400/403 (API Key inválida), 429 (límite de cuota) y falta de detección.
3. **Actualizar `lib/services/image_processing_service.dart`:**
   - Ajustar guardado en directorio estándar `Pictures` (`getExternalStorageDirectories(type: StorageDirectory.pictures)` en Android con fallback defensivo).
   - Añadir método `pruneOldMealPhotos({required int retentionDays})` para borrar archivos huérfanos/antiguos en disco manteniendo registros de base de datos.
4. **Actualizar `lib/services/database_service.dart`:**
   - Implementar método `upsertMeal(Meal meal)` con `ConflictAlgorithm.replace`.
   - Añadir consulta histórica global `getAllWeightLogs()`.
   - Añadir método `clearMealImagePath(String mealId)` y depuración por fecha límite.
5. **Actualizar `lib/controllers/meal_controller.dart`:**
   - Soportar rango `days: 0` para modo "Histórico" en métricas.
   - Conectar lógica de depuración de fotos de comidas.

### Fase 2: Presentación, Bento Grid e Interfaces Atómicas (`Frontend-UI`)
1. **Perfil Metabólico (`lib/widgets/profile/`):**
   - Corregir `biometric_inputs_card.dart` evitando que el listener de edad reinicie el texto al vaciar temporalmente el campo para escribir.
   - Actualizar `metabolic_summary_bento_card.dart` con pastilla informativa de biometría y editor colapsable/modal del Master Prompt con opciones de guardado y restablecimiento.
2. **Selector de Modelos Gemini (`lib/widgets/settings/`):**
   - Crear `model_picker_bottom_sheet.dart` con buscador reactivo, filtros chips (`Todos`, `Flash`, `Pro`), badges y detalles de tokens.
   - Rediseñar `gemini_model_selector_card.dart` con botón que abre el nuevo modal y chips flexibles sin desbordamiento.
3. **Métricas y Bento Grid (`lib/screens/metrics_screen.dart` y widgets):**
   - Añadir pestaña **"Histórico"** al selector de períodos en `MetricsScreen`.
   - Eliminar botón redundante de registro de peso en la tarjeta.
   - Añadir sección de historial de pesajes con visualización de notas.
   - Corregir badges truncados en `calorie_compliance_bento_card.dart` y `streak_compliance_bento_card.dart`.
   - Desacoplar textos en `macro_distribution_bento_card.dart` para evitar colisiones.
4. **Dashboard y Guardado (`lib/widgets/dashboard/` y `lib/screens/`):**
   - Mostrar indicador de notas en `meal_section_card.dart`.
   - Añadir campos de macros opcionales en `quick_meal_dialog.dart`.
   - Corregir `meal_detail_screen.dart` para usar `upsertMeal`, garantizando persistencia inmediata de comidas analizadas.
5. **Ajustes (`lib/screens/settings_screen.dart`):**
   - Añadir tarjeta de política de depuración de fotos (`Para siempre`, `90 días`, `30 días`, `15 días`).
   - Aplicar `TextAlign.justify` en bloques descriptivos de las tarjetas.

### Fase 3: Quality Gate, Pruebas y Auditoría (`Systems-Auditor`)
1. Actualizar y ejecutar la suite completa de pruebas unitarias y de widgets.
2. Verificar que el 100% de los modelos no aptos queden bloqueados en el filtro.
3. Verificar que `upsertMeal` y la depuración de fotos conserven la integridad de los datos.
4. Emitir reporte de auditoría en `artifacts/audit_reports/audit_report.md` con `veredicto: PASS`.

### Fase 4: CI/CD y Empaquetado (`DevOps-Engineer`)
1. Actualizar `pubspec.yaml` a `0.3.0-alpha+1`.
2. Verificar que los pipelines de GitHub Actions compilen sin errores con el Keystore permanente.
3. Publicar el Release `v0.3.0-alpha` con artefactos APK de Android y ZIP de Windows.

