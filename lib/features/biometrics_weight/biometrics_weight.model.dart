import 'package:flutter/foundation.dart';
export 'package:food_tracker/features/biometrics_weight/models/weight_log.dart';

/// Predefined time filtering intervals for weight analytics.
enum WeightFilterRange {
  sevenDays(7),
  thirtyDays(30),
  ninetyDays(90),
  all(0);

  final int days;
  const WeightFilterRange(this.days);

  static WeightFilterRange fromDays(int days) {
    for (final r in WeightFilterRange.values) {
      if (r.days == days) return r;
    }
    return WeightFilterRange.thirtyDays;
  }
}

/// WHO Clinical BMI categorization.
enum BmiCategory {
  underweight,
  normal,
  overweight,
  obeseClass1,
  obeseClass2,
  obeseClass3;

  static BmiCategory fromBmi(double bmi) {
    if (bmi < 18.5) return BmiCategory.underweight;
    if (bmi < 25.0) return BmiCategory.normal;
    if (bmi < 30.0) return BmiCategory.overweight;
    if (bmi < 35.0) return BmiCategory.obeseClass1;
    if (bmi < 40.0) return BmiCategory.obeseClass2;
    return BmiCategory.obeseClass3;
  }
}

/// Directional movement of body weight across a time window.
enum WeightTrendDirection {
  decreasing,
  stable,
  increasing,
}

/// Clinical formulas for BMR (Mifflin-St Jeor), TDEE, BMI, ABW, and moving averages.
class BiometricsCalculator {
  /// Basal Metabolic Rate (BMR / TMB) via Mifflin-St Jeor equation.
  static double calculateBmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required bool isFemale,
  }) {
    final offset = isFemale ? -161.0 : 5.0;
    final bmr = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age) + offset;
    return double.parse(bmr.toStringAsFixed(1));
  }

  /// Total Daily Energy Expenditure (TDEE).
  static double calculateTdee({
    required double bmr,
    required double activityMultiplier,
  }) {
    final tdee = bmr * activityMultiplier;
    return double.parse(tdee.toStringAsFixed(1));
  }

  /// Body Mass Index (BMI).
  static double calculateBmi({
    required double weightKg,
    required double heightCm,
  }) {
    if (heightCm <= 0) return 0.0;
    final heightM = heightCm / 100.0;
    final bmi = weightKg / (heightM * heightM);
    return double.parse(bmi.toStringAsFixed(1));
  }

  /// Ideal Body Weight (IBW) via Devine clinical formula.
  static double calculateIdealBodyWeight({
    required double heightCm,
    required bool isFemale,
  }) {
    final base = isFemale ? 45.5 : 50.0;
    if (heightCm < 152.4) {
      final heightM = heightCm / 100.0;
      return double.parse((22.0 * heightM * heightM).toStringAsFixed(2));
    }
    final ibw = base + 0.91 * (heightCm - 152.4);
    return double.parse(ibw.toStringAsFixed(2));
  }

  /// Adjusted Body Weight (ABW) for clinical nutrition in obesity (BMI >= 30.0).
  /// Formula: ABW = IBW + 0.4 * (Actual Weight - IBW).
  static double calculateAdjustedBodyWeight({
    required double actualWeightKg,
    required double heightCm,
    required bool isFemale,
  }) {
    final ibw = calculateIdealBodyWeight(heightCm: heightCm, isFemale: isFemale);
    if (actualWeightKg <= ibw) return actualWeightKg;
    final abw = ibw + 0.4 * (actualWeightKg - ibw);
    return double.parse(abw.toStringAsFixed(2));
  }

  /// Calculates a simple moving average over the last [window] logs.
  static double calculateMovingAverage(List<WeightLog> logs, {int window = 7}) {
    if (logs.isEmpty) return 0.0;
    final count = logs.length < window ? logs.length : window;
    final slice = logs.sublist(logs.length - count);
    final sum = slice.fold<double>(0.0, (acc, item) => acc + item.weight);
    return double.parse((sum / count).toStringAsFixed(2));
  }
}

/// Immutable state container for the Biometrics & Weight vertical slice.
@immutable
class BiometricsWeightState {
  final List<WeightLog> logs;
  final WeightLog? latestLog;
  final WeightFilterRange filterRange;
  final bool isLoading;
  final String? errorMessage;
  final double? bmr;
  final double? tdee;
  final double? adjustedBodyWeight;
  final double? bmi;
  final BmiCategory? bmiCategory;
  final double movingAverage7d;

  static const Object _sentinel = Object();

  const BiometricsWeightState({
    this.logs = const [],
    this.latestLog,
    this.filterRange = WeightFilterRange.thirtyDays,
    this.isLoading = false,
    this.errorMessage,
    this.bmr,
    this.tdee,
    this.adjustedBodyWeight,
    this.bmi,
    this.bmiCategory,
    this.movingAverage7d = 0.0,
  });

  static const BiometricsWeightState initial = BiometricsWeightState();

  double? get currentWeight => latestLog?.weight;

  double? get weightDelta {
    if (logs.length < 2) return null;
    final sorted = List<WeightLog>.from(logs)..sort((a, b) => a.date.compareTo(b.date));
    return double.parse((sorted.last.weight - sorted.first.weight).toStringAsFixed(2));
  }

  WeightTrendDirection get trendDirection {
    final delta = weightDelta;
    if (delta == null || delta.abs() <= 0.05) return WeightTrendDirection.stable;
    return delta < 0 ? WeightTrendDirection.decreasing : WeightTrendDirection.increasing;
  }

  BiometricsWeightState copyWith({
    List<WeightLog>? logs,
    Object? latestLog = _sentinel,
    WeightFilterRange? filterRange,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    Object? bmr = _sentinel,
    Object? tdee = _sentinel,
    Object? adjustedBodyWeight = _sentinel,
    Object? bmi = _sentinel,
    Object? bmiCategory = _sentinel,
    double? movingAverage7d,
  }) {
    return BiometricsWeightState(
      logs: logs ?? this.logs,
      latestLog: identical(latestLog, _sentinel)
          ? this.latestLog
          : (latestLog as WeightLog?),
      filterRange: filterRange ?? this.filterRange,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : (errorMessage as String?),
      bmr: identical(bmr, _sentinel) ? this.bmr : (bmr as double?),
      tdee: identical(tdee, _sentinel) ? this.tdee : (tdee as double?),
      adjustedBodyWeight: identical(adjustedBodyWeight, _sentinel)
          ? this.adjustedBodyWeight
          : (adjustedBodyWeight as double?),
      bmi: identical(bmi, _sentinel) ? this.bmi : (bmi as double?),
      bmiCategory: identical(bmiCategory, _sentinel)
          ? this.bmiCategory
          : (bmiCategory as BmiCategory?),
      movingAverage7d: movingAverage7d ?? this.movingAverage7d,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BiometricsWeightState &&
          runtimeType == other.runtimeType &&
          listEquals(logs, other.logs) &&
          latestLog == other.latestLog &&
          filterRange == other.filterRange &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage &&
          bmr == other.bmr &&
          tdee == other.tdee &&
          adjustedBodyWeight == other.adjustedBodyWeight &&
          bmi == other.bmi &&
          bmiCategory == other.bmiCategory &&
          movingAverage7d == other.movingAverage7d;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(logs),
        latestLog,
        filterRange,
        isLoading,
        errorMessage,
        bmr,
        tdee,
        adjustedBodyWeight,
        bmi,
        bmiCategory,
        movingAverage7d,
      );
}
