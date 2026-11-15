import 'package:flutter/foundation.dart';
import 'daily_goals.dart';
import 'model_sanitizer.dart';
import 'weight_log.dart';

@immutable
class UserProfile {
  final String id;
  final String? name;
  final int age;
  final String gender;
  final double height;
  final double weight;
  final String activityLevel;
  final String bodyGoal;
  final int estimatedSteps;
  final double bmr;
  final double tdee;
  final double targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final String? masterPrompt;
  final DateTime updatedAt;

  static const Object _sentinel = Object();

  UserProfile({
    String? id,
    String? name,
    required int age,
    String gender = 'male',
    required num height,
    required num weight,
    String activityLevel = 'sedentary',
    String bodyGoal = 'maintenance',
    int estimatedSteps = 8000,
    required num bmr,
    required num tdee,
    required num targetCalories,
    required num targetProtein,
    required num targetCarbs,
    required num targetFat,
    String? masterPrompt,
    DateTime? updatedAt,
  })  : id = ModelSanitizer.truncate(id, 128, fallback: 'primary'),
        name = ModelSanitizer.truncateNullable(name, ModelSanitizer.maxNameLength),
        age = age.clamp(10, 120),
        gender = _sanitizeGender(gender),
        height = ModelSanitizer.clampDouble(height, min: 50.0, max: 300.0),
        weight = ModelSanitizer.clampDouble(weight, min: 20.0, max: 500.0),
        activityLevel = _sanitizeActivity(activityLevel),
        bodyGoal = _sanitizeGoal(bodyGoal),
        estimatedSteps = estimatedSteps.clamp(0, 100000),
        bmr = ModelSanitizer.clampDouble(bmr, min: 500.0, max: 5000.0),
        tdee = ModelSanitizer.clampDouble(tdee, min: 500.0, max: 8000.0),
        targetCalories = ModelSanitizer.clampDouble(targetCalories, min: 500.0, max: 8000.0),
        targetProtein = ModelSanitizer.clampDouble(targetProtein, min: 10.0, max: 1000.0),
        targetCarbs = ModelSanitizer.clampDouble(targetCarbs, min: 10.0, max: 1000.0),
        targetFat = ModelSanitizer.clampDouble(targetFat, min: 10.0, max: 1000.0),
        masterPrompt = ModelSanitizer.truncateNullable(masterPrompt, ModelSanitizer.maxJsonLength),
        updatedAt = updatedAt ?? DateTime.now();

  static String _sanitizeGender(String? raw) {
    if (raw == null) return 'male';
    final lower = raw.trim().toLowerCase();
    if (lower == 'female' || lower == 'femenino' || lower == 'mujer') return 'female';
    return 'male';
  }

  static String _sanitizeActivity(String? raw) {
    if (raw == null) return 'sedentary';
    final lower = raw.trim().toLowerCase();
    if (lower.contains('light') || lower.contains('ligero')) return 'light';
    if (lower.contains('moderat') || lower.contains('moderado')) return 'moderate';
    if (lower.contains('very') || lower.contains('muy')) return 'very_active';
    return 'sedentary';
  }

  static String _sanitizeGoal(String? raw) {
    if (raw == null) return 'maintenance';
    final lower = raw.trim().toLowerCase();
    if (lower.contains('fat') || lower.contains('perdid') || lower.contains('déficit') || lower.contains('deficit')) return 'fat_loss';
    if (lower.contains('gain') || lower.contains('gananc') || lower.contains('superávit') || lower.contains('superavit')) return 'muscle_gain';
    return 'maintenance';
  }

