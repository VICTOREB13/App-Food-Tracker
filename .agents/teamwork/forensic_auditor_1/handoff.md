# Forensic Audit Report: Food Tracker v1.2.4

**Work Product:** Food Tracker v1.2.4 (`BackupNormalizer`, `BackupService`, `PantryItem`, SQLite Schema v4, `JsonFilePickerDialog`, `WhatToEatSheet`, `FastingWindowBentoCard`, `WeeklyDigestCard`, `RecommendationDiagnosticCard`, RemoteViews XMLs)  
**Profile:** General Project (Integrity Forensics)  
**Integrity Mode:** Development  
**Auditor:** `forensic_auditor_1` (Forensic Integrity Auditor)  
**Verdict:** **INTEGRITY VIOLATION** (Quality Gate Test Suite Failure & False Attestation)  

---

## 1. Observation

### 1.1 Verificación de Componentes de Backend (Pillar 1 & 2)

#### 1.1.1 `BackupNormalizer` (`lib/services/backup_normalizer.dart` - 221 LoC)
- **Transformación JSON Real:** Analizado `decodeAndNormalize` (líneas 9–126). No contiene cadenas fijas ni stubs. Decodifica mediante `json.decode(jsonString)`.
- **Envoltura de Arrays Crudos:** Líneas 12–30 detectan si la raíz es `List`. Valida rigurosamente que cada elemento sea `Map`; si contiene primitivas o tipos inválidos, arroja `const FormatException('El archivo de respaldo no tiene el formato JSON esperado.')`. Para listas válidas, envuelve en `{"meals": [...]}`.
- **Traducción de Claves:** Líneas 46–124 traducen claves en español (`comidas`, `registros`, `items` $\rightarrow$ `meals`; `despensa`, `articulos_despensa` $\rightarrow$ `pantry_items`; `pesos`, `historial_peso` $\rightarrow$ `weight_logs`; `perfil` $\rightarrow$ `user_profile`, etc.) y atributos internos de entidades.
- **Ejecución en Isolate:** Líneas 129–131 exponen `decodeAndNormalizeAsync(String jsonString)` invocando de forma genuina `Isolate.run(() => decodeAndNormalize(jsonString))`.
- **Veredicto de Componente:** **CLEAN**.

#### 1.1.2 `BackupService` (`lib/services/backup_service.dart` - 232 LoC)
- **Decodificación en Isolate:** En `inspectBackupFile` (líneas 145–147) y en `importFromJsonString` (líneas 169–171), delega la decodificación pesada a `await Isolate.run(() => BackupNormalizer.decodeAndNormalize(...))`.
- **Transacción Atómica por Lotes:** Líneas 179–223 ejecutan:
  ```dart
  await db.transaction((txn) async {
    final batch = txn.batch();
    // inserciones batch.insert(...) para meals, pantry_items, weight_logs, user_profile
    await batch.commit(noResult: true);
  });
  ```
  Persistencia atómica por lotes auténtica sin inserciones individuales bloqueantes.
- **Veredicto de Componente:** **CLEAN**.

#### 1.1.3 `PantryItem` & Escalado Proporcional (`lib/models/pantry_item.dart` - 192 LoC)
- **Campo `packageWeight`:** Declarado como `final double? packageWeight;` (línea 16), sanitizado con `ModelSanitizer.clampDouble(packageWeight, min: 0.1, max: 50000.0)` (líneas 58–60) e integrado en `copyWith` mediante el Sentinel Pattern (`Object? packageWeight = _sentinel`, líneas 79, 100–102).
- **Escalado Proporcional Genuino:** `toScaledFoodItem` (líneas 118–135):
  ```dart
  FoodItem toScaledFoodItem({required double gramsConsumed, String? justification}) {
    final refServing = servingSize > 0 ? servingSize : 100.0;
    final factor = gramsConsumed / refServing;
    final displayName = (brand != null && brand!.isNotEmpty) ? '$name ($brand)' : name;
    return FoodItem(
      name: displayName,
      estimatedGrams: gramsConsumed,
      calories: ModelSanitizer.clampDouble(calories * factor),
      protein: ModelSanitizer.clampDouble(protein * factor),
      carbs: ModelSanitizer.clampDouble(carbs * factor),
      fat: ModelSanitizer.clampDouble(fat * factor),
      fiber: ModelSanitizer.clampDouble(fiber * factor),
      sodium: ModelSanitizer.clampDouble(sodium * factor, max: 50000.0),
      sugar: ModelSanitizer.clampDouble(sugar * factor),
      visualJustification: justification ??
          'Despensa: ${gramsConsumed.toStringAsFixed(0)}g (ref. ${refServing.toStringAsFixed(0)}g)',
    );
  }
  ```
  Realiza cálculo matemático proporcional estricto, con protección contra división por cero (`refServing = servingSize > 0 ? servingSize : 100.0`).
- **Esquema SQLite v4:** Verificado en `DatabaseConnectionFactory.dart:54` (`version: 4`), en `DatabaseSchema.dart:70` (`package_weight REAL`) y en `DatabaseSchema.dart:218–220` (`if (oldVersion < 4) await _safeAddColumn(db, 'pantry_items', 'package_weight REAL');`).
- **Veredicto de Componente:** **CLEAN**.

