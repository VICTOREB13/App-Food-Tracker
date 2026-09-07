---
title: Visión General del Proyecto: Victor Engineer - Food Tracker
status: active
tags: [proyecto, overview, victor-engineer, local-first, flutter, ai-vision, bento-grid, gemini, usda, mifflin-st-jeor]
agent: project-planner
project: App_Food_Tracker
version: v0.2.0-alpha
date: 2026-09-07
---

# 🚀 Visión General del Proyecto: Victor Engineer - Food Tracker

> **Mesa de Control (Project-Planner):** Este documento centraliza la visión del producto, capacidades técnicas, directrices de arquitectura y el índice de navegación interconectado de todos los artefactos del proyecto según la metodología de Prototipado Evolutivo y estándares Obsidian.

---

## 📖 1. ¿Qué es Victor Engineer - Food Tracker?

**Victor Engineer - Food Tracker** es una aplicación móvil y de escritorio de alto rendimiento desarrollada en **Flutter 3.22+ / 3.27+**, concebida bajo la filosofía de ingeniería de precisión, diseño visual de grado de estudio y arquitectura **100% Local-First**, resolviendo la fricción del pesaje y registro nutricional diario sin requerir báscula de alimentos.

### Propuesta de Valor Central

1. **Estimación Volumétrica Visual Asistida por IA (Gemini Multimodal Dinámico):**
   - **Descubrimiento Dinámico de Modelos:** Cero hardcoding. La aplicación consulta en tiempo real `GET https://generativelanguage.googleapis.com/v1beta/models` para descubrir y listar únicamente aquellos modelos que soportan generación de contenido estructurado y procesamiento visual (`gemini-2.5-flash`, `gemini-1.5-pro`, `gemini-2.0-flash`, etc.).
   - **Cálculo Volumétrico Clínico sin Báscula:** Computa volúmenes basados en referencias anatómicas universales (puño cerrado ~ 1 taza de carbohidratos/legumbres, palma de la mano ~ 100-130g de carne cocida, falange distal ~ 10-15g de grasa/aceite).
   - **Compensación de Merma y Grasa Oculta:** Ajusta mermas por cocción (20-25% en carnes), factores de hidratación (2.5-3x en arroz/pastas) y adiciona entre 5g y 10g de grasa oculta en sofritos y guisos caseros.
   - **Inyección del "Master Prompt":** Enriquecimiento de la inferencia con el perfil biométrico del usuario, hábitos y objetivos metabólicos calculados en el onboarding.

2. **Cascada Híbrida de Consulta Nutricional (USDA FoodData Central + Open Food Facts):**
   - **Motor Cascada Resiliente (`BarcodeLookupService`):** Prioriza la base de datos oficial del Departamento de Agricultura de EE.UU. (**USDA FoodData Central**) para máxima precisión de micronutrientes y macronutrientes oficiales.
   - **Fallback Transparente:** En caso de no disponibilidad o ausencia de código en USDA, conmuta automáticamente a **Open Food Facts API v2** sin interrupción perceptible para el usuario.
   - **Normalización Energética y Rate Limiting:** Conversión automática de kilojulios a kilocalorías ($kJ \rightarrow kcal$ factor 4.184) y control defensivo de tasa de 1.000 req/hr.

3. **Motor Metabólico Clínico Mifflin-St Jeor & Onboarding (`UserProfileScreen`):**
   - Implementación estricta de la fórmula internacional **Mifflin-St Jeor** para Tasa Metabólica Basal (TMB) y Gasto Energético Total Diario (TDEE).
   - Ajuste por niveles de actividad física y conteo de pasos diarios promedio.
   - Sincronización atómica con las metas diarias de macronutrientes y persistencia en hardware seguro.

4. **Persistencia 100% Local-First & SQLite v2 (`weight_logs` y `meals`):**
   - Persistencia local en SQLite optimizado con `PRAGMA journal_mode = WAL;`, `synchronous = NORMAL;` y llaves foráneas activas (`foreign_keys = ON;`).
   - Esquema relacional v2 con migración automática, incorporando la tabla `weight_logs` indexada por fecha para auditoría de tendencias de composición corporal.
   - Consultas de agregación en rangos de 7, 30 y 90 días ejecutadas en menos de 2 ms sin filtrado ineficiente en memoria RAM.

