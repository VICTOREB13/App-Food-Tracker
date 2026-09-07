import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/pantry_item.dart';

void main() {
  group('PantryItem Model Tests', () {
    test('toSqliteMap y fromSqliteMap preservan campos', () {
      final item = PantryItem(
        id: 'pantry-uuid-1',
        name: 'Avena en Hojuelas',
        brand: 'Quaker',
        category: 'Cereales',
        calories: 389.0,
        protein: 16.9,
        carbs: 66.3,
        fat: 6.9,
        isFavorite: true,
      );

      final map = item.toSqliteMap();
      expect(map['name'], equals('Avena en Hojuelas'));
      expect(map['brand'], equals('Quaker'));
      expect(map['category'], equals('Cereales'));
      expect(map['is_favorite'], equals(1));

      final restored = PantryItem.fromSqliteMap(map);
      expect(restored.id, equals(item.id));
      expect(restored.name, equals(item.name));
      expect(restored.brand, equals(item.brand));
      expect(restored.category, equals(item.category));
      expect(restored.calories, equals(389.0));
      expect(restored.isFavorite, isTrue);
    });

    test('copyWith con Sentinel permite eliminar brand y category con null', () {
      final item = PantryItem(
        name: 'Leche Descremada',
        brand: 'Colanta',
        category: 'Lácteos',
        isFavorite: true,
      );

      final cleared = item.copyWith(brand: null, category: null);
      expect(cleared.brand, isNull);
      expect(cleared.category, isNull);
      expect(cleared.name, equals('Leche Descremada'));
      expect(cleared.isFavorite, isTrue);
    });
  });
}