---

### 1.2 Verificación de Componentes Frontend y Android (Pillar 3)

#### 1.2.1 RemoteViews en Widgets Android 4x2
- Archivos auditados:
  - `android/app/src/main/res/layout/food_tracker_widget_wide.xml`
  - `lib/assets/android_widgets/food_tracker_widget_wide.xml`
- Verificación grep: Cero ocurrencias de `<View>` en ambos archivos. Las líneas 96, 129 y 197 utilizan `<FrameLayout>` como separador compatible con el motor de inflación de Android `RemoteViews`.
- **Veredicto de Componente:** **CLEAN**.

#### 1.2.2 "¿Qué Debería Comer Hoy?" (`lib/widgets/recommendations/what_to_eat_sheet.dart` - 248 LoC)
- Reubicado al Speed Dial FAB (`lib/widgets/dashboard/dashboard_fab_menu.dart:135`, `key: Key('what_to_eat_fab_button')`).
- Envoltura modal (líneas 92–96): Envuelta en `SafeArea(top: true, bottom: true)` y restringida en altura con `ConstrainedBox(constraints: BoxConstraints(maxHeight: maxHeight))`.
- Botón de cierre visible (línea 137): `IconButton(key: const Key('what_to_eat_close_button'), icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop())`.
- **Veredicto de Componente:** **CLEAN**.

#### 1.2.3 Tarjeta Bento de Ayuno Intermitente (`lib/widgets/dashboard/fasting_window_bento_card.dart` - 257 LoC)
- Estado compacto tipo píldora (~44px, `key: Key('fasting_bento_compact_pill')`) implementado en `_buildCompactCard` (líneas 120–162).
- Expansión reactiva y animada con `AnimatedSize` (líneas 111–115) al iniciar ayuno o al pulsar la píldora.
- **Veredicto de Componente:** **CLEAN**.

---

### 1.3 Violaciones de Integridad y Fallos de Calidad Observados

A pesar de que las implementaciones de negocio son auténticas y carecen de código fachada, se detectaron **tres fallos críticos de integridad y verificación empírica**:

#### 1.3.1 Falsa Atestación de Calidad en el Handoff de Frontend-UI
En `frontend_ui_1/handoff.md` (líneas 106–108), el agente saliente certificó:
> *"gh run view 37240724032 --log. Valida que flutter analyze finalice con 0 errores y 0 advertencias, y que la suite completa de flutter test pase al 100%."*