5. **Panel de Analíticas Bento Grid (`MetricsScreen`):**
   - Visualización de tendencias de peso mediante curvas de Bézier suavizadas dibujadas a **60 FPS** con `WeightLineChartPainter` acelerado por hardware.
   - Tarjetas Bento Grid semánticas: adherencia calórica, distribución porcentual de macronutrientes y racha de registro de comidas.
   - Modal de registro rápido `QuickWeightEntryDialog` con sanitización defensiva contra valores astronómicos, `NaN` o infinitos.

6. **Seguridad Criptográfica BYOK (Bring Your Own Key) & Firma Permanente Android:**
   - Custodia segura en hardware mediante `flutter_secure_storage` (`EncryptedSharedPreferences` en Android / Keychain en iOS) para las API Keys de Gemini y USDA.
   - Configuración de Keystore permanente RSA 2048 con validez hasta el año 2056 para despliegues continuos sin pérdida de datos ni necesidad de desinstalación.

7. **Sistema de Diseño Victor Engineer (Bento Grid & Obsidian Zinc):**
   - Paleta monocromática de alta fidelidad: *Obsidian Zinc* (`#09090B`) para modo oscuro y *Crisp Zinc* (`#FAFAFA`) para modo claro, con acento carmesí corporativo `#DC2626`.
   - Tipografía `Outfit` para métricas numéricas display e `Inter` para datos secundarios y cuerpos de texto.
   - Descomposición estricta en Monolito Modular: todas las pantallas (`DashboardScreen`, `MealDetailScreen`, `SettingsScreen`, `UserProfileScreen`, `MetricsScreen`) se mantienen por debajo de las 300 líneas de código.

---

## 🗺️ 2. Índice Oficial de Artefactos del Proyecto

Todos los enlaces internos siguen estrictamente el estándar de Obsidian con el prefijo oficial del proyecto `[[PRJ_VEFoodTracker_{artefacto}|Alias]]`:

- **Arquitectura del Sistema:** [[PRJ_VEFoodTracker_architecture|Arquitectura del Sistema]]
- **Contrato de Datos y Especificación de API:** [[PRJ_VEFoodTracker_api_spec|Especificación de API, Esquema SQLite y Contratos Backend]]
- **Sistema de Diseño y Tokens UI/UX:** [[PRJ_VEFoodTracker_design_system|Sistema de Diseño (DESIGN.md)]]
- **Plan de Implementación Iterativa:** [[PRJ_VEFoodTracker_implementation_plan|Plan de Implementación]]
- **Checklist de Tareas y Roles:** [[PRJ_VEFoodTracker_task|Checklist Maestro de Tareas de Agentes]]
- **Historial de Versiones (Changelog):** [[PRJ_VEFoodTracker_changelog_v1|Registro de Cambios (Changelog)]]
- **Reporte de Auditoría y Quality Gate:** [[PRJ_VEFoodTracker_audit_report|Reporte de Auditoría Integral y Quality Gate]]

---

## 👥 3. Equipo de Agentes de IA y Responsabilidades

| Agente | Rol en el Proyecto | Principales Entregables |
| :--- | :--- | :--- |
| **Project-Planner** | Tech Lead & Orquestador Maestro | `project_overview.md`, `implementation_plan.md`, `task.md`, `changelog_v1.md`. |
| **Backend-Architect** | Arquitecto de Datos y Servicios | `api_spec.md`, `architecture.md`, `DatabaseService` (SQLite v2), `GeminiModelService`, `UsdaFoodDataService`, `BarcodeLookupService`, `MetabolicCalculator`, sanitizadores y modelos inmutables Sentinel. |
| **Frontend-UI** | Especialista de Interfaz y Tokens | `DESIGN.md`, `ThemeManager`, `DashboardScreen`, `MealDetailScreen`, `SettingsScreen`, `UserProfileScreen`, `MetricsScreen`, widgets atómicos (< 300 LoC), microinteracciones y `WeightLineChartPainter`. |
| **Systems-Auditor** | Guardián del Quality Gate y Pruebas | `audit_report.md`, batería de pruebas automatizadas (37 suites, 237 pruebas unitarias/widgets/integración en verde), auditoría N+1, SecOps. |
| **DevOps-Engineer** | Infraestructura, CI/CD y Releases | `.github/workflows/ci.yml`, `build_apk.yml`, `build_windows.yml`, `release.yml`, Keystore RSA permanente, empaquetado y publicación oficial. |
