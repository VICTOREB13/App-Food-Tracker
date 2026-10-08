---
tipo: implementation_plan
proyecto: App_Food_Tracker
iteracion: v1.4.0
estado: activo
fecha: 2026-10-08
tags: [proyecto, planning, v1-4-0, local-notifications, background-processing, gemini-resilience, storage-mode, pdf-export, csv-export, l10n, semver]
---

# 🎯 Plan de Implementación v1.4.0: Procesamiento Asíncrono con Notificaciones Push, Resiliencia Gemini, Selector de Almacenamiento (Público/Privado), Exportación PDF/CSV y Purga de Volumetría

> **Mesa de Control (Project-Planner):** Este plan formaliza la evolución de la iteración **v1.4.0** del proyecto **Victor Engineer - Food Tracker**. Se incorporan notificaciones locales push en segundo plano para análisis de comida y recordatorio de ayuno intermitente, resiliencia con degradación dual (stream/unario) en Gemini Vision, selector de almacenamiento privado vs público de imágenes y reportes, exportador dual a PDF y CSV guardando en Documentos accesibles, eliminación de justificación volumétrica redundante en el esquema y UI, y resiliencia total de internacionalización con variables l10n.

---

## 🔍 1. Diagnóstico Forense y Decisiones Técnicas

1. **Recomendación de Versión: v1.4.0 vs v1.3.5**
   - **Decisión:** **v1.4.0**.
   - **Fundamento SemVer:** Añadir notificaciones push/locales, generación de documentos PDF, selector de privacidad de almacenamiento y alteración de los esquemas de inferencia son adiciones funcionales mayores que incrementan la versión menor (`1.4.0`). Reservar parches (`1.3.5`) para hotfixes menores.

2. **Evaluación de Context Caching de Gemini API (https://ai.google.dev/gemini-api/docs/caching)**
   - **Análisis:** La API de Google Gemini impone un **umbral mínimo obligatorio de 32.768 tokens** para crear un recurso `CachedContent`. En nuestra app, el prompt maestro con vajilla y despensa suma entre 1.500 y 2.500 tokens, y la foto a 768px consume ~258 tokens (total ~3.000 tokens).
   - **Conclusión:** **No es viable ni conveniente**. La API rechaza el cacheo por debajo de 32k tokens. El flujo actual optimizado a 768px es el más veloz y económico posible dentro del tier gratuito.

3. **Procesamiento Asíncrono y Notificaciones Locales Push:**
   - La cola de análisis `AnalysisQueueService` opera de forma no bloqueante; al concluir o fallar una tarea con la app minimizada, se emitirá una notificación local instantánea con alta prioridad vía `flutter_local_notifications`.
   - Para el ayuno intermitente, `FastingController` programará una notificación exacta en el sistema (`zonedSchedule` con `timezone`) para dispararse exactamente al cumplir las horas meta, incluso si el sistema cierra la app.

4. **Resiliencia de Conexión en Gemini Vision & Apertura Futura a OpenRouter:**
   - Para resolver caídas abruptas de socket/NAT durante el streaming, se implementa una estrategia dual: intento con streaming continuo para mantener el socket y pacing a 60 FPS, y ante error de red o socket abort (`os error: 104/10054`, `connection closed`, etc.), fallback inmediato a llamada unaria `generateContent` antes de conmutar de modelo.
   - Se mantiene la arquitectura lista para incorporar OpenRouter mediante un contrato de proveedor desacoplado.

5. **Selector de Almacenamiento (Público vs Privado) & Exportación CSV/PDF:**
   - Selector en Ajustes: `Público` (visible en Galería y Documentos accesibles `/Pictures/FoodTracker` y `/Documents/FoodTracker`) vs `Privado` (aislado en el almacenamiento interno de la app).
   - Generación de PDF clínico elegante con tabla de macronutrientes, micronutrientes y resúmenes diarios usando `pdf`.
   - Eliminación de la ruta cruda (`/data/user/0/...`) en el diálogo clínico, reemplazándola por "Se guardó en Documentos/FoodTracker".

6. **Eliminación de Justificación Volumétrica:**
   - Eliminación de `justificacion_visual` en el esquema de items y en la UI, liberando tokens de salida y agilizando la respuesta de la IA.

7. **Internacionalización Integral (l10n):**
   - Incorporación de todas las claves con placeholders dinámicos (`{dishName}`, `{calories}`, `{hours}`, `{folder}`) en `app_es.arb` y `app_en.arb`.

---

## 🏗️ 2. Fases de Ejecución

| Fase | Tarea | Componentes |
|---|---|---|
| **Fase 1** | Configuración & Dependencias | `pubspec.yaml`, `AndroidManifest.xml`, `AppConstants.dart` (v1.4.0) |
| **Fase 2** | Servicio de Notificaciones | `NotificationService.dart`, `AnalysisQueueService`, `FastingController` |
| **Fase 3** | Resiliencia Gemini & Purga de Volumetría | `GeminiResilienceHelper`, `GeminiVisionService` |
| **Fase 4** | Selector de Almacenamiento & Exportador PDF/CSV | `StorageMode`, `MealImageStorageResolver`, `ClinicalExportService`, `ClinicalExportDialog` |
| **Fase 5** | Purga de UI & l10n Completo | `FoodItemsListCard`, `FoodItemEditorDialog`, `app_es.arb`, `app_en.arb` |
| **Fase 6** | Pruebas Automatizadas & Auditoría | Unit tests, static analysis, < 300 LoC, Quality Gate PASS |

---
