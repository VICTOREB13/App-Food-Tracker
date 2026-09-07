---
name: flutter-production-engineering
description: Comprehensive production engineering guide for Flutter applications. Use whenever designing, building, refactoring, or debugging Flutter cross-platform apps (Windows, Android, iOS, Web). Covers monolithic screen decomposition (<300 LoC), 60 FPS rendering, memory leak prevention (controllers/images), modern Flutter standards (withValues, initialValue), and native CI/CD pipelines (Gradle 8/9, Kotlin DSL, compileSdk alignment, MSVC toolchains).
license: MIT
metadata:
  author: Victor Engineer
  version: "1.0.0"
  tags: [flutter, performance, architecture, modularization, clean-code, gradle, android, windows, ci-cd]
---

# Flutter Production Engineering

Guía exhaustiva de ingeniería, arquitectura y rendimiento para aplicaciones Flutter en producción multiplataforma (Windows y Android). Basada en lecciones aprendidas en proyectos reales con miles de líneas de código refactorizadas, resolución de cuellos de botella y superación de gates de calidad estrictos.

---

## 1. Principios Arquitectónicos y Descomposición de Monolitos

### 1.1 La Regla de Oro: Pantallas Orquestadoras (< 300 LoC)
Las pantallas principales (`screens/`) no deben contener lógica de presentación profunda, widgets hijos masivos ni llamadas HTTP directas.
* **Función exclusiva de la pantalla:** Conectar el ciclo de vida (`initState`, `dispose`), escuchar estados (Streams/ChangeNotifiers), orquestar la persistencia con la capa de servicios y ensamblar subwidgets modulares.
* **Límite mandatorio:** Ningún archivo de pantalla debe superar las **300 Líneas de Código (LoC)**. Si supera ese límite, debe descomponerse inmediatamente.

### 1.2 Anatomía de Descomposición Modular
Separa cada pantalla en submódulos cohesivos dentro de `lib/views/widgets/<dominio>/`:
* **App Bars & Monogramas:** Componente desacoplado que implementa `PreferredSizeWidget`. Conserva la identidad visual del autor (`VE` para Victor Engineer) en el monograma SVG/Contenedor.
* **Barras de Filtros:** Chips de estado y dropdowns de taxonomía adaptativos (2 filas en móvil, 1 fila en desktop).
* **Vistas de Datos & Grids:** Separar la tarjeta de cuadrícula (`GameCardGrid`), la fila de lista (`GameCardList`), el Hero principal (`HeroSpotlightCard`) y el Shimmer placeholder (`DashboardSkeletonGrid`).
* **Barras de Navegación y Docks Integrados:** Nunca dejes un botón de acción flotante (FAB) colisionando o desacoplado de los controles de paginación. Unifica paginación, selector de tamaño de página y acción rápida ("+ Añadir") en un dock inferior cohesivo (`bottomNavigationBar`).

### 1.3 Prevención de Fugas de Memoria en Diálogos y Modales
* **Nunca** instancies controladores (`TextEditingController`, `ScrollController`, `AnimationController`) dentro de métodos de construcción de diálogos (`showDialog`, `showModalBottomSheet`) sin un ciclo de vida cerrado.
* **Patrón Obligatorio:** Extrae el contenido del diálogo a un `StatefulWidget` independiente donde cada controlador se inicialice en `initState()` y se libere estrictamente en `dispose()`.

---

## 2. Rendimiento a 60 FPS y Gestión de Memoria

### 2.1 Carga Eficiente de Imágenes y Portadas (`AppCoverImage`)
* **Prohibido el I/O síncrono en `build()`:** Nunca ejecutes `File(path).existsSync()` dentro de un método `build()`, ya que bloquea el hilo de renderizado y provoca micro-tirones (jank).
* **Caché Inteligente por Ancho (Aspect Ratio Natural):**
  Al limitar el tamaño de texturas en memoria con `CachedNetworkImage` o `ResizeImage`:
  * Configura `cacheWidth: 600` (o `memCacheWidth: 600`).
  * Deja `cacheHeight = null` (o `memCacheHeight = null`).
  * *Razón:* Al dejar la altura nula, el motor de decodificación de Flutter escala la imagen preservando exactamente su relación de aspecto nativa (16:9, banners de Steam, 2:3), evitando deformaciones o compresiones visuales.
* **Uso de `errorBuilder` y `placeholder`:** Todo cargador de imagen debe contemplar estados de carga elegantes y fallbacks ante rutas locales rotas o URLs caídas.

### 2.2 Aislamiento de Repintado (`RepaintBoundary`)
* Coloca `RepaintBoundary` alrededor de:
  1. Indicadores de pulso continuo o animaciones cíclicas (ej. badge "Jugando").
  2. Efectos shimmer y esqueletos de carga.
  3. Contenedores que se capturan como imagen en memoria (`RenderRepaintBoundary.toImage()`).

### 2.3 Cero Filtrado Masivo en Memoria RAM
* Nunca uses `list.where(...)` en Dart sobre colecciones de cientos o miles de elementos en cada reconstrucción de frame.
* Delega todo filtrado por estado, plataforma, búsqueda de texto y ordenamiento a la base de datos subyacente (SQLite / Engine).

---

## 3. Estándares Modernos de Flutter (Flutter 3.27+ / 3.29+ / 3.47+)

