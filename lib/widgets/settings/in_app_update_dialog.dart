import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../core/di/service_locator.dart';
import '../../core/interfaces/app_installer_service_interface.dart';
import '../../core/interfaces/app_update_service_interface.dart';
import '../../models/github_release_model.dart';
import '../../services/theme_manager.dart';
import '../../services/app_update_service.dart';
import '../../services/app_installer_service.dart';

/// Opens the in-app updater modal dialog.
Future<void> showInAppUpdateDialog(
  BuildContext context, {
  required GitHubReleaseModel release,
  IAppUpdateService? updateService,
  IAppInstallerService? installerService,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => InAppUpdateDialog(release: release, updateService: updateService, installerService: installerService),
);

/// Modal dialog for reviewing changelogs and downloading/installing GitHub APK releases.
class InAppUpdateDialog extends StatefulWidget {
  final GitHubReleaseModel release;
  final IAppUpdateService? updateService;
  final IAppInstallerService? installerService;

  const InAppUpdateDialog({super.key, required this.release, this.updateService, this.installerService});

  @override
  State<InAppUpdateDialog> createState() => _InAppUpdateDialogState();
}

class _InAppUpdateDialogState extends State<InAppUpdateDialog> {
  late final IAppUpdateService _updateService;
  late final IAppInstallerService _installerService;

  bool _isDownloading = false;
  bool _isInstalling = false;
  bool _isCancelled = false;
  http.Client? _downloadClient;
  double _progressRatio = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _downloadedApkPath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _updateService = widget.updateService ??
        (getIt.isRegistered<IAppUpdateService>() ? getIt<IAppUpdateService>() : AppUpdateService.instance);
    _installerService = widget.installerService ??
        (getIt.isRegistered<IAppInstallerService>() ? getIt<IAppInstallerService>() : AppInstallerService.instance);
  }

  @override
  void dispose() {
    _downloadClient?.close();
    super.dispose();
  }

  String _formatSize(int? bytes) =>
      (bytes == null || bytes <= 0) ? '' : '~${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  static String _sanitizeErrorMessage(dynamic error) {
    if (error == null) return 'Error desconocido durante la descarga.';
    final s = error is HttpException ? error.message : error.toString();
    final clean = s
        .replaceAll(RegExp(r',?\s*uri\s*=\s*https?://\S+', caseSensitive: false), '')
        .replaceAll(RegExp(r'https?://\S+'), '')
        .replaceAll(RegExp(r'\?[^ ]*AWSAccessKeyId[^ ]*', caseSensitive: false), '');
    final lower = s.toLowerCase();
    if (lower.contains('socketexception') || lower.contains('clientexception') ||
        lower.contains('connection') || lower.contains('timed out') || lower.contains('network')) {
      return 'Error de conexión al descargar la actualización. Verifica tu red e inténtalo de nuevo.';
    }
    final trimmed = clean.replaceAll(RegExp(r'^Exception:\s*'), '').trim();
    if (trimmed.length < 8 || trimmed.length > 120) {
      if (lower.contains('403') || lower.contains('404')) {
        return 'No se pudo acceder al archivo de actualización en GitHub.';
      }
      return 'Error al descargar el archivo de actualización. Por favor, reintenta.';
    }
    return trimmed;
  }

  void _cancelDownload() {
    _isCancelled = true;
    _downloadClient?.close();
    _downloadClient = null;
    if (mounted) setState(() { _isDownloading = false; _errorMessage = 'Descarga cancelada por el usuario.'; });
  }

  Future<void> _startUpdate() async {
    final apkUrl = widget.release.apkDownloadUrl;
    if (apkUrl == null || apkUrl.isEmpty) {
      await _installerService.openWebRelease(widget.release.htmlUrl);
      return;
    }

    _isCancelled = false;
    _downloadClient = http.Client();
    setState(() { _isDownloading = true; _errorMessage = null; _progressRatio = 0.0; });

    try {
      final apkFile = await _updateService.downloadApk(
        downloadUrl: apkUrl,
        versionTag: widget.release.tagName,
        client: _downloadClient,
        onProgress: (ratio, rec, tot) {
          if (mounted && !_isCancelled) {
            setState(() { _progressRatio = ratio; _receivedBytes = rec; _totalBytes = tot; });
          }
        },
      );

      if (_isCancelled) return;
      _downloadedApkPath = apkFile.path;
      if (!mounted) return;
      setState(() { _isDownloading = false; _isInstalling = true; });

      final success = await _installerService.installApk(apkFile.path);
      if (!mounted) return;
      setState(() => _isInstalling = false);

      if (!success) {
        setState(() => _errorMessage = 'No se pudo iniciar la instalación automática.');
      }
    } catch (e) {
      if (mounted) {
        if (_isCancelled) {
          setState(() { _isDownloading = false; _isInstalling = false; _errorMessage = 'Descarga cancelada por el usuario.'; });
          return;
        }
        setState(() { _isDownloading = false; _isInstalling = false; _errorMessage = _sanitizeErrorMessage(e); });
      }
    } finally {
      _downloadClient = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final release = widget.release;
    final sizeLabel = _formatSize(release.apkSizeBytes);

    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.border(context))),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.system_update_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Actualización Disponible', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                      child: Text(release.tagName, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    if (sizeLabel.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(sizeLabel, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context))),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Notas de la versión:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.background(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border(context))),
                child: SingleChildScrollView(
                  child: Text(
                    release.releaseNotes.isNotEmpty ? release.releaseNotes : 'Nuevas mejoras de rendimiento y estabilidad.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary(context), height: 1.4),
                  ),
                ),
              ),
              if (_isDownloading) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _progressRatio > 0 ? _progressRatio : null,
                    backgroundColor: AppColors.border(context),
                    color: AppColors.primary,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Descargando... ${(_progressRatio * 100).toInt()}% (${(_receivedBytes / (1024 * 1024)).toStringAsFixed(1)} MB / ${_totalBytes > 0 ? (_totalBytes / (1024 * 1024)).toStringAsFixed(1) : '?'} MB)',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context)),
                ),
              ],
              if (_isInstalling) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 8),
                    Text('Iniciando instalador de paquetes...', style: GoogleFonts.inter(fontSize: 12)),
                  ],
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(_errorMessage!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                if (_downloadedApkPath != null) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () => _installerService.installApk(_downloadedApkPath!),
                    icon: const Icon(Icons.install_mobile, size: 16),
                    label: const Text('Reintentar instalación nativa'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (_isDownloading)
          TextButton.icon(
            key: const Key('cancel_download_button'),
            onPressed: _cancelDownload,
            icon: const Icon(Icons.close_rounded, size: 16),
            label: Text('Cancelar descarga', style: GoogleFonts.inter(color: AppColors.primary)),
          ),
        if (!_isDownloading && !_isInstalling)
          TextButton(
            key: const Key('later_button'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Más tarde', style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
          ),
        TextButton(
          onPressed: () => _installerService.openWebRelease(release.htmlUrl),
          child: Text('Ver en GitHub', style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
        ),
        if (!_isDownloading && !_isInstalling)
          ElevatedButton(
            key: const Key('start_in_app_update_button'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: _startUpdate,
            child: Text(release.hasApk ? 'Actualizar Ahora' : 'Abrir en Navegador', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}
