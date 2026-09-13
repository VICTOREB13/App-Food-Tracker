---
tipo: implementation_plan
proyecto: App_Food_Tracker
iteracion: v1.0.4
estado: completado
fecha: 2026-09-13
tags: [proyecto, planning, v1-0-4, yagni, local-first, ui-ux, gemini-ai, get-it, daos, l10n, result-pattern]
---

# 🎯 Plan de Implementación: Victor Engineer - Food Tracker (v1.0.4)

> **Mesa de Control (Project-Planner):** Este plan formaliza la evolución progresiva hacia el estado de excelencia técnica y de arquitectura (calificación 10/10), incorporando la inyección de dependencias con GetIt, DAOs especializados bajo el límite estricto de < 300 LoC, soporte multi-idioma (l10n) y manejo funcional de errores con Result pattern.

---

## 🎯 1. Objetivos Maestros del Sistema

1. **Estimación Volumétrica Visual Asistida por IA (Gemini Multimodal Dinámico):**
   - Detección precisa de comidas mediante inferencia multimodal y cálculo volumétrico clínico.
   - Desglose anatómico individual de ingredientes sin valores genéricos (cero 200g).
   - Re-análisis inteligente incorporando correcciones del usuario.
2. **Procesamiento Asíncrono en Segundo Plano (`AnalysisQueueService` & `VeLoadingRing`):**
   - Despacho no bloqueante de capturas fotográficas hacia una cola persistente en SQLite.
   - Componente visual interactivo de anillo de carga con `CustomPainter` a 60 FPS.
   - Banner reactivo en el Dashboard con visualización de avance por etapas.
3. **Inyección de Dependencias Formal y Arquitectura Desacoplada (`GetIt`):**
   - Service Locator centralizado con contratos abstractos (`IDatabaseService`, `IImageProcessingService`, DAOs).
   - Inyección por constructor en controladores para testing hermético con mocks.
4. **Persistencia Local-First & DAOs Modulares (< 300 LoC):**
   - Descomposición de la base de datos en DAOs especializados: `MealDao`, `WeightLogDao`, `UserProfileDao`, `PantryDao`.
   - Separación de conexión (`DatabaseConnectionFactory`) y esquema/migraciones (`DatabaseSchema`).
5. **Manejo Funcional de Errores (Result / Either):**
   - Tipo suma sellado en Dart 3 `Result<T, Failure>` con combinadores funcionales (`fold`, `map`, `guardAsync`).
6. **Internacionalización y Localización Multi-idioma (`AppLocalizations`):**
   - Catálogos bilingües oficiales en español (`app_es.arb`) e inglés (`app_en.arb`).

---

## 🛠️ 2. Fases Históricas y Evolución de Construcción

### Fase 1 a 4: Núcleo MVP y Refinamiento (v0.1.0 – v0.4.0)
- Modelos inmutables con Sentinel y sanitizador centralizado (`ModelSanitizer`).
- Integración multimodal con Google Gemini API y cascada nutricional (USDA + Open Food Facts).
- Rediseño ergonómico de macros en `FoodItemEditorDialog` y extracción modular de widgets.

### Fase 5: Optimización de CI y Firma Permanente de Release (`DevOps-Engineer`)
- Keystore permanente RSA 2048 (`release.keystore`) con SHA-256 inmutable (`3af69b6dc7c40fdfd42b27591d8b525b37bc30caf15d10650a5f4303583106b8`).
- Pipeline unificado de Quality Gate y compilación de release APK en GitHub Actions.

### Fase 6: Flujo de Inicio y Onboarding Nutricional Personalizado (`Frontend-UI`)
- Pantalla guiada `OnboardingScreen` con 4 pasos interactivos y cálculo dinámico Mifflin-St Jeor.
- Inicio de pizarra limpia (Clean Slate) con campos vacíos y validaciones estrictas.
- Sincronización bidireccional entre metas nutricionales y perfil metabólico.

### Fase 7: Desglose Fino de Ingredientes y Detección Asíncrona con Anillo (v1.0.2)
- Erradicación del comodín plano de 200g y de la duplicación del nombre del plato en ingredientes.
- Cola asíncrona y worker en SQLite (`AnalysisQueueService`) desacoplada del hilo de UI.
- Anillo animado de carga `VeLoadingRing` y banner interactivo `AnalysisProgressBanner`.

### Fase 8: Robustez de Análisis, Resiliencia y Precisión Clínica (v1.0.3)
- **H-01:** Coincidencia exacta GTIN (14 dígitos) en USDA y fallback transparente a Open Food Facts.
- **H-02:** Compresión asíncrona de fotos en Isolate secundario (`compressAndResizeAsync`) y bypass si $\le 1024$ px.
- **H-03:** Sincronización metabólica al registrar peso (`recordWeight`) recalculando macros y actualizando metas.
- **H-04:** Salvaguarda de condimentos, hierbas y especias (`isSeasoningOrHerb`) contra acaparamiento de macros.
- **H-05:** Ecuación de Peso Corporal Ajustado ($ABW = IBW + 0.4 \times (TBW - IBW)$) para usuarios con IMC $\ge 30$.
- **H-06:** Robustez en cola de análisis con ID determinista de comidas y método `retryTask(taskId)`.
- **H-08:** Algoritmo resiliente de rescate de JSON truncado (`JsonRepairHelper`).
- **H-09:** Consulta SQLite por rango de fechas `getMealsByRange(start, end)` para mitigar uso de memoria RAM.
- **H-14:** Timeout defensivo de 35 segundos en llamadas de red a Gemini Vision.

### Fase 9: Arquitectura de Calificación 10/10: Inyección de Dependencias, DAOs Modulares, l10n y Result Type (v1.0.4)
- **Inyección de Dependencias con GetIt (`lib/core/di/service_locator.dart`):** Registro de interfaces abstractas (`IDatabaseService`, `IImageProcessingService`, `IMealDao`, `IWeightLogDao`, `IUserProfileDao`, `IPantryDao`), permitiendo inyección por constructor y preservando compatibilidad con `.instance`.
- **Modularización Estricta de Servicios (< 300 LoC):**
  - Descomposición de `DatabaseService` en DAOs especializados: `MealDao` (220 LoC), `WeightLogDao` (185 LoC), `UserProfileDao` (83 LoC), `PantryDao` (119 LoC), `DatabaseConnectionFactory` (81 LoC) y `DatabaseSchema` (116 LoC).
  - Descomposición de `ImageProcessingService` en `MealImageFileNamer` (229 LoC) y `MealImageStorageResolver` (153 LoC).
  - 100% de los archivos del proyecto por debajo del límite estricto de 300 líneas (< 300 LoC).
- **Internacionalización Nativa (`l10n` / `i18n`):** Creación de diccionarios `app_es.arb` y `app_en.arb`, contratos en `AppLocalizations` e integración en `NutriTrackerApp`.
- **Manejo Funcional de Errores con Patrón Result:** Implementación de `Result<T, Failure>` y jerarquía sellada `Failure` en Dart 3 con combinadores funcionales y APIs en todos los DAOs.
- **Batería de Pruebas Automatizadas:** 53 suites de prueba (367 tests), logrando un veredicto de 100% PASS en el Quality Gate.