### 3.1 Manipulación Cromática de Alta Precisión (`withValues`)
* En Flutter 3.27+, el método `.withOpacity(double)` quedó formalmente deprecado para evitar pérdida de precisión y artefactos sRGB.
* **Reemplazo Obligatorio:**
  ```dart
  // ❌ DEPRECADO
  color.withOpacity(0.5)

  // ✅ ESTÁNDAR MODERNO
  color.withValues(alpha: 0.5)
  ```

### 3.2 Formularios y Campos Desplegables
* En `DropdownButtonFormField`, el parámetro `value:` está deprecado en versiones modernas.
* **Reemplazo Obligatorio:**
  ```dart
  // ❌ DEPRECADO
  DropdownButtonFormField<String>(value: selectedItem, ...)

  // ✅ ESTÁNDAR MODERNO
  DropdownButtonFormField<String>(initialValue: selectedItem, ...)
  ```

### 3.3 Calibración de Linter y Brechas Asíncronas
* **Async Context Safety:** Tras cualquier `await`, protege el uso de `BuildContext` o `Navigator`:
  ```dart
  final result = await showDialog<bool>(...);
  if (!context.mounted) return;
  // o dentro de un State:
  if (!mounted) return;
  ```
* **Tipado Estricto de Futuros y Navegación:**
  * Usa `showDialog<void>`, `showModalBottomSheet<void>`, `MaterialPageRoute<void>`.
  * Usa `unawaited(...)` de `dart:async` para futuros en segundo plano intencionales que no deban bloquear el flujo.
  * Usa `Future<void>.delayed(...)` con su tipo genérico explícito.

---

## 4. Pipeline de CI/CD y Toolchains Nativos (Windows & Android)

### 4.1 Compilación Nativa en Windows Desktop (MSVC)
* **Visual Studio 2022:** Asegúrate de que el runner use `windows-latest` y no fuerces generadores heredados (`Visual Studio 16 2019`).
* Permite que Flutter y CMake seleccionen automáticamente el toolchain nativo de MSVC en el runner de GitHub Actions.

### 4.2 Android Gradle Plugin (AGP 8.x/9.x) y Kotlin DSL (`.kts`)
A partir de Flutter 3.29+, los proyectos generan `build.gradle.kts` y `settings.gradle.kts` (Kotlin DSL) por defecto:
1. **Conflicto de AAR Metadata (`compileSdk 36` vs `android-34`):**
   * Dependencias modernas (ej. `:flutter_plugin_android_lifecycle`) exigen compilar contra `compileSdk 36`.
   * Librerías de terceros antiguas (ej. `file_picker` en Groovy) traen hardcodeado `compileSdkVersion 34`.
2. **Lo que NUNCA debes hacer:**
   * ❌ **Desactivar la tarea `CheckAarMetadata` (`enabled = false`):** En Gradle 9, la tarea `bundleReleaseLocalLintAar` exige obligatoriamente la carpeta de salida generada por `checkReleaseAarMetadata`. Si la desactivas, la compilación fallará con:
     `property 'aarMetadataCheck' specifies directory ... which doesn't exist`.
   * ❌ **Inyectar `subprojects { afterEvaluate { ... } }` en el `build.gradle.kts` raíz:** En AGP 8+ y Gradle 9, el plugin loader de Flutter evalúa los proyectos anticipadamente, causando la excepción fatal:
     `Cannot run Project.afterEvaluate(Action) when the project is already evaluated`.
3. **La Solución Canónica y Robusta:**
   * **Inyectar propiedades globales de Gradle en `~/.gradle/gradle.properties`:**
     ```bash
     mkdir -p ~/.gradle
     echo "compileSdkVersion=36" >> ~/.gradle/gradle.properties
     echo "compileSdk=36" >> ~/.gradle/gradle.properties
     echo "flutter.compileSdkVersion=36" >> ~/.gradle/gradle.properties
     ```
     Todas las librerías que consulten `project.hasProperty('compileSdkVersion')` recibirán `36` globalmente.
   * **Parcheo seguro en `pub-cache`:**
     ```bash
     find "$HOME/.pub-cache" -name "build.gradle" -exec sed -i -E 's/compileSdkVersion[ (].*/compileSdkVersion 36/g' {} + 2>/dev/null || true
     find "$HOME/.pub-cache" -name "build.gradle" -exec sed -i -E 's/compileSdk [0-9]+/compileSdk 36/g' {} + 2>/dev/null || true
     ```
     *Nota Crítica de Regex:* Usa siempre `[0-9]+` (uno o más dígitos) o patrones estrictos. Nunca uses `[0-9]*` porque coincidirá con cadenas vacías en archivos Kotlin DSL corrompiendo líneas como `compileSdk = flutter.compileSdkVersion`.

---

## 5. Checklist de Verificación Pre-Release (Quality Gate)
- [ ] Conteo de LoC verificado: Ninguna pantalla monolítica supera las 300 LoC.
- [ ] `flutter analyze` pasa con 0 errores y 0 warnings sin necesidad de ignorar reglas estándar.
- [ ] Cero uso de `.withOpacity()`, reemplazado por `.withValues(alpha: ...)`.
- [ ] Todos los `DropdownButtonFormField` usan `initialValue:`.
- [ ] Monograma oficial del autor (`VE`) preservado en AppBar y tarjetas sociales.
- [ ] `flutter test` pasa al 100% de forma determinista offline con mocks de red.
- [ ] Flujo de GitHub Actions compila tanto Fat APK (Android) como ejecutable x64 (Windows).
