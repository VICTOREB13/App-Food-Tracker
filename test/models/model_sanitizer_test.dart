import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/model_sanitizer.dart';

void main() {
  group('ModelSanitizer Unit Tests', () {
    group('clampDouble', () {
      test('acota números astronómicos al máximo permitido (9999.0)', () {
        final clamped = ModelSanitizer.clampDouble(99999999);
        expect(clamped, equals(9999.0));
      });

      test('acota valores negativos al mínimo permitido (0.0)', () {
        final clamped = ModelSanitizer.clampDouble(-150.5);
        expect(clamped, equals(0.0));
      });

      test('parsea números válidos provistos como cadenas de texto', () {
        final clamped = ModelSanitizer.clampDouble('250.75');
        expect(clamped, equals(250.75));
      });

      test('devuelve el mínimo defensivo ante valores nulos o inválidos', () {
        expect(ModelSanitizer.clampDouble(null), equals(0.0));
        expect(ModelSanitizer.clampDouble('no-es-numero'), equals(0.0));
        expect(ModelSanitizer.clampDouble(double.nan), equals(0.0));
      });

      test('respeta rangos personalizados (ej. metas diarias)', () {
        expect(ModelSanitizer.clampDouble(250, min: 500, max: 10000), equals(500.0));
        expect(ModelSanitizer.clampDouble(25000, min: 500, max: 10000), equals(10000.0));
        expect(ModelSanitizer.clampDouble(2200, min: 500, max: 10000), equals(2200.0));
      });
    });

    group('truncate & truncateNullable', () {
      test('trunca cadenas que exceden el tamaño máximo permitido', () {
        final veryLongName = 'A' * 300;
        final truncated = ModelSanitizer.truncate(veryLongName, 255);
        expect(truncated.length, equals(255));
      });

      test('devuelve fallback cuando la cadena es nula o vacía', () {
        expect(ModelSanitizer.truncate(null, 100, fallback: 'Fallback'), equals('Fallback'));
        expect(ModelSanitizer.truncate('   ', 100, fallback: 'Fallback'), equals('Fallback'));
      });

      test('truncateNullable preserva null ante vacíos o nulos', () {
        expect(ModelSanitizer.truncateNullable(null, 100), isNull);
        expect(ModelSanitizer.truncateNullable('   ', 100), isNull);
        expect(ModelSanitizer.truncateNullable('Hola', 100), equals('Hola'));
      });
    });

    group('parseDate & formatIsoDate', () {
      test('parsea correctamente cadenas ISO 8601', () {
        final parsed = ModelSanitizer.parseDate('2026-09-06T12:00:00.000');
        expect(parsed.year, equals(2026));
        expect(parsed.month, equals(9));
        expect(parsed.day, equals(6));
      });

      test('devuelve fallback ante cadenas corruptas o nulas', () {
        final fallback = DateTime(2026, 1, 1);
        expect(ModelSanitizer.parseDate('corrupt-date', fallback: fallback), equals(fallback));
        expect(ModelSanitizer.parseDate(null, fallback: fallback), equals(fallback));
      });

      test('formatIsoDate serializa DateTime a cadena ISO estándar', () {
        final date = DateTime(2026, 9, 6, 15, 30);
        expect(ModelSanitizer.formatIsoDate(date), contains('2026-09-06T15:30'));
      });
    });
  });
}
