import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/controllers/settings_controller.dart';
import 'package:food_tracker/l10n/app_localizations.dart';
import 'package:food_tracker/models/storage_mode.dart';
import 'package:food_tracker/services/secure_storage_service.dart';
import 'package:food_tracker/widgets/settings/storage_mode_card.dart';

class _FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
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
}

void main() {
  group('StorageModeCard Widget Tests', () {
    late _FakeFlutterSecureStorage fakeStorage;

    setUp(() {
      fakeStorage = _FakeFlutterSecureStorage();
      SecureStorageService.setMockInstance(SecureStorageService.withStorage(fakeStorage));
      SettingsController.resetInstance();
    });

    tearDown(() {
      SecureStorageService.resetInstance();
    });

    testWidgets('renders storage mode options and toggles between public and private', (tester) async {
      final controller = SettingsController.instance;
      expect(controller.storageMode, equals(StorageMode.public));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StorageModeCard(),
            ),
          ),
        ),
      );

      expect(find.text('ALMACENAMIENTO DE FOTOS'), findsOneWidget);
      expect(find.text('Público (Galería)'), findsOneWidget);
      expect(find.text('Privado (Aislado)'), findsOneWidget);

      // Tap on Privado
      await tester.tap(find.text('Privado (Aislado)'));
      await tester.pumpAndSettle();

      expect(controller.storageMode, equals(StorageMode.private));

      // Tap back on Público
      await tester.tap(find.text('Público (Galería)'));
      await tester.pumpAndSettle();

      expect(controller.storageMode, equals(StorageMode.public));
    });

    testWidgets('renders storage mode in English when locale is en', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: StorageModeCard(),
            ),
          ),
        ),
      );

      expect(find.text('PHOTO STORAGE'), findsOneWidget);
      expect(find.text('Public (Gallery)'), findsOneWidget);
      expect(find.text('Private (Isolated)'), findsOneWidget);
    });
  });
}
