import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Helper resolving user-accessible Documents storage directory for CSV and PDF clinical exports.
class AccessibleStorageResolver {
  static const String androidPublicDocumentsPath = '/storage/emulated/0/Documents/FoodTracker';
  static const String friendlyExportFolderPath = '/Documents/FoodTracker';

  static Future<Directory> getAccessibleDocumentsDirectory() async {
    if (Platform.isAndroid) {
      final publicDir = Directory(androidPublicDocumentsPath);
      try {
        if (!await publicDir.exists()) {
          await publicDir.create(recursive: true);
        }
        return publicDir;
      } catch (_) {
        // Fallback to app external storage documents directory
      }

      try {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.documents);
        if (extDirs != null && extDirs.isNotEmpty) {
          final dir = Directory(p.join(extDirs.first.path, 'FoodTracker'));
          if (!await dir.exists()) await dir.create(recursive: true);
          return dir;
        }
      } catch (_) {}

      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final dir = Directory(p.join(extDir.path, 'Documents', 'FoodTracker'));
          if (!await dir.exists()) await dir.create(recursive: true);
          return dir;
        }
      } catch (_) {}
    }

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docsDir.path, 'Documents', 'FoodTracker'));
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    } catch (_) {}

    final tempDir = Directory(p.join(Directory.systemTemp.path, 'Documents', 'FoodTracker'));
    if (!await tempDir.exists()) await tempDir.create(recursive: true);
    return tempDir;
  }
}
