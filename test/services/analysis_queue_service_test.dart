import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/meal.dart';
import 'package:food_tracker/services/analysis_queue_service.dart';

void main() {
  group('AnalysisTask & AnalysisQueueService Tests', () {
    setUp(() {
      AnalysisQueueService.instance.clearAllTasksForTesting();
    });

    tearDown(() {
      AnalysisQueueService.instance.clearAllTasksForTesting();
    });

    test('AnalysisTask initializes with correct defaults and isPending flag', () {
      final task = AnalysisTask(
        imagePath: '/tmp/fake_meal.jpg',
        mealType: 'Almuerzo',
        date: DateTime(2026, 9, 12),
      );

      expect(task.id, isNotEmpty);
      expect(task.status, equals(AnalysisStatus.queued));
      expect(task.progress, equals(0.05));
      expect(task.isPending, isTrue);
      expect(task.error, isNull);
      expect(task.resultMeal, isNull);
      expect(task.imagePath, equals('/tmp/fake_meal.jpg'));
    });

    test('AnalysisTask transitions through states correctly', () {
      final task = AnalysisTask(
        imagePath: '/tmp/fake_meal.jpg',
        mealType: 'Cena',
        date: DateTime(2026, 9, 12),
      );

      // Processing
      task.status = AnalysisStatus.processing;
      task.progress = 0.50;
      task.stage = 'Desglosando ingredientes...';
      expect(task.isPending, isTrue);

      // Completed
      task.status = AnalysisStatus.completed;
      task.progress = 1.0;
      task.stage = '¡Completado!';
      task.resultMeal = Meal(name: 'Ensalada César', mealType: 'Cena');
      expect(task.isPending, isFalse);
      expect(task.resultMeal?.name, equals('Ensalada César'));

      // Failed
      task.status = AnalysisStatus.failed;
      task.error = 'Error de conexión';
      expect(task.isPending, isFalse);
      expect(task.error, equals('Error de conexión'));
    });

    test('AnalysisQueueService dismissTask and clearCompleted update in-memory tasks', () async {
      final service = AnalysisQueueService.instance;
      final task1 = AnalysisTask(
        id: 'test-task-1',
        imagePath: '/tmp/test1.jpg',
        mealType: 'Desayuno',
        date: DateTime.now(),
        status: AnalysisStatus.completed,
      );
      final task2 = AnalysisTask(
        id: 'test-task-2',
        imagePath: '/tmp/test2.jpg',
        mealType: 'Almuerzo',
        date: DateTime.now(),
        status: AnalysisStatus.queued,
      );

      service.addTaskForTesting(task1);
      service.addTaskForTesting(task2);

      expect(service.tasks.length, equals(2));
      expect(service.activeTasks.length, equals(1));
      expect(service.currentActiveTask?.id, equals('test-task-2'));

      await service.dismissTask('test-task-2');
      expect(service.tasks.any((t) => t.id == 'test-task-2'), isFalse);

      await service.clearCompleted();
      expect(service.tasks.any((t) => t.id == 'test-task-1'), isFalse);
    });
  });
}
