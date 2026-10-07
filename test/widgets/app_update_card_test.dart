import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/core/interfaces/app_installer_service_interface.dart';
import 'package:food_tracker/core/interfaces/app_update_service_interface.dart';
import 'package:food_tracker/models/github_release_model.dart';
import 'package:food_tracker/widgets/settings/app_update_card.dart';
import 'package:food_tracker/widgets/settings/in_app_update_dialog.dart';

class _FakeUpdateService implements IAppUpdateService {
  final GitHubReleaseModel? releaseToReturn;
  final bool updateAvailable;

  _FakeUpdateService({this.releaseToReturn, this.updateAvailable = false});

  @override
  Future<GitHubReleaseModel?> checkLatestRelease() async => releaseToReturn;

  @override
  bool isUpdateAvailable(String currentVersion, String latestTag) => updateAvailable;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeInstallerService implements IAppInstallerService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AppUpdateCard Widget Tests', () {
    testWidgets('renders current version and allows manual update check', (tester) async {
      final fakeService = _FakeUpdateService(updateAvailable: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppUpdateCard(
              currentVersion: '1.3.0',
              updateService: fakeService,
              installerService: _FakeInstallerService(),
            ),
          ),
        ),
      );

      expect(find.text('Actualizaciones de la Aplicación'), findsOneWidget);
      expect(find.textContaining('v1.3.0'), findsOneWidget);
      expect(find.byKey(const Key('check_updates_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('check_updates_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tu versión (v1.3.0) está al día'), findsOneWidget);
    });

    testWidgets('shows InAppUpdateDialog when update is available', (tester) async {
      final release = GitHubReleaseModel(
        tagName: 'v1.4.0',
        title: 'v1.4.0 - Major features',
        releaseNotes: 'Notas de la versión',
        publishedAt: DateTime.now(),
        htmlUrl: 'https://example.com',
      );
      final fakeService = _FakeUpdateService(
        releaseToReturn: release,
        updateAvailable: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppUpdateCard(
              currentVersion: '1.3.0',
              updateService: fakeService,
              installerService: _FakeInstallerService(),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('check_updates_button')));
      await tester.pumpAndSettle();

      expect(find.byType(InAppUpdateDialog), findsOneWidget);
      expect(find.text('v1.4.0'), findsOneWidget);
    });

    testWidgets('defaults to canonical AppConstants.appVersion when omitted', (tester) async {
      final fakeService = _FakeUpdateService(updateAvailable: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppUpdateCard(
              updateService: fakeService,
              installerService: _FakeInstallerService(),
            ),
          ),
        ),
      );

      expect(find.textContaining('v1.3.2'), findsOneWidget);
    });
  });
}
