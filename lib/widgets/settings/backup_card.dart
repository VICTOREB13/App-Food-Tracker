import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import '../../services/backup_service.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';
import 'json_file_picker_dialog.dart';

/// Card providing real JSON file export and import functionality.
class BackupCard extends StatelessWidget {
  final Future<String> Function()? onExport;
  final Future<Map<String, int>> Function(String)? onImport;
  final Future<File> Function()? onExportFile;
  final Future<Map<String, int>> Function(File)? onImportFile;

  const BackupCard({
    super.key,
    this.onExport,
    this.onImport,
    this.onExportFile,
    this.onImportFile,
  });

  Future<void> _handleExport(BuildContext context) async {
    try {
      final File file;
      if (onExportFile != null) {
        file = await onExportFile!();
      } else {
        file = await BackupService.instance.exportToJsonFile();
      }

      final length = await file.length();
      final fileSizeKb = (length / 1024).toStringAsFixed(1);
      final fileName = p.basename(file.path);

      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: AppColors.surface(dialogCtx),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.border(dialogCtx)),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.protein, size: 24),
              const SizedBox(width: 8),
              Text(
                'Archivo JSON Creado',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(dialogCtx),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Se generó el archivo de respaldo completo en el almacenamiento de tu dispositivo:',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(dialogCtx), height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.protein.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.protein.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fileName, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.protein)),
                    const SizedBox(height: 4),
                    Text('Tamaño: $fileSizeKb KB', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary(dialogCtx))),
                    const SizedBox(height: 6),
                    Text(
                      file.path,
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted(dialogCtx)),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: file.path));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ruta del archivo copiada al portapapeles')),
                );
              },
              child: Text('Copiar ruta', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.protein)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.protein,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Aceptar', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar archivo de respaldo: $e'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (dialogCtx) => JsonFilePickerDialog(
        onRestoreFile: (file) async {
          if (onImportFile != null) {
            return await onImportFile!(file);
          }
          return await BackupService.instance.importFromFile(file);
        },
      ),
    );

    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Restauración exitosa! Se importaron ${result['imported_meals'] ?? 0} comidas y ${result['imported_pantry'] ?? 0} productos.',
          ),
          backgroundColor: AppColors.protein,
        ),
      );
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
                'RESPALDO Y MIGRACIÓN EN ARCHIVOS',
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
            'Genera archivos físicos (.json) descargables para guardar tus comidas y despensa, o importa un archivo de respaldo previo sin usar el portapapeles.',
            textAlign: TextAlign.justify,
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
