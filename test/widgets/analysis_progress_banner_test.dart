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
  });
}
