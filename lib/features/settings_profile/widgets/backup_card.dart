import 'dart:io';
import 'package:flutter/material.dart';
import 'package:food_tracker/features/data_backup/data_backup.dart';

/// Legacy backwards-compatibility wrapper delegating to DataBackupView.
/// Maintained so legacy callers continue functioning without breaking changes.
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

  @override
  Widget build(BuildContext context) {
    return DataBackupView(
      onExport: onExport,
      onImport: onImport,
      onExportFile: onExportFile,
      onImportFile: onImportFile,
    );
  }
}
