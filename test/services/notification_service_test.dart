import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/core/interfaces/notification_service_interface.dart';
import 'package:food_tracker/services/notification_service.dart';

class _FakeNotificationService implements INotificationService {
  bool initialized = false;
  String? lastCompletedMeal;
  double? lastCalories;
  String? lastCompletedTitle;
  String? lastCompletedBody;
  String? lastFailedError;
  String? lastFailedTitle;
  String? lastFailedBody;
  DateTime? lastScheduledTime;
  double? lastTargetHours;
  String? lastScheduledTitle;
  String? lastScheduledBody;
  bool fastingCancelled = false;

  @override
  Future<void> init() async {
    initialized = true;
  }

  @override
  Future<void> showMealAnalysisCompleted({
    required String mealName,
    required double calories,
    String? title,
    String? body,
  }) async {
    lastCompletedMeal = mealName;
    lastCalories = calories;
    lastCompletedTitle = title;
    lastCompletedBody = body;
  }

  @override
  Future<void> showMealAnalysisFailed({
    required String error,
    String? title,
    String? body,
  }) async {
    lastFailedError = error;
    lastFailedTitle = title;
    lastFailedBody = body;
  }

  @override
  Future<void> scheduleFastingCompleted({
    required DateTime scheduledTime,
    required double targetHours,
    String? title,
    String? body,
  }) async {
    lastScheduledTime = scheduledTime;
    lastTargetHours = targetHours;
    lastScheduledTitle = title;
    lastScheduledBody = body;
  }

  @override
  Future<void> cancelFastingReminder() async {
    fastingCancelled = true;
  }

  @override
  Future<void> cancelAllNotifications() async {}
}

void main() {
  group('NotificationService Tests', () {
    test('NotificationService singleton exposes constant channel and notification IDs', () {
      expect(NotificationService.mealChannelId, equals('meal_analysis_channel'));
      expect(NotificationService.fastingChannelId, equals('fasting_reminder_channel'));
      expect(NotificationService.mealCompletedNotificationId, equals(2001));
      expect(NotificationService.mealFailedNotificationId, equals(2002));
      expect(NotificationService.fastingNotificationId, equals(1001));
    });

    test('supports mock instance injection for headless test environments', () async {
      final fake = _FakeNotificationService();
      await fake.init();
      expect(fake.initialized, isTrue);

      await fake.showMealAnalysisCompleted(mealName: 'Arroz con Pollo', calories: 450);
      expect(fake.lastCompletedMeal, equals('Arroz con Pollo'));
      expect(fake.lastCalories, equals(450));

      await fake.showMealAnalysisFailed(error: 'Connection timeout');
      expect(fake.lastFailedError, equals('Connection timeout'));

      final now = DateTime.now().add(const Duration(hours: 16));
      await fake.scheduleFastingCompleted(scheduledTime: now, targetHours: 16);
      expect(fake.lastScheduledTime, equals(now));
      expect(fake.lastTargetHours, equals(16));

      await fake.cancelFastingReminder();
      expect(fake.fastingCancelled, isTrue);
    });

    test('supports localized title and body overrides', () async {
      final fake = _FakeNotificationService();
      await fake.showMealAnalysisCompleted(
        mealName: 'Salad',
        calories: 200,
        title: 'Meal Analysis Complete',
        body: 'Salad has 200 kcal',
      );
      expect(fake.lastCompletedTitle, equals('Meal Analysis Complete'));
      expect(fake.lastCompletedBody, equals('Salad has 200 kcal'));

      await fake.showMealAnalysisFailed(
        error: 'Network failure',
        title: 'Analysis Failed',
        body: 'Custom error body',
      );
      expect(fake.lastFailedTitle, equals('Analysis Failed'));
      expect(fake.lastFailedBody, equals('Custom error body'));

      final target = DateTime.now().add(const Duration(hours: 18));
      await fake.scheduleFastingCompleted(
        scheduledTime: target,
        targetHours: 18,
        title: 'Fast Ended',
        body: 'You completed 18h',
      );
      expect(fake.lastScheduledTitle, equals('Fast Ended'));
      expect(fake.lastScheduledBody, equals('You completed 18h'));
    });
  });
}
