abstract class INotificationService {
  Future<void> init();

  Future<void> showMealAnalysisCompleted({
    required String mealName,
    required double calories,
    String? title,
    String? body,
  });

  Future<void> showMealAnalysisFailed({
    required String error,
    String? title,
    String? body,
  });

  Future<void> scheduleFastingCompleted({
    required DateTime scheduledTime,
    required double targetHours,
    String? title,
    String? body,
  });

  Future<void> cancelFastingReminder();

  Future<void> cancelAllNotifications();
}
