import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/food_item.dart';

void main() {
  group('FoodItem Model Tests', () {
    test('Serialización JSON y deserialización son fieles', () {
      final item = FoodItem(
        id: 'item-uuid-1',
        name: 'Aguacate Hass',
        estimatedGrams: 80,
        calories: 128,
        protein: 1.6,
        carbs: 6.8,
        fat: 11.7,
        visualJustification: 'Aproximadamente medio aguacate mediano',
      );

      final jsonMap = item.toJson();
      expect(jsonMap['alimento'], equals('Aguacate Hass'));
      expect(jsonMap['gramos_estimados'], equals(80.0));
      expect(jsonMap['calorias'], equals(128.0));
      expect(jsonMap['justificacion_visual'], equals('Aproximadamente medio aguacate mediano'));

      final restored = FoodItem.fromJson(jsonMap);
      expect(restored.id, equals(item.id));
      expect(restored.name, equals(item.name));
      expect(restored.calories, equals(item.calories));
      expect(restored.visualJustification, equals(item.visualJustification));
    });

    test('Límites defensivos en gramos y macros', () {
      final item = FoodItem(
        name: 'Queso',
        estimatedGrams: -100,
        calories: -50,
        protein: 999999,
      );

      expect(item.estimatedGrams, equals(0.0));
      expect(item.calories, equals(0.0));
      expect(item.protein, equals(9999.0));
    });

    test('copyWith con Sentinel borra justificacion_visual con null', () {
      final item = FoodItem(
        name: 'Plátano maduro',
        visualJustification: 'Un tercio de plátano frito',
      );

      final updated = item.copyWith(visualJustification: null);
      expect(updated.visualJustification, isNull);
      expect(updated.name, equals('Plátano maduro'));

      final unchanged = item.copyWith(name: 'Plátano verde');
      expect(unchanged.name, equals('Plátano verde'));
      expect(unchanged.visualJustification, equals('Un tercio de plátano frito'));
    });
  });
}
