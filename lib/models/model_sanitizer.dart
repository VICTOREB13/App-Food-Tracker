class ModelSanitizer {
  static const int maxNameLength = 255;
  static const int maxNotesLength = 2000;
  static const int maxPathLength = 1024;
  static const int maxJsonLength = 100000;
  static const int maxJustificationLength = 1000;
  static const double minMacroValue = 0.0;
  static const double maxMacroValue = 9999.0;

  static String truncate(String? value, int maxLength, {String fallback = ''}) {
    if (value == null) return fallback;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed.length <= maxLength ? trimmed : trimmed.substring(0, maxLength);
  }

  static String? truncateNullable(String? value, int maxLength) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.length <= maxLength ? trimmed : trimmed.substring(0, maxLength);
  }

  static double clampDouble(
    dynamic value, {
    double min = minMacroValue,
    double max = maxMacroValue,
  }) {
    if (value == null) return min;
    double? doubleVal;
    if (value is num) {
      doubleVal = value.toDouble();
    } else {
      doubleVal = double.tryParse(value.toString().trim());
    }
    if (doubleVal == null || doubleVal.isNaN) return min;
    if (doubleVal < min) return min;
    if (doubleVal > max) return max;
    return double.parse(doubleVal.toStringAsFixed(2));
  }

  static DateTime parseDate(dynamic value, {DateTime? fallback}) {
    if (value == null) return fallback ?? DateTime.now();
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return fallback ?? DateTime.now();
    }
  }

  static String formatIsoDate(DateTime? date) {
    return (date ?? DateTime.now()).toIso8601String();
  }
}
