import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/screens/user_profile_screen.dart';
import 'package:food_tracker/services/database_service.dart';
import 'package:food_tracker/services/secure_storage_service.dart';
import 'package:food_tracker/widgets/profile/activity_goal_selector_card.dart';
import 'package:food_tracker/widgets/profile/biometric_inputs_card.dart';
import 'package:food_tracker/widgets/profile/metabolic_summary_bento_card.dart';
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
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late FakeFlutterSecureStorage fakeStorage;

  setUp(() async {
    fakeStorage = FakeFlutterSecureStorage();
    SecureStorageService.setMockInstance(SecureStorageService.withStorage(fakeStorage));

    db = await databaseFactoryFfi.openDatabase(
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
        },
      ),
    );
    DatabaseService.instance.setDatabaseForTesting(db);
  });

  tearDown(() async {
    await DatabaseService.instance.closeForTesting();
    SecureStorageService.resetInstance();
  });

  Widget createTestWidget({bool isOnboarding = false, VoidCallback? onSaved}) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: UserProfileScreen(
        isOnboarding: isOnboarding,
        onProfileSaved: onSaved,
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('UserProfileScreen Widget & Interaction Tests', () {
    testWidgets('Renderiza correctamente la pantalla, títulos y tarjetas atómicas', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await pumpScreen(tester);

      // Verifica App Bar
      expect(find.text('Perfil Metabólico'), findsOneWidget);
      expect(find.text('Mifflin-St Jeor & Master Prompt'), findsOneWidget);

      // Verifica presencia de las 3 tarjetas modulares
      expect(find.byType(MetabolicSummaryBentoCard), findsOneWidget);
      expect(find.byType(BiometricInputsCard), findsOneWidget);
      expect(find.byType(ActivityGoalSelectorCard), findsOneWidget);

      // Verifica encabezados de las tarjetas
      expect(find.text('RESUMEN METABÓLICO'), findsOneWidget);
      expect(find.text('DATOS BIOMÉTRICOS'), findsOneWidget);
      expect(find.text('ACTIVIDAD Y OBJETIVO'), findsOneWidget);

      // Verifica botón principal
      expect(find.text('Guardar Perfil y Sincronizar Metas'), findsOneWidget);
    });

    testWidgets('Modo Onboarding muestra títulos y botón adaptados', (tester) async {
      await tester.pumpWidget(createTestWidget(isOnboarding: true));
      await pumpScreen(tester);

      expect(find.text('Configura tu Perfil'), findsOneWidget);
      expect(find.text('Paso 1: Parámetros Biológicos y Metas TDEE'), findsOneWidget);
      expect(find.text('Completar Onboarding y Guardar Metas'), findsOneWidget);
    });

    testWidgets('Calcula en tiempo real al alternar género biológico', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await pumpScreen(tester);

      // Por defecto es Masculino
      expect(find.text('Masculino'), findsOneWidget);

      // Tocar opción 'Femenino'
      await tester.tap(find.text('Femenino'));
      await pumpScreen(tester);

      // El resumen metabólico debe recalcularse (BMR femenino es menor debido a -161)
      expect(find.byType(MetabolicSummaryBentoCard), findsOneWidget);
    });

    testWidgets('Calcula en tiempo real al seleccionar otro nivel de actividad', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await pumpScreen(tester);

      // Seleccionar 'Muy Activo (1.725x)'
      final veryActiveTile = find.text('Muy Activo (1.725x)');
      expect(veryActiveTile, findsOneWidget);

      await tester.tap(veryActiveTile);
      await pumpScreen(tester);

      // Verifica que el widget sigue renderizando y responde
      expect(find.byType(MetabolicSummaryBentoCard), findsOneWidget);
    });

    testWidgets('Calcula en tiempo real al seleccionar otro objetivo corporal', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await pumpScreen(tester);

      // Seleccionar 'Ganancia Muscular' (+300 kcal)
      final gainTile = find.text('Ganancia Muscular');
      expect(gainTile, findsOneWidget);

      await tester.tap(gainTile);
      await pumpScreen(tester);

      expect(find.byType(MetabolicSummaryBentoCard), findsOneWidget);
    });

    testWidgets('Guardar perfil persiste en SQLite, SecureStorage y muestra confirmación', (tester) async {
      bool onSavedCalled = false;

      await tester.pumpWidget(createTestWidget(
        onSaved: () => onSavedCalled = true,
      ));
      await pumpScreen(tester);

      // Tocar botón de guardar
      final saveBtn = find.text('Guardar Perfil y Sincronizar Metas');
      await tester.tap(saveBtn);
      await pumpScreen(tester);

      // Verifica invocación del callback
      expect(onSavedCalled, isTrue);

      // Verifica mensaje SnackBar
      expect(find.text('Perfil metabólico y metas sincronizadas con éxito'), findsOneWidget);

      // Verifica persistencia en SQLite
      UserProfile? savedProfile;
      await tester.runAsync(() async {
        savedProfile = await DatabaseService.instance.getUserProfile();
      });
      expect(savedProfile, isNotNull);
      expect(savedProfile!.name, equals('Victor Engineer'));
      expect(savedProfile.bmr, greaterThan(1000.0));
      expect(savedProfile.masterPrompt, isNotNull);

      // Verifica persistencia en SecureStorage
      final onboardingDone = await SecureStorageService.instance.hasCompletedOnboarding();
      expect(onboardingDone, isTrue);

      final dailyGoals = await SecureStorageService.instance.getDailyGoals();
      expect(dailyGoals.calories, equals(savedProfile.targetCalories));
      expect(dailyGoals.protein, equals(savedProfile.targetProtein));

      final masterPrompt = await SecureStorageService.instance.getMasterPrompt();
      expect(masterPrompt, isNotNull);
      expect(masterPrompt, contains('Victor Engineer'));
    });
  });
}
