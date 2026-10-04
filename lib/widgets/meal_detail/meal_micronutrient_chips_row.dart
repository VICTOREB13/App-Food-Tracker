import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';

class MealMicronutrientChipsRow extends StatelessWidget {
  final double fiber;
  final double sodium;
  final double sugar;

  const MealMicronutrientChipsRow({
    super.key,
    required this.fiber,
    required this.sodium,
    required this.sugar,
  });

  @override
  Widget build(BuildContext context) {
    if (fiber <= 0 && sodium <= 0 && sugar <= 0) {
      return const SizedBox.shrink();
    }

    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPill(
            context,
            icon: Icons.grass_rounded,
            label: 'Fibra',
            value: '${fiber.toStringAsFixed(1)}g',
            color: const Color(0xFF10B981),
          ),
          Container(
            width: 1,
            height: 20,
            color: AppColors.border(context),
          ),
          _buildPill(
            context,
            icon: Icons.grain_rounded,
            label: 'Sodio',
            value: '${sodium.toStringAsFixed(0)}mg',
            color: const Color(0xFFF59E0B),
          ),
          Container(
            width: 1,
            height: 20,
            color: AppColors.border(context),
          ),
          _buildPill(
            context,
            icon: Icons.cookie_outlined,
            label: 'Azúcar',
            value: '${sugar.toStringAsFixed(1)}g',
            color: const Color(0xFFEC4899),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary(context),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
          ),
        ),
      ],
    );
  }
}
