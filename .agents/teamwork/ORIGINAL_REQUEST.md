# Original User Request

## 2026-10-04T18:31:10Z

This is a single self-contained fix; keep it small and focused.

Investigar la causa raíz del cierre inmediato (fatal startup crash) de la aplicación Victor Engineer Food Tracker en dispositivos con Android 16 (API 36) y aplicar la solución técnica definitiva para garantizar un arranque inmediato, fluido y tolerante a fallos.

Working directory: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker
Integrity mode: development

## Requirements

### R1. Diagnóstico y Depuración de Causa Raíz en Android 16
Aislar el origen exacto del cierre abrupto al iniciar la app:
- Verificar la compatibilidad de páginas de memoria de 16 KB en librerías nativas C/C++ (`.so`) empaquetadas en el APK (revisar paquetes como `sqlite3_flutter_libs`, `sqflite` y dependencias nativas).
- Verificar posibles excepciones en la inicialización nativa de plugins (`flutter_secure_storage` v11, `home_widget`) y el ciclo de vida de `MainActivity`.
- Verificar la configuración de `AndroidManifest.xml` y `build.gradle` (temas, application name, receivers).

### R2. Arquitectura de Arranque Resiliente e Inmediata
Asegurar que `lib/main.dart` y la Activity nativa arranquen sin dependencias bloqueantes:
- Garantizar que la interfaz gráfica principal se dibuje de inmediato en el frame 0.
- Aislar en segundo plano y con salvaguardas de timeout cualquier inicialización de base de datos o hardware Keystore que pueda disparar el Watchdog de Android 16.

### R3. Certificación de Calidad y Empaquetado
Asegurar que el proyecto mantenga el límite modular de < 300 LoC por archivo, que `flutter analyze` tenga 0 errores y que las pruebas automatizadas pasen al 100%.

## Acceptance Criteria

### Estabilidad y Compatibilidad con Android 16
- [ ] No existen archivos binarios `.so` con desalineación de páginas de 16 KB en el APK que puedan provocar `SIGSEGV` o fallos de `dlopen` en el kernel de Android 16.
- [ ] La aplicación arranca y despliega su interfaz de usuario sin cerrarse súbitamente ni quedarse congelada en pantalla negra/blanca.
- [ ] La configuración de Gradle y AndroidManifest cumple con los estándares de Android 14+ y Android 16 (API 34/36).

### Higiene y Modularidad de Código
- [ ] `flutter analyze` pasa con 0 errores y 0 advertencias.
- [ ] 100% de las suites de prueba unitarias y de widgets se ejecutan exitosamente (100% PASS).
- [ ] Todos los archivos modificados o creados se mantienen estrictamente bajo el límite de 300 líneas de código (< 300 LoC).


## 2026-10-04T21:41:59Z

Refinamiento integral de la experiencia de usuario (UX/UI), selector de archivos nativo del sistema operativo móvil para respaldos JSON con compatibilidad retroactiva resiliente, y reestructuración ergonómica de features del Dashboard (¿Qué debería comer hoy?, Ayuno Intermitente y Despensa).

Working directory: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker
Integrity mode: development

## Requirements

### R1. Selector de Archivos Nativo y Normalización Retrocompatible de JSON
- Integrar selector de archivos nativo del sistema operativo móvil (`file_picker` / SAF) para que el usuario seleccione su archivo `.json` visualmente desde Descargas, Drive o almacenamiento interno con un solo toque, eliminando por completo la entrada manual de rutas de archivo.
- Implementar un normalizador adaptativo en `BackupService` que soporte e importe de forma transparente respaldos legados (versiones v1.0.4 y anteriores), detectando y traduciendo automáticamente variantes de claves (`meals`/`comidas`/array directo de comidas, `pantry_items`/`despensa`, `user_profile`/`perfil`, `weight_logs`/`pesos`).
- Ejecutar la lectura, decodificación y parseo JSON en un Isolate secundario (`Isolate.run`) y la persistencia en SQLite mediante operaciones por lotes (`batch.commit()`) para garantizar una importación instantánea a 60 FPS sin congelamientos del hilo de la interfaz.

### R2. Reubicación Ergonómica y Rediseño de "¿Qué Debería Comer Hoy?"
- Retirar la tarjeta fija invasiva del Dashboard principal y reubicar "¿Qué debería comer hoy?" como una opción destacada dentro del menú emergente al pulsar el botón `+` flotante.
- Rediseñar la vista modal de "¿Qué debería comer hoy?" corrigiendo los errores visuales de `Screenshot_20261004-172008.jpg`: envolver en `SafeArea`, incorporar una barra de cabecera con botón explícito de cerrar (`IconButton(icon: Icon(Icons.close))`), y aplicar restricciones de altura y scroll fluido para que no invada la barra de estado del sistema ni bloquee la navegación.

