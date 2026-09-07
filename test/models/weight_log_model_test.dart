import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/weight_log.dart';

void main() {
  group('WeightLog Model Tests', () {
    test('toMap y fromMap preservan todos los campos fielmente', () {
      final now = DateTime(2026, 9, 7, 10, 15);
      final log = WeightLog(
        id: 'weight-uuid-101',
        date: now,
        weight: 78.4,
        notes: 'Pesaje en ayunas tras cardio matutino',
      );

      final map = log.toMap();
      expect(map['id'], equals('weight-uuid-101'));
      expect(map['date'], equals(now.toIso8601String()));
      expect(map['weight'], equals(78.4));
      expect(map['notes'], equals('Pesaje en ayunas tras cardio matutino'));

      final restored = WeightLog.fromMap(map);
      expect(restored, equals(log));
      expect(restored.id, equals(log.id));
      expect(restored.date, equals(log.date));
      expect(restored.weight, equals(log.weight));
      expect(restored.notes, equals(log.notes));
    });

    test('toSqliteMap y fromSqliteMap serializan y deserializan correctamente', () {
      final date = DateTime(2026, 9, 7, 7, 30);
      final log = WeightLog(
        id: 'sqlite-log-1',
        date: date,
        weight: 81.2,
        notes: 'Registro SQLite',
      );

      final sqliteMap = log.toSqliteMap();
      final restored = WeightLog.fromSqliteMap(sqliteMap);

      expect(restored, equals(log));
      expect(restored.weight, equals(81.2));
    });

    test('toJson y fromJson son compatibles con BackupService', () {
      final log = WeightLog(
        id: 'json-log-1',
        date: DateTime(2026, 9, 7, 8, 0),
        weight: 75.0,
      );

      final jsonMap = log.toJson();
      final restored = WeightLog.fromJson(jsonMap);

      expect(restored.id, equals('json-log-1'));
      expect(restored.weight, equals(75.0));
      expect(restored.notes, isNull);
    });

    test('Límites defensivos se aplican a pesos inválidos y notas desmedidas', () {
      final superLongNotes = 'W' * 3000;
      final negativeLog = WeightLog(
        weight: -15.0,
        notes: superLongNotes,
      );

      expect(negativeLog.weight, equals(0.1));
      expect(negativeLog.notes!.length, equals(2000));
      expect(negativeLog.id, isNotEmpty);

      final excessiveLog = WeightLog(weight: 999.0);
      expect(excessiveLog.weight, equals(500.0));
    });

    test('copyWith con Sentinel borra notas al pasar null explícito', () {
      final log = WeightLog(
        id: 'wl-1',
        weight: 80.0,
        notes: 'Nota existente',
      );

      // Explicit null clears notes
      final cleared = log.copyWith(notes: null);
      expect(cleared.notes, isNull);
      expect(cleared.weight, equals(80.0));

      // Omitting notes keeps existing note
      final updatedWeight = log.copyWith(weight: 79.2);
      expect(updatedWeight.weight, equals(79.2));
      expect(updatedWeight.notes, equals('Nota existente'));

      // New note replaces existing note
      final newNotes = log.copyWith(notes: 'Nueva nota');
      expect(newNotes.notes, equals('Nueva nota'));
    });

    test('Igualdad y hashCode respetan los valores de los campos', () {
      final date = DateTime(2026, 9, 7, 8, 0);
      final logA = WeightLog(id: 'w1', date: date, weight: 70.0, notes: 'A');
      final logB = WeightLog(id: 'w1', date: date, weight: 70.0, notes: 'A');
      final logC = WeightLog(id: 'w2', date: date, weight: 70.0, notes: 'A');

      expect(logA, equals(logB));
      expect(logA.hashCode, equals(logB.hashCode));
      expect(logA == logC, isFalse);
    });
  });
}
