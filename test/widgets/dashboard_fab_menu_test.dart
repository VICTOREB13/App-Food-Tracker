import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/widgets/dashboard/dashboard_fab_menu.dart';

void main() {
  group('DashboardFabMenu Widget Tests', () {
    testWidgets('Tapping FAB opens speed dial modal with action grid', (tester) async {
      bool aiPhotoClicked = false;
      bool barcodeClicked = false;
      bool manualClicked = false;
      bool quickWaterClicked = false;
      bool quickMealClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: DashboardFabMenu(
              onAiPhotoScan: () => aiPhotoClicked = true,
              onBarcodeScan: () => barcodeClicked = true,
              onManualEntry: () => manualClicked = true,
              onQuickWater: () => quickWaterClicked = true,
              onQuickMeal: () => quickMealClicked = true,
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Tap FAB to open modal
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('REGISTRAR COMIDA O ACTIVIDAD'), findsOneWidget);
      expect(find.text('Foto con IA'), findsOneWidget);
      expect(find.text('Galería'), findsOneWidget);
      expect(find.text('Código Barras'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
      expect(find.text('+250ml Agua'), findsOneWidget);
      expect(find.text('Rápida'), findsOneWidget);

      // Tap on '+250ml Agua'
      await tester.tap(find.text('+250ml Agua'));
      await tester.pumpAndSettle();

      expect(quickWaterClicked, isTrue);
    });
  });
}
