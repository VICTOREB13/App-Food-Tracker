---
tipo: overview
proyecto: App_Food_Tracker
version: v1.0.4
estado: activo
fecha: 2026-09-13
tags: [proyecto, overview, local-first, flutter, ai-vision, bento-grid, get-it, l10n, result-pattern]
---

# 🚀 Visión General del Proyecto: Victor Engineer - Food Tracker (v1.0.4)

> **Mesa de Control (Project-Planner):** Este documento centraliza la visión del producto, capacidades técnicas, directrices de arquitectura y el índice de navegación interconectado de todos los artefactos del proyecto según la metodología de Prototipado Evolutivo y estándares Obsidian.

---

## 📖 1. ¿Qué es Victor Engineer - Food Tracker?

**Victor Engineer - Food Tracker** es una aplicación móvil y de escritorio de alto rendimiento desarrollada en **Flutter 3.22+ / 3.27+**, concebida bajo la filosofía de ingeniería de precisión, diseño visual de grado de estudio y arquitectura **100% Local-First**, resolviendo la fricción del pesaje y registro nutricional diario sin requerir báscula de alimentos.

### Propuesta de Valor Central

1. **Estimación Volumétrica Visual Asistida por IA (Gemini Multimodal Dinámico):**
   - **Descubrimiento Dinámico de Modelos:** Cero hardcoding. La aplicación consulta en tiempo real `GET https://generativelanguage.googleapis.com/v1beta/models` para descubrir y listar únicamente aquellos modelos que soportan generación de contenido estructurado y procesamiento visual (`gemini-2.5-flash`, `gemini-1.5-pro`, `gemini-2.0-flash`, etc.).
   - **Cálculo Volumétrico Clínico sin Báscula:** Computa volúmenes basados en referencias anatómicas universales (puño cerrado ~ 1 taza de carbohidratos/legumbres, palma de la mano ~ 100-130g de carne cocida, falange distal ~ 10-15g de grasa/aceite).
   - **Compensación de Merma y Grasa Oculta:** Ajusta mermas por cocción (20-25% en carnes), factores de hidratación (2.5-3x en arroz/pastas) y adiciona entre 5g y 10g de grasa oculta en sofritos y guisos caseros.
   - **Desglose Anatómico Individual y Cero 200g:** Erradicación total del comodín genérico de 200g y de la duplicación del nombre del plato en ingredientes. Cada elemento se desglosa con su gramaje y macronutrientes reales.
   - **Inyección del "Master Prompt":** Enriquecimiento de la inferencia con el perfil biométrico del usuario, hábitos y objetivos metabólicos calculados en el onboarding.
   - **Resiliencia de Inferencia:** Timeout defensivo de 35s, rescate de JSON truncado (`JsonRepairHelper`) y salvaguarda de hierbas/especias (`isSeasoningOrHerb`) para evitar distorsiones de macros.

2. **Detección Asíncrona en Background con Anillo Animado (`AnalysisQueueService` & `VeLoadingRing`):**
   - La captura fotográfica despacha tareas asíncronas a una cola SQLite sin congelar la UI ni bloquear al usuario con diálogos modales sincrónicos.
   - Anillo de carga de alta fidelidad `VeLoadingRing` inspirado en bocetos de estudio con `CustomPainter`, terminales redondeadas y rotación continua fluida a 60 FPS.
   - Banner reactivo en el Dashboard con visualización de progreso por etapas y apertura instantánea del plato analizado.

3. **Inyección de Dependencias Formal y Arquitectura Desacoplada (`GetIt`):**
   - Adopción de `get_it` como Service Locator centralizado (`lib/core/di/service_locator.dart`), registrando interfaces abstractas (`IDatabaseService`, `IImageProcessingService`, `IMealDao`, `IWeightLogDao`, `IUserProfileDao`, `IPantryDao`).
   - Inyección por constructor en controladores (`MealController`, `SettingsController`) para pruebas unitarias herméticas sin acoplamiento global, manteniendo preservada la compatibilidad con accesores `.instance`.

4. **Persistencia Local-First & DAOs Modulares (< 300 LoC):**
   - Descomposición estricta de `DatabaseService` en DAOs especializados: `MealDao`, `WeightLogDao`, `UserProfileDao` y `PantryDao`, coordinados por `DatabaseConnectionFactory` y `DatabaseSchema`.
   - SQLite v2 con `PRAGMA journal_mode = WAL;`, `synchronous = NORMAL;` y llaves foráneas (`foreign_keys = ON;`).
   - Consultas indexadas B-Tree en rangos de 7, 30 y 90 días ejecutadas en menos de 2 ms sin sobrecargar la memoria RAM.

5. **Manejo Funcional de Errores con Tipo Suma Sellado (`Result<T, Failure>`):**
   - Adopción del tipo sellado en Dart 3 `Result<T, E extends Failure>` (`Success`, `FailureResult`) en `lib/core/errors/result.dart`.
   - APIs seguras en DAOs y controladores que erradican excepciones no controladas mediante combinadores funcionales (`fold`, `map`, `flatMap`, `guardAsync`).
   - Jerarquía sellada `Failure` tipada por dominio (`DatabaseFailure`, `AiServiceFailure`, `NetworkFailure`, etc.).

6. **Internacionalización y Localización Nativa (`l10n` / `i18n`):**
   - Catálogos de idioma completos en español (`lib/l10n/app_es.arb`) e inglés (`lib/l10n/app_en.arb`).
   - Integración nativa con `AppLocalizations` en `NutriTrackerApp` con soporte para detección automática del idioma del dispositivo.

