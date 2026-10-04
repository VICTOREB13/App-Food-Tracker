import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/services/food_search_coordinator.dart';

void main() {
  group('FoodSearchCoordinator Tests', () {
    test('search returns empty list for short queries', () async {
      final results = await FoodSearchCoordinator.instance.search('a');
      expect(results, isEmpty);
    });

    test('search finds local items with Local badge', () async {
      final results = await FoodSearchCoordinator.instance.search('Pollo');
      expect(results, isNotEmpty);
      final first = results.first;
      expect(first.name.toLowerCase(), contains('pollo'));
      expect(first.caloriesPer100g, greaterThan(0));
      expect(first.sourceBadgeLabel, equals('Local'));
    });
  });
}
