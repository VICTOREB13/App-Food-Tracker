import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/daily_goals.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

class DailyCalorieSummaryCard extends StatelessWidget {
  final double currentCalories;
  final double currentProtein;
  final double currentCarbs;
  final double currentFat;
  final DailyGoals goals;

  const DailyCalorieSummaryCard({
    super.key,
    required this.currentCalories,
    required this.currentProtein,
    required this.currentCarbs,
    required this.currentFat,
    required this.goals,
  });

  @override
  Widget build(BuildContext context) {
    final calorieProgress = goals.calories > 0
        ? (currentCalories / goals.calories).clamp(0.0, 1.0)
        : 0.0;
    final remaining = goals.calories - currentCalories;

    return VeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RESUMEN DEL DÍA',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(calorieProgress * 100).toInt()}%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                currentCalories.toStringAsFixed(0),
                style: GoogleFonts.outfit(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${goals.calories.toStringAsFixed(0)} kcal',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const Spacer(),
              Text(
                remaining >= 0
                    ? '${remaining.toStringAsFixed(0)} restantes'
                    : '+${(-remaining).toStringAsFixed(0)} exceso',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: remaining >= 0 ? AppColors.protein : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: calorieProgress,
              minHeight: 8,
              backgroundColor: AppColors.border(context),
              valueColor: AlwaysStoppedAnimation<Color>(
                remaining >= 0 ? AppColors.primary : AppColors.primaryLight,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMacroColumn(
                  context,
                  label: 'Proteína',
                  current: currentProtein,
                  goal: goals.protein,
                  color: AppColors.protein,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroColumn(
                  context,
                  label: 'Carbos',
                  current: currentCarbs,
                  goal: goals.carbs,
                  color: AppColors.carbs,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroColumn(
                  context,
                  label: 'Grasas',
                  current: currentFat,
                  goal: goals.fat,
                  color: AppColors.fat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroColumn(
    BuildContext context, {
    required String label,
    required double current,
    required double goal,
    required Color color,
  }) {
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${current.toStringAsFixed(0)}/${goal.toStringAsFixed(0)}g',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.border(context),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
