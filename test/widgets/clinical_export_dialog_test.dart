import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/l10n/app_localizations.dart';
import 'package:food_tracker/widgets/metrics/clinical_export_dialog.dart';

void main() {
  testWidgets('showClinicalExportDialog renders dialog with range choices', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showClinicalExportDialog(context),
              child: const Text('Open Export Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Export Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Reporte Clínico'), findsOneWidget);
    expect(find.text('CSV (Excel)'), findsOneWidget);
    expect(find.text('PDF Clínico'), findsOneWidget);
    expect(find.text('7 días'), findsOneWidget);
    expect(find.text('30 días'), findsOneWidget);
    expect(find.text('90 días'), findsOneWidget);
    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('Exportar CSV'), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);

    // Switch format to PDF
    await tester.tap(find.text('PDF Clínico'));
    await tester.pumpAndSettle();
    expect(find.text('Exportar PDF'), findsOneWidget);

    // Tap Cerrar dismisses dialog
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.text('Reporte Clínico'), findsNothing);
  });

  testWidgets('showClinicalExportDialog renders localized strings in English', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showClinicalExportDialog(context),
              child: const Text('Open Export Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Export Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Clinical Report'), findsOneWidget);
    expect(find.text('Report format:'), findsOneWidget);
    expect(find.text('CSV (Excel)'), findsOneWidget);
    expect(find.text('Clinical PDF'), findsOneWidget);
    expect(find.text('Time range:'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });
}
