import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';

class MealMacroChipsRow extends StatelessWidget {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const MealMacroChipsRow({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildTile(
            context,
            label: 'Calorías',
            value: calories.toStringAsFixed(0),
            unit: 'kcal',
            color: AppColors.calories,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTile(
            context,
            label: 'Proteínas',
            value: protein.toStringAsFixed(0),
            unit: 'g',
            color: AppColors.protein,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTile(
            context,
            label: 'Carbos',
            value: carbs.toStringAsFixed(0),
            unit: 'g',
            color: AppColors.carbs,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTile(
            context,
            label: 'Grasas',
            value: fat.toStringAsFixed(0),
            unit: 'g',
            color: AppColors.fat,
          ),
        ),
      ],
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
            ),
          ),
          Text(
            unit,
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
