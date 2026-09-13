import 'package:flutter/foundation.dart';

/// Base sealed class representing a domain failure in the application.
@immutable
sealed class Failure {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const Failure({
    required this.message,
    this.cause,
    this.stackTrace,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          cause == other.cause;

  @override
  int get hashCode => Object.hash(runtimeType, message, cause);

  @override
  String toString() => '$runtimeType: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Represents failures originating from SQLite, migrations, or DAOs.
class DatabaseFailure extends Failure {
  final String? sqlCode;

  const DatabaseFailure({
    required super.message,
    this.sqlCode,
    super.cause,
    super.stackTrace,
  });
}

/// Represents failures from Gemini Vision or generative AI interactions.
class AiServiceFailure extends Failure {
  final int? statusCode;

  const AiServiceFailure({
    required super.message,
    this.statusCode,
    super.cause,
    super.stackTrace,
  });
}

/// Represents HTTP or network connection failures (USDA, Open Food Facts).
class NetworkFailure extends Failure {
  final int? statusCode;

  const NetworkFailure({
    required super.message,
    this.statusCode,
    super.cause,
    super.stackTrace,
  });
}

/// Represents invalid business rules, unparseable payloads, or model sanitization issues.
class ValidationFailure extends Failure {
  final String? property;

  const ValidationFailure({
    required super.message,
    this.property,
    super.cause,
    super.stackTrace,
  });
}

/// Represents failures with secure storage or persistent preferences.
class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

/// Represents errors during image decoding, compression, resizing, or filesystem saving.
class ImageProcessingFailure extends Failure {
  const ImageProcessingFailure({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

/// Generic fallback failure for uncaught anomalies.
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}
