# Flutter Production Engineering (Local Dump)
- Source: C:\Users\vmesp\.gemini\config\skills\flutter-production-engineering\SKILL.md
- Core methodology: Monolithic screen decomposition (<300 LoC), 60 FPS rendering, memory leak prevention (controllers/images), modern Flutter standards (withValues, initialValue), and native CI/CD pipelines.
- Rules applied:
  1. Screens strictly < 300 LoC.
  2. Dialogs extract state to StatefulWidget with proper controller dispose.
  3. Strict use of `.withValues(alpha: ...)`, no `.withOpacity(...)`.
  4. Context mounted checks after async gaps.
