import 'package:uuid/uuid.dart';
import 'model_sanitizer.dart';

/// Immutable model representing calibrated dishware for computer-vision reference sizing.
class CalibratedDishware {
  final String id;
  final String name;
  final double diameterCm;
  final double depthCm;
  final String shape;
  final bool isDefault;
  final DateTime createdAt;

  CalibratedDishware({
    String? id,
    required String name,
    required num diameterCm,
    num depthCm = 0.0,
    String shape = 'circle',
    this.isDefault = false,
    DateTime? createdAt,
  })  : id = ModelSanitizer.truncate(id, 128, fallback: const Uuid().v4()),
        name = ModelSanitizer.truncate(name, ModelSanitizer.maxNameLength, fallback: 'Plato calibrado'),
        diameterCm = ModelSanitizer.clampDouble(diameterCm, min: 1.0, max: 100.0),
        depthCm = ModelSanitizer.clampDouble(depthCm, min: 0.0, max: 50.0),
        shape = ModelSanitizer.truncate(shape, 50, fallback: 'circle'),
        createdAt = createdAt ?? DateTime.now();

  CalibratedDishware copyWith({
    String? id,
    String? name,
    double? diameterCm,
    double? depthCm,
    String? shape,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return CalibratedDishware(
      id: id ?? this.id,
      name: name ?? this.name,
      diameterCm: diameterCm ?? this.diameterCm,
      depthCm: depthCm ?? this.depthCm,
      shape: shape ?? this.shape,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'diameter_cm': diameterCm,
        'depth_cm': depthCm,
        'shape': shape,
        'is_default': isDefault ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toJson() => toMap();

  factory CalibratedDishware.fromMap(Map<String, dynamic> map) {
    return CalibratedDishware(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? 'Plato calibrado',
      diameterCm: ModelSanitizer.clampDouble(map['diameter_cm'] ?? map['diameterCm'], min: 1.0, max: 100.0),
      depthCm: ModelSanitizer.clampDouble(map['depth_cm'] ?? map['depthCm'], min: 0.0, max: 50.0),
      shape: map['shape']?.toString() ?? 'circle',
      isDefault: map['is_default'] == 1 || map['is_default'] == true || map['isDefault'] == true,
      createdAt: ModelSanitizer.parseDate(map['created_at'] ?? map['createdAt']),
    );
  }

  factory CalibratedDishware.fromJson(Map<String, dynamic> json) =>
      CalibratedDishware.fromMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalibratedDishware &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          diameterCm == other.diameterCm &&
          depthCm == other.depthCm &&
          shape == other.shape &&
          isDefault == other.isDefault;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      diameterCm.hashCode ^
      depthCm.hashCode ^
      shape.hashCode ^
      isDefault.hashCode;
}
