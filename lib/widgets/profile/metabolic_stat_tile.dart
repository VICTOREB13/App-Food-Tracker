import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';

/// Reusable stat tile for BMR/TDEE and macro badge in metabolic summary cards.
class MetabolicStatTile extends StatelessWidget {
  final String label;
  final String value;

  const MetabolicStatTile({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
        ],
      ),
    );
  }
}

class MetabolicMacroBadge extends StatelessWidget {
  final String label;
  final double grams;
  final double calories;
  final Color color;

  const MetabolicMacroBadge({
    super.key,
    required this.label,
    required this.grams,
    required this.calories,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          Text('${grams.toStringAsFixed(0)}g', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
          Text('${calories.toStringAsFixed(0)} kcal', style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textMuted(context))),
        ],
      ),
    );
  }
}
