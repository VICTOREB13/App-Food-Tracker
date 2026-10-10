---
tipo: implementation_plan
proyecto: App_Food_Tracker
iteracion: v1.4.1
estado: completado
fecha: 2026-10-09
tags: [proyecto, planning, v1-4-1, l10n-architecture, pure-dart, zero-fallbacks, loc-strict, semver, release]
---

# 🎯 Plan de Implementación v1.4.1: Saneamiento Integral de Localización (l10n 100% Pure Dart), Modularización por Dominios, Cero Fallbacks y Release Oficial

> **Mesa de Control (Project-Planner):** Este plan formaliza la ejecución técnica y el cierre de la iteración **v1.4.1** del proyecto **Victor Engineer - Food Tracker**. Tras la evaluación arquitectónica de opciones de internacionalización, se implementa la **Opción A (100% Pure Dart)**, desacoplando el sistema de localización de las dependencias rígidas de generación de código (`l10n.yaml`, `.arb`), estructurando contratos por dominios de negocio e implementaciones por idioma con cumplimiento de la regla `< 300 LoC`, erradicando fallbacks hardcodeados en la interfaz de usuario, y completando el ciclo de entrega continua con Quality Gate oficial y release en GitHub.

---

## 🔍 1. Diagnóstico Forense y Decisiones Técnicas

1. **Selección Arquitectónica: Opción A (100% Pure Dart):**
   - **Problema Previo:** La generación de código con `l10n.yaml` y archivos `.arb` introducía acoplamiento a herramientas de generación (`flutter gen-l10n`), creaba archivos monolíticos que rozaban el límite de 300 LoC, generaba shims redundantes en la raíz de `lib/l10n/` y propiciaba fallbacks defensivos en la UI (`l10n?.key ?? 'español'`).
   - **Decisión:** Migrar a una arquitectura modular 100% Pure Dart dividida en:
     - `lib/l10n/domains/`: Contratos abstractos tipados por área de negocio (`core`, `dashboard`, `meal`, `metrics`, `profile`, `settings`).
     - `lib/l10n/es/`: Implementaciones concretas en español encadenadas por dominio y clase agregadora `AppLocalizationsEs`.
     - `lib/l10n/en/`: Implementaciones concretas en inglés encadenadas por dominio y clase agregadora `AppLocalizationsEn`.
     - `lib/l10n/app_localizations.dart`: Fachada central con `AppLocalizations.of(context)` retornando instancia no-nulable con fallback interno seguro a `AppLocalizationsEs`, delegados y exportación unificada.

2. **Reubicación de la Extensión `MealTypeLocalization`:**
   - Extraída del archivo suelto `lib/l10n/meal_type_l10n.dart` (el cual es eliminado) e integrada dentro de `lib/l10n/domains/app_localizations_meal.dart`.
   - Exportada automáticamente a través de la fachada `package:food_tracker/l10n/app_localizations.dart`, permitiendo invocar `'Desayuno'.toLocalizedMealType(context)` en cualquier componente sin importaciones secundarias.

3. **Erradicación Total de Fallbacks Hardcodeados:**
   - Sustitución del 100% de operadores `?? 'texto'` y condicionales `l10n != null ? l10n.x : 'texto'` en `lib/screens/` y `lib/widgets/` por acceso directo a propiedades de `l10n`.
   - Parametrización de elementos gráficos de canvas (`WeightLineChartPainter` y `WeightChartRenderUtils`) para recibir etiquetas localizadas desde sus widgets contenedores.

4. **Purga de Residuos Técnicos:**
   - Retiro de `generate: true` en `pubspec.yaml`.
   - Eliminación de `l10n.yaml`, `lib/l10n/app_es.arb` y `lib/l10n/app_en.arb`.
   - Purga de shims redundantes (`app_localizations_es.dart`, `app_localizations_en.dart`) de la raíz de `lib/l10n/`.
   - Eliminación de scripts temporales y volcados de auditoría previos.

5. **Cumplimiento de la Regla de Oro Modular (< 300 LoC):**
   - Todos los archivos creados o refactorizados en `lib/` mantienen `LoC < 300` (máximo verificado: 296 LoC en `model_picker_bottom_sheet.dart` y 295 LoC en `meal.dart`).

---

## 🏗️ 2. Fases de Ejecución

| Fase | Tarea | Componentes Afectados |
|---|---|---|
| **Fase 1** | Contratos de Dominio Pure Dart | `lib/l10n/domains/` (`core`, `dashboard`, `meal`, `metrics`, `profile`, `settings`) |
| **Fase 2** | Implementaciones Concretas e Idiomas | `lib/l10n/es/`, `lib/l10n/en/`, agregadores `AppLocalizationsEs` y `AppLocalizationsEn` |
| **Fase 3** | Fachada y Reubicación de Extensiones | `lib/l10n/app_localizations.dart`, `MealTypeLocalization` en `app_localizations_meal.dart` |
| **Fase 4** | Saneamiento Exhaustivo de UI | `lib/screens/` (100% pantallas), `lib/widgets/` (100% Bento cards, dialogs, canvas painters) |
| **Fase 5** | Purga de Catálogos y Shims | Eliminación de `l10n.yaml`, `.arb`, shims de raíz y scripts residuales; ajuste de `pubspec.yaml` |
| **Fase 6** | Ajuste de Suites de Pruebas | Actualización de matchers y delegados en `test/l10n/`, `test/widgets/` (539 tests PASS) |
| **Fase 7** | Quality Gate, Tagging y Release Oficial | Push a `main`, disparo de `ci.yml`, creación y push de tag `v1.4.1`, ejecución de `release.yml` |

---