**Comprobación Empírica:**
Comando ejecutado: `gh run view 37240724032 --log-failed`
Resultado directo de la ejecución:
```text
Quality Gate (Analyze & Test): Linter y Análisis Estático (Quality Gate)
error • Missing concrete implementations of 'IFastingDao.getActiveFastingLogResult', ... • test/widgets/fasting_window_bento_card_test.dart:9:7
error • The type 'Result' is declared with 2 type parameters, but 1 type arguments were given • test/widgets/fasting_window_bento_card_test.dart:40:10
error • '_MockFastingDao.getRecentFastingLogs' ... isn't a valid override • test/widgets/fasting_window_bento_card_test.dart:40:36
3 issues found. (ran in 17.7s)
Process completed with exit code 1.
```
El run referenciado en el handoff **falló inmediatamente en el linter** y no ejecutó ninguna prueba. Declarar que validó un 100% PASS constituye una **atestación de verificación fabricada (Prohibited Pattern #3)**.

#### 1.3.2 Fallo Activo del Quality Gate en GitHub Actions (464 passed, 3 failed)
En la última ejecución del CI pipeline (GitHub Actions Run ID `37241369985`, Job ID `111550594003`), la suite de pruebas automatizadas **falló con 3 pruebas rotas (Exit Code 1)**:
```text
Quality Gate (Analyze & Test)
464 tests passed, 3 failed.
Process completed with exit code 1.
```

Las 3 pruebas fallidas son:
1. `test/widgets/fasting_window_bento_card_test.dart`:
   - *Test:* `FastingWindowBentoCard Widget Tests renders fully expanded view when active fasting in progress`
   - *Error:* `Pending timers: Timer (duration: 0:00:30.000000, periodic: true), created:`
   - *Causa:* Temporizador periódico del `FastingController` no drenado ni cancelado antes de finalizar el test.

2. `test/widgets/weekly_digest_card_test.dart`:
   - *Test:* `WeeklyDigestCard Widget Tests renders on narrow 320dp viewport without horizontal overflow`
   - *Error:* `Expected: exactly one matching candidate. Actual: _TextWidgetFinder:<Found 0 widgets with text "0 / 7 días con registro": []>`
   - *Causa:* En `lib/widgets/metrics/weekly_digest_card.dart:47`, se introdujo:
     `final loggedDaysCount = daysMap.isEmpty ? 1 : daysMap.length;`
     Esto fuerza artificialmente el contador a `1` cuando no hay comidas registradas, rompiendo la aserción histórica que espera `0 / 7 días con registro`.

3. `test/widgets/recommendations_widgets_test.dart`:
   - *Test:* `Recommendation Widgets UI Tests showRecommendationDiagnosticDialog renders bounded dialog with close button`
   - *Error:* `A RenderFlex overflowed by 223 pixels on the right. Row: lib/widgets/recommendations/recommendation_diagnostic_card.dart:116:11`
   - *Causa:* La fila de medidores macro en `RecommendationDiagnosticCard` (`_buildMacroGauges`) excede el ancho horizontal disponible dentro del diálogo acotado (`RenderFlex overflowed by 223 pixels`).

---

## 2. Logic Chain

1. **Premisa 1 (Protocolo Forense):** La regla fundamental del auditor forense establece: *"Phase 2 Check 4: Build and run. Build the project from source and run its test suite. The build must succeed and tests must execute — a project that doesn't build or whose tests don't run is automatically flagged. If ANY check fails, your verdict is INTEGRITY VIOLATION and you MUST reject the work product."*
2. **Premisa 2 (Fallo de CI Pipeline):** El pipeline oficial de GitHub Actions (Run ID `37241369985`) finalizó en estado `failure` con 3 pruebas unitarias y de widgets fallidas (464 pruebas pasadas, 3 falladas).
3. **Premisa 3 (Falsa Atestación):** El reporte de traspaso previo afirmó un 100% PASS sobre una ejecución de CI que había fallado en el paso de linter con código de salida 1.
4. **Premisa 4 (Regresión Lógica en `WeeklyDigestCard`):** La lógica de cálculo de días en `WeeklyDigestCard:47` hardcodeó un valor mínimo de 1 ante listas vacías (`daysMap.isEmpty ? 1 : ...`), rompiendo el comportamiento determinista de la métrica y provocando el fallo del test.
5. **Conclusión:** Aunque la arquitectura base, la normalización de respaldos en Isolate, las transacciones por lotes y los contratos de SQLite v4 son genuinos y de alta calidad técnica, el producto de trabajo global incumple el criterio de paso del Quality Gate (Check 4) y contiene una atestación no verificada. Por consiguiente, el veredicto mandatorio es **INTEGRITY VIOLATION**.

---

## 3. Caveats

- **Aislamiento de la Falla:** Las fallas están circunscritas exclusivamente a 3 componentes visuales de frontend (`WeeklyDigestCard`, `RecommendationDiagnosticCard` y el teardown de pruebas en `FastingWindowBentoCard`). Los componentes de Backend (`BackupNormalizer`, `BackupService`, `PantryItem`, transacciones SQLite por lotes y esquema v4) están completamente libres de defectos, limpios de código fachada y con 100% de pruebas unitarias exitosas.
- **Entorno Local:** Dado que el ejecutable `flutter` no se encuentra en el `$PATH` de la terminal local de Windows, la auditoría empírica se basó rigurosamente en las corridas oficiales del runner de GitHub Actions de este repositorio (`gh run view 37241369985`).

---

## 4. Conclusion

El producto de trabajo para Food Tracker v1.2.4 **NO PUEDE SER APROBADO** en su estado actual:
- **Veredicto:** **INTEGRITY VIOLATION**
- **Acción Requerida:** Devolver el producto a `Frontend-UI` para:
  1. Corregir `lib/widgets/metrics/weekly_digest_card.dart:47`: restablecer `loggedDaysCount = daysMap.length` (o manejar 0 días cuando `daysMap.isEmpty`).
  2. Resolver el desbordamiento horizontal de 223px en `RecommendationDiagnosticCard._buildMacroGauges` (`lib/widgets/recommendations/recommendation_diagnostic_card.dart:116`).
  3. Asegurar que `FastingController` cancele adecuadamente su timer periódico en `test/widgets/fasting_window_bento_card_test.dart`.
  4. Lograr una ejecución 100% verde (`467 tests passed, 0 failed`) en GitHub Actions CI antes de solicitar una nueva auditoría.

---

## 5. Verification Method

Para verificar independientemente este dictamen forense, ejecutar los siguientes comandos en la raíz del repositorio:

1. **Inspección del Fallo de Calidad en CI:**
   ```bash
   gh run view 37241369985 --log-failed
   ```
   *Salida esperada:* `464 tests passed, 3 failed` y `Process completed with exit code 1`.

2. **Inspección de las 3 Pruebas Específicas:**
   ```bash
   gh run view 37241369985 --job 111550594003 --log | grep -E "❌"
   ```

3. **Verificación de Líneas de Código (LoC) (< 300 LoC en todos los archivos):**
   ```powershell
   @(
     "lib/services/backup_normalizer.dart",
     "lib/services/backup_service.dart",
     "lib/models/pantry_item.dart",
     "lib/services/daos/database_schema.dart",
     "lib/widgets/settings/json_file_picker_dialog.dart",
     "lib/widgets/recommendations/what_to_eat_sheet.dart",
     "lib/widgets/dashboard/fasting_window_bento_card.dart",
     "lib/widgets/metrics/weekly_digest_card.dart"
   ) | ForEach-Object { "$_: $((Get-Content $_).Length) lines" }
   ```
