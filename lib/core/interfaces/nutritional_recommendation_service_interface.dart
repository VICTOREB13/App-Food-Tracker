import '../../models/nutritional_recommendation.dart';

/// Contract for nutritional analysis and intelligent meal recommendation services.
abstract class INutritionalRecommendationService {
  /// Analyzes past meals across [days] (7, 15, or 30 days) and returns a diagnostic report.
  Future<NutritionalAnalysisReport> analyzeHistory({int days = 7});

  /// Computes remaining calories/macros for today and recommends optimal dishes.
  /// Supports optional filtering by [category] ('Todos', 'Desayuno', 'Almuerzo', 'Cena', 'Snack')
  /// and dynamic variety via [shuffle].
  Future<TodayRecommendationPlan> getWhatShouldIEatToday({
    DateTime? date,
    String? category,
    bool shuffle = false,
  });
}
