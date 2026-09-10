import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/meal_controller.dart';
import '../../models/daily_goals.dart';
import '../../models/meal.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

class MacroDistributionBentoCard extends StatelessWidget {
  final List<Meal> meals;
  final DailyGoals? goals;

  const MacroDistributionBentoCard({
    super.key,
    required this.meals,
    this.goals,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGoals = goals ?? MealController.instance.dailyGoals;

    // Group meals by day to calculate true daily averages
    final daysSet = <String>{};
    for (final meal in meals) {
      daysSet.add('${meal.date.year}-${meal.date.month}-${meal.date.day}');
    }

    final activeDays = math.max(1, daysSet.length);
    final hasData = meals.isNotEmpty;

    final totalProtein = meals.fold<double>(0.0, (acc, m) => acc + m.protein);
    final totalCarbs = meals.fold<double>(0.0, (acc, m) => acc + m.carbs);
    final totalFat = meals.fold<double>(0.0, (acc, m) => acc + m.fat);

    final avgProtein = hasData ? (totalProtein / activeDays) : 0.0;
    final avgCarbs = hasData ? (totalCarbs / activeDays) : 0.0;
    final avgFat = hasData ? (totalFat / activeDays) : 0.0;

    final totalMacroGrams = avgProtein + avgCarbs + avgFat;

    final pctProtein = totalMacroGrams > 0 ? (avgProtein / totalMacroGrams * 100) : 33.3;
    final pctCarbs = totalMacroGrams > 0 ? (avgCarbs / totalMacroGrams * 100) : 33.3;
    final pctFat = totalMacroGrams > 0 ? (avgFat / totalMacroGrams * 100) : 33.4;

    const colorProtein = AppColors.protein;
    const colorCarbs = AppColors.carbs;
    const colorFat = AppColors.fat;

    return VeCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.protein.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart_outline,
                  color: AppColors.protein,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DISTRIBUCIÓN DE MACROS',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Promedio diario',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Proportional Multi-Segment Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: math.max(1, pctProtein.round()),
                    child: Container(color: colorProtein),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: math.max(1, pctCarbs.round()),
                    child: Container(color: colorCarbs),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: math.max(1, pctFat.round()),
                    child: Container(color: colorFat),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3 Columns Breakdown
          Row(
            children: [
              // Protein
              Expanded(
                child: _buildMacroItem(
                  context,
                  label: 'Proteína',
                  grams: avgProtein,
                  distributionPct: pctProtein,
                  targetGrams: effectiveGoals.protein,
                  color: colorProtein,
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: AppColors.border(context),
              ),
              // Carbs
              Expanded(
                child: _buildMacroItem(
                  context,
                  label: 'Carbos',
                  grams: avgCarbs,
                  distributionPct: pctCarbs,
                  targetGrams: effectiveGoals.carbs,
                  color: colorCarbs,
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: AppColors.border(context),
              ),
              // Fat
              Expanded(
                child: _buildMacroItem(
                  context,
                  label: 'Grasas',
                  grams: avgFat,
                  distributionPct: pctFat,
                  targetGrams: effectiveGoals.fat,
                  color: colorFat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(
    BuildContext context, {
    required String label,
    required double grams,
    required double distributionPct,
    required double targetGrams,
    required Color color,
  }) {
    final goalPercent = targetGrams > 0 ? (grams / targetGrams * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                grams.toStringAsFixed(0),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(width: 2),
              Text(
                'g',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
          Text(
            '${goalPercent.toStringAsFixed(0)}% · Meta: ${targetGrams.toStringAsFixed(0)}g',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textMuted(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
