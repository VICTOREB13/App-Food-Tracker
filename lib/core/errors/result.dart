import 'failures.dart';

/// A type representing either a successful computation [Success] with value [T],
/// or an operation that failed [FailureResult] with an error [E].
///
/// Provides compile-time exhaustive pattern matching in Dart 3:
/// ```dart
/// final result = await service.perform();
/// switch (result) {
///   case Success(data: final val):
///     print('Success: $val');
///   case FailureResult(error: final err):
///     print('Failure: ${err.message}');
/// }
/// ```
sealed class Result<T, E extends Failure> {
  const Result();

  /// Creates a successful result holding [data].
  const factory Result.ok(T data) = Success<T, E>;

  /// Creates a failed result holding [error].
  const factory Result.err(E error) = FailureResult<T, E>;

  /// Returns true if this is a [Success].
  bool get isSuccess => this is Success<T, E>;

  /// Returns true if this is a [FailureResult].
  bool get isFailure => this is FailureResult<T, E>;

  /// Retrieves data if success, or `null` otherwise.
  T? get dataOrNull => switch (this) {
        Success(:final data) => data,
        FailureResult() => null,
      };

  /// Retrieves failure if error, or `null` otherwise.
  E? get errorOrNull => switch (this) {
        Success() => null,
        FailureResult(:final error) => error,
      };

  /// Unwraps the value or throws the contained [Failure] or an exception.
  T getOrThrow() => switch (this) {
        Success(:final data) => data,
        FailureResult(:final error) => throw error,
      };

  /// Returns the value if successful, or [defaultValue] if failed.
  T getOrDefault(T defaultValue) => switch (this) {
        Success(:final data) => data,
        FailureResult() => defaultValue,
      };

  /// Folds both paths into a single output [R].
  R fold<R>(
    R Function(T data) onSuccess,
    R Function(E error) onFailure,
  ) {
    return switch (this) {
      Success(:final data) => onSuccess(data),
      FailureResult(:final error) => onFailure(error),
    };
  }

  /// Transforms the success value [T] into [R].
  Result<R, E> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success(:final data) => Success(transform(data)),
      FailureResult(:final error) => FailureResult(error),
    };
  }

  /// Chains another operation that returns a [Result].
  Result<R, E> flatMap<R>(Result<R, E> Function(T data) transform) {
    return switch (this) {
      Success(:final data) => transform(data),
      FailureResult(:final error) => FailureResult(error),
    };
  }

  /// Transforms the failure value [E] into [R].
  Result<T, R> mapError<R extends Failure>(R Function(E error) transform) {
    return switch (this) {
      Success(:final data) => Success(data),
      FailureResult(:final error) => FailureResult(transform(error)),
    };
  }

  /// Executes asynchronous action [fn] and wraps any thrown exceptions into a [FailureResult].
  static Future<Result<T, Failure>> guardAsync<T>(
    Future<T> Function() fn, {
    Failure Function(Object error, StackTrace stack)? onError,
  }) async {
    try {
      final value = await fn();
      return Success(value);
    } catch (e, stack) {
      if (onError != null) {
        return FailureResult(onError(e, stack));
      }
      if (e is Failure) {
        return FailureResult(e);
      }
      return FailureResult(UnknownFailure(message: e.toString(), cause: e, stackTrace: stack));
    }
  }

  /// Executes synchronous action [fn] and wraps any thrown exceptions into a [FailureResult].
  static Result<T, Failure> guard<T>(
    T Function() fn, {
    Failure Function(Object error, StackTrace stack)? onError,
  }) {
    try {
      final value = fn();
      return Success(value);
    } catch (e, stack) {
      if (onError != null) {
        return FailureResult(onError(e, stack));
      }
      if (e is Failure) {
        return FailureResult(e);
      }
      return FailureResult(UnknownFailure(message: e.toString(), cause: e, stackTrace: stack));
    }
  }
}

/// A successful [Result] containing [data].
final class Success<T, E extends Failure> extends Result<T, E> {
  final T data;

  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T, E> && runtimeType == other.runtimeType && data == other.data;

  @override
  int get hashCode => Object.hash(runtimeType, data);

  @override
  String toString() => 'Success($data)';
}

/// A failed [Result] containing [error].
final class FailureResult<T, E extends Failure> extends Result<T, E> {
  final E error;

  const FailureResult(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FailureResult<T, E> && runtimeType == other.runtimeType && error == other.error;

  @override
  int get hashCode => Object.hash(runtimeType, error);

  @override
  String toString() => 'FailureResult($error)';
}
