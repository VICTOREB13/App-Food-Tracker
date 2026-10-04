import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/clinical_excel_export_service.dart';
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
  bool _isExporting = false;
  File? _exportedFile;

  Future<void> _export() async {
    setState(() => _isExporting = true);
    try {
      final now = DateTime.now();
      final DateTime start;
      if (_selectedDays == 0) {
        start = DateTime(2000, 1, 1);
      } else {
        start = now.subtract(Duration(days: _selectedDays));
      }

      final file = await ClinicalExcelExportService.instance.exportClinicalCsvFile(
        startDate: start,
        endDate: now,
      );

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
              'Reporte Clínico',
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
                'Exporta tu historial nutricional tabulado con macros, fibra, sodio y azúcar para tu consulta clínica o nutricionista.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context), height: 1.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Rango temporal:',
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
                  padding: const EdgeInsets.all(10),
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
                          const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                          const SizedBox(width: 6),
                          Text('Archivo generado con éxito', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _exportedFile!.path,
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary(context)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _exportedFile!.path));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ruta copiada al portapapeles')),
                          );
                        },
                        child: Text(
                          'Copiar ruta del archivo',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
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
          child: Text('Cerrar', style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
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
              : Text('Exportar CSV', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ),
      ],
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
