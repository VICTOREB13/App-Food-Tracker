import 'dart:io';
import '../../models/meal.dart';

/// Contract for Clinical Tabular Excel/CSV Export Service.
abstract interface class IClinicalExcelExportService {
  String generateClinicalCsv({required List<Meal> meals});

  Future<String> exportClinicalCsv({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<File> exportClinicalCsvFile({
    required DateTime startDate,
    required DateTime endDate,
    String? targetDirectoryPath,
  });
}
