import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_tracker/controllers/settings_controller.dart';
import 'package:food_tracker/models/user_profile.dart';
import 'package:food_tracker/services/database_service.dart';
import 'package:food_tracker/services/metabolic_calculator.dart';
import 'package:food_tracker/services/secure_storage_service.dart';

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }
}

void main() {
  group('MetabolicCalculator - Mifflin-St Jeor BMR Tests', () {
    test('Calcula BMR para hombre adulto promedio con fórmula exacta', () {
      // Male: (10 * 70) + (6.25 * 175) - (5 * 30) + 5 = 700 + 1093.75 - 150 + 5 = 1648.75 -> 1648.8
      final bmr = MetabolicCalculator.calculateBmr(
        gender: 'male',
        weightKg: 70.0,
        heightCm: 175.0,
        age: 30,
      );
      expect(bmr, equals(1648.8));
    });

    test('Calcula BMR para mujer adulta promedio con fórmula exacta (-161)', () {
      // Female: (10 * 60) + (6.25 * 165) - (5 * 30) - 161 = 600 + 1031.25 - 150 - 161 = 1320.25 -> 1320.3
      final bmr = MetabolicCalculator.calculateBmr(
        gender: 'female',
        weightKg: 60.0,
        heightCm: 165.0,
        age: 30,
      );
      expect(bmr, equals(1320.3));
    });

    test('Maneja sinónimos y variaciones de género (femenino, mujer, hombre, etc.)', () {
      final bmrFem1 = MetabolicCalculator.calculateBmr(
        gender: 'FEMALE',
        weightKg: 55.0,
        heightCm: 160.0,
        age: 25,
      );
      final bmrFem2 = MetabolicCalculator.calculateBmr(
        gender: 'mujer',
        weightKg: 55.0,
        heightCm: 160.0,
        age: 25,
      );
      final bmrFem3 = MetabolicCalculator.calculateBmr(
        gender: 'femenino',
        weightKg: 55.0,
        heightCm: 160.0,
        age: 25,
      );
      expect(bmrFem1, equals(bmrFem2));
      expect(bmrFem2, equals(bmrFem3));

      final bmrMale1 = MetabolicCalculator.calculateBmr(
        gender: 'MALE',
        weightKg: 80.0,
        heightCm: 180.0,
        age: 28,
      );
      final bmrMale2 = MetabolicCalculator.calculateBmr(
        gender: 'hombre',
        weightKg: 80.0,
        heightCm: 180.0,
        age: 28,
      );
      expect(bmrMale1, equals(bmrMale2));
    });

    test('Casos límite de edad, altura y peso', () {
      // Joven límite (edad 15)
      final bmrTeen = MetabolicCalculator.calculateBmr(
        gender: 'male',
        weightKg: 50.0,
        heightCm: 160.0,
        age: 15,
      );
      // (10 * 50) + (6.25 * 160) - (5 * 15) + 5 = 500 + 1000 - 75 + 5 = 1430.0
      expect(bmrTeen, equals(1430.0));

      // Adulto mayor (edad 80)
      final bmrElder = MetabolicCalculator.calculateBmr(
        gender: 'female',
        weightKg: 65.0,
        heightCm: 155.0,
        age: 80,
      );
      // (10 * 65) + (6.25 * 155) - (5 * 80) - 161 = 650 + 968.75 - 400 - 161 = 1057.75 -> 1057.8
      expect(bmrElder, equals(1057.8));
    });
  });

  group('MetabolicCalculator - Activity Multipliers & TDEE', () {
    test('Calcula TDEE correctamente para los 4 niveles de actividad', () {
      const bmr = 1600.0;

      final tdeeSedentary = MetabolicCalculator.calculateTdee(
        bmr: bmr,
        activityLevel: 'sedentary',
      );
      // 1600 * 1.2 = 1920.0
      expect(tdeeSedentary, equals(1920.0));

      final tdeeLight = MetabolicCalculator.calculateTdee(
        bmr: bmr,
        activityLevel: 'light',
      );
      // 1600 * 1.375 = 2200.0
      expect(tdeeLight, equals(2200.0));

      final tdeeModerate = MetabolicCalculator.calculateTdee(
        bmr: bmr,
        activityLevel: 'moderate',
      );
      // 1600 * 1.55 = 2480.0
      expect(tdeeModerate, equals(2480.0));

      final tdeeVeryActive = MetabolicCalculator.calculateTdee(
        bmr: bmr,
        activityLevel: 'very_active',
      );
      // 1600 * 1.725 = 2760.0
      expect(tdeeVeryActive, equals(2760.0));
    });

    test('Fallback a sedentary (1.2x) para niveles no reconocidos', () {
      final tdee = MetabolicCalculator.calculateTdee(
        bmr: 1500.0,
        activityLevel: 'desconocido_123',
      );
      expect(tdee, equals(1800.0)); // 1500 * 1.2
    });
  });

  group('MetabolicCalculator - Caloric Goal & Protection Floor', () {
    test('Mantenimiento es igual a TDEE', () {
      final goal = MetabolicCalculator.calculateCaloricGoal(
        tdee: 2400.0,
        bmr: 1600.0,
        bodyGoal: 'maintenance',
      );
      expect(goal, equals(2400.0));
    });

    test('Ganancia muscular añade 300 kcal a TDEE', () {
      final goal = MetabolicCalculator.calculateCaloricGoal(
        tdee: 2400.0,
        bmr: 1600.0,
        bodyGoal: 'muscle_gain',
      );
      expect(goal, equals(2700.0));
    });

    test('Pérdida de grasa aplica déficit de 500 kcal si está sobre BMR', () {
      final goal = MetabolicCalculator.calculateCaloricGoal(
        tdee: 2400.0,
        bmr: 1600.0,
        bodyGoal: 'fat_loss',
      );
      // 2400 - 500 = 1900 (> 1600)
      expect(goal, equals(1900.0));
    });

    test('Piso de protección clínica: Déficit nunca desciende por debajo del BMR', () {
      // Caso de persona pequeña o sedentaria:
      // BMR = 1400, TDEE = 1600.
      // TDEE - 500 = 1100, que es menor que BMR (1400).
      // Debe proteger el metabolismo haciendo floor en 1400.
      final goal = MetabolicCalculator.calculateCaloricGoal(
        tdee: 1600.0,
        bmr: 1400.0,
        bodyGoal: 'fat_loss',
      );
      expect(goal, equals(1400.0));
    });
  });

  group('MetabolicCalculator - Macronutrient Distribution', () {
    test('Distribución para pérdida de grasa: 2.0g/kg proteína', () {
      final macros = MetabolicCalculator.calculateMacros(
        targetCalories: 2000.0,
        weightKg: 75.0,
        bodyGoal: 'fat_loss',
      );
      // Proteína: 75 * 2.0 = 150.0g (600 kcal)
      expect(macros.protein, equals(150.0));

      // Grasa: max(2000 * 0.25 / 9 = 55.55...g, 75 * 0.8 = 60.0g)
      // 60.0g es mayor que 55.56g -> grasa = 60.0g (540 kcal)
      expect(macros.fat, equals(60.0));

      // Carbohidratos: (2000 - 600 - 540) / 4 = 860 / 4 = 215.0g (860 kcal)
      expect(macros.carbs, equals(215.0));

      // Balance calórico total: 600 + 540 + 860 = 2000
      expect(macros.totalCalories, closeTo(2000.0, 1.0));
    });

    test('Distribución para ganancia muscular: 2.2g/kg proteína', () {
      final macros = MetabolicCalculator.calculateMacros(
        targetCalories: 2800.0,
        weightKg: 80.0,
        bodyGoal: 'muscle_gain',
      );
      // Proteína: 80 * 2.2 = 176.0g (704 kcal)
      expect(macros.protein, equals(176.0));

      // Grasa: max(2800 * 0.25 / 9 = 77.78g, 80 * 0.8 = 64.0g)
      // 77.8g es mayor que 64g -> grasa = 77.8g (700.2 kcal)
      expect(macros.fat, equals(77.8));

      // Carbs: (2800 - 704 - (77.8*9)) / 4 = (2800 - 704 - 700.2) / 4 = 1395.8 / 4 = 348.95 -> 349.0g
      expect(macros.carbs, closeTo(349.0, 0.5));

      // Balance calórico
      expect(macros.totalCalories, closeTo(2800.0, 2.0));
    });

    test('Distribución para mantenimiento: 1.8g/kg proteína', () {
      final macros = MetabolicCalculator.calculateMacros(
        targetCalories: 2200.0,
        weightKg: 70.0,
        bodyGoal: 'maintenance',
      );
      // Proteína: 70 * 1.8 = 126.0g
      expect(macros.protein, equals(126.0));

      // Grasa: max(2200 * 0.25 / 9 = 61.11g, 70 * 0.8 = 56.0g) -> 61.1g
      expect(macros.fat, equals(61.1));

      // Balance
      expect(macros.totalCalories, closeTo(2200.0, 2.0));
    });
  });

  group('MetabolicCalculator - Master Prompt Synthesis', () {
    test('Genera un Master Prompt en Markdown con todas las secciones clínicas requeridas', () {
      final profile = UserProfile(
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
      );

      final prompt = MetabolicCalculator.generateMasterPrompt(profile);

      // Verificación de estructura Markdown
      expect(prompt, contains('# Contexto Biológico y Metas Nutricionales del Comensal'));
      expect(prompt, contains('## 1. Datos Biométricos'));
      expect(prompt, contains('Victor Engineer'));
      expect(prompt, contains('28 años'));
      expect(prompt, contains('Masculino'));
      expect(prompt, contains('178.0 cm'));
      expect(prompt, contains('76.5 kg'));

      // Sección 2: Actividad y Gasto
      expect(prompt, contains('## 2. Nivel de Actividad y Gasto Energético'));
      expect(prompt, contains('10000 pasos/día'));
      expect(prompt, contains('1750 kcal/día'));
      expect(prompt, anyOf(contains('2712 kcal/día'), contains('2713 kcal/día')));

      // Sección 3: Metas
      expect(prompt, contains('## 3. Metas Metabólicas y Objetivos'));
      expect(prompt, contains('Pérdida de Grasa'));
      expect(prompt, anyOf(contains('2212 kcal/día'), contains('2213 kcal/día')));

      // Sección 4: Macronutrientes
      expect(prompt, contains('## 4. Distribución de Macronutrientes Objetivo'));
      expect(prompt, contains('153 g/día'));
      expect(prompt, contains('245 g/día'));
      expect(prompt, contains('61 g/día'));

      // Sección 5: Directrices Clínicas para Gemini Vision
      expect(prompt, contains('## 5. Instrucciones Clínicas para la Estimación Visual (Gemini Vision)'));
      expect(prompt, contains('Prioridad Proteica'));
      expect(prompt, contains('Densidad Calórica y Grasa Oculta'));
      expect(prompt, contains('Volumetría de Carbohidratos'));
    });
  });

  group('MetabolicCalculator - Profile Integration & DailyGoals Sync', () {
    test('calculateProfile construye un UserProfile consistente con Master Prompt embebido', () {
      final profile = MetabolicCalculator.calculateProfile(
        name: 'Sofia',
        age: 26,
        gender: 'female',
        height: 168.0,
        weight: 62.0,
        activityLevel: 'light',
        bodyGoal: 'fat_loss',
        estimatedSteps: 9000,
      );

      expect(profile.name, equals('Sofia'));
      expect(profile.gender, equals('female'));
      expect(profile.age, equals(26));
      expect(profile.bmr, greaterThan(1200.0));
      expect(profile.tdee, greaterThan(profile.bmr));
      expect(profile.targetCalories, greaterThanOrEqualTo(profile.bmr));
      expect(profile.targetProtein, equals(124.0)); // 62 * 2.0
      expect(profile.masterPrompt, isNotNull);
      expect(profile.masterPrompt!, contains('Sofia'));
      expect(profile.masterPrompt!, contains('Femenino'));

      // Conversión a DailyGoals
      final goals = MetabolicCalculator.toDailyGoals(profile);
      expect(goals.calories, equals(profile.targetCalories));
      expect(goals.protein, equals(profile.targetProtein));
      expect(goals.carbs, equals(profile.targetCarbs));
      expect(goals.fat, equals(profile.targetFat));
    });

    test('saveAndSynchronizeProfile persiste en SQLite, SecureStorage y sincroniza SettingsController', () async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS user_profile (
                id TEXT PRIMARY KEY,
                name TEXT,
                age INTEGER NOT NULL,
                gender TEXT NOT NULL,
                height REAL NOT NULL,
                weight REAL NOT NULL,
                activity_level TEXT NOT NULL,
                body_goal TEXT NOT NULL,
                estimated_steps INTEGER NOT NULL DEFAULT 8000,
                bmr REAL NOT NULL,
                tdee REAL NOT NULL,
                target_calories REAL NOT NULL,
                target_protein REAL NOT NULL,
                target_carbs REAL NOT NULL,
                target_fat REAL NOT NULL,
                master_prompt TEXT,
                updated_at TEXT NOT NULL
              )
            ''');
          },
        ),
      );
      DatabaseService.instance.setDatabaseForTesting(db);

      final fakeStorage = FakeFlutterSecureStorage();
      SecureStorageService.setMockInstance(SecureStorageService.withStorage(fakeStorage));
      SettingsController.resetInstance();

      final profile = MetabolicCalculator.calculateProfile(
        name: 'Carlos',
        age: 32,
        gender: 'male',
        height: 180.0,
        weight: 85.0,
        activityLevel: 'moderate',
        bodyGoal: 'fat_loss',
      );

      await MetabolicCalculator.saveAndSynchronizeProfile(profile);

      // Verify SQLite
      final inDb = await DatabaseService.instance.getUserProfile();
      expect(inDb, isNotNull);
      expect(inDb!.name, equals('Carlos'));
      expect(inDb.targetCalories, equals(profile.targetCalories));

      // Verify SecureStorage
      final inStorage = await SecureStorageService.instance.getDailyGoals();
      expect(inStorage.calories, equals(profile.targetCalories));

      // Verify SettingsController
      expect(SettingsController.instance.dailyGoals.calories, equals(profile.targetCalories));
      expect(SettingsController.instance.dailyGoals.protein, equals(profile.targetProtein));

      await DatabaseService.instance.closeForTesting();
    });
  });
}
