import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/core/interfaces/database_service_interface.dart';
import 'package:food_tracker/models/food_item.dart';
import 'package:food_tracker/models/meal.dart';
import 'package:food_tracker/services/clinical_pdf_export_service.dart';

class _FakeDatabaseService implements IDatabaseService {
  final List<Meal> meals;
  _FakeDatabaseService([this.meals = const []]);

  @override
  Future<List<Meal>> getMealsByRange(DateTime start, DateTime end) async => meals;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClinicalPdfExportService Tests', () {
    late ClinicalPdfExportService service;
    late Meal meal1;

    setUp(() {
      meal1 = Meal(
        id: 'm1',
        name: 'Pollo con arroz y ensalada',
        mealType: 'Almuerzo',
        date: DateTime(2026, 10, 8, 13, 0),
        calories: 620,
        protein: 48,
        carbs: 65,
        fat: 16,
        fiber: 7,
        sodium: 420,
        sugar: 3,
        items: [
          FoodItem(name: 'Pechuga de pollo', estimatedGrams: 150, calories: 240, protein: 42, carbs: 0, fat: 5),
          FoodItem(name: 'Arroz blanco', estimatedGrams: 180, calories: 230, protein: 4, carbs: 50, fat: 1),
        ],
      );
      service = ClinicalPdfExportService(databaseService: _FakeDatabaseService([meal1]));
    });

    test('generateClinicalPdf produces non-empty valid PDF bytes with %PDF magic header', () async {
      final pdfBytes = await service.generateClinicalPdf(meals: [meal1]);

      expect(pdfBytes.isNotEmpty, isTrue);
      // Valid PDF documents start with %PDF- (ASCII bytes: 0x25, 0x50, 0x44, 0x46, 0x2D)
      expect(pdfBytes.length, greaterThan(100));
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('generateClinicalPdf handles empty meal list cleanly without crashing', () async {
      final pdfBytes = await service.generateClinicalPdf(meals: []);
      expect(pdfBytes.isNotEmpty, isTrue);
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('exportClinicalPdfFile writes PDF file to specified directory', () async {
      final tempDir = await Directory.systemTemp.createTemp('pdf_test_');
      try {
        final now = DateTime.now();
        final file = await service.exportClinicalPdfFile(
          startDate: now.subtract(const Duration(days: 7)),
          endDate: now,
          targetDirectoryPath: tempDir.path,
        );

        expect(await file.exists(), isTrue);
        expect(file.path.endsWith('.pdf'), isTrue);
        final bytes = await file.readAsBytes();
        expect(bytes.length, greaterThan(100));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
