import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/meal_controller.dart';
import '../../models/daily_goals.dart';
import '../../models/meal.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

class CalorieComplianceBentoCard extends StatelessWidget {
  final List<Meal> meals;
  final int days;
  final DailyGoals? goals;

  const CalorieComplianceBentoCard({
    super.key,
    required this.meals,
    this.days = 30,
    this.goals,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGoals = goals ?? MealController.instance.dailyGoals;
    final targetCalories = effectiveGoals.calories;

    // Group meals by day to calculate true daily average
    final dailyTotals = <String, double>{};
    for (final meal in meals) {
      final key = '${meal.date.year}-${meal.date.month}-${meal.date.day}';
      dailyTotals[key] = (dailyTotals[key] ?? 0.0) + meal.calories;
    }

    final totalCalories = meals.fold<double>(0.0, (acc, m) => acc + m.calories);
    final activeDays = dailyTotals.length;
    final avgCalories = activeDays > 0 ? (totalCalories / activeDays) : 0.0;

    final double progressFraction = targetCalories > 0
        ? (avgCalories / targetCalories).clamp(0.0, 1.5)
        : 0.0;
    final int compliancePercent = targetCalories > 0
        ? ((avgCalories / targetCalories) * 100).toInt()
        : 0;

    final String statusText;
    final Color statusColor;
    if (targetCalories <= 0) {
      statusText = 'Sin meta';
      statusColor = AppColors.textSecondary(context);
    } else if (avgCalories == 0) {
      statusText = 'Sin registros';
      statusColor = AppColors.textSecondary(context);
    } else if (avgCalories < targetCalories - 200) {
      statusText = 'Déficit saludable';
      statusColor = AppColors.protein;
    } else if ((avgCalories - targetCalories).abs() <= 200) {
      statusText = 'Mantenimiento';
      statusColor = AppColors.carbs;
    } else {
      statusText = 'Superávit';
      statusColor = AppColors.primaryLight;
    }

    return VeCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.calories.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_outlined,
                      color: AppColors.calories,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CALORÍAS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Big value & target
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                avgCalories.toStringAsFixed(0),
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'kcal/día',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Meta: ${targetCalories.toStringAsFixed(0)} kcal ($compliancePercent%)',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 10),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressFraction.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.border(context),
              valueColor: AlwaysStoppedAnimation<Color>(
                progressFraction > 1.0 ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Days registered footer
          Text(
            '$activeDays de $days días con ingesta',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textMuted(context),
            ),
          ),
        ],
      ),
    );
  }
}
