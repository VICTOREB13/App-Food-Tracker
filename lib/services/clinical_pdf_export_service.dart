import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/interfaces/clinical_pdf_export_service_interface.dart';
import '../core/interfaces/database_service_interface.dart';
import '../models/meal.dart';
import 'accessible_storage_resolver.dart';
import 'database_service.dart';

/// Service generating professional PDF clinical reports with nutritional breakdowns.
class ClinicalPdfExportService implements IClinicalPdfExportService {
  final IDatabaseService _db;

  static ClinicalPdfExportService? _mockInstance;
  static final ClinicalPdfExportService _defaultInstance = ClinicalPdfExportService();

  static ClinicalPdfExportService get instance => _mockInstance ?? _defaultInstance;

  @visibleForTesting
  static void setMockInstance(ClinicalPdfExportService? mock) => _mockInstance = mock;

  ClinicalPdfExportService({IDatabaseService? databaseService})
      : _db = databaseService ?? DatabaseService.instance;

  @override
  Future<Uint8List> generateClinicalPdf({required List<Meal> meals}) async {
    final doc = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    double totalCal = 0.0;
    double totalProt = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;
    double totalFiber = 0.0;
    double totalSodium = 0.0;
    double totalSugar = 0.0;
    final distinctDates = <String>{};

    for (final m in meals) {
      distinctDates.add(dateFormat.format(m.date));
      totalCal += m.calories;
      totalProt += m.protein;
      totalCarbs += m.carbs;
      totalFat += m.fat;
      totalFiber += m.fiber;
      totalSodium += m.sodium;
      totalSugar += m.sugar;
    }

    final daysCount = distinctDates.isEmpty ? 1 : distinctDates.length;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context ctx) => _buildPdfHeader(),
        footer: (pw.Context ctx) => _buildPdfFooter(ctx),
        build: (pw.Context ctx) {
          return [
            pw.SizedBox(height: 10),
            _buildSummaryCard(
              mealsCount: meals.length,
              daysCount: daysCount,
              totalCal: totalCal,
              totalProt: totalProt,
              totalCarbs: totalCarbs,
              totalFat: totalFat,
              totalFiber: totalFiber,
              totalSodium: totalSodium,
              totalSugar: totalSugar,
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Desglose Cronológico de Comidas (${meals.length})',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
            ),
            pw.SizedBox(height: 8),
            _buildMealsTable(meals, dateFormat, timeFormat),
          ];
        },
      ),
    );

    return await doc.save();
  }

  pw.Widget _buildPdfHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal700, width: 1.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('VICTOR ENGINEER - FOOD TRACKER', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
              pw.SizedBox(height: 2),
              pw.Text('Reporte Clínico Nutricional', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
            ],
          ),
          pw.Text('Fecha: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Documento para seguimiento clínico y dietético', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryCard({
    required int mealsCount,
    required int daysCount,
    required double totalCal,
    required double totalProt,
    required double totalCarbs,
    required double totalFat,
    required double totalFiber,
    required double totalSodium,
    required double totalSugar,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Resumen Acumulado y Promedios Diarios', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Métrica', 'Calorías (kcal)', 'Proteína (g)', 'Carbos (g)', 'Grasa (g)', 'Fibra (g)', 'Sodio (mg)', 'Azúcar (g)'],
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.center,
            data: [
              [
                'Total ($mealsCount reg.)',
                totalCal.toStringAsFixed(0),
                totalProt.toStringAsFixed(1),
                totalCarbs.toStringAsFixed(1),
                totalFat.toStringAsFixed(1),
                totalFiber.toStringAsFixed(1),
                totalSodium.toStringAsFixed(0),
                totalSugar.toStringAsFixed(1),
              ],
              [
                'Promedio / Día ($daysCount d.)',
                (totalCal / daysCount).toStringAsFixed(0),
                (totalProt / daysCount).toStringAsFixed(1),
                (totalCarbs / daysCount).toStringAsFixed(1),
                (totalFat / daysCount).toStringAsFixed(1),
                (totalFiber / daysCount).toStringAsFixed(1),
                (totalSodium / daysCount).toStringAsFixed(0),
                (totalSugar / daysCount).toStringAsFixed(1),
              ],
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMealsTable(List<Meal> meals, DateFormat dateFormat, DateFormat timeFormat) {
    if (meals.isEmpty) {
      return pw.Text('No hay comidas registradas en este período.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700));
    }

    final tableData = meals.map((m) {
      return [
        dateFormat.format(m.date),
        timeFormat.format(m.date),
        m.mealType,
        m.name,
        m.calories.toStringAsFixed(0),
        m.protein.toStringAsFixed(1),
        m.carbs.toStringAsFixed(1),
        m.fat.toStringAsFixed(1),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Fecha', 'Hora', 'Tipo', 'Plato', 'Kcal', 'P (g)', 'C (g)', 'G (g)'],
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      data: tableData,
    );
  }

  @override
  Future<File> exportClinicalPdfFile({
    required DateTime startDate,
    required DateTime endDate,
    String? targetDirectoryPath,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    final meals = await _db.getMealsByRange(start, end);
    final pdfBytes = await generateClinicalPdf(meals: meals);

    final Directory directory;
    if (targetDirectoryPath != null) {
      directory = Directory(targetDirectoryPath);
    } else {
      directory = await AccessibleStorageResolver.getAccessibleDocumentsDirectory();
    }
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final dateStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = p.join(directory.path, 'reporte_clinico_nutricion_$dateStamp.pdf');
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes, flush: true);
    return file;
  }
}
