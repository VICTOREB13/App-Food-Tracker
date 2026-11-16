import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:food_tracker/l10n/app_localizations.dart';
import 'package:food_tracker/core/services/theme/theme_manager.dart';

/// Renders self-validation chips displaying the AI model's estimated confidence
/// percentage and caloric error margin without subjective level labels or remarks.
class MealAiValidationChips extends StatelessWidget {
  final int? confidencePercentage;
  final int? calorieErrorMargin;
  final bool isPartial;

  const MealAiValidationChips({
    super.key,
    this.confidencePercentage,
    this.calorieErrorMargin,
    this.isPartial = false,
  });

  Color _resolveConfidenceColor(int percentage) {
    if (percentage >= 85) return AppColors.success;
    if (percentage >= 70) return AppColors.carbs;
    return AppColors.caloriesFlame;
  }

  @override
  Widget build(BuildContext context) {
    if (confidencePercentage == null && calorieErrorMargin == null && !isPartial) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final isDark = AppColors.isDark(context);

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (isPartial)
          _buildChip(
            context,
            icon: Icons.warning_amber_rounded,
            label: 'Análisis parcial',
            tooltip: 'La respuesta se recuperó parcialmente de un corte de red.',
            color: AppColors.caloriesFlame,
            isDark: isDark,
          ),
        if (confidencePercentage != null)
          _buildChip(
            context,
            icon: Icons.verified_outlined,
            label: l10n.confidenceCertaintyLabel('$confidencePercentage'),
            tooltip: l10n.visualConfidenceTooltip('$confidencePercentage'),
            color: _resolveConfidenceColor(confidencePercentage!),
            isDark: isDark,
          ),
        if (calorieErrorMargin != null)
          _buildChip(
            context,
            icon: Icons.tune,
            label: '±$calorieErrorMargin kcal',
            tooltip: l10n.calorieErrorMarginTooltip('$calorieErrorMargin'),
            color: AppColors.portion,
            isDark: isDark,
          ),
      ],
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String tooltip,
    required Color color,
    required bool isDark,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.35 : 0.22),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
