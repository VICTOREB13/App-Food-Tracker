import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/meal.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

class StreakComplianceBentoCard extends StatelessWidget {
  final List<Meal> meals;
  final int days;

  const StreakComplianceBentoCard({
    super.key,
    required this.meals,
    this.days = 30,
  });

  static int calculateStreak(List<Meal> meals) {
    if (meals.isEmpty) return 0;

    final dateSet = <String>{};
    for (final meal in meals) {
      dateSet.add('${meal.date.year}-${meal.date.month.toString().padLeft(2, '0')}-${meal.date.day.toString().padLeft(2, '0')}');
    }

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    DateTime checkDate;
    if (dateSet.contains(todayStr)) {
      checkDate = now;
    } else if (dateSet.contains(yesterdayStr)) {
      checkDate = yesterday;
    } else {
      return 0;
    }

    int streak = 0;
    while (true) {
      final key = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (dateSet.contains(key)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    // Unique active days in range
    final activeDateSet = <String>{};
    for (final meal in meals) {
      activeDateSet.add('${meal.date.year}-${meal.date.month}-${meal.date.day}');
    }
    final activeDays = activeDateSet.length;
    final streak = calculateStreak(meals);

    final isAllTime = days <= 0;
    final double consistencyFraction = isAllTime
        ? (activeDays > 0 ? 1.0 : 0.0)
        : (activeDays / days).clamp(0.0, 1.0);
    final int consistencyPercent = (consistencyFraction * 100).toInt();

    final String badgeText;
    final Color badgeColor;
    if (streak >= 7) {
      badgeText = 'Imparable 🔥';
      badgeColor = AppColors.primary;
    } else if (streak >= 3) {
      badgeText = 'Buen ritmo ✨';
      badgeColor = AppColors.protein;
    } else if (streak >= 1) {
      badgeText = 'Activo 💪';
      badgeColor = AppColors.carbs;
    } else {
      badgeText = 'Comienza hoy 🎯';
      badgeColor = AppColors.textSecondary(context);
    }

    return VeCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.protein.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.bolt_outlined,
                  color: AppColors.protein,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CONSTANCIA',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Big streak text
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$streak',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                streak == 1 ? 'día racha' : 'días racha',
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
            isAllTime
                ? '$activeDays días registrados en total'
                : '$activeDays de $days días registrados ($consistencyPercent%)',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 10),

          // Consistency Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: consistencyFraction,
              minHeight: 6,
              backgroundColor: AppColors.border(context),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.protein),
            ),
          ),
          const SizedBox(height: 8),

          // Motivational message
          Text(
            activeDays == 0
                ? 'Registra tus comidas para crear el hábito'
                : 'La disciplina supera la motivación',
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
