import '../../l10n/app_localizations.dart';

/// Helper to simulate smooth, realistic pacing during Gemini Vision analysis (up to 60-90s)
/// without premature jumps, keeping users visually engaged across distinct stages.
class MealAnalysisPacing {
  static const double initialProgress = 0.05;
  static const double maxPacingProgress = 0.95;

  /// Returns the localized description for the current progress value.
  static String getStageMessage(double progress, AppLocalizations l10n) {
    if (progress < 0.20) {
      return l10n.analysisStageOptimizing;
    } else if (progress < 0.45) {
      return l10n.analysisStageConnecting;
    } else if (progress < 0.70) {
      return l10n.analysisStageVolumetric;
    } else if (progress < 0.85) {
      return l10n.analysisStageDensities;
    } else if (progress < 1.0) {
      return l10n.analysisStageMacros;
    } else {
      return l10n.analysisStageComplete;
    }
  }

  /// Calculates the next progress step based on current progress.
  /// Designed for a timer firing every 500ms over a 60-90s envelope.
  static double nextProgress(double currentProgress) {
    if (currentProgress < 0.20) {
      // 0.05 -> 0.20 in ~10-12s
      return (currentProgress + 0.007).clamp(0.0, 0.20);
    } else if (currentProgress < 0.45) {
      // 0.20 -> 0.45 in ~16s
      return (currentProgress + 0.0078).clamp(0.0, 0.45);
    } else if (currentProgress < 0.70) {
      // 0.45 -> 0.70 in ~22s
      return (currentProgress + 0.0057).clamp(0.0, 0.70);
    } else if (currentProgress < 0.85) {
      // 0.70 -> 0.85 in ~20s
      return (currentProgress + 0.0038).clamp(0.0, 0.85);
    } else if (currentProgress < maxPacingProgress) {
      // 0.85 -> 0.95 in ~20s
      return (currentProgress + 0.0025).clamp(0.0, maxPacingProgress);
    }
    return maxPacingProgress;
  }
}
