import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../models/nutritional_recommendation.dart';
import '../../services/theme_manager.dart';

/// Card displaying details and quick-log action for a single recommended dish or snack.
class RecommendationDishCard extends StatelessWidget {
  final RecommendedDish dish;
  final bool isAdding;
  final VoidCallback onAdd;

  const RecommendationDishCard({
    super.key,
    required this.dish,
    required this.isAdding,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dish.name,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.protein.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.fitScoreLabel(dish.fitScore.toString()),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.protein,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dish.description,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context)),
          ),
          const SizedBox(height: 8),
          Text(
            '${dish.calories.round()} kcal • P: ${dish.protein.round()}g • C: ${dish.carbs.round()}g • G: ${dish.fat.round()}g',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.whyRecommendedLabel(dish.whyRecommended),
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted(context)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: isAdding ? null : onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.protein,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: isAdding
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add, size: 14),
              label: Text(
                l10n.logInTodayAction,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
