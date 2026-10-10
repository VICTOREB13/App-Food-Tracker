import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/services/clinical_share_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClinicalShareService Tests', () {
    late ClinicalShareService service;

    setUp(() {
      service = ClinicalShareService.instance;
    });

    test('ClinicalShareService provides singleton instance', () {
      expect(service, isNotNull);
    });

    test('resolveMimeType maps standard extensions accurately', () {
      expect(service.resolveMimeType('clinical_report.pdf'), equals('application/pdf'));
      expect(service.resolveMimeType('/path/to/data.csv'), equals('text/csv'));
      expect(service.resolveMimeType('backup.json'), equals('application/json'));
      expect(service.resolveMimeType('photo.png'), equals('image/png'));
      expect(service.resolveMimeType('picture.jpg'), equals('image/jpeg'));
      expect(service.resolveMimeType('picture.jpeg'), equals('image/jpeg'));
      expect(service.resolveMimeType('unknown.xyz'), equals('application/octet-stream'));
      expect(service.resolveMimeType('UPPERCASE.PDF'), equals('application/pdf'));
    });

    test('shareFile returns false if file does not exist', () async {
      final nonExistent = File('path/that/does/not/exist_test_123.pdf');
      final result = await service.shareFile(nonExistent);
      expect(result, isFalse);
    });

    test('openFile returns false if file does not exist', () async {
      final nonExistent = File('path/that/does/not/exist_test_123.csv');
      final result = await service.openFile(nonExistent);
      expect(result, isFalse);
    });
  });
}
