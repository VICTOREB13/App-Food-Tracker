import 'package:food_tracker/features/fasting_tracker/models/fasting_log.dart';
import 'package:flutter/foundation.dart';
export 'package:food_tracker/features/fasting_tracker/models/fasting_log.dart';

/// Predefined fasting protocols and schedule distributions.
enum FastingProtocol {
  circadian(13.0, 'Circadiano', '13:11'),
  fourteenTen(14.0, '14:10', '14:10'),
  sixteenEight(16.0, '16:8', '16:8'),
  eighteenSix(18.0, '18:6', '18:6'),
  twentyFour(20.0, '20:4', '20:4'),
  custom(16.0, 'Personalizado', 'Custom');

  final double targetHours;
  final String label;
  final String ratio;

  const FastingProtocol(this.targetHours, this.label, this.ratio);

  int get fastHours => targetHours.round();
  int get eatHours => (24 - targetHours).clamp(0, 24).round();

  static FastingProtocol fromHours(double hours) {
    for (final protocol in FastingProtocol.values) {
      if (protocol != FastingProtocol.custom &&
          (protocol.targetHours - hours).abs() < 0.1) {
        return protocol;
      }
    }
    return FastingProtocol.custom;
  }
}

/// Physiological fasting metabolic phase based on elapsed duration.
enum KetosisPhase {
  anabolic(0.0, 4.0, 'Anabólico', 'Digestión e insulina basal'),
  glycogenDepletion(4.0, 12.0, 'Descenso Glucosa', 'Consumo de glucógeno hepático'),
  ketosis(12.0, 18.0, 'Cetosis', 'Quema acelerada de grasa'),
  deepKetosis(18.0, 168.0, 'Autofagia', 'Reparación celular profunda');

  final double startHour;
  final double endHour;
  final String label;
  final String description;

  const KetosisPhase(
    this.startHour,
    this.endHour,
    this.label,
    this.description,
  );

  static KetosisPhase fromElapsed(Duration elapsed) {
    final hours = elapsed.inMinutes / 60.0;
    if (hours < 4.0) return KetosisPhase.anabolic;
    if (hours < 12.0) return KetosisPhase.glycogenDepletion;
    if (hours < 18.0) return KetosisPhase.ketosis;
    return KetosisPhase.deepKetosis;
  }
}

/// Immutable state container for the Fasting Tracker vertical slice.
@immutable
class FastingState {
  final FastingLog? activeFast;
  final FastingProtocol protocol;
  final bool isLoading;
  final Duration elapsed;
  final Duration remaining;
  final double progressRatio;
  final KetosisPhase ketosisPhase;

  static const Object _sentinel = Object();

  const FastingState({
    this.activeFast,
    this.protocol = FastingProtocol.sixteenEight,
    this.isLoading = false,
    this.elapsed = Duration.zero,
    this.remaining = Duration.zero,
    this.progressRatio = 0.0,
    this.ketosisPhase = KetosisPhase.anabolic,
  });

  static const FastingState initial = FastingState();

  bool get isFastingActive => activeFast != null && activeFast!.isActive;

  double get targetHours => activeFast?.targetHours ?? protocol.targetHours;

  Duration get targetDuration =>
      Duration(minutes: (targetHours * 60).round());

  String get formattedElapsed {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String get formattedRemaining {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  FastingState copyWith({
    Object? activeFast = _sentinel,
    FastingProtocol? protocol,
    bool? isLoading,
    Duration? elapsed,
    Duration? remaining,
    double? progressRatio,
    KetosisPhase? ketosisPhase,
  }) {
    return FastingState(
      activeFast: identical(activeFast, _sentinel)
          ? this.activeFast
          : (activeFast as FastingLog?),
      protocol: protocol ?? this.protocol,
      isLoading: isLoading ?? this.isLoading,
      elapsed: elapsed ?? this.elapsed,
      remaining: remaining ?? this.remaining,
      progressRatio: progressRatio ?? this.progressRatio,
      ketosisPhase: ketosisPhase ?? this.ketosisPhase,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FastingState &&
          runtimeType == other.runtimeType &&
          activeFast == other.activeFast &&
          protocol == other.protocol &&
          isLoading == other.isLoading &&
          elapsed == other.elapsed &&
          remaining == other.remaining &&
          progressRatio == other.progressRatio &&
          ketosisPhase == other.ketosisPhase;

  @override
  int get hashCode =>
      activeFast.hashCode ^
      protocol.hashCode ^
      isLoading.hashCode ^
      elapsed.hashCode ^
      remaining.hashCode ^
      progressRatio.hashCode ^
      ketosisPhase.hashCode;
}
