import 'dart:io';
import 'dart:typed_data';
import 'package:food_tracker/features/food_entry/models/meal.dart';

/// Contract for Clinical PDF export services generating patient-facing nutritional reports.
abstract interface class IClinicalPdfExportService {
  Future<Uint8List> generateClinicalPdf({required List<Meal> meals});

  Future<File> exportClinicalPdfFile({
    required DateTime startDate,
    required DateTime endDate,
    String? targetDirectoryPath,
  });
}