  UserProfile copyWith({
    String? id,
    Object? name = _sentinel,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? activityLevel,
    String? bodyGoal,
    int? estimatedSteps,
    double? bmr,
    double? tdee,
    double? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
    Object? masterPrompt = _sentinel,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: identical(name, _sentinel) ? this.name : (name as String?),
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      bodyGoal: bodyGoal ?? this.bodyGoal,
      estimatedSteps: estimatedSteps ?? this.estimatedSteps,
      bmr: bmr ?? this.bmr,
      tdee: tdee ?? this.tdee,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFat: targetFat ?? this.targetFat,
      masterPrompt: identical(masterPrompt, _sentinel)
          ? this.masterPrompt
          : (masterPrompt as String?),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Direct conversion to DailyGoals for effortless synchronization
  DailyGoals get dailyGoals => DailyGoals(
        calories: targetCalories,
        protein: targetProtein,
        carbs: targetCarbs,
        fat: targetFat,
      );

  /// Synchronous conversion to WeightLog when profile weight is updated
  WeightLog toWeightLog({String? notes}) => WeightLog(
        weight: weight,
        date: updatedAt,
        notes: notes ?? 'Registro automático desde actualización de perfil',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'age': age,
        'gender': gender,
        'height': height,
        'weight': weight,
        'activity_level': activityLevel,
        'body_goal': bodyGoal,
        'estimated_steps': estimatedSteps,
        'bmr': bmr,
        'tdee': tdee,
        'target_calories': targetCalories,
        'target_protein': targetProtein,
        'target_carbs': targetCarbs,
        'target_fat': targetFat,
        'master_prompt': masterPrompt,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id']?.toString(),
      name: map['name']?.toString(),
      age: (map['age'] as num?)?.toInt() ?? 25,
      gender: map['gender']?.toString() ?? 'male',
      height: ModelSanitizer.clampDouble(
        map['height'] ?? map['height_cm'],
        min: 50.0,
        max: 300.0,
      ),
      weight: ModelSanitizer.clampDouble(
        map['weight'] ?? map['current_weight_kg'],
        min: 20.0,
        max: 500.0,
      ),
      activityLevel: (map['activity_level'] ?? 'sedentary').toString(),
      bodyGoal: (map['body_goal'] ?? map['goal'] ?? 'maintenance').toString(),
      estimatedSteps: (map['estimated_steps'] as num?)?.toInt() ?? 8000,
      bmr: ModelSanitizer.clampDouble(
        map['bmr'] ?? map['tmb'],
        min: 500.0,
        max: 5000.0,
      ),
      tdee: ModelSanitizer.clampDouble(
        map['tdee'],
        min: 500.0,
        max: 8000.0,
      ),
      targetCalories: ModelSanitizer.clampDouble(
        map['target_calories'],
        min: 500.0,
        max: 8000.0,
      ),
      targetProtein: ModelSanitizer.clampDouble(
        map['target_protein'] ?? map['target_protein_g'],
        min: 10.0,
        max: 1000.0,
      ),
      targetCarbs: ModelSanitizer.clampDouble(
        map['target_carbs'] ?? map['target_carbs_g'],
        min: 10.0,
        max: 1000.0,
      ),
      targetFat: ModelSanitizer.clampDouble(
        map['target_fat'] ?? map['target_fat_g'],
        min: 10.0,
        max: 1000.0,
      ),
      masterPrompt: map['master_prompt']?.toString(),
      updatedAt: ModelSanitizer.parseDate(map['updated_at']),
    );
  }

  /// SQLite compatibility alias
  Map<String, dynamic> toSqliteMap() => toMap();
  factory UserProfile.fromSqliteMap(Map<String, dynamic> map) => UserProfile.fromMap(map);

  /// JSON / BackupService compatibility alias
  Map<String, dynamic> toJson() => toMap();
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile.fromMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          age == other.age &&
          gender == other.gender &&
          height == other.height &&
          weight == other.weight &&
          activityLevel == other.activityLevel &&
          bodyGoal == other.bodyGoal &&
          estimatedSteps == other.estimatedSteps &&
          bmr == other.bmr &&
          tdee == other.tdee &&
          targetCalories == other.targetCalories &&
          targetProtein == other.targetProtein &&
          targetCarbs == other.targetCarbs &&
          targetFat == other.targetFat &&
          masterPrompt == other.masterPrompt &&
          updatedAt.toIso8601String() == other.updatedAt.toIso8601String();

  @override
  int get hashCode =>
      id.hashCode ^
      (name?.hashCode ?? 0) ^
      age.hashCode ^
      gender.hashCode ^
      height.hashCode ^
      weight.hashCode ^
      activityLevel.hashCode ^
      bodyGoal.hashCode ^
      estimatedSteps.hashCode ^
      bmr.hashCode ^
      tdee.hashCode ^
      targetCalories.hashCode ^
      targetProtein.hashCode ^
      targetCarbs.hashCode ^
      targetFat.hashCode ^
      (masterPrompt?.hashCode ?? 0) ^
      updatedAt.toIso8601String().hashCode;

  @override
  String toString() =>
      'UserProfile(id: $id, name: $name, age: $age, gender: $gender, height: $height, weight: $weight, tdee: $tdee, targetCalories: $targetCalories)';
}
