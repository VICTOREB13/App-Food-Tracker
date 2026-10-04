import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/services/backup_normalizer.dart';

void main() {
  group('BackupNormalizer Tests', () {
    test('raw array wrapping: envuelve lista directa de comidas en {"meals": [...]}', () {
      final rawList = [
        {
          'id': 'm1',
          'nombre': 'Desayuno Clásico',
          'tipo_comida': 'Desayuno',
          'calorias': 350.0,
          'proteinas': 20.0,
          'carbos': 40.0,
          'grasa': 10.0,
        },
        {
          'id': 'm2',
          'nombre': 'Almuerzo Rápido',
          'calorias': 500.0,
        }
      ];

      final normalized =
          BackupNormalizer.decodeAndNormalize(json.encode(rawList));

      expect(normalized['meals'], isA<List>());
      final meals = normalized['meals'] as List;
      expect(meals.length, equals(2));
      expect(meals[0]['name'], equals('Desayuno Clásico'));
      expect(meals[0]['meal_type'], equals('Desayuno'));
      expect(meals[0]['calories'], equals(350.0));
      expect(meals[0]['protein'], equals(20.0));
      expect(meals[1]['name'], equals('Almuerzo Rápido'));
      expect(meals[1]['calories'], equals(500.0));
      expect(normalized['pantry_items'], isEmpty);
      expect(normalized['weight_logs'], isEmpty);
      expect(normalized['user_profile'], isNull);
    });

    test('traducción de claves raíz y de campos en español', () {
      final spanishPayload = {
        'comidas': [
          {
            'id': 'c1',
            'nombre': 'Arepa Reina Pepiada',
            'tipo': 'Cena',
            'calorias': 450.0,
            'proteina': 25.0,
            'carbohidratos': 35.0,
            'grasas': 18.0,
            'fibra': 5.0,
            'sodio': 420.0,
            'azucar': 2.0,
            'notas': 'Cena ligera',
          }
        ],
        'despensa': [
          {
            'id': 'd1',
            'nombre': 'Avena en Hojuelas',
            'marca': 'Quaker',
            'categoria': 'Cereales',
            'calorias': 380.0,
            'proteinas': 14.0,
            'carbos': 65.0,
            'grasas': 7.0,
            'porcion': 40.0,
            'unidad': 'g',
            'peso_neto': 500.0,
            'favorito': 1,
          }
        ],
        'pesos': [
          {
            'id': 'w1',
            'fecha': '2026-10-04T07:00:00.000',
            'peso': 76.8,
            'notas': 'En ayunas',
          }
        ],
        'perfil': {
          'nombre': 'Victor',
          'edad': 29,
          'genero': 'male',
          'altura': 178.0,
          'peso': 76.8,
          'nivel_actividad': 'moderate',
          'meta': 'fat_loss',
          'pasos_estimados': 10000,
          'tmb': 1750.0,
          'tdee': 2700.0,
          'calorias_objetivo': 2200.0,
          'proteina_objetivo': 160.0,
          'carbos_objetivo': 240.0,
          'grasa_objetivo': 60.0,
        }
      };

      final normalized =
          BackupNormalizer.decodeAndNormalize(json.encode(spanishPayload));

      expect(normalized['meals'], isNotEmpty);
      final meal = (normalized['meals'] as List).first as Map<String, dynamic>;
      expect(meal['name'], equals('Arepa Reina Pepiada'));
      expect(meal['meal_type'], equals('Cena'));
      expect(meal['calories'], equals(450.0));
      expect(meal['protein'], equals(25.0));

      expect(normalized['pantry_items'], isNotEmpty);
      final pantry =
          (normalized['pantry_items'] as List).first as Map<String, dynamic>;
      expect(pantry['name'], equals('Avena en Hojuelas'));
      expect(pantry['brand'], equals('Quaker'));
      expect(pantry['serving_size'], equals(40.0));
      expect(pantry['package_weight'], equals(500.0));
      expect(pantry['is_favorite'], equals(1));

      expect(normalized['weight_logs'], isNotEmpty);
      final weight =
          (normalized['weight_logs'] as List).first as Map<String, dynamic>;
      expect(weight['weight'], equals(76.8));
      expect(weight['notes'], equals('En ayunas'));

      expect(normalized['user_profile'], isNotNull);
      final profile = normalized['user_profile'] as Map<String, dynamic>;
      expect(profile['name'], equals('Victor'));
      expect(profile['age'], equals(29));
      expect(profile['target_calories'], equals(2200.0));
    });

    test('preserva respaldos modernos con formato canónico en inglés', () {
      final modernPayload = {
        'app': 'Victor Engineer Food Tracker',
        'version': '2.0.0',
        'schema_version': 2,
        'meals': [
          {'id': 'm1', 'name': 'Lunch', 'calories': 600.0}
        ],
        'pantry_items': [
          {'id': 'p1', 'name': 'Rice', 'calories': 360.0, 'package_weight': 1000.0}
        ],
        'weight_logs': [
          {'id': 'w1', 'weight': 75.5}
        ],
        'user_profile': {
          'name': 'Victor',
          'age': 28,
        }
      };

      final normalized =
          BackupNormalizer.decodeAndNormalize(json.encode(modernPayload));
      expect(normalized['app'], equals('Victor Engineer Food Tracker'));
      expect((normalized['meals'] as List).length, equals(1));
      expect((normalized['pantry_items'] as List).length, equals(1));
      expect((normalized['pantry_items'] as List).first['package_weight'],
          equals(1000.0));
    });

    test(
        'arroja FormatException ante JSON corrupto, tipos inválidos o lista no-mapa',
        () {
      expect(
        () => BackupNormalizer.decodeAndNormalize('{invalid_json: true}'),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => BackupNormalizer.decodeAndNormalize('12345'),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => BackupNormalizer.decodeAndNormalize('"solo un string"'),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => BackupNormalizer.decodeAndNormalize('["no", "es", "un", "mapa"]'),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => BackupNormalizer.decodeAndNormalize('[1, 2, 3]'),
        throwsA(isA<FormatException>()),
      );
    });

    test('decodeAndNormalizeAsync ejecuta exitosamente en Isolate secundario',
        () async {
      final payload = json.encode({
        'comidas': [
          {'nombre': 'Comida Isolate', 'calorias': 300.0}
        ]
      });

      final result = await BackupNormalizer.decodeAndNormalizeAsync(payload);
      expect(result['meals'], isNotEmpty);
      expect((result['meals'] as List).first['name'], equals('Comida Isolate'));
    });

    test('tolerancia y defaults para campos faltantes sin arrojar FormatException',
        () {
      final partialPayload = {
        'comidas': [
          {'id': 'c_parcial'}
        ]
      };

      final normalized =
          BackupNormalizer.decodeAndNormalize(json.encode(partialPayload));
      final meal = (normalized['meals'] as List).first as Map<String, dynamic>;
      expect(meal['id'], equals('c_parcial'));
      expect(meal['name'], equals('Comida'));
      expect(meal['calories'], equals(0.0));
      expect(meal['meal_type'], equals('Almuerzo'));
    });
  });
}
