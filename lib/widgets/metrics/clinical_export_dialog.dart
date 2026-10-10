import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import '../../l10n/app_localizations.dart';
import '../../services/accessible_storage_resolver.dart';
import '../../services/clinical_excel_export_service.dart';
import '../../services/clinical_pdf_export_service.dart';
import '../../services/clinical_share_service.dart';
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
        final l10n = AppLocalizations.of(context);
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportError(e.toString())),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.border(context))),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.table_chart_rounded, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.clinicalReportTitle,
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
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
                  Expanded(child: _buildFormatChip('CSV', l10n.exportFormatCsv)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildFormatChip('PDF', l10n.exportFormatPdf)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                l10n.timeRangeLabel,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildRangeChip(7, l10n.sevenDaysLabel)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildRangeChip(30, l10n.thirtyDaysLabel)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildRangeChip(90, l10n.ninetyDaysLabel)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildRangeChip(0, l10n.allTimeHistorical)),
                    ],
                  ),
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                ClinicalShareService.instance.shareFile(_exportedFile!);
                              },
                              icon: const Icon(Icons.share_outlined, size: 16),
                              label: Text(l10n.shareReportAction, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary(context),
                                side: BorderSide(color: AppColors.border(context)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                ClinicalShareService.instance.openFile(_exportedFile!);
                              },
                              icon: const Icon(Icons.open_in_new_rounded, size: 16),
                              label: Text(l10n.openReportAction, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
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
      showCheckmark: false,
      label: Center(child: Text(label)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          HapticFeedback.selectionClick();
          setState(() => _selectedFormat = format);
        }
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
      showCheckmark: false,
      label: Center(child: Text(label)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          HapticFeedback.selectionClick();
          setState(() => _selectedDays = days);
        }
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
