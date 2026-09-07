import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/daily_goals.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';
import 'calories_hero_ring.dart';
import 'macro_bento_card.dart';

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
          const SizedBox(height: 14),
          Row(
            children: [
              CaloriesHeroRing(
                current: currentCalories,
                goal: goals.calories,
                size: 88,
                strokeWidth: 8,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: calorieProgress,
                        minHeight: 6,
                        backgroundColor: AppColors.border(context),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          remaining >= 0 ? AppColors.primary : AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MacroBentoCard(
                  label: 'Proteína',
                  iconEmoji: '🍗',
                  current: currentProtein,
                  goal: goals.protein,
                  color: AppColors.protein,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MacroBentoCard(
                  label: 'Carbos',
                  iconEmoji: '🌾',
                  current: currentCarbs,
                  goal: goals.carbs,
                  color: AppColors.carbs,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MacroBentoCard(
                  label: 'Grasas',
                  iconEmoji: '🥑',
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
}
