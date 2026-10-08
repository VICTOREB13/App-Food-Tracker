import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_es.dart';
import '../../services/accessible_storage_resolver.dart';
import '../../services/clinical_excel_export_service.dart';
import '../../services/clinical_pdf_export_service.dart';
import '../../services/theme_manager.dart';

Future<void> showClinicalExportDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => const _ClinicalExportDialog(),
  );
}

class _ClinicalExportDialog extends StatefulWidget {
  const _ClinicalExportDialog();

  @override
  State<_ClinicalExportDialog> createState() => _ClinicalExportDialogState();
}

class _ClinicalExportDialogState extends State<_ClinicalExportDialog> {
  int _selectedDays = 30;
  String _selectedFormat = 'CSV'; // 'CSV' or 'PDF'
  bool _isExporting = false;
  File? _exportedFile;

  Future<void> _export() async {
    setState(() => _isExporting = true);
    try {
      final now = DateTime.now();
      final DateTime start = _selectedDays == 0 ? DateTime(2000, 1, 1) : now.subtract(Duration(days: _selectedDays));

      final File file;
      if (_selectedFormat == 'PDF') {
        file = await ClinicalPdfExportService.instance.exportClinicalPdfFile(
          startDate: start,
          endDate: now,
        );
      } else {
        file = await ClinicalExcelExportService.instance.exportClinicalCsvFile(
          startDate: start,
          endDate: now,
        );
      }

      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportedFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();

    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border(context)),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.table_chart_rounded, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.clinicalReportTitle,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.clinicalExportDesc,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context), height: 1.4),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.exportFormatLabel,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildFormatChip('CSV', l10n.exportFormatCsv),
                  const SizedBox(width: 8),
                  _buildFormatChip('PDF', l10n.exportFormatPdf),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                l10n.timeRangeLabel,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildRangeChip(7, '7 días'),
                  _buildRangeChip(30, '30 días'),
                  _buildRangeChip(90, '90 días'),
                  _buildRangeChip(0, 'Histórico'),
                ],
              ),
              const SizedBox(height: 16),
              if (_exportedFile != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, size: 18, color: AppColors.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.exportSuccessTitle,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.exportSavedInFolder(AccessibleStorageResolver.friendlyExportFolderPath),
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.basename(_exportedFile!.path),
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.closeButton, style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
        ),
        ElevatedButton(
          onPressed: _isExporting ? null : _export,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isExporting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_selectedFormat == 'CSV' ? l10n.exportCsvButton : l10n.exportPdfButton, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildFormatChip(String format, String label) {
    final isSelected = _selectedFormat == format;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFormat = format);
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.textSecondary(context),
      ),
    );
  }

  Widget _buildRangeChip(int days, String label) {
    final isSelected = _selectedDays == days;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedDays = days);
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.textSecondary(context),
      ),
    );
  }
}
