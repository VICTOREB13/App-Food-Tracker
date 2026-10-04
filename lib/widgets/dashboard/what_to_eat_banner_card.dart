import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';
import '../recommendations/recommendation_diagnostic_card.dart';
import '../recommendations/what_to_eat_sheet.dart';

/// Bento card on the Dashboard inviting the user to explore what to eat and inspect recommendations.
class WhatToEatBannerCard extends StatelessWidget {
  final DateTime selectedDate;

  const WhatToEatBannerCard({
    super.key,
    required this.selectedDate,
  });

  void _openWhatToEatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WhatToEatSheet(date: selectedDate),
    );
  }

  void _openDiagnosticDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        contentPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border(context)),
        ),
        content: const SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: RecommendationDiagnosticCard(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cerrar', style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.protein.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.protein, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Qué debería comer hoy?',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Combinaciones para bajar grasas y alcanzar tus metas',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => _openWhatToEatSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.protein,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.restaurant_menu, size: 16),
                  label: Text('Sugerencias de Hoy', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: () => _openDiagnosticDialog(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border(context)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Diagnóstico', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
