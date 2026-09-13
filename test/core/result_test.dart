import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/core/errors/failures.dart';
import 'package:food_tracker/core/errors/result.dart';

void main() {
  group('Result and Failure Unit Tests', () {
    test('Success returns data and isSuccess is true', () {
      const result = Result<int, Failure>.ok(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, equals(42));
      expect(result.errorOrNull, isNull);
      expect(result.getOrThrow(), equals(42));
      expect(result.getOrDefault(0), equals(42));
    });

    test('FailureResult returns error and isFailure is true', () {
      const failure = DatabaseFailure(message: 'Disk I/O error', sqlCode: 'SQLITE_IOERR');
      const result = Result<int, Failure>.err(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.errorOrNull, equals(failure));
      expect(result.getOrDefault(99), equals(99));
      expect(() => result.getOrThrow(), throwsA(isA<DatabaseFailure>()));
    });

    test('Dart 3 pattern matching works exhaustively with Result', () {
      const Result<String, Failure> success = Result.ok('ok_payload');
      const Result<String, Failure> failure = Result.err(AiServiceFailure(message: 'Rate limit'));

      final successMsg = switch (success) {
        Success(:final data) => 'Parsed: $data',
        FailureResult(:final error) => 'Failed: ${error.message}',
      };
      expect(successMsg, equals('Parsed: ok_payload'));

      final failMsg = switch (failure) {
        Success(:final data) => 'Parsed: $data',
        FailureResult(:final error) => 'Failed: ${error.message}',
      };
      expect(failMsg, equals('Failed: Rate limit'));
    });

    test('fold correctly evaluates success and failure branches', () {
      const success = Result<int, Failure>.ok(10);
      const failure = Result<int, Failure>.err(ValidationFailure(message: 'Invalid weight'));

      final foldedSuccess = success.fold(
        (data) => 'Value: $data',
        (err) => 'Error: ${err.message}',
      );
      expect(foldedSuccess, equals('Value: 10'));

      final foldedFailure = failure.fold(
        (data) => 'Value: $data',
        (err) => 'Error: ${err.message}',
      );
      expect(foldedFailure, equals('Error: Invalid weight'));
    });

    test('map transforms success value and preserves failure', () {
      const success = Result<int, Failure>.ok(5);
      final mapped = success.map((x) => x * 2);
      expect(mapped.dataOrNull, equals(10));

      const failure = Result<int, Failure>.err(StorageFailure(message: 'Corrupted'));
      final mappedFail = failure.map((x) => x * 2);
      expect(mappedFail.isFailure, isTrue);
      expect(mappedFail.errorOrNull?.message, equals('Corrupted'));
    });

    test('flatMap chains computation safely', () {
      const success = Result<int, Failure>.ok(10);
      final chained = success.flatMap((val) => Result<String, Failure>.ok('Score: $val'));
      expect(chained.dataOrNull, equals('Score: 10'));
    });

    test('guard wraps synchronous expressions safely', () {
      final success = Result.guard(() => int.parse('123'));
      expect(success.isSuccess, isTrue);
      expect(success.dataOrNull, equals(123));

      final failure = Result.guard(() => int.parse('not-a-number'));
      expect(failure.isFailure, isTrue);
      expect(failure.errorOrNull, isA<UnknownFailure>());
    });

    test('guardAsync catches asynchronous exceptions', () async {
      final success = await Result.guardAsync(() async => 'hello');
      expect(success.isSuccess, isTrue);
      expect(success.dataOrNull, equals('hello'));

      final failure = await Result.guardAsync<String>(() async {
        throw const ImageProcessingFailure(message: 'Cannot decode png');
      });
      expect(failure.isFailure, isTrue);
      expect(failure.errorOrNull, isA<ImageProcessingFailure>());
    });
  });
}
