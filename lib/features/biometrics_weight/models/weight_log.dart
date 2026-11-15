import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'model_sanitizer.dart';

@immutable
class WeightLog {
  final String id;
  final DateTime date;
  final double weight;
  final String? notes;

  static const Object _sentinel = Object();

  WeightLog({
    String? id,
    DateTime? date,
    required num weight,
    String? notes,
  })  : id = ModelSanitizer.truncate(id, 128, fallback: const Uuid().v4()),
        date = date ?? DateTime.now(),
        weight = ModelSanitizer.clampDouble(weight, min: 0.1, max: 500.0),
        notes = ModelSanitizer.truncateNullable(notes, ModelSanitizer.maxNotesLength);

  WeightLog copyWith({
    String? id,
    DateTime? date,
    double? weight,
    Object? notes = _sentinel,
  }) {
    return WeightLog(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      notes: identical(notes, _sentinel) ? this.notes : (notes as String?),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'weight': weight,
        'notes': notes,
      };

  factory WeightLog.fromMap(Map<String, dynamic> map) {
    return WeightLog(
      id: map['id']?.toString(),
      date: ModelSanitizer.parseDate(map['date']),
      weight: ModelSanitizer.clampDouble(map['weight'], min: 0.1, max: 500.0),
      notes: map['notes']?.toString(),
    );
  }

  /// SQLite compatibility alias
  Map<String, dynamic> toSqliteMap() => toMap();
  factory WeightLog.fromSqliteMap(Map<String, dynamic> map) => WeightLog.fromMap(map);

  /// JSON / BackupService compatibility alias
  Map<String, dynamic> toJson() => toMap();
  factory WeightLog.fromJson(Map<String, dynamic> json) => WeightLog.fromMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date.toIso8601String() == other.date.toIso8601String() &&
          weight == other.weight &&
          notes == other.notes;

  @override
  int get hashCode =>
      id.hashCode ^
      date.toIso8601String().hashCode ^
      weight.hashCode ^
      notes.hashCode;

  @override
  String toString() =>
      'WeightLog(id: $id, date: ${date.toIso8601String()}, weight: $weight, notes: $notes)';
}