7. **Cascada Híbrida de Consulta Nutricional (USDA FoodData Central + Open Food Facts):**
   - **Motor Cascada Resiliente (`BarcodeLookupService`):** Prioriza la base de datos oficial del Departamento de Agricultura de EE.UU. (**USDA FoodData Central**) con coincidencia exacta GTIN a 14 dígitos.
   - **Fallback Transparente:** En caso de no coincidencia o ausencia de clave USDA, conmuta automáticamente a **Open Food Facts API v2** sin interrupción perceptible para el usuario.
   - **Normalización Energética:** Conversión automática de kilojulios a kilocalorías ($kJ \rightarrow kcal$ factor 4.184) y control defensivo de tasa de 1.000 req/hr.

8. **Motor Metabólico Clínico Mifflin-St Jeor & Onboarding (`UserProfileScreen` & `OnboardingScreen`):**
   - Implementación estricta de la fórmula internacional **Mifflin-St Jeor** para Tasa Metabólica Basal (TMB) y Gasto Energético Total Diario (TDEE), con Peso Corporal Ajustado ($ABW$) para usuarios con IMC $\ge 30$.
   - Asistente guiado de onboarding con inicio limpio (Clean Slate), validaciones estrictas y sincronización bidireccional automática entre metas nutricionales y perfil.
   - Sincronización automática de pesajes corporales con los datos biométricos.

9. **Seguridad Criptográfica BYOK & Firma Permanente Android:**
   - Custodia segura en hardware mediante `flutter_secure_storage` (`EncryptedSharedPreferences` en Android / Keychain en iOS) para las API Keys de Gemini y USDA.
   - Configuración de Keystore permanente RSA 2048 con validez hasta el año 2056 para despliegues continuos sin pérdida de datos.

10. **Sistema de Diseño Victor Engineer (Bento Grid & Obsidian Zinc):**
    - Paleta monocromática de alta fidelidad: *Obsidian Zinc* (`#09090B`) para modo oscuro y *Crisp Zinc* (`#FAFAFA`) para modo claro, con acento carmesí corporativo `#DC2626`.
    - Tipografía `Outfit` para métricas numéricas display e `Inter` para datos secundarios y cuerpos de texto.
    - 100% de pantallas, widgets y archivos de servicios bajo el límite estricto de 300 líneas de código (< 300 LoC).
    - Suite de pruebas de regresión automatizada: 53 suites, 370 tests pasando (100% PASS).

---

## 🗺️ 2. Índice Oficial de Artefactos del Proyecto

Todos los enlaces internos siguen estrictamente el estándar de Obsidian con el prefijo oficial del proyecto `[[PRJ_App_Food_Tracker_{artefacto}|Alias]]`:

- **Arquitectura:** [[PRJ_App_Food_Tracker_architecture|Arquitectura del Sistema]]
- **Diagrama Interactivo:** [[PRJ_App_Food_Tracker_architecture_diagram.html|Diagrama HTML (Archify)]]
- **Abstracciones:** [[PRJ_App_Food_Tracker_abstractions|Abstracciones del Sistema y Arquitectura de Código]]
- **Contrato de Datos (API):** [[PRJ_App_Food_Tracker_api_spec|Especificación de API y Modelos de Datos]]
- **Sistema de Diseño:** [[PRJ_App_Food_Tracker_design_system|Sistema de Diseño (DESIGN.md)]]
- **Plan de Implementación:** [[PRJ_App_Food_Tracker_implementation_plan|Plan de Implementación Actual]]
- **Checklist de Tareas:** [[PRJ_App_Food_Tracker_task|Checklist de Tareas]]
- **Historial de Cambios:** [[PRJ_App_Food_Tracker_changelog_v1|Registro de Versiones (Changelog)]]
- **Último Reporte de Auditoría:** [[PRJ_App_Food_Tracker_audit_report|Reporte de Auditoría (Quality Gate)]]

---

## 👥 3. Equipo de Agentes de IA y Responsabilidades

| Agente | Rol en el Proyecto | Principales Entregables |
| :--- | :--- | :--- |
| **Project-Planner** | Tech Lead & Orquestador Maestro | `project_overview.md`, `implementation_plan.md`, `task.md`, `changelog_v1.md`, diagramas Archify. |
| **Backend-Architect** | Arquitecto de Datos y Servicios | `api_spec.md`, `architecture.md`, `abstractions.md`, `DatabaseService` (SQLite v2 & DAOs), `service_locator.dart`, `Result<T, Failure>`, `GeminiModelService`, `UsdaFoodDataService`, `BarcodeLookupService`, `MetabolicCalculator`. |
| **Frontend-UI** | Especialista de Interfaz y Tokens | `design_system.md`, `ThemeManager`, `AppLocalizations`, `DashboardScreen`, `MealDetailScreen`, `SettingsScreen`, `UserProfileScreen`, `MetricsScreen`, `OnboardingScreen`, widgets atómicos (< 300 LoC), microinteracciones y `WeightLineChartPainter`. |
| **Systems-Auditor** | Guardián del Quality Gate y Pruebas | `audit_report.md`, batería de 53 suites de pruebas automatizadas (370 tests), auditoría N+1, WCAG, SecOps. |
| **DevOps-Engineer** | Infraestructura, CI/CD y Releases | `.github/workflows/ci.yml`, `build_apk.yml`, `release.yml`, Keystore RSA permanente, empaquetado y publicación oficial. |

