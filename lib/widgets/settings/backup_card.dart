import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

class BackupCard extends StatelessWidget {
  final Future<String> Function() onExport;
  final Future<Map<String, int>> Function(String) onImport;

  const BackupCard({
    super.key,
    required this.onExport,
    required this.onImport,
  });

  void _handleExport(BuildContext context) async {
    try {
      final jsonString = await onExport();
      await Clipboard.setData(ClipboardData(text: jsonString));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Respaldo JSON copiado al portapapeles con éxito.'),
          backgroundColor: AppColors.protein,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar respaldo: $e'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _handleImport(BuildContext context) async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border(context)),
        ),
        title: Text(
          'Pegar Respaldo JSON',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
          ),
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pega el contenido del archivo de respaldo JSON para restaurar comidas y despensa.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 6,
                style: GoogleFonts.inter(fontSize: 12),
                decoration: const InputDecoration(
                  hintText: '{\n  "meals": [...]\n}',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: AppColors.textSecondary(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Importar', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      try {
        final counts = await onImport(controller.text.trim());
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Importado: ${counts['imported_meals']} comidas y ${counts['imported_pantry']} artículos.',
            ),
            backgroundColor: AppColors.protein,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en importación: $e'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return VeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_alt_outlined, size: 20, color: AppColors.protein),
              const SizedBox(width: 8),
              Text(
                'RESPALDO Y MIGRACIÓN JSON',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Exporta o importa tu historial completo de comidas y biblioteca de alimentos en formato JSON estándar.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleExport(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.file_upload_outlined, size: 16),
                  label: Text('Exportar JSON', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleImport(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: Text('Importar JSON', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
