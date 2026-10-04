import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/pantry_item.dart';
import 'package:food_tracker/services/nutrition_label_scanner_service.dart';

void main() {
  group('NutritionLabelScannerService JSON Parsing Tests', () {
    test('parses clean valid Nutrition Facts JSON correctly', () {
      final jsonSample = json.encode({
        'nombre_producto': 'Harina de Maíz Blanco Precocida',
        'marca': 'P.A.N.',
        'categoria': 'Granos y Harinas',
        'tamano_porcion': 100,
        'unidad_porcion': 'g',
        'calorias': 365.0,
        'proteinas': 7.0,
        'carbohidratos': 78.0,
        'grasas': 1.5,
        'fibra': 4.0,
        'sodio_mg': 5.0,
        'azucar': 0.8,
        'palabras_clave': 'arepa, masa, empanada, bollo',
      });

      final item = NutritionLabelScannerService.parsePantryItemJson(jsonSample);

      expect(item, isNotNull);
      expect(item!.name, 'Harina de Maíz Blanco Precocida');
      expect(item.brand, 'P.A.N.');
      expect(item.category, 'Granos y Harinas');
      expect(item.servingSize, 100.0);
      expect(item.servingUnit, 'g');
      expect(item.calories, 365.0);
      expect(item.protein, 7.0);
      expect(item.carbs, 78.0);
      expect(item.fat, 1.5);
      expect(item.fiber, 4.0);
      expect(item.sodium, 5.0);
      expect(item.sugar, 0.8);
      expect(item.matchKeywords, 'arepa, masa, empanada, bollo');
      expect(item.isVerifiedByUser, isTrue);
    });

    test('strips markdown code blocks correctly', () {
      const rawText = '''
```json
{
  "nombre_producto": "Yogurt Griego Natural",
  "marca": "Chobani",
  "categoria": "Lácteos",
  "tamano_porcion": 150,
  "unidad_porcion": "g",
  "calorias": 130,
  "proteinas": 15,
  "carbohidratos": 6,
  "grasas": 4,
  "fibra": 0,
  "sodio_mg": 65,
  "azucar": 4,
  "palabras_clave": "yogurt, merienda, proteina"
}
```
''';

      final item = NutritionLabelScannerService.parsePantryItemJson(rawText);

      expect(item, isNotNull);
      expect(item!.name, 'Yogurt Griego Natural');
      expect(item.brand, 'Chobani');
      expect(item.servingSize, 150.0);
      expect(item.protein, 15.0);
      expect(item.sodium, 65.0);
      expect(item.isVerifiedByUser, isTrue);
    });

    test('uses brandHint if marca is omitted in JSON', () {
      final jsonSample = json.encode({
        'nombre_producto': 'Avena en Hojuelas',
        'calorias': 370,
        'proteinas': 13,
        'carbohidratos': 66,
        'grasas': 7,
      });

      final item = NutritionLabelScannerService.parsePantryItemJson(
        jsonSample,
        brandHint: 'Quaker',
      );

      expect(item, isNotNull);
      expect(item!.name, 'Avena en Hojuelas');
      expect(item.brand, 'Quaker');
      expect(item.isVerifiedByUser, isTrue);
    });

    test('returns null gracefully on corrupted or malformed input', () {
      expect(NutritionLabelScannerService.parsePantryItemJson(''), isNull);
      expect(NutritionLabelScannerService.parsePantryItemJson('not a json'), isNull);
      expect(NutritionLabelScannerService.parsePantryItemJson('{"other_key": 123}'), isNull);
    });
  });
}
