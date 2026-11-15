import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:food_tracker/l10n/app_localizations.dart';
import 'package:food_tracker/core/services/theme/theme_manager.dart';
import 'package:food_tracker/core/ui/components/ve_card.dart';
import 'package:food_tracker/features/settings_profile/widgets/json_file_picker_dialog.dart';
import 'data_backup.controller.dart';

/// Card providing real JSON file export and import functionality.
/// Refactored under Vertical Slice Architecture / Micro-MVC (< 300 LoC budget).
class DataBackupView extends StatelessWidget {
  final Future<String> Function()? onExport;
  final Future<Map<String, int>> Function(String)? onImport;
  final Future<File> Function()? onExportFile;
  final Future<Map<String, int>> Function(File)? onImportFile;
  final DataBackupController? controller;

  const DataBackupView({
    super.key,
    this.onExport,
    this.onImport,
    this.onExportFile,
    this.onImportFile,
    this.controller,
  });

  DataBackupController get _controller => controller ?? DataBackupController.instance;

  Future<void> _handleExport(BuildContext context) async {
    try {
      final File file;
      if (onExportFile != null) {
        file = await onExportFile!();
      } else if (onExport != null) {
        final json = await onExport!();
        final dir = await _controller.resolveBackupDirectory();
        final dateStamp = DateTime.now().millisecondsSinceEpoch;
        file = File(p.join(dir.path, 'backup_$dateStamp.json'));
        await file.writeAsString(json, flush: true);
      } else {
        file = await _controller.exportBackup();
      }

      final length = await file.length();
      final fileSizeKb = (length / 1024).toStringAsFixed(1);
      final fileName = p.basename(file.path);

      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context);

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
                l10n.jsonFileCreatedTitle,
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
                l10n.backupGeneratedPathDesc,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary(dialogCtx),
                  height: 1.4,
                ),
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
                    Text(
                      fileName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.protein,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.fileSizeLabel(fileSizeKb),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textSecondary(dialogCtx),
                      ),
                    ),
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
                  SnackBar(content: Text(l10n.filePathCopiedSnackBar)),
                );
              },
              child: Text(
                l10n.copyPathAction,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.protein),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.protein,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(l10n.acceptAction, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.backupGenerationError(e.toString())),
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
          if (onImport != null) {
            final content = await file.readAsString();
            return await onImport!(content);
          }
          return await _controller.restoreBackup(file: file);
        },
      ),
    );

    if (result != null && context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.backupRestoreSuccess(
              (result['imported_meals'] ?? 0).toString(),
              (result['imported_pantry'] ?? 0).toString(),
            ),
          ),
          backgroundColor: AppColors.protein,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return VeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_alt_outlined, size: 20, color: AppColors.protein),
              const SizedBox(width: 8),
              Text(
                l10n.backupAndMigrationHeader,
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
            l10n.backupAndMigrationDesc,
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
                  label: Text(l10n.exportJsonAction, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
                  label: Text(l10n.importJsonAction, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
