import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:food_tracker/l10n/app_localizations.dart';
import 'package:food_tracker/core/services/theme/theme_manager.dart';

/// Renders self-validation chips displaying the AI model's estimated confidence
/// percentage and caloric error margin without subjective level labels or remarks.
class MealAiValidationChips extends StatelessWidget {
  final int? confidencePercentage;
  final int? calorieErrorMargin;
  final bool isPartial;
  final String? modelUsed;
  final bool isFallback;
  final String? thinkingLevel;

  const MealAiValidationChips({
    super.key,
    this.confidencePercentage,
    this.calorieErrorMargin,
    this.isPartial = false,
    this.modelUsed,
    this.isFallback = false,
    this.thinkingLevel,
  });

  Color _resolveConfidenceColor(int percentage) {
    if (percentage >= 85) {
      return AppColors.success;
    }
    if (percentage >= 70) {
      return AppColors.carbs;
    }
    return AppColors.caloriesFlame;
  }

  String _formatTelemetry() {
    final raw = (modelUsed ?? '').replaceAll('models/', '');
    if (raw.isEmpty) {
      return '';
    }

    final knownNames = <String, String>{
      'gemini-2.5-flash': 'Gemini 2.5 Flash',
      'gemini-2.5-pro': 'Gemini 2.5 Pro',
      'gemini-3.5-flash-lite': 'Gemini 3.5 Flash-Lite',
      'gemini-3.6-flash': 'Gemini 3.6 Flash',
      'gemini-3.1-pro': 'Gemini 3.1 Pro',
      'gemini-3.8-flash': 'Gemini 3.8 Flash',
    };

    final name = knownNames[raw.toLowerCase()] ??
        raw.split('-').map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}').join(' ');

    if (isFallback) {
      return 'Fallback: $name';
    }
    if (thinkingLevel != null && thinkingLevel != 'OFF') {
      final effort = (thinkingLevel == 'HIGH' || thinkingLevel == 'XHIGH')
          ? 'Alto'
          : (thinkingLevel == 'LOW' ? 'Bajo' : 'Medio');
      return '$name · Esfuerzo: $effort';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final hasTelemetry = modelUsed != null && modelUsed!.isNotEmpty;
    if (confidencePercentage == null && calorieErrorMargin == null && !isPartial && !hasTelemetry) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final isDark = AppColors.isDark(context);

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (hasTelemetry)
          _buildChip(
            context,
            icon: isFallback ? Icons.alt_route_rounded : Icons.auto_awesome,
            label: _formatTelemetry(),
            tooltip: isFallback ? 'Modelo de reserva ejecutado por corte de red' : 'Modelo de inferencia activo',
            color: isFallback ? AppColors.caloriesFlame : AppColors.primary,
            isDark: isDark,
          ),
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