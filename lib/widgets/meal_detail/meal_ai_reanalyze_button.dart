import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';
import '../common/ve_loading_ring.dart';

class MealAiReanalyzeButton extends StatelessWidget {
  final bool isReanalyzing;
  final VoidCallback onPressed;

  const MealAiReanalyzeButton({
    super.key,
    required this.isReanalyzing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isReanalyzing ? null : onPressed,
      icon: isReanalyzing
          ? const VeLoadingRing(
              size: 16,
              strokeWidth: 2,
              color: AppColors.primary,
            )
          : const Icon(Icons.auto_awesome, size: 18),
      label: Text(
        isReanalyzing ? 'Re-analizando con IA...' : 'Re-analizar con correcciones',
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
