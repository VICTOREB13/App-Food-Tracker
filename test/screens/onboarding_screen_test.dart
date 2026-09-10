import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/screens/onboarding_screen.dart';
import 'package:food_tracker/services/database_service.dart';
import 'package:food_tracker/services/secure_storage_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> data = {};

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
    return data[key];
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
      data[key] = value;
    } else {
      data.remove(key);
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
    data.remove(key);
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  late Database db;
  late FakeFlutterSecureStorage fakeStorage;

  setUp(() async {
    fakeStorage = FakeFlutterSecureStorage();
    SecureStorageService.setMockInstance(SecureStorageService.withStorage(fakeStorage));

    db = await databaseFactoryFfiNoIsolate.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE user_profile (
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
          await db.execute('''
            CREATE TABLE meals (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              meal_type TEXT NOT NULL,
              date TEXT NOT NULL,
              image_path TEXT,
              calories REAL NOT NULL,
              protein REAL NOT NULL,
              carbs REAL NOT NULL,
              fat REAL NOT NULL,
              notes TEXT,
              ai_breakdown_json TEXT
            )
          ''');
        },
      ),
    );
    DatabaseService.instance.setDatabaseForTesting(db);
  });

  tearDown(() async {
    await DatabaseService.instance.closeForTesting();
    SecureStorageService.resetInstance();
  });

  testWidgets('Onboarding 4-step flow walkthrough and completion', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Step 0: Welcome
    expect(find.text('¡Bienvenido a Food Tracker!'), findsOneWidget);
    expect(find.text('PASO 1 DE 4'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);

    // Tap Continuar -> Step 1: Biometrics
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Parámetros Biológicos'), findsOneWidget);
    expect(find.text('PASO 2 DE 4'), findsOneWidget);
    expect(find.text('Atrás'), findsOneWidget);

    // Tap Continuar -> Step 2: Activity
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Actividad y Movimiento Diario'), findsOneWidget);
    expect(find.text('PASO 3 DE 4'), findsOneWidget);

    // Tap Continuar -> Step 3: Goal & Plan
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Objetivo y Plan Metabólico'), findsOneWidget);
    expect(find.text('PASO 4 DE 4'), findsOneWidget);
    expect(find.text('Guardar y Empezar a Registrar'), findsOneWidget);
    expect(find.text('RESUMEN METABÓLICO EN VIVO'), findsOneWidget);

    // Tap Save and Finish
    await tester.tap(find.text('Guardar y Empezar a Registrar'));
    await tester.pumpAndSettle();

    // Verify persistence
    final profile = await DatabaseService.instance.getUserProfile();
    expect(profile, isNotNull);
    expect(profile!.name, equals('Victor'));
    expect(profile.bmr, greaterThan(1000));

    final hasCompleted = await SecureStorageService.instance.hasCompletedOnboarding();
    expect(hasCompleted, isTrue);

    final dailyGoals = await SecureStorageService.instance.getDailyGoals();
    expect(dailyGoals.calories, greaterThan(1000));
  });
}
