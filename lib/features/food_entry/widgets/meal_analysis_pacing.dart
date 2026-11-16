import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:food_tracker/l10n/app_localizations.dart';
import 'package:food_tracker/core/services/theme/theme_manager.dart';

/// Helper to simulate smooth, realistic pacing during Gemini Vision analysis (up to 60-90s)
/// without premature jumps, keeping users visually engaged across distinct stages.
class MealAnalysisPacing {
  static const double initialProgress = 0.05;
  static const double maxPacingProgress = 0.95;

  static String getStageMessage(double progress, AppLocalizations l10n) {
    if (progress < 0.20) return l10n.analysisStageOptimizing;
    if (progress < 0.45) return l10n.analysisStageConnecting;
    if (progress < 0.70) return l10n.analysisStageVolumetric;
    if (progress < 0.85) return l10n.analysisStageDensities;
    if (progress < 1.0) return l10n.analysisStageMacros;
    return l10n.analysisStageComplete;
  }

  static double nextProgress(double currentProgress) {
    if (currentProgress < 0.20) return (currentProgress + 0.007).clamp(0.0, 0.20);
    if (currentProgress < 0.45) return (currentProgress + 0.0078).clamp(0.0, 0.45);
    if (currentProgress < 0.70) return (currentProgress + 0.0057).clamp(0.0, 0.70);
    if (currentProgress < 0.85) return (currentProgress + 0.0038).clamp(0.0, 0.85);
    if (currentProgress < maxPacingProgress) return (currentProgress + 0.0025).clamp(0.0, maxPacingProgress);
    return maxPacingProgress;
  }
}

/// Interactive banner displayed in AnalysisProgressBanner when DecisionGate detects
/// non-food or low quality, offering '[Tomar otra foto]' or '[Analizar de todos modos]'.
class DecisionGateWarningBanner extends StatelessWidget {
  final bool isFood;
  final String imageQuality;
  final VoidCallback onRetakePhoto;
  final VoidCallback onAnalyzeAnyway;

  const DecisionGateWarningBanner({
    super.key,
    required this.isFood,
    required this.imageQuality,
    required this.onRetakePhoto,
    required this.onAnalyzeAnyway,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final warningColor = !isFood ? AppColors.caloriesFlame : AppColors.carbs;
    final title = !isFood ? 'No parece comida' : 'Calidad de imagen baja';
    final subtitle = !isFood
        ? 'No se detectaron alimentos claros en la toma.'
        : 'La imagen parece borrosa o poco iluminada.';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: warningColor.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: warningColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: warningColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w700, color: warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  foregroundColor: AppColors.textPrimary(context),
                ),
                onPressed: onRetakePhoto,
                child: Text('Tomar otra foto', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  elevation: 0,
                  backgroundColor: warningColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: onAnalyzeAnyway,
                child: Text('Analizar de todos modos', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Warning chip displayed when MealAnalysisResult has isPartial: true.
class MealAnalysisPartialWarningChip extends StatelessWidget {
  const MealAnalysisPartialWarningChip({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Tooltip(
      message: 'La respuesta se recuperó parcialmente de un corte de red.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: AppColors.caloriesFlame.withValues(alpha: isDark ? 0.16 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.caloriesFlame.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.caloriesFlame),
            const SizedBox(width: 4),
            Text(
              'Análisis parcial',
              style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.caloriesFlame,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
