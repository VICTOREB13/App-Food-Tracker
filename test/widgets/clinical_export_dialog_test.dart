import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(find.text('7 días'), findsOneWidget);
    expect(find.text('30 días'), findsOneWidget);
    expect(find.text('90 días'), findsOneWidget);
    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('Exportar CSV'), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);

    // Tap Cerrar dismisses dialog
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.text('Reporte Clínico'), findsNothing);
  });
}
