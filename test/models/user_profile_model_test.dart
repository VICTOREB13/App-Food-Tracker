import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/user_profile.dart';

void main() {
  group('UserProfile Model Tests', () {
    test('toMap y fromMap realizan ciclo de serialización idéntico', () {
      final now = DateTime(2026, 9, 7, 12, 0);
      final profile = UserProfile(
        id: 'primary',
        name: 'Victor Engineer',
        age: 28,
        gender: 'male',
        height: 178.0,
        weight: 76.5,
        activityLevel: 'moderate',
        bodyGoal: 'fat_loss',
        estimatedSteps: 10000,
        bmr: 1750.0,
        tdee: 2712.5,
        targetCalories: 2212.5,
        targetProtein: 153.0,
        targetCarbs: 245.0,
        targetFat: 61.0,
        masterPrompt: 'Prompt de sistema para IA',
        updatedAt: now,
      );

      final map = profile.toMap();
      expect(map['name'], equals('Victor Engineer'));
      expect(map['bmr'], equals(1750.0));
      expect(map['tdee'], equals(2712.5));
      expect(map['target_calories'], equals(2212.5));
      expect(map['estimated_steps'], equals(10000));

      final restored = UserProfile.fromMap(map);
      expect(restored, equals(profile));
      expect(restored.dailyGoals.calories, equals(2212.5));
      expect(restored.dailyGoals.protein, equals(153.0));
      expect(restored.dailyGoals.carbs, equals(245.0));
      expect(restored.dailyGoals.fat, equals(61.0));
    });

    test('toSqliteMap y fromSqliteMap serializan y deserializan correctamente', () {
      final now = DateTime(2026, 9, 7, 14, 0);
      final profile = UserProfile(
        name: 'Maria',
        age: 30,
        gender: 'female',
        height: 165.0,
        weight: 60.0,
        bmr: 1350.0,
        tdee: 1850.0,
        targetCalories: 1850.0,
        targetProtein: 120.0,
        targetCarbs: 190.0,
        targetFat: 50.0,
        updatedAt: now,
      );

      final sqliteMap = profile.toSqliteMap();
      final restored = UserProfile.fromSqliteMap(sqliteMap);

      expect(restored, equals(profile));
      expect(restored.gender, equals('female'));
    });

    test('Tolerancia a alias de columnas (height_cm, current_weight_kg, tmb, etc.)', () {
      final aliasedMap = {
        'id': 'profile-alias',
        'name': 'Carlos',
        'age': 35,
        'gender': 'masculino',
        'height_cm': 180.0,
        'current_weight_kg': 82.0,
        'activity_level': 'ligero',
        'goal': 'déficit',
        'estimated_steps': 9000,
        'tmb': 1800.0,
        'tdee': 2400.0,
        'target_calories': 1900.0,
        'target_protein_g': 160.0,
        'target_carbs_g': 200.0,
        'target_fat_g': 55.0,
        'master_prompt': 'Contexto médico',
        'updated_at': '2026-09-07T10:00:00.000',
      };

      final profile = UserProfile.fromMap(aliasedMap);
      expect(profile.height, equals(180.0));
      expect(profile.weight, equals(82.0));
      expect(profile.bmr, equals(1800.0));
      expect(profile.activityLevel, equals('light'));
      expect(profile.bodyGoal, equals('fat_loss'));
      expect(profile.targetProtein, equals(160.0));
      expect(profile.targetCarbs, equals(200.0));
      expect(profile.targetFat, equals(55.0));
    });

    test('Límites defensivos se aplican a entradas desmedidas', () {
      final invalidProfile = UserProfile(
        age: 150,
        height: 450.0,
        weight: 1200.0,
        bmr: 99999.0,
        tdee: 99999.0,
        targetCalories: 99999.0,
        targetProtein: 99999.0,
        targetCarbs: 99999.0,
        targetFat: 99999.0,
        estimatedSteps: 200000,
      );

      expect(invalidProfile.age, equals(120));
      expect(invalidProfile.height, equals(300.0));
      expect(invalidProfile.weight, equals(500.0));
      expect(invalidProfile.bmr, equals(5000.0));
      expect(invalidProfile.tdee, equals(8000.0));
      expect(invalidProfile.targetCalories, equals(8000.0));
      expect(invalidProfile.targetProtein, equals(1000.0));
      expect(invalidProfile.targetCarbs, equals(1000.0));
      expect(invalidProfile.targetFat, equals(1000.0));
      expect(invalidProfile.estimatedSteps, equals(100000));
    });

    test('copyWith con Sentinel borra name y masterPrompt con null explícito', () {
      final profile = UserProfile(
        name: 'Victor',
        age: 25,
        height: 175.0,
        weight: 70.0,
        bmr: 1600.0,
        tdee: 2200.0,
        targetCalories: 2000.0,
        targetProtein: 140.0,
        targetCarbs: 220.0,
        targetFat: 65.0,
        masterPrompt: 'Prompt guardado',
      );

      // Explicit null clears name and masterPrompt
      final cleared = profile.copyWith(name: null, masterPrompt: null);
      expect(cleared.name, isNull);
      expect(cleared.masterPrompt, isNull);
      expect(cleared.age, equals(25));

      // Omitting parameters keeps existing values
      final updatedAge = profile.copyWith(age: 26);
      expect(updatedAge.name, equals('Victor'));
      expect(updatedAge.masterPrompt, equals('Prompt guardado'));
      expect(updatedAge.age, equals(26));
    });

    test('toWeightLog genera un registro fiel sincronizado con el perfil', () {
      final now = DateTime(2026, 9, 7, 9, 30);
      final profile = UserProfile(
        weight: 74.2,
        age: 30,
        height: 170.0,
        bmr: 1600.0,
        tdee: 2000.0,
        targetCalories: 2000.0,
        targetProtein: 140.0,
        targetCarbs: 220.0,
        targetFat: 65.0,
        updatedAt: now,
      );

      final weightLog = profile.toWeightLog();
      expect(weightLog.weight, equals(74.2));
      expect(weightLog.date, equals(now));
      expect(weightLog.notes, contains('perfil'));
    });
  });
}
