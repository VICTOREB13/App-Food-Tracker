import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/widgets/dashboard/voice_meal_recording_dialog.dart';

void main() {
  testWidgets('showVoiceMealRecordingDialog renders recording dialog and allows text entry', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showVoiceMealRecordingDialog(context),
              child: const Text('Open Voice Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Voice Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Dictado por Voz'), findsOneWidget);
    expect(find.byIcon(Icons.mic_none), findsWidgets);
    expect(find.text('Analizar con IA'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);

    // Enter meal text directly
    await tester.enterText(find.byType(TextField), 'Omelette con queso y espinaca');
    expect(find.text('Omelette con queso y espinaca'), findsOneWidget);

    // Cancel closes dialog
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Dictado por Voz'), findsNothing);
  });
}