### R3. Reorganización del Dashboard y Posicionamiento del Ayuno Intermitente
- Transformar el componente de Ayuno Intermitente en el Dashboard en una tarjeta Bento compacta y colapsable que muestre un estado discreto por defecto y se expanda únicamente cuando el usuario esté activamente en un período de ayuno o decida interactuar con él.
- Corregir el solapamiento de textos en el diálogo del Motor de Recomendación Nutricional (`Screenshot_20261004-172027.jpg`), asegurando que las sustituciones sugeridas sean completamente navegables con scroll sobre el botón de cierre.
- Corregir en `MetricsScreen` (`Screenshot_20261004-172452.jpg`) el desbordamiento horizontal del badge "1/7 días con registro" en `WeeklyDigestCard` y el contenedor superior cortado sobre la tarjeta de distribución de macros.

### R4. Gramaje de Referencia y Porciones en Despensa / Productos
- En el modelo y editor de alimentos de despensa (`PantryItem` / `PantryItemEditorDialog`), incorporar campos para la porción de referencia en gramos (ej. "Cada 100g") y el peso neto total del empaque (ej. "500g").
- Permitir que al registrar un alimento de la despensa hacia una comida, los macronutrientes y calorías se calculen y escalen matemáticamente de forma automática en base a los gramos consumidos por el usuario.

## Acceptance Criteria

### Experiencia de Usuario y Flujo de Respaldo
- [ ] Al pulsar "Importar JSON", el usuario puede tocar un botón prominente para abrir el explorador de archivos nativo de Android y elegir cualquier archivo `.json` sin necesidad de teclear rutas manuales.
- [ ] Respaldos exportados en versiones v1.0.4 o anteriores se importan exitosamente sin arrojar `FormatException` ni errores de cabecera.
- [ ] La importación y exportación de respaldos grandes (>500 registros) no produce caídas de frames ni congelamiento de la interfaz gracias al uso de Isolates y transacciones por lotes (`batch`).

### Ergonomía Visual y Modales
- [ ] La hoja de "¿Qué debería comer hoy?" respeta la barra de estado del sistema (`SafeArea`), cuenta con un botón visible para cerrarla y se activa desde el menú del botón `+`.
- [ ] El Dashboard se visualiza limpio y sin sobrecarga visual, con el temporizador de ayuno en formato Bento colapsable.
- [ ] El diálogo del Motor de Recomendaciones permite leer todas las sustituciones sugeridas mediante scroll sin solaparse con el botón de cierre.
- [ ] La tarjeta de resumen semanal en Métricas no desborda su badge fuera de la pantalla.

### Despensa y Gramajes
- [ ] Los productos de despensa permiten especificar su porción de referencia en gramos (ej. 100g) y escalan los macros correctamente según la porción servida.

### Calidad de Código y Modularidad
- [ ] `flutter analyze` pasa con 0 errores y 0 advertencias.
- [ ] 100% de las pruebas automatizadas existentes y nuevas pasan exitosamente.
- [ ] Cada archivo modificado o creado cumple estrictamente con el límite de < 300 LoC.


## 2026-10-04T21:42:58Z

El usuario ha especificado formalmente que esta iteración debe ser versionada como la versión 1.2.4 (versión 1.2.4+1 en pubspec.yaml y entrada [1.2.4] en artifacts/planning/changelog_v1.md). Por favor, asegúrate de que todos los artefactos de versión y configuración de Gradle utilicen 1.2.4.


## 2026-10-04T21:56:31Z

Requerimiento adicional reportado por el usuario para v1.2.4:
El widget nativo 4x2 (`FoodTrackerWideWidgetProvider`) no carga en el dispositivo del usuario (mientras que el 2x2 sí funciona).
Causa raíz identificada: En `android/app/src/main/res/layout/food_tracker_widget_wide.xml` (y en `lib/assets/android_widgets/food_tracker_widget_wide.xml`) se utilizan etiquetas genéricas `<View>` como separadores/espaciadores (líneas 96, 129 y 197). En Android `RemoteViews`, la clase `android.view.View` está estrictamente prohibida y provoca un `InflateException: Class not allowed to be inflated in RemoteViews: android.view.View`.
Por favor, incluye en las tareas de Frontend/Android para v1.2.4 la sustitución de dichas etiquetas `<View>` por `<FrameLayout>` o `<ImageView>` compatibles con `RemoteViews` para que el widget 4x2 se infle correctamente en todos los launchers de Android.
