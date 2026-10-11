import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../models/nutritional_recommendation.dart';
import '../../services/recommendations/recommendation_filter_engine.dart';
import '../../services/theme_manager.dart';

/// Bento summary displaying remaining calories and macros alongside targeted snack advice.
class RecommendationBudgetSummary extends StatelessWidget {
  final TodayRecommendationPlan plan;
  final String selectedCategory;

  const RecommendationBudgetSummary({
    super.key,
    required this.plan,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSnack = RecommendationFilterEngine.normalizeCategory(selectedCategory) == 'Snack';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.border(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.todayRemainingMargin,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMacroBadge(context, l10n.calories, '${plan.remainingCalories.round()} kcal', AppColors.primary),
                  _buildMacroBadge(context, l10n.protein, '${plan.remainingProtein.round()}g', AppColors.protein),
                  _buildMacroBadge(context, l10n.carbs, '${plan.remainingCarbs.round()}g', AppColors.carbs),
                  _buildMacroBadge(context, l10n.fat, '${plan.remainingFat.round()}g', AppColors.fat),
                ],
              ),
            ],
          ),
        ),
        if (isSnack) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.protein.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.protein.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_outlined, size: 14, color: AppColors.protein),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.practicalSnackHint,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.protein,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMacroBadge(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary(context))),
      ],
    );
  }
}
