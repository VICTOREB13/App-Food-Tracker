import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/l10n/app_localizations.dart';
import 'package:food_tracker/widgets/meal_detail/meal_analysis_pacing.dart';

void main() {
  group('MealAnalysisPacing Tests', () {
    final l10n = AppLocalizationsEs();

    test('getStageMessage returns expected stages across the progress range', () {
      expect(MealAnalysisPacing.getStageMessage(0.05, l10n), equals(l10n.analysisStageOptimizing));
      expect(MealAnalysisPacing.getStageMessage(0.25, l10n), equals(l10n.analysisStageConnecting));
      expect(MealAnalysisPacing.getStageMessage(0.55, l10n), equals(l10n.analysisStageVolumetric));
      expect(MealAnalysisPacing.getStageMessage(0.75, l10n), equals(l10n.analysisStageDensities));
      // Critical boundary verification: at 95% (max pacing), it must still be analysisStageMacros, NOT complete
      expect(MealAnalysisPacing.getStageMessage(0.95, l10n), equals(l10n.analysisStageMacros));
      expect(MealAnalysisPacing.getStageMessage(0.99, l10n), equals(l10n.analysisStageMacros));
      // Only at 1.0 (or above) does it return complete
      expect(MealAnalysisPacing.getStageMessage(1.0, l10n), equals(l10n.analysisStageComplete));
    });

    test('nextProgress smoothly increases progress and caps at maxPacingProgress', () {
      double p = MealAnalysisPacing.initialProgress;
      for (int i = 0; i < 200; i++) {
        p = MealAnalysisPacing.nextProgress(p);
      }
      expect(p, equals(MealAnalysisPacing.maxPacingProgress));
      expect(p, equals(0.95));
      // Ensure capped value continues to report macros stage, avoiding premature completion
      expect(MealAnalysisPacing.getStageMessage(p, l10n), equals(l10n.analysisStageMacros));
    });
  });
}
