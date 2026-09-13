import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/widgets/meal_detail/food_image_viewer_dialog.dart';
import 'package:food_tracker/widgets/meal_detail/meal_image_card.dart';

void main() {
  group('MealImageCard & FoodImageViewerScreen Tests', () {
    late Directory tempDir;
    late File testFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('meal_img_card_test_');
      testFile = File('${tempDir.path}/test_meal.jpg');
      await testFile.writeAsString('fake_image_bytes');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('MealImageCard without image shows placeholder and Tomar foto button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealImageCard(
              imagePath: null,
              onPickImage: () {},
            ),
          ),
        ),
      );

      expect(find.text('Sin imagen del plato'), findsOneWidget);
      expect(find.text('Tomar foto'), findsOneWidget);
      expect(find.text('Inspeccionar comida'), findsNothing);
    });

    testWidgets('MealImageCard with valid image displays Cambiar foto and Inspeccionar comida buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealImageCard(
              imagePath: testFile.path,
              dishName: 'Arroz con Pollo',
              onPickImage: () {},
            ),
          ),
        ),
      );

      expect(find.text('Cambiar foto'), findsOneWidget);
      expect(find.text('Inspeccionar comida'), findsOneWidget);
    });

    testWidgets('Tapping Inspeccionar comida opens FoodImageViewerScreen with InteractiveViewer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealImageCard(
              imagePath: testFile.path,
              dishName: 'Arroz con Pollo',
              onPickImage: () {},
            ),
          ),
        ),
      );

      // Tap Inspeccionar comida button
      await tester.tap(find.text('Inspeccionar comida'));
      await tester.pumpAndSettle();

      // Should find FoodImageViewerScreen
      expect(find.byType(FoodImageViewerScreen), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('Arroz con Pollo'), findsOneWidget);
      expect(find.text('Pellizca para ampliar y explorar detalles'), findsOneWidget);

      // Tap close button to pop viewer
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(FoodImageViewerScreen), findsNothing);
    });

    testWidgets('MealImageCard shows analyzing overlay with progress when isAnalyzing is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealImageCard(
              imagePath: testFile.path,
              onPickImage: () {},
              isAnalyzing: true,
              analysisStage: 'Optimizando foto y cubicaje...',
              analysisProgress: 0.45,
            ),
          ),
        ),
      );

      expect(find.text('Optimizando foto y cubicaje...'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
    });
  });
}
