import 'dart:ui';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/main.dart';
import 'package:food_tracker/screens/dashboard_screen.dart';
import 'package:food_tracker/screens/onboarding_screen.dart';
import 'package:food_tracker/services/daos/database_schema.dart';
import 'package:food_tracker/services/database_service.dart';
import 'package:food_tracker/services/secure_storage_service.dart';
import 'package:food_tracker/services/theme_manager.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> data = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
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
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => data.remove(key);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  late Database testDb;
  late _FakeSecureStorage fakeStorage;

  setUp(() async {
    testDb = await databaseFactoryFfiNoIsolate.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onConfigure: (db) async {
          await db.rawQuery('PRAGMA journal_mode = WAL;');
          await db.execute('PRAGMA synchronous = NORMAL;');
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) => DatabaseSchema.createAllTables(db),
      ),
    );
    DatabaseService.instance.setDatabaseForTesting(testDb);

    fakeStorage = _FakeSecureStorage();
    fakeStorage.data['has_completed_onboarding'] = 'true';
    SecureStorageService.setMockInstance(SecureStorageService.withStorage(fakeStorage));
  });

  tearDown(() async {
    SecureStorageService.resetInstance();
    await DatabaseService.instance.closeForTesting();
  });

  testWidgets('NutriTrackerApp boots and renders DashboardScreen without crashing', (tester) async {
    await tester.pumpWidget(const NutriTrackerApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(NutriTrackerApp), findsOneWidget);
    expect(ThemeManager.instance, isNotNull);
  });

  testWidgets('NutriTrackerApp renders cleanly in English locale', (tester) async {
    await tester.pumpWidget(const NutriTrackerApp(locale: Locale('en')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(NutriTrackerApp), findsOneWidget);
  });

  testWidgets('NutriTrackerApp gracefully falls back to Spanish for unsupported locale', (tester) async {
    await tester.pumpWidget(const NutriTrackerApp(locale: Locale('fr')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(NutriTrackerApp), findsOneWidget);
  });

  testWidgets('NutriTrackerApp renders OnboardingScreen when hasCompletedOnboarding is false', (tester) async {
    await tester.pumpWidget(const NutriTrackerApp(hasCompletedOnboarding: false));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('NutriTrackerApp renders DashboardScreen when hasCompletedOnboarding is true', (tester) async {
    await tester.pumpWidget(const NutriTrackerApp(hasCompletedOnboarding: true));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('NutriTrackerApp dynamically updates when hasCompletedOnboarding prop changes', (tester) async {
    await tester.pumpWidget(const NutriTrackerApp(hasCompletedOnboarding: false));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(OnboardingScreen), findsOneWidget);

    await tester.pumpWidget(const NutriTrackerApp(hasCompletedOnboarding: true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('NutriTrackerApp background check transitions to OnboardingScreen when uncompleted in storage', (tester) async {
    fakeStorage.data.remove('has_completed_onboarding');

    await tester.pumpWidget(const NutriTrackerApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('OnboardingScreen onCompleted callback updates root app to DashboardScreen', (tester) async {
    fakeStorage.data.remove('has_completed_onboarding');

    await tester.pumpWidget(const NutriTrackerApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(OnboardingScreen), findsOneWidget);

    final onboardingWidget = tester.widget<OnboardingScreen>(find.byType(OnboardingScreen));
    onboardingWidget.onCompleted?.call();

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
