import 'package:uuid/uuid.dart';
import 'model_sanitizer.dart';

/// Immutable model representing an intermittent fasting session log.
class FastingLog {
  final String id;
  final DateTime startTime;
  final double targetHours;
  final DateTime? endTime;
  final bool isActive;
  final String? notes;

  static const Object _sentinel = Object();

  FastingLog({
    String? id,
    DateTime? startTime,
    num targetHours = 16.0,
    this.endTime,
    this.isActive = true,
    String? notes,
  })  : id = ModelSanitizer.truncate(id, 128, fallback: const Uuid().v4()),
        startTime = startTime ?? DateTime.now(),
        targetHours = ModelSanitizer.clampDouble(targetHours, min: 1.0, max: 168.0),
        notes = ModelSanitizer.truncateNullable(notes, ModelSanitizer.maxNotesLength);

  FastingLog copyWith({
    String? id,
    DateTime? startTime,
    double? targetHours,
    Object? endTime = _sentinel,
    bool? isActive,
    Object? notes = _sentinel,
  }) {
    return FastingLog(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      targetHours: targetHours ?? this.targetHours,
      endTime: identical(endTime, _sentinel) ? this.endTime : (endTime as DateTime?),
      isActive: isActive ?? this.isActive,
      notes: identical(notes, _sentinel) ? this.notes : (notes as String?),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'start_time': startTime.toIso8601String(),
        'target_hours': targetHours,
        'end_time': endTime?.toIso8601String(),
        'is_active': isActive ? 1 : 0,
        'notes': notes,
      };

  Map<String, dynamic> toJson() => toMap();

  factory FastingLog.fromMap(Map<String, dynamic> map) {
    return FastingLog(
      id: map['id']?.toString(),
      startTime: ModelSanitizer.parseDate(map['start_time'] ?? map['startTime']),
      targetHours: ModelSanitizer.clampDouble(map['target_hours'] ?? map['targetHours'], min: 1.0, max: 168.0),
      endTime: map['end_time'] != null || map['endTime'] != null
          ? ModelSanitizer.parseDate(map['end_time'] ?? map['endTime'])
          : null,
      isActive: map['is_active'] == 1 || map['is_active'] == true || map['isActive'] == true,
      notes: map['notes']?.toString(),
    );
  }

  factory FastingLog.fromJson(Map<String, dynamic> json) => FastingLog.fromMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FastingLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          startTime == other.startTime &&
          targetHours == other.targetHours &&
          endTime == other.endTime &&
          isActive == other.isActive &&
          notes == other.notes;

  @override
  int get hashCode =>
      id.hashCode ^
      startTime.hashCode ^
      targetHours.hashCode ^
      endTime.hashCode ^
      isActive.hashCode ^
      notes.hashCode;
}
