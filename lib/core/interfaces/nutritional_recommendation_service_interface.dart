import 'package:food_tracker/core/interfaces/diet_advisor_service_interface.dart';
import 'package:food_tracker/core/models/diet_pattern_insight.dart';
import 'package:food_tracker/core/models/nutritional_recommendation.dart';

/// Contract for nutritional analysis and intelligent meal recommendation services.
abstract class INutritionalRecommendationService implements IDietAdvisorService {
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

  /// Generates longitudinal diet pattern insights (fat, protein, fiber, sodium, visual menu, swaps) via Gemini.
  @override
  Future<DietPatternInsight> getDietPatternInsights({
    int days = 7,
    bool forceRefresh = false,
  });
}
