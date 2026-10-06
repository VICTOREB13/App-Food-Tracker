import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/daily_goals.dart';
import '../../models/meal.dart';
import '../../services/theme_manager.dart';

/// Bento card presenting weekly nutritional averages, net calorie balance, and macro consistency.
class WeeklyDigestCard extends StatelessWidget {
  final List<Meal> meals;
  final DailyGoals goals;

  const WeeklyDigestCard({
    super.key,
    required this.meals,
    required this.goals,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate 7-day range
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));

    final recentMeals = meals.where((m) {
      final mDate = DateTime(m.date.year, m.date.month, m.date.day);
      return !mDate.isBefore(weekStart) && !mDate.isAfter(today);
    }).toList();

    // Group meals by day to find logged days count
    final daysMap = <String, double>{};
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;
    double totalCalories = 0.0;

    for (final m in recentMeals) {
      final key = DateFormat('yyyy-MM-dd').format(m.date);
      daysMap[key] = (daysMap[key] ?? 0.0) + m.calories;
      totalCalories += m.calories;
      totalProtein += m.protein;
      totalCarbs += m.carbs;
      totalFat += m.fat;
    }

    final loggedDaysCount = daysMap.length;
    final avgCalories = totalCalories / 7.0;
    final avgProtein = totalProtein / 7.0;
    final avgCarbs = totalCarbs / 7.0;
    final avgFat = totalFat / 7.0;

    // Cumulative balance over 7 days against target
    final weeklyTarget = goals.calories * 7.0;
    final cumulativeBalance = totalCalories - weeklyTarget;
    final isSurplus = cumulativeBalance > 50.0;
    final isDeficit = cumulativeBalance < -50.0;

    // Adherence percentages
    final calAdherence = goals.calories > 0
        ? ((avgCalories / goals.calories) * 100).clamp(0, 200).toInt()
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_graph_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'RESUMEN SEMANAL (7 DÍAS)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$loggedDaysCount / 7 días con registro',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Stats Row
          Row(
            children: [
              // Average calories
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Promedio Diario',
                  value: '${avgCalories.toInt()} kcal',
                  subtitle: 'Meta: ${goals.calories.toInt()} kcal ($calAdherence%)',
                  color: AppColors.calories,
                ),
              ),
              const SizedBox(width: 10),
              // Cumulative balance
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Balance Neto Semanal',
                  value: '${cumulativeBalance >= 0 ? '+' : ''}${cumulativeBalance.toInt()} kcal',
                  subtitle: isSurplus
                      ? 'Superávit calórico'
                      : (isDeficit ? 'Déficit calórico' : 'Mantenimiento'),
                  color: isSurplus
                      ? AppColors.primary
                      : (isDeficit ? AppColors.success : AppColors.textPrimary(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Macro Consistency Section
          Text(
            'Consistencia de Macronutrientes (Promedio / Meta):',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMacroProgress(
                  context,
                  name: 'Proteína',
                  avg: avgProtein,
                  target: goals.protein,
                  color: AppColors.protein,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroProgress(
                  context,
                  name: 'Carbos',
                  avg: avgCarbs,
                  target: goals.carbs,
                  color: AppColors.carbs,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroProgress(
                  context,
                  name: 'Grasas',
                  avg: avgFat,
                  target: goals.fat,
                  color: AppColors.fat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildMacroProgress(
    BuildContext context, {
    required String name,
    required double avg,
    required double target,
    required Color color,
  }) {
    final ratio = target > 0 ? (avg / target).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                ),
              ),
              const SizedBox(width: 2),
              Text(
                '${(ratio * 100).toInt()}%',
                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 4,
              backgroundColor: color.withValues(alpha: 0.15),
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${avg.toInt()}g/${target.toInt()}g',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 9, color: AppColors.textMuted(context)),
          ),
        ],
      ),
    );
  }
}
