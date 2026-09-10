import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

class DatabaseMaintenanceCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isLoading;
  final VoidCallback onOptimize;

  const DatabaseMaintenanceCard({
    super.key,
    required this.stats,
    required this.isLoading,
    required this.onOptimize,
  });

  @override
  Widget build(BuildContext context) {
    final mealsCount = stats['meals_count'] ?? 0;
    final pantryCount = stats['pantry_count'] ?? 0;
    final fileSizeKb = stats['file_size_kb'] ?? '0.0';

    return VeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage_outlined, size: 20, color: AppColors.carbs),
              const SizedBox(width: 8),
              Text(
                'MANTENIMIENTO SQLITE LOCAL-FIRST',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  context,
                  label: 'Comidas',
                  value: '$mealsCount',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(
                  context,
                  label: 'Despensa',
                  value: '$pantryCount',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(
                  context,
                  label: 'Tamaño DB',
                  value: '$fileSizeKb KB',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onOptimize,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.border(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cleaning_services_outlined, size: 16),
              label: Text(
                isLoading ? 'Optimizando...' : 'Optimizar y Compactar',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, {required String label, required String value}) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}
