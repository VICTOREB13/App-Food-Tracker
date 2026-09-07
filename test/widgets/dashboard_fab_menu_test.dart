import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/widgets/dashboard/dashboard_fab_menu.dart';

void main() {
  group('DashboardFabMenu Widget Tests', () {
    Widget buildTestWidget({
      VoidCallback? onAiPhotoScan,
      VoidCallback? onGalleryScan,
      VoidCallback? onBarcodeScan,
      VoidCallback? onManualEntry,
      VoidCallback? onQuickWater,
      VoidCallback? onQuickMeal,
    }) {
      return MaterialApp(
        home: Scaffold(
          floatingActionButton: DashboardFabMenu(
            onAiPhotoScan: onAiPhotoScan ?? () {},
            onGalleryScan: onGalleryScan,
            onBarcodeScan: onBarcodeScan ?? () {},
            onManualEntry: onManualEntry ?? () {},
            onQuickWater: onQuickWater,
            onQuickMeal: onQuickMeal,
          ),
        ),
      );
    }

    testWidgets('Tapping FAB opens speed dial modal with action grid', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool quickWaterClicked = false;

      await tester.pumpWidget(
        buildTestWidget(
          onQuickWater: () => quickWaterClicked = true,
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
      expect(find.text('REGISTRAR COMIDA O ACTIVIDAD'), findsNothing);
    });

    testWidgets('Tapping Foto con IA triggers onAiPhotoScan and closes modal', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool clicked = false;
      await tester.pumpWidget(buildTestWidget(onAiPhotoScan: () => clicked = true));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Foto con IA'));
      await tester.pumpAndSettle();

      expect(clicked, isTrue);
      expect(find.text('REGISTRAR COMIDA O ACTIVIDAD'), findsNothing);
    });

    testWidgets('Tapping Galería triggers onGalleryScan callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool clicked = false;
      await tester.pumpWidget(buildTestWidget(onGalleryScan: () => clicked = true));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Galería'));
      await tester.pumpAndSettle();

      expect(clicked, isTrue);
      expect(find.text('REGISTRAR COMIDA O ACTIVIDAD'), findsNothing);
    });

    testWidgets('Tapping Código Barras triggers onBarcodeScan callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool clicked = false;
      await tester.pumpWidget(buildTestWidget(onBarcodeScan: () => clicked = true));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Código Barras'));
      await tester.pumpAndSettle();

      expect(clicked, isTrue);
      expect(find.text('REGISTRAR COMIDA O ACTIVIDAD'), findsNothing);
    });

    testWidgets('Tapping Manual triggers onManualEntry callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool clicked = false;
      await tester.pumpWidget(buildTestWidget(onManualEntry: () => clicked = true));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Manual'));
      await tester.pumpAndSettle();

      expect(clicked, isTrue);
      expect(find.text('REGISTRAR COMIDA O ACTIVIDAD'), findsNothing);
    });

    testWidgets('Tapping Rápida triggers onQuickMeal callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool clicked = false;
      await tester.pumpWidget(buildTestWidget(onQuickMeal: () => clicked = true));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rápida'));
      await tester.pumpAndSettle();

      expect(clicked, isTrue);
      expect(find.text('REGISTRAR COMIDA O ACTIVIDAD'), findsNothing);
    });

    testWidgets('Tapping Close icon dismisses modal without triggering callbacks', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool anyClicked = false;
      await tester.pumpWidget(
        buildTestWidget(
          onAiPhotoScan: () => anyClicked = true,
          onBarcodeScan: () => anyClicked = true,
          onManualEntry: () => anyClicked = true,
          onQuickWater: () => anyClicked = true,
          onQuickMeal: () => anyClicked = true,
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('REGISTRAR COMIDA O ACTIVIDAD'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(anyClicked, isFalse);
      expect(find.text('REGISTRAR COMIDA O ACTIVIDAD'), findsNothing);
    });
  });
}
