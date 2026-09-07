import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/meal.dart';
import '../../services/theme_manager.dart';
import '../common/macro_indicator_chip.dart';
import '../common/ve_card.dart';

class MealSectionCard extends StatelessWidget {
  final String mealType;
  final List<Meal> meals;
  final ValueChanged<Meal> onMealTap;
  final VoidCallback onAddMeal;

  const MealSectionCard({
    super.key,
    required this.mealType,
    required this.meals,
    required this.onMealTap,
    required this.onAddMeal,
  });

  IconData get _sectionIcon {
    switch (mealType) {
      case 'Desayuno':
        return Icons.wb_sunny_outlined;
      case 'Almuerzo':
        return Icons.restaurant_outlined;
      case 'Cena':
        return Icons.nightlight_round_outlined;
      default:
        return Icons.cookie_outlined;
    }
  }

  double get _totalCalories => meals.fold(0.0, (acc, m) => acc + m.calories);

  @override
  Widget build(BuildContext context) {
    return VeCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_sectionIcon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                mealType,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const Spacer(),
              if (meals.isNotEmpty)
                Text(
                  '${_totalCalories.toStringAsFixed(0)} kcal',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: AppColors.primary,
                onPressed: onAddMeal,
                tooltip: 'Añadir a $mealType',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Sin registros en esta comida.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted(context),
                ),
              ),
            )
          else ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 4),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: meals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final meal = meals[index];
                return _buildMealTile(context, meal);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealTile(BuildContext context, Meal meal) {
    return InkWell(
      onTap: () => onMealTap(meal),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            if (meal.imagePath != null && File(meal.imagePath!).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(meal.imagePath!),
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                ),
              )
            else
              _buildFallbackIcon(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      MacroIndicatorChip(
                        label: 'Cal',
                        value: meal.calories.toStringAsFixed(0),
                        accentColor: AppColors.calories,
                        isCompact: true,
                      ),
                      MacroIndicatorChip(
                        label: 'P',
                        value: '${meal.protein.toStringAsFixed(0)}g',
                        accentColor: AppColors.protein,
                        isCompact: true,
                      ),
                      MacroIndicatorChip(
                        label: 'C',
                        value: '${meal.carbs.toStringAsFixed(0)}g',
                        accentColor: AppColors.carbs,
                        isCompact: true,
                      ),
                      MacroIndicatorChip(
                        label: 'G',
                        value: '${meal.fat.toStringAsFixed(0)}g',
                        accentColor: AppColors.fat,
                        isCompact: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textMuted(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.fastfood_outlined,
        color: AppColors.primary,
        size: 22,
      ),
    );
  }
}
