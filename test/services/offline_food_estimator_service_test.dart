import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/services/offline_food_estimator_service.dart';

void main() {
  late OfflineFoodEstimatorService estimator;

  setUp(() {
    estimator = OfflineFoodEstimatorService.instance;
  });

  group('OfflineFoodEstimatorService Tests', () {
    test('estimateNutrients accurately estimates base food item per 100g', () {
      final item = estimator.estimateNutrients(query: 'pechuga de pollo', grams: 100.0);
      expect(item, isNotNull);
      expect(item!.name, equals('pechuga de pollo'));
      expect(item.estimatedGrams, equals(100.0));
      expect(item.protein, equals(31.0));
      expect(item.calories, equals(165.0));
      expect(item.fat, equals(3.6));
      expect(item.carbs, equals(0.0));
      expect(item.sodium, equals(74.0));
    });

    test('estimateNutrients scales linearly with requested grams', () {
      final item200g = estimator.estimateNutrients(query: 'arroz blanco', grams: 200.0);
      expect(item200g, isNotNull);
      expect(item200g!.estimatedGrams, equals(200.0));
      expect(item200g.calories, equals(260.0)); // 130 * 2
      expect(item200g.carbs, closeTo(56.4, 0.1)); // 28.2 * 2
    });

    test('estimateNutrients is accent-insensitive and case-insensitive', () {
      final withAccent = estimator.estimateNutrients(query: 'Plátano maduro', grams: 100.0);
      final withoutAccent = estimator.estimateNutrients(query: 'platano maduro', grams: 100.0);
      final upperCase = estimator.estimateNutrients(query: 'PLATANO MADURO', grams: 100.0);

      expect(withAccent, isNotNull);
      expect(withoutAccent, isNotNull);
      expect(upperCase, isNotNull);
      expect(withAccent!.calories, equals(withoutAccent!.calories));
      expect(withAccent.calories, equals(upperCase!.calories));
    });

    test('estimateNutrients calculates micronutrients (fiber, sodium, sugar)', () {
      final aguacate = estimator.estimateNutrients(query: 'aguacate hass', grams: 100.0);
      expect(aguacate, isNotNull);
      expect(aguacate!.fiber, equals(6.7));
      expect(aguacate.sodium, equals(7.0));
      expect(aguacate.sugar, equals(0.7));

      final manzana = estimator.estimateNutrients(query: 'manzana', grams: 150.0);
      expect(manzana, isNotNull);
      expect(manzana!.sugar, closeTo(15.6, 0.1)); // 10.4 * 1.5
      expect(manzana.fiber, closeTo(3.6, 0.1)); // 2.4 * 1.5
    });

    test('estimateNutrients returns null for unknown items or zero/negative grams', () {
      expect(estimator.estimateNutrients(query: 'computadora cuantica', grams: 100.0), isNull);
      expect(estimator.estimateNutrients(query: 'arroz', grams: 0.0), isNull);
      expect(estimator.estimateNutrients(query: 'arroz', grams: -50.0), isNull);
      expect(estimator.estimateNutrients(query: '', grams: 100.0), isNull);
    });

    test('searchCatalog returns matches up to specified limit', () {
      final results = estimator.searchCatalog(query: 'pollo', limit: 5);
      expect(results.isNotEmpty, isTrue);
      expect(results.length, lessThanOrEqualTo(5));
      expect(results.any((r) => r.name.toLowerCase().contains('pollo')), isTrue);
    });
  });
}
