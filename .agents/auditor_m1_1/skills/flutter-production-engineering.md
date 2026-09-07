# flutter-production-engineering (Local Copy)
Source: C:\Users\vmesp\.gemini\config\skills\flutter-production-engineering\SKILL.md

Comprehensive production engineering guide for Flutter applications:
1. Screen & Controller line count < 300 LoC per file.
2. Modular decomposition in `lib/widgets/<domain>/`.
3. Safe controller lifecycles in `StatefulWidget` (initState/dispose).
4. No synchronous file I/O in `build()`.
5. Modern Flutter: `color.withValues(alpha: ...)`, `DropdownButtonFormField(initialValue: ...)`.
6. Zero massive RAM filtering.
