import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/food_item.dart';
import 'package:food_tracker/models/meal.dart';
import 'package:food_tracker/services/clinical_excel_export_service.dart';

void main() {
  group('ClinicalExcelExportService CSV Generation Tests', () {
    late ClinicalExcelExportService service;

    setUp(() {
      service = ClinicalExcelExportService();
    });

    test('generates CSV with UTF-8 BOM and correct clinical header', () {
      final csv = service.generateClinicalCsv(meals: []);

      expect(csv.startsWith('\uFEFF'), isTrue, reason: 'Must contain UTF-8 BOM for Excel compatibility');
      expect(csv, contains('Fecha,Hora,Tipo de Comida,Nombre del Plato,Calorías (kcal),Proteína (g),Carbohidratos (g),Grasas (g),Fibra (g),Sodio (mg),Azúcar (g),Ingredientes Desglosados,Notas'));
      expect(csv, contains('--- RESUMEN CLÍNICO ACUMULADO ---'));
      expect(csv, contains('TOTAL ACUMULADO'));
      expect(csv, contains('PROMEDIO DIARIO'));
    });

    test('escapes fields properly per RFC 4180', () {
      expect(ClinicalExcelExportService.escapeCsvField('Arroz blanco'), 'Arroz blanco');
      expect(ClinicalExcelExportService.escapeCsvField('Arroz, frijoles'), '"Arroz, frijoles"');
      expect(ClinicalExcelExportService.escapeCsvField('Pollo "asado"'), '"Pollo ""asado"""');
      expect(ClinicalExcelExportService.escapeCsvField('Línea 1\nLínea 2'), '"Línea 1\nLínea 2"');
    });

    test('formats clinical meal rows, items breakdown, and cumulative totals correctly', () {
      final meal1 = Meal(
        id: 'm1',
        name: 'Pabellón Criollo, Especial',
        mealType: 'Almuerzo',
        date: DateTime(2026, 10, 4, 13, 30),
        calories: 750,
        protein: 42,
        carbs: 85,
        fat: 22,
        fiber: 12,
        sodium: 480,
        sugar: 6,
        notes: 'Sin queso rallado adicional',
        items: [
          FoodItem(name: 'Carne mechada', estimatedGrams: 120, calories: 250, protein: 28, carbs: 2, fat: 14),
          FoodItem(name: 'Caraotas negras', estimatedGrams: 140, calories: 180, protein: 10, carbs: 30, fat: 1, fiber: 9),
          FoodItem(name: 'Arroz blanco', estimatedGrams: 150, calories: 200, protein: 4, carbs: 45, fat: 1),
          FoodItem(name: 'Tajadas de plátano', estimatedGrams: 60, calories: 120, protein: 0, carbs: 8, fat: 6, sugar: 5),
        ],
      );

      final meal2 = Meal(
        id: 'm2',
        name: 'Cena Ligera',
        mealType: 'Cena',
        date: DateTime(2026, 10, 4, 20, 0),
        calories: 350,
        protein: 25,
        carbs: 15,
        fat: 10,
        fiber: 4,
        sodium: 220,
        sugar: 2,
        notes: null,
        items: [
          FoodItem(name: 'Ensalada con atún', estimatedGrams: 180, calories: 350, protein: 25, carbs: 15, fat: 10),
        ],
      );

      final csv = service.generateClinicalCsv(meals: [meal1, meal2]);

      // Meal 1 row check (escaped due to comma in name)
      expect(csv, contains('"Pabellón Criollo, Especial"'));
      expect(csv, contains('Almuerzo'));
      expect(csv, contains('750.0'));
      expect(csv, contains('42.0'));
      expect(csv, contains('480.0'));
      expect(csv, contains('Carne mechada (120g - 250 kcal)'));
      expect(csv, contains('Sin queso rallado adicional'));

      // Meal 2 row check
      expect(csv, contains('Cena Ligera'));
      expect(csv, contains('350.0'));
      expect(csv, contains('25.0'));

      // Cumulative summary check: total cal = 1100, prot = 67, sodium = 700
      expect(csv, contains('1100.0'));
      expect(csv, contains('67.0'));
      expect(csv, contains('700.0'));
      expect(csv, contains('2 comidas registradas'));
      expect(csv, contains('1 días analizados'));
    });
  });
}
