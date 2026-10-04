import '../../models/nutritional_recommendation.dart';

/// Contract for nutritional analysis and intelligent meal recommendation services.
abstract class INutritionalRecommendationService {
  /// Analyzes past meals across [days] (7, 15, or 30 days) and returns a diagnostic report.
  Future<NutritionalAnalysisReport> analyzeHistory({int days = 7});

  /// Computes remaining calories/macros for today and recommends optimal dishes.
  Future<TodayRecommendationPlan> getWhatShouldIEatToday({DateTime? date});
}
