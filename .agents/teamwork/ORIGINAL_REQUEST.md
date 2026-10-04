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
