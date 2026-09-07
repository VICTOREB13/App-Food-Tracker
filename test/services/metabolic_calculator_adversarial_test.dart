import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/user_profile.dart';
import 'package:food_tracker/services/metabolic_calculator.dart';

void main() {
  group('MetabolicCalculator Adversarial - Mifflin-St Jeor Divergence & Boundaries', () {
    test('Divergencia entre sexos biológicos es exactamente de 166.0 kcal para datos idénticos', () {
      const testCases = [
        {'w': 30.0, 'h': 100.0, 'a': 10},
        {'w': 50.0, 'h': 150.0, 'a': 18},
        {'w': 70.0, 'h': 175.0, 'a': 30},
        {'w': 90.0, 'h': 185.0, 'a': 50},
        {'w': 120.0, 'h': 190.0, 'a': 80},
        {'w': 200.0, 'h': 210.0, 'a': 90},
        {'w': 300.0, 'h': 250.0, 'a': 120},
      ];

      for (final tc in testCases) {
        final bmrMale = MetabolicCalculator.calculateBmr(
          gender: 'male',
          weightKg: tc['w']! as double,
          heightCm: tc['h']! as double,
          age: (tc['a']! as num).toInt(),
        );
        final bmrFemale = MetabolicCalculator.calculateBmr(
          gender: 'female',
          weightKg: tc['w']! as double,
          heightCm: tc['h']! as double,
          age: (tc['a']! as num).toInt(),
        );

        final diff = double.parse((bmrMale - bmrFemale).toStringAsFixed(1));
        expect(diff, equals(166.0),
            reason: 'Divergencia falló para w=${tc['w']}, h=${tc['h']}, a=${tc['a']}');
      }
    });

    test('Casos límite de edad (10, 18, 50, 90, 120)', () {
      final ages = [10, 18, 50, 90, 120];
      for (final age in ages) {
        final bmr = MetabolicCalculator.calculateBmr(
          gender: 'male',
          weightKg: 70.0,
          heightCm: 175.0,
          age: age,
        );
        // (10 * 70) + (6.25 * 175) - (5 * age) + 5
        // 700 + 1093.75 - 5*age + 5 = 1798.75 - 5*age
        final expected = double.parse((1798.75 - (5 * age)).toStringAsFixed(1));
        expect(bmr, equals(expected));
      }
    });

    test('Casos límite de peso (30kg a 300kg) y altura (100cm a 250cm)', () {
      // Mínimo de frontera
      final bmrMin = MetabolicCalculator.calculateBmr(
        gender: 'female',
        weightKg: 30.0,
        heightCm: 100.0,
        age: 120,
      );
      // (10 * 30) + (6.25 * 100) - (5 * 120) - 161 = 300 + 625 - 600 - 161 = 164.0
      expect(bmrMin, equals(164.0));

      // Máximo de frontera
      final bmrMax = MetabolicCalculator.calculateBmr(
        gender: 'male',
        weightKg: 300.0,
        heightCm: 250.0,
        age: 10,
      );
      // (10 * 300) + (6.25 * 250) - (5 * 10) + 5 = 3000 + 1562.5 - 50 + 5 = 4517.5
      expect(bmrMax, equals(4517.5));
    });

    test('Matriz de sinónimos de género (femenino, mujer, Female, hombre, Varón, null)', () {
      final femaleSynonyms = [
        'female', 'FEMALE', 'Female', 'femenino', 'FEMENINO', 'mujer', 'MUJER', 'f', 'F',
        '  female  ', ' femenino '
      ];
      final maleSynonyms = [
        'male', 'MALE', 'Male', 'hombre', 'HOMBRE', 'varón', 'Varón', 'VARON', 'varon',
        'm', 'M', '  hombre  ', null, '', 'otro', 'non-binary'
      ];

      for (final s in femaleSynonyms) {
        expect(MetabolicCalculator.normalizeGender(s), equals('female'));
      }
      for (final s in maleSynonyms) {
        expect(MetabolicCalculator.normalizeGender(s), equals('male'));
      }
    });
  });

  group('MetabolicCalculator Adversarial - Starvation Defense & Goals', () {
    test('Garantía de defensa de inanición: Calorías de pérdida de grasa nunca bajan del BMR', () {
      final bmrProfiles = [800.0, 1000.0, 1200.0, 1400.0, 1600.0, 2000.0, 2800.0];
      final activities = ['sedentary', 'light', 'moderate', 'very_active'];

      for (final bmr in bmrProfiles) {
        for (final act in activities) {
          final tdee = MetabolicCalculator.calculateTdee(bmr: bmr, activityLevel: act);
          final fatLossTarget = MetabolicCalculator.calculateCaloricGoal(
            tdee: tdee,
            bmr: bmr,
            bodyGoal: 'fat_loss',
          );

          expect(fatLossTarget, greaterThanOrEqualTo(bmr),
              reason: 'Starvation defense violated for bmr=$bmr, act=$act, target=$fatLossTarget');
        }
      }
    });

    test('Mantenimiento coincide exactamente con TDEE y Ganancia con TDEE + 300', () {
      const bmr = 1500.0;
      final tdee = MetabolicCalculator.calculateTdee(bmr: bmr, activityLevel: 'moderate');
      // 1500 * 1.55 = 2325.0
      expect(tdee, equals(2325.0));

      final maint = MetabolicCalculator.calculateCaloricGoal(
        tdee: tdee,
        bmr: bmr,
        bodyGoal: 'maintenance',
      );
      expect(maint, equals(2325.0));

      final gain = MetabolicCalculator.calculateCaloricGoal(
        tdee: tdee,
        bmr: bmr,
        bodyGoal: 'muscle_gain',
      );
      expect(gain, equals(2625.0));
    });
  });

  group('MetabolicCalculator Adversarial - Macro Distribution & Summation Margin', () {
    test('Sumatoria calórica (P*4 + C*4 + F*9) respeta margen <= 5 kcal en rango humano típico', () {
      final humanProfiles = [
        {'w': 45.0, 'cals': 1500.0, 'goal': 'fat_loss'},
        {'w': 55.0, 'cals': 1800.0, 'goal': 'maintenance'},
        {'w': 65.0, 'cals': 2100.0, 'goal': 'muscle_gain'},
        {'w': 75.0, 'cals': 2000.0, 'goal': 'fat_loss'},
        {'w': 80.0, 'cals': 2400.0, 'goal': 'maintenance'},
        {'w': 90.0, 'cals': 2700.0, 'goal': 'muscle_gain'},
        {'w': 105.0, 'cals': 2300.0, 'goal': 'fat_loss'},
        {'w': 120.0, 'cals': 2600.0, 'goal': 'maintenance'},
      ];

      for (final hp in humanProfiles) {
        final w = hp['w']! as double;
        final cals = hp['cals']! as double;
        final goal = hp['goal']! as String;

        final macros = MetabolicCalculator.calculateMacros(
          targetCalories: cals,
          weightKg: w,
          bodyGoal: goal,
        );

        // Piso de grasa hormonal (0.8 g/kg)
        expect(macros.fat, greaterThanOrEqualTo(double.parse((w * 0.8).toStringAsFixed(1)) - 0.1));

        // Carbohidratos no negativos
        expect(macros.carbs, greaterThanOrEqualTo(0.0));

        // Sumatoria calórica
        final diff = (macros.totalCalories - cals).abs();
        expect(diff, lessThanOrEqualTo(5.0),
            reason: 'Caloric summation violated for w=$w, cals=$cals: diff=$diff');
      }
    });

    test('Comportamiento en sobrepeso extremo: piso de grasa y proteína saturan déficit sin carbs negativos', () {
      // 250kg persona en fat_loss
      final macros = MetabolicCalculator.calculateMacros(
        targetCalories: 3000.0,
        weightKg: 250.0,
        bodyGoal: 'fat_loss',
      );

      // Proteína: 250 * 2.0 = 500g (2000 kcal)
      expect(macros.protein, equals(500.0));

      // Grasa: max(3000*0.25/9 = 83.3g, 250*0.8 = 200g) -> 200g (1800 kcal)
      expect(macros.fat, equals(200.0));

      // Suma P+F = 3800 kcal > 3000 kcal -> Carbs deben ser 0.0 (protegidos contra negativos)
      expect(macros.carbs, equals(0.0));
    });
  });

  group('MetabolicCalculator Adversarial - ModelSanitizer & Defensive Clamping', () {
    test('UserProfile y ModelSanitizer acotan cleanly valores negativos, NaN y cero', () {
      final profile = UserProfile(
        id: null,
        name: null,
        age: -50,
        gender: 'desconocido',
        height: -100.0,
        weight: 0.0,
        activityLevel: 'invalido',
        bodyGoal: 'invalido',
        estimatedSteps: -5000,
        bmr: -500.0,
        tdee: double.nan,
        targetCalories: 0.0,
        targetProtein: -10.0,
        targetCarbs: double.nan,
        targetFat: -5.0,
      );

      expect(profile.id, equals('primary'));
      expect(profile.name, isNull);
      expect(profile.age, equals(10));
      expect(profile.gender, equals('male'));
      expect(profile.height, equals(50.0));
      expect(profile.weight, equals(20.0));
      expect(profile.activityLevel, equals('sedentary'));
      expect(profile.bodyGoal, equals('maintenance'));
      expect(profile.estimatedSteps, equals(0));
      expect(profile.bmr, equals(500.0));
      expect(profile.tdee, equals(500.0));
      expect(profile.targetCalories, equals(500.0));
      expect(profile.targetProtein, equals(10.0));
      expect(profile.targetCarbs, equals(10.0));
      expect(profile.targetFat, equals(10.0));
    });

    test('UserProfile acota cleanly valores gigantescos', () {
      final profile = UserProfile(
        age: 500,
        height: 999.0,
        weight: 999.0,
        bmr: 99999.0,
        tdee: 99999.0,
        targetCalories: 99999.0,
        targetProtein: 99999.0,
        targetCarbs: 99999.0,
        targetFat: 99999.0,
        estimatedSteps: 999999,
      );

      expect(profile.age, equals(120));
      expect(profile.height, equals(300.0));
      expect(profile.weight, equals(500.0));
      expect(profile.bmr, equals(5000.0));
      expect(profile.tdee, equals(8000.0));
      expect(profile.targetCalories, equals(8000.0));
      expect(profile.targetProtein, equals(1000.0));
      expect(profile.targetCarbs, equals(1000.0));
      expect(profile.targetFat, equals(1000.0));
      expect(profile.estimatedSteps, equals(100000));
    });
  });

  group('MetabolicCalculator Adversarial - Master Prompt Clinical Directives', () {
    test('Master Prompt incluye todas las secciones clínicas y marcadores biométricos', () {
      final profile = UserProfile(
        name: 'Ana García',
        age: 32,
        gender: 'female',
        height: 164.0,
        weight: 58.5,
        activityLevel: 'light',
        bodyGoal: 'fat_loss',
        estimatedSteps: 7500,
        bmr: 1300.0,
        tdee: 1787.5,
        targetCalories: 1300.0,
        targetProtein: 117.0,
        targetCarbs: 83.0,
        targetFat: 52.0,
      );

      final prompt = MetabolicCalculator.generateMasterPrompt(profile);

      // Secciones
      expect(prompt, contains('# Contexto Biológico y Metas Nutricionales del Comensal'));
      expect(prompt, contains('## 1. Datos Biométricos'));
      expect(prompt, contains('## 2. Nivel de Actividad y Gasto Energético'));
      expect(prompt, contains('## 3. Metas Metabólicas y Objetivos'));
      expect(prompt, contains('## 4. Distribución de Macronutrientes Objetivo'));
      expect(prompt, contains('## 5. Instrucciones Clínicas para la Estimación Visual (Gemini Vision)'));

      // Marcadores
      expect(prompt, contains('Ana García'));
      expect(prompt, contains('32 años'));
      expect(prompt, contains('Femenino'));
      expect(prompt, contains('164.0 cm'));
      expect(prompt, contains('58.5 kg'));
      expect(prompt, contains('7500 pasos/día'));

      // Directivas clínicas
      expect(prompt, contains('Prioridad Proteica'));
      expect(prompt, contains('Densidad Calórica y Grasa Oculta'));
      expect(prompt, contains('Volumetría de Carbohidratos'));
      expect(prompt, contains('Alineación con el Objetivo'));
    });
  });
}
