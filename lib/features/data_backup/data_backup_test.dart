import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/features/data_backup/services/backup_normalizer.dart';
import 'data_backup.dart';

void main() {
  group('BackupProgress Sentinel States & Mutation', () {
    test('initial state has sentinel defaults', () {
      const state = BackupProgress.initial;
      expect(state.status, equals(BackupStatus.idle));
      expect(state.operation, equals(BackupOperationType.none));
      expect(state.exportedFile, isNull);
      expect(state.selectedFile, isNull);
      expect(state.metadata, isNull);
      expect(state.restoreResult, isNull);
      expect(state.errorMessage, isNull);
      expect(state.progress, equals(0.0));
      expect(state.isIdle, isTrue);
      expect(state.isBusy, isFalse);
      expect(state.hasError, isFalse);
      expect(state.hasSuccess, isFalse);
    });

    test('state transitions correctly reflect helper getters', () {
      final exporting = BackupProgress.initial.copyWith(
        status: BackupStatus.exporting,
        operation: BackupOperationType.export,
      );
      expect(exporting.isExporting, isTrue);
      expect(exporting.isBusy, isTrue);
      expect(exporting.isIdle, isFalse);

      final restoring = BackupProgress.initial.copyWith(
        status: BackupStatus.restoring,
        operation: BackupOperationType.restore,
      );
      expect(restoring.isRestoring, isTrue);
      expect(restoring.isBusy, isTrue);

      final error = BackupProgress.initial.copyWith(
        status: BackupStatus.error,
        errorMessage: 'Storage full',
      );
      expect(error.hasError, isTrue);
      expect(error.isBusy, isFalse);
      expect(error.errorMessage, equals('Storage full'));

      final success = BackupProgress.initial.copyWith(
        status: BackupStatus.success,
      );
      expect(success.hasSuccess, isTrue);
      expect(success.isBusy, isFalse);
    });

    test('copyWith preserves properties and sentinel clears nullable values', () {
      final file = File('backup.json');
      const meta = BackupMetadata(
        path: 'backup.json',
        filename: 'backup.json',
        sizeBytes: 1024,
      );

      final state = BackupProgress.initial.copyWith(
        status: BackupStatus.success,
        exportedFile: file,
        metadata: meta,
        errorMessage: 'Temporary',
      );

      expect(state.exportedFile?.path, equals('backup.json'));
      expect(state.metadata?.sizeBytes, equals(1024));
      expect(state.errorMessage, equals('Temporary'));

      // Sentinel clear of errorMessage
      final cleared = state.copyWith(errorMessage: null);
      expect(cleared.errorMessage, isNull);
      expect(cleared.exportedFile?.path, equals('backup.json'));
      expect(cleared.metadata?.sizeBytes, equals(1024));
    });

    test('value equality and hashCode consistency', () {
      const stateA = BackupProgress(status: BackupStatus.idle, progress: 0.5);
      const stateB = BackupProgress(status: BackupStatus.idle, progress: 0.5);
      const stateC = BackupProgress(status: BackupStatus.exporting, progress: 0.5);

      expect(stateA, equals(stateB));
      expect(stateA.hashCode, equals(stateB.hashCode));
      expect(stateA, isNot(equals(stateC)));
    });
  });

  group('BackupMetadata & Size Calculations', () {
    test('computes human readable fileSizeKb accurately', () {
      const meta1 = BackupMetadata(path: 'a', filename: 'a', sizeBytes: 1024);
      expect(meta1.fileSizeKb, equals('1.0'));

      const meta2 = BackupMetadata(path: 'b', filename: 'b', sizeBytes: 2560);
      expect(meta2.fileSizeKb, equals('2.5'));

      const metaZero = BackupMetadata(path: 'c', filename: 'c', sizeBytes: 0);
      expect(metaZero.fileSizeKb, equals('0.0'));
    });

    test('fromMap and toMap serialization symmetry', () {
      final map = {
        'path': '/storage/backups/test.json',
        'filename': 'test.json',
        'size_bytes': 4096,
        'export_date': '2026-11-15T12:00:00Z',
        'meals_count': 10,
        'pantry_count': 5,
        'weight_logs_count': 3,
        'has_user_profile': true,
      };

      final meta = BackupMetadata.fromMap(map);
      expect(meta.path, equals('/storage/backups/test.json'));
      expect(meta.filename, equals('test.json'));
      expect(meta.sizeBytes, equals(4096));
      expect(meta.mealsCount, equals(10));
      expect(meta.pantryCount, equals(5));
      expect(meta.weightLogsCount, equals(3));
      expect(meta.hasUserProfile, isTrue);
      expect(meta.fileSizeKb, equals('4.0'));

      expect(meta.toMap(), equals(map));
    });

    test('fromMap defaults missing fields safely', () {
      final meta = BackupMetadata.fromMap(const {});
      expect(meta.path, isEmpty);
      expect(meta.filename, isEmpty);
      expect(meta.sizeBytes, equals(0));
      expect(meta.mealsCount, equals(0));
      expect(meta.hasUserProfile, isFalse);
    });
  });

  group('JSON Repair Logic (DataBackupController.repairTruncatedJson)', () {
    test('valid JSON remains unchanged and parseable', () {
      const valid = '{"app":"Food Tracker","version":"2.0.0"}';
      final repaired = DataBackupController.repairTruncatedJson(valid);
      final decoded = json.decode(repaired);
      expect(decoded['app'], equals('Food Tracker'));
    });

    test('repairs unclosed string literals', () {
      const truncated = '{"app":"Food Tracker';
      final repaired = DataBackupController.repairTruncatedJson(truncated);
      final decoded = json.decode(repaired);
      expect(decoded['app'], equals('Food Tracker'));
    });

    test('repairs unclosed nested braces and brackets in LIFO order', () {
      const truncated = '{"meals":[{"id":"1","name":"Avena';
      final repaired = DataBackupController.repairTruncatedJson(truncated);
      final decoded = json.decode(repaired) as Map<String, dynamic>;
      final meals = decoded['meals'] as List;
      expect(meals.length, equals(1));
      expect((meals.first as Map)['name'], equals('Avena'));
    });

    test('repairs trailing dangling commas in objects and arrays', () {
      const truncated = '{"items":[1,2,';
      final repaired = DataBackupController.repairTruncatedJson(truncated);
      final decoded = json.decode(repaired) as Map<String, dynamic>;
      expect(decoded['items'], equals([1, 2]));
    });

    test('repairs trailing dangling unvalued keys', () {
      const truncated = '{"count":5,"meals":';
      final repaired = DataBackupController.repairTruncatedJson(truncated);
      final decoded = json.decode(repaired) as Map<String, dynamic>;
      expect(decoded['count'], equals(5));
      expect(decoded.containsKey('meals'), isFalse);
    });

    test('handles empty and whitespace strings gracefully', () {
      expect(DataBackupController.repairTruncatedJson(''), equals(''));
      expect(DataBackupController.repairTruncatedJson('   '), equals(''));
    });
  });

  group('BackupNormalizer Integration', () {
    test('normalizes legacy Spanish backup keys seamlessly', () {
      const rawLegacy = '''{
        "comidas": [{"nombre": "Pollo con arroz", "calorias": 450.0}],
        "despensa": [{"nombre": "Arroz Integral", "porcion": 100.0}],
        "pesos": [{"peso": 75.5, "fecha": "2026-11-15T08:00:00"}]
      }''';

      final normalized = BackupNormalizer.decodeAndNormalize(rawLegacy);
      expect(normalized['meals'], isNotEmpty);
      expect(normalized['meals'].first['name'], equals('Pollo con arroz'));
      expect(normalized['meals'].first['calories'], equals(450.0));
      expect(normalized['pantry_items'], isNotEmpty);
      expect(normalized['pantry_items'].first['name'], equals('Arroz Integral'));
      expect(normalized['weight_logs'], isNotEmpty);
      expect(normalized['weight_logs'].first['weight'], equals(75.5));
    });

    test('normalizes direct meal arrays from v1 backups', () {
      const arrayJson = '[{"nombre": "Yogurt Griego", "calorias": 120.0}]';
      final normalized = BackupNormalizer.decodeAndNormalize(arrayJson);
      expect(normalized['meals'], hasLength(1));
      expect(normalized['meals'].first['name'], equals('Yogurt Griego'));
    });
  });
}
