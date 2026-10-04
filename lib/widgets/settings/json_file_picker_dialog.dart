import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import '../../services/backup_service.dart';
import '../../services/theme_manager.dart';

/// Modal dialog allowing the user to select a JSON backup file via the native system file picker.
class JsonFilePickerDialog extends StatefulWidget {
  final Future<Map<String, int>> Function(File file) onRestoreFile;

  const JsonFilePickerDialog({
    super.key,
    required this.onRestoreFile,
  });

  @override
  State<JsonFilePickerDialog> createState() => _JsonFilePickerDialogState();
}

class _JsonFilePickerDialogState extends State<JsonFilePickerDialog> {
  File? _selectedFile;
  Map<String, dynamic>? _previewMetadata;
  bool _isPicking = false;
  bool _isRestoring = false;
  String? _errorMessage;

  Future<void> _pickFileWithNativePicker() async {
    setState(() {
      _isPicking = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        if (path != null && path.isNotEmpty) {
          final file = File(path);
          if (await file.exists()) {
            await _selectFile(file);
          } else {
            setState(() => _errorMessage = 'El archivo seleccionado no existe.');
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Error al abrir el selector: $e');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _selectFile(File file) async {
    setState(() {
      _selectedFile = file;
      _errorMessage = null;
    });

    try {
      final meta = await BackupService.instance.inspectBackupFile(file);
      if (mounted) setState(() => _previewMetadata = meta);
    } catch (e) {
      if (mounted) {
        setState(() {
          _previewMetadata = null;
          _errorMessage = 'Archivo no válido o corrupto: $e';
        });
      }
    }
  }

  Future<void> _confirmRestore() async {
    if (_selectedFile == null) return;
    setState(() => _isRestoring = true);

    try {
      final result = await widget.onRestoreFile(_selectedFile!);
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRestoring = false;
          _errorMessage = 'Error durante la restauración: $e';
        });
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
          const Icon(Icons.file_download_outlined, color: AppColors.protein, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Importar Respaldo JSON',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Selecciona tu archivo JSON de respaldo con un toque desde Descargas, Drive o almacenamiento interno.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context), height: 1.4),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                key: const Key('native_file_picker_button'),
                onPressed: (_isPicking || _isRestoring) ? null : _pickFileWithNativePicker,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.protein,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                icon: _isPicking
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.folder_open_rounded, size: 20),
                label: Text(
                  _isPicking ? 'Abriendo explorador...' : 'Seleccionar Archivo JSON',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              if (_selectedFile != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.protein.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.protein),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: AppColors.protein),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              p.basename(_selectedFile!.path),
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedFile!.path,
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary(context)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
              if (_previewMetadata != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contenido a restaurar:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.protein)),
                      const SizedBox(height: 4),
                      Text(
                        '• ${_previewMetadata!['meals_count']} comidas\n'
                        '• ${_previewMetadata!['pantry_count']} alimentos en despensa\n'
                        '• ${_previewMetadata!['weight_logs_count']} registros de peso',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary(context), height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(_errorMessage!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
        ),
        ElevatedButton(
          key: const Key('confirm_restore_button'),
          onPressed: (_selectedFile != null && !_isRestoring) ? _confirmRestore : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.protein,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isRestoring
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Restaurar Datos', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
