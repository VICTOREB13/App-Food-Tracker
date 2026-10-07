import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/meal.dart';
import 'package:food_tracker/services/analysis_queue_service.dart';
import 'package:food_tracker/widgets/common/ve_loading_ring.dart';
import 'package:food_tracker/widgets/dashboard/analysis_progress_banner.dart';

void main() {
  group('AnalysisProgressBanner Widget Tests', () {
    setUp(() {
      AnalysisQueueService.instance.clearAllTasksForTesting();
    });

    tearDown(() {
      AnalysisQueueService.instance.clearAllTasksForTesting();
    });

    testWidgets('AnalysisProgressBanner renders empty when no tasks exist', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalysisProgressBanner(
              onOpenMeal: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(AnalysisProgressBanner), findsOneWidget);
      expect(find.byType(VeLoadingRing), findsNothing);
    });

    testWidgets('AnalysisProgressBanner renders active task with VeLoadingRing and stage', (tester) async {
      final task = AnalysisTask(
        id: 'active-test-task',
        imagePath: '/non/existent/image.jpg',
        mealType: 'Almuerzo',
        date: DateTime.now(),
        status: AnalysisStatus.processing,
        progress: 0.45,
        stage: 'Consultando modelo Gemini...',
      );

      AnalysisQueueService.instance.addTaskForTesting(task);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalysisProgressBanner(
              onOpenMeal: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(AnalysisProgressBanner), findsOneWidget);
      expect(find.byType(VeLoadingRing), findsOneWidget);
      expect(find.text('Consultando modelo Gemini...'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
    });

    testWidgets('AnalysisProgressBanner renders task with rawImageBytes before file is saved', (tester) async {
      final task = AnalysisTask(
        id: 'queued-memory-task',
        imagePath: '',
        rawImageBytes: Uint8List.fromList([
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
          0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
          0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
          0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
          0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
          0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
        ]),
        mealType: 'Desayuno',
        date: DateTime.now(),
        status: AnalysisStatus.processing,
        progress: 0.15,
        stage: 'Comprimiendo imagen...',
      );

      AnalysisQueueService.instance.addTaskForTesting(task);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalysisProgressBanner(
              onOpenMeal: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(AnalysisProgressBanner), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(VeLoadingRing), findsOneWidget);
      expect(find.text('Comprimiendo imagen...'), findsOneWidget);
      expect(find.byKey(const ValueKey('queued-memory-task')), findsOneWidget);
    });

    testWidgets('AnalysisProgressBanner renders completed task with action button', (tester) async {
      Meal? openedMeal;
      final meal = Meal(
        name: 'Arroz con Pollo',
        mealType: 'Almuerzo',
        calories: 550,
      );

      final task = AnalysisTask(
        id: 'completed-test-task',
        imagePath: '/non/existent/image.jpg',
        mealType: 'Almuerzo',
        date: DateTime.now(),
        status: AnalysisStatus.completed,
        progress: 1.0,
        stage: '¡Comida analizada y registrada!',
        resultMeal: meal,
      );

      AnalysisQueueService.instance.addTaskForTesting(task);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalysisProgressBanner(
              onOpenMeal: (m) => openedMeal = m,
            ),
          ),
        ),
      );

      expect(find.text('Arroz con Pollo'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
      expect(openedMeal?.name, equals('Arroz con Pollo'));
    });

    testWidgets('AnalysisProgressBanner renders failed task with retry and manual edit buttons', (tester) async {
      Meal? openedMeal;
      final task = AnalysisTask(
        id: 'failed-test-task',
        imagePath: '/test/photo.jpg',
        mealType: 'Cena',
        date: DateTime.now(),
        status: AnalysisStatus.failed,
        error: 'No se pudo conectar con el servidor',
      );

      AnalysisQueueService.instance.addTaskForTesting(task);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalysisProgressBanner(
              onOpenMeal: (m) => openedMeal = m,
            ),
          ),
        ),
      );

      expect(find.text('No se pudo analizar la foto'), findsOneWidget);
      expect(find.text('No se pudo conectar con el servidor'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Editar manualmente'), findsOneWidget);

      await tester.tap(find.text('Editar manualmente'));
      await tester.pumpAndSettle();

      expect(openedMeal, isNotNull);
      expect(openedMeal?.mealType, equals('Cena'));
    });

    testWidgets('AnalysisProgressBanner renders multiple tasks concurrently without erasing previous failed tasks', (tester) async {
      final failedTask = AnalysisTask(
        id: 'failed-concurrent-task',
        imagePath: '/test/failed_photo.jpg',
        mealType: 'Almuerzo',
        date: DateTime.now(),
        status: AnalysisStatus.failed,
        error: 'Error de análisis en primera comida',
      );

      final activeTask = AnalysisTask(
        id: 'active-concurrent-task',
        imagePath: '/test/active_photo.jpg',
        mealType: 'Cena',
        date: DateTime.now(),
        status: AnalysisStatus.processing,
        progress: 0.50,
        stage: 'Consultando modelo Gemini...',
      );

      AnalysisQueueService.instance.addTaskForTesting(failedTask);
      AnalysisQueueService.instance.addTaskForTesting(activeTask);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalysisProgressBanner(
              onOpenMeal: (_) {},
            ),
          ),
        ),
      );

      // Verify both tasks are rendered concurrently on screen
      expect(find.text('No se pudo analizar la foto'), findsOneWidget);
      expect(find.text('Error de análisis en primera comida'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Editar manualmente'), findsOneWidget);

      expect(find.text('Analizando en segundo plano'), findsOneWidget);
      expect(find.text('Consultando modelo Gemini...'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.byType(VeLoadingRing), findsOneWidget);
    });
  });
}
