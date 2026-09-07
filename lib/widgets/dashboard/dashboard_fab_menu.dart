import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';

class DashboardFabMenu extends StatelessWidget {
  final VoidCallback onAiPhotoScan;
  final VoidCallback onBarcodeScan;
  final VoidCallback onManualEntry;

  const DashboardFabMenu({
    super.key,
    required this.onAiPhotoScan,
    required this.onBarcodeScan,
    required this.onManualEntry,
  });

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'REGISTRAR COMIDA',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                context,
                icon: Icons.auto_awesome,
                iconColor: AppColors.primary,
                title: 'Foto con IA (Gemini 2.5 Flash)',
                subtitle: 'Cubicaje volumétrico y desglose de plato casero',
                onTap: () {
                  Navigator.of(bottomContext).pop();
                  onAiPhotoScan();
                },
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                context,
                icon: Icons.qr_code_scanner,
                iconColor: AppColors.carbs,
                title: 'Escanear Código de Barras',
                subtitle: 'Consulta instantánea en Open Food Facts',
                onTap: () {
                  Navigator.of(bottomContext).pop();
                  onBarcodeScan();
                },
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                context,
                icon: Icons.edit_note,
                iconColor: AppColors.protein,
                title: 'Registro Manual',
                subtitle: 'Introducir nombre y macros directamente',
                onTap: () {
                  Navigator.of(bottomContext).pop();
                  onManualEntry();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted(context)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showActionSheet(context),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add_a_photo_outlined, size: 20),
      label: Text(
        'Añadir Comida',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
