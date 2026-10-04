import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../../services/backup_service.dart';
import '../../services/theme_manager.dart';

/// Modal dialog allowing the user to select an existing JSON backup file or specify a local file path.
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
  final TextEditingController _pathController = TextEditingController();
  List<File> _availableFiles = [];
  File? _selectedFile;
  Map<String, dynamic>? _previewMetadata;
  bool _isLoading = true;
  bool _isRestoring = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailableFiles();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await BackupService.instance.listAvailableBackups();
      if (mounted) {
        setState(() {
          _availableFiles = files;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se pudieron escanear respaldos: $e';
        });
      }
    }
  }

  Future<void> _selectFile(File file) async {
    setState(() {
      _selectedFile = file;
      _pathController.text = file.path;
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

  Future<void> _handleManualPathCheck() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) return;
    final file = File(path);
    if (!await file.exists()) {
      setState(() => _errorMessage = 'El archivo no existe en la ruta especificada.');
      return;
    }
    await _selectFile(file);
  }

  Future<void> _confirmRestore() async {
    if (_selectedFile == null) return;
    setState(() => _isRestoring = true);

    try {
      final result = await widget.onRestoreFile(_selectedFile!);
      if (mounted) {
        Navigator.of(context).pop(result);
      }
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
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selecciona un archivo JSON generado por la app para restaurar todas tus comidas y despensa.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context), height: 1.4),
              ),
              const SizedBox(height: 14),
              Text(
                'Archivos detectados en el dispositivo:',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
              ),
              const SizedBox(height: 8),
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
              else if (_availableFiles.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.border(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'No se encontraron archivos .json automáticos. Ingresa la ruta manualmente abajo.',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context)),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _availableFiles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, idx) {
                      final file = _availableFiles[idx];
                      final isSelected = _selectedFile?.path == file.path;
                      final name = p.basename(file.path);
                      final modified = DateFormat('dd/MM/yyyy HH:mm').format(file.lastModifiedSync());
                      return InkWell(
                        onTap: () => _selectFile(file),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.protein.withValues(alpha: 0.15) : AppColors.surface(context),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? AppColors.protein : AppColors.border(context)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.insert_drive_file_outlined, size: 18, color: isSelected ? AppColors.protein : AppColors.textSecondary(context)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                    Text(modified, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary(context))),
                                  ],
                                ),
                              ),
                              if (isSelected) const Icon(Icons.check_circle, size: 16, color: AppColors.protein),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 14),
              Text(
                'O ruta de archivo:',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context)),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pathController,
                      style: GoogleFonts.inter(fontSize: 11),
                      decoration: InputDecoration(
                        hintText: '/storage/emulated/0/Download/...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.search, size: 20),
                    tooltip: 'Cargar ruta',
                    onPressed: _handleManualPathCheck,
                  ),
                ],
              ),
              if (_previewMetadata != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.protein.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.protein.withValues(alpha: 0.3)),
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
