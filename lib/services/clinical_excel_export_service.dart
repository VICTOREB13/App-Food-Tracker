import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/interfaces/clinical_excel_export_service_interface.dart';
import '../core/interfaces/database_service_interface.dart';
import '../models/meal.dart';
import 'database_service.dart';

/// Service generating RFC 4180 compliant CSV reports formatted for clinical analysis.
class ClinicalExcelExportService implements IClinicalExcelExportService {
  final IDatabaseService _db;

  static ClinicalExcelExportService? _mockInstance;
  static final ClinicalExcelExportService _defaultInstance = ClinicalExcelExportService();

  static ClinicalExcelExportService get instance => _mockInstance ?? _defaultInstance;

  @visibleForTesting
  static void setMockInstance(ClinicalExcelExportService? mock) => _mockInstance = mock;

  ClinicalExcelExportService({IDatabaseService? databaseService})
      : _db = databaseService ?? DatabaseService.instance;

  static String escapeCsvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }

  @override
  String generateClinicalCsv({required List<Meal> meals}) {
    final buffer = StringBuffer();
    // UTF-8 BOM for Microsoft Excel / LibreOffice / Google Sheets
    buffer.write('\uFEFF');

    // Header
    buffer.writeln([
      'Fecha',
      'Hora',
      'Tipo de Comida',
      'Nombre del Plato',
      'Calorías (kcal)',
      'Proteína (g)',
      'Carbohidratos (g)',
      'Grasas (g)',
      'Fibra (g)',
      'Sodio (mg)',
      'Azúcar (g)',
      'Ingredientes Desglosados',
      'Notas',
    ].map(escapeCsvField).join(','));

    double totalCal = 0.0;
    double totalProt = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;
    double totalFiber = 0.0;
    double totalSodium = 0.0;
    double totalSugar = 0.0;
    final distinctDates = <String>{};

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    for (final m in meals) {
      final dateStr = dateFormat.format(m.date);
      final timeStr = timeFormat.format(m.date);
      distinctDates.add(dateStr);

      totalCal += m.calories;
      totalProt += m.protein;
      totalCarbs += m.carbs;
      totalFat += m.fat;
      totalFiber += m.fiber;
      totalSodium += m.sodium;
      totalSugar += m.sugar;

      final itemsSummary = m.items.map((i) {
        return '${i.name} (${i.estimatedGrams.toStringAsFixed(0)}g - ${i.calories.toStringAsFixed(0)} kcal)';
      }).join('; ');

      buffer.writeln([
        dateStr,
        timeStr,
        m.mealType,
        m.name,
        m.calories.toStringAsFixed(1),
        m.protein.toStringAsFixed(1),
        m.carbs.toStringAsFixed(1),
        m.fat.toStringAsFixed(1),
        m.fiber.toStringAsFixed(1),
        m.sodium.toStringAsFixed(1),
        m.sugar.toStringAsFixed(1),
        itemsSummary,
        m.notes ?? '',
      ].map(escapeCsvField).join(','));
    }

    // Totals and Daily Averages Section
    buffer.writeln();
    buffer.writeln('--- RESUMEN CLÍNICO ACUMULADO ---');
    buffer.writeln([
      'TOTAL ACUMULADO',
      '',
      '',
      '${meals.length} comidas registradas',
      totalCal.toStringAsFixed(1),
      totalProt.toStringAsFixed(1),
      totalCarbs.toStringAsFixed(1),
      totalFat.toStringAsFixed(1),
      totalFiber.toStringAsFixed(1),
      totalSodium.toStringAsFixed(1),
      totalSugar.toStringAsFixed(1),
      '',
      '',
    ].map(escapeCsvField).join(','));

    final daysCount = distinctDates.isEmpty ? 1 : distinctDates.length;
    buffer.writeln([
      'PROMEDIO DIARIO',
      '',
      '',
      '$daysCount días analizados',
      (totalCal / daysCount).toStringAsFixed(1),
      (totalProt / daysCount).toStringAsFixed(1),
      (totalCarbs / daysCount).toStringAsFixed(1),
      (totalFat / daysCount).toStringAsFixed(1),
      (totalFiber / daysCount).toStringAsFixed(1),
      (totalSodium / daysCount).toStringAsFixed(1),
      (totalSugar / daysCount).toStringAsFixed(1),
      '',
      '',
    ].map(escapeCsvField).join(','));

    return buffer.toString();
  }

  @override
  Future<String> exportClinicalCsv({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    final meals = await _db.getMealsByRange(start, end);
    return generateClinicalCsv(meals: meals);
  }

  @override
  Future<File> exportClinicalCsvFile({
    required DateTime startDate,
    required DateTime endDate,
    String? targetDirectoryPath,
  }) async {
    final csvContent = await exportClinicalCsv(startDate: startDate, endDate: endDate);
    final Directory directory;
    if (targetDirectoryPath != null) {
      directory = Directory(targetDirectoryPath);
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final dateStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = p.join(directory.path, 'reporte_clinico_nutricion_$dateStamp.csv');
    final file = File(filePath);
    await file.writeAsString(csvContent, flush: true);
    return file;
  }
}
