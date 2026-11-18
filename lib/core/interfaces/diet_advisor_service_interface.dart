import 'package:food_tracker/core/models/diet_pattern_insight.dart';

/// Contract for AI-powered longitudinal diet pattern analysis.
abstract interface class IDietAdvisorService {
  /// Analyzes longitudinal nutrition over [days] and returns structured insights.
  Future<DietPatternInsight> getDietPatternInsights({
    int days = 7,
    bool forceRefresh = false,
  });
}
