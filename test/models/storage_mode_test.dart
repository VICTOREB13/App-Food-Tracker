import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/storage_mode.dart';

void main() {
  group('StorageMode Tests', () {
    test('fromString parses private correctly', () {
      expect(StorageMode.fromString('private'), equals(StorageMode.private));
    });

    test('fromString defaults to public for null, empty or unknown strings', () {
      expect(StorageMode.fromString(null), equals(StorageMode.public));
      expect(StorageMode.fromString(''), equals(StorageMode.public));
      expect(StorageMode.fromString('public'), equals(StorageMode.public));
      expect(StorageMode.fromString('other'), equals(StorageMode.public));
    });

    test('name matches expected enum strings', () {
      expect(StorageMode.public.name, equals('public'));
      expect(StorageMode.private.name, equals('private'));
    });
  });
}
