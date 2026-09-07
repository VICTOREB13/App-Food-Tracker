---
title: Visión General del Proyecto: Victor Engineer Food Tracker
status: active
tags: [proyecto, overview, victor-engineer, local-first, flutter, ai-vision, bento-grid]
agent: project-planner
project: App_Food_Tracker
version: v1.0.0
date: 2026-09-06
---

# 🚀 Visión General del Proyecto: Victor Engineer - Food Tracker (NutriTracker Local-First)

> **Mesa de Control (Project-Planner):** Este documento centraliza la visión del producto, capacidades técnicas, directrices de arquitectura y el índice de navegación interconectado de todos los artefactos del proyecto según la metodología de Prototipado Evolutivo y estándares Obsidian.

---

## 📖 1. ¿Qué es Victor Engineer - Food Tracker?

**Victor Engineer - Food Tracker** (NutriTracker Local-First) es una aplicación móvil de alto rendimiento desarrollada en **Flutter 3.22+**, diseñada para resolver la fricción del registro nutricional diario sin requerir báscula de alimentos.

### Propuesta de Valor Central
1. **Estimación Volumétrica Visual Asistida por IA (Gemini 2.5 Flash):**
   - El usuario fotografía su plato o selecciona una imagen de la galería.
   - El servicio de visión clínica computa volúmenes basados en referencias anatómicas universales (puño ~ 1 taza de carbohidratos/legumbres, palma de la mano ~ 100-130g de carne cocida, falange distal ~ 10-15g de grasa).
   - Ajusta automáticamente factores de cocción (merma de carnes de 20-25%, multiplicación de peso de arroz/pastas 2.5-3x) y contempla entre 5g y 10g de grasa oculta en sofritos y guisos caseros.
   - Devuelve un desglose estructurado en JSON con nombres, pesos estimados, calorías y macronutrientes.
2. **Filosofía 100% Local-First & Cero Latencia (< 16 ms):**
   - Persistencia completa en **SQLite** local optimizado con `PRAGMA journal_mode = WAL;`, `synchronous = NORMAL;` y claves foráneas activadas.
   - Toda la navegación, lectura de historial diario, desglose semanal y modificación de metas opera de forma offline e instantánea sin depender de la nube.
3. **Seguridad y Privacidad BYOK (Bring Your Own Key):**
   - La clave API de Google Gemini es provista por el usuario y se almacena con cifrado de hardware mediante `flutter_secure_storage` (`EncryptedSharedPreferences` en Android / Keychain en iOS). Nunca se expone en código ni en registros.
4. **Escáner de Despensa por Código de Barras:**
   - Integración con la API v2 de Open Food Facts para escanear y almacenar productos envasados en la despensa local SQLite.
5. **Sistema de Diseño Victor Engineer (Bento Grid & Obsidian Zinc):**
   - Paleta monocromática de alta fidelidad con acento carmesí (`#DC2626`), tipografía `Outfit` para métricas numéricas y títulos, `Inter` para cuerpos de texto, tarjetas squircle (20px de radio) y menú Speed-Dial elástico con física `Curves.easeOutBack`.

---

## 🗺️ 2. Índice Oficial de Artefactos del Proyecto

Todos los enlaces internos siguen estrictamente el estándar de Obsidian con el prefijo oficial del proyecto `[[PRJ_VEFoodTracker_{artefacto}|Alias]]`:

- **Arquitectura del Sistema:** [[PRJ_VEFoodTracker_architecture|Arquitectura del Sistema]]
- **Contrato de Datos y Especificación de API:** [[PRJ_VEFoodTracker_api_spec|Especificación de API y Modelos]]
- **Sistema de Diseño y Tokens UI/UX:** [[PRJ_VEFoodTracker_design_system|Sistema de Diseño (DESIGN.md)]]
- **Plan de Implementación Iterativa:** [[PRJ_VEFoodTracker_implementation_plan|Plan de Implementación]]
- **Checklist de Tareas y Roles:** [[PRJ_VEFoodTracker_task|Checklist de Tareas de Agentes]]
- **Historial de Versiones (Changelog):** [[PRJ_VEFoodTracker_changelog_v1|Changelog v1.0.0]]
- **Reporte de Auditoría y Quality Gate:** [[PRJ_VEFoodTracker_audit_report|Reporte de Auditoría Quality Gate]]

---

## 👥 3. Equipo de Agentes de IA y Responsabilidades

| Agente | Rol en el Proyecto | Principales Entregables |
| :--- | :--- | :--- |
| **Project-Planner** | Tech Lead & Orquestador Maestro | `project_overview.md`, `implementation_plan.md`, `task.md`, `changelog_v1.md`. |
| **Backend-Architect** | Arquitecto de Datos y Servicios | `api_spec.md`, `architecture.md`, `DatabaseService`, `GeminiVisionService`, modelos y sanitización. |
| **Frontend-UI** | Especialista de Interfaz y Tokens | `DESIGN.md`, `ThemeManager`, `DashboardScreen`, widgets atómicos (< 300 LoC), microinteracciones. |
| **Systems-Auditor** | Guardián del Quality Gate y Pruebas | `audit_report.md`, batería de pruebas unitarias/widgets (13 suites), auditoría N+1, SecOps. |
| **DevOps-Engineer** | Infraestructura, CI/CD y Releases | `.github/workflows/ci.yml`, `build_apk.yml`, `build_windows.yml`, `release.yml`, empaquetado. |
