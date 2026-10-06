/// Typed exception for Google Gemini API errors
class GeminiApiException implements Exception {
  final int statusCode;
  final String message;
  final String? details;

  const GeminiApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  @override
  String toString() =>
      'GeminiApiException($statusCode): $message${details != null ? ' - $details' : ''}';
}
