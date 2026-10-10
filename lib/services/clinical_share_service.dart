import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

/// Service facilitating native share sheet intents and OS file previews.
class ClinicalShareService {
  static final ClinicalShareService instance = ClinicalShareService._();
  ClinicalShareService._();

  static const MethodChannel _channel =
      MethodChannel('com.victorengineer.foodtracker/app_installer');

  /// Resolves MIME type from standard file extension.
  String resolveMimeType(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.pdf':
        return 'application/pdf';
      case '.csv':
        return 'text/csv';
      case '.json':
        return 'application/json';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  /// Dispatches the file to the native system share sheet.
  Future<bool> shareFile(File file, {String? title}) async {
    if (!await file.exists()) {
      debugPrint('ClinicalShareService: file does not exist at ${file.path}');
      return false;
    }

    final mimeType = resolveMimeType(file.path);
    final shareTitle = title ?? 'Compartir reporte';

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final res = await _channel.invokeMethod<bool>('shareFile', {
          'filePath': file.path,
          'mimeType': mimeType,
          'title': shareTitle,
        });
        return res ?? false;
      } catch (e) {
        debugPrint('ClinicalShareService: Android share intent error: $e');
        return false;
      }
    }

    // Desktop/Fallback: Open file location
    return openFile(file);
  }

  /// Opens the file with the operating system's default viewer (PDF/CSV/Sheets).
  Future<bool> openFile(File file) async {
    if (!await file.exists()) {
      debugPrint('ClinicalShareService: file does not exist at ${file.path}');
      return false;
    }

    final mimeType = resolveMimeType(file.path);

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final res = await _channel.invokeMethod<bool>('openFile', {
          'filePath': file.path,
          'mimeType': mimeType,
        });
        return res ?? false;
      } catch (e) {
        debugPrint('ClinicalShareService: Android open file error: $e');
        return false;
      }
    }

    // Windows / macOS / Linux fallback
    try {
      final uri = Uri.file(file.path);
      return await launchUrl(uri);
    } catch (_) {
      if (!kIsWeb && Platform.isWindows) {
        try {
          final result = await Process.run('cmd', ['/c', 'start', '', file.path]);
          return result.exitCode == 0;
        } catch (e) {
          debugPrint('ClinicalShareService: Windows launch error: $e');
        }
      }
      return false;
    }
  }
}
