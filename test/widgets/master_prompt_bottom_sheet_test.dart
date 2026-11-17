import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/l10n/app_localizations.dart';
import 'package:food_tracker/features/settings_profile/models/user_profile.dart';
import 'package:food_tracker/features/settings_profile/widgets/profile/master_prompt_bottom_sheet.dart';

void main() {
  testWidgets('MasterPromptBottomSheet renders tabs, preview, and editor', (tester) async {
    final profile = UserProfile(
      id: 'test_user',
      name: 'Tester',
      age: 30,
      gender: 'male',
      height: 180.0,
      weight: 75.0,
      activityLevel: 'moderate',
      bodyGoal: 'maintenance',
      estimatedSteps: 8000,
      bmr: 1700.0,
      tdee: 2300.0,
      targetCalories: 2300.0,
      targetProtein: 150.0,
      targetCarbs: 250.0,
      targetFat: 65.0,
      masterPrompt: 'Prompt de prueba personalizado',
      updatedAt: DateTime(2026, 10, 10),
    );

    String? savedPrompt;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => MasterPromptBottomSheet.show(
                context,
                profile: profile,
                onSaved: (val) => savedPrompt = val,
              ),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Check header and tabs in Dark Bento design
    expect(find.text('Prompt Maestro'), findsOneWidget);
    expect(find.text('Resumen Bento'), findsOneWidget);
    expect(find.text('Editor de Prompt'), findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded), findsWidgets);

    // Check preview content contains custom prompt
    expect(find.text('Prompt de prueba personalizado'), findsOneWidget);

    // Test 1-tap copy button in header
    await tester.tap(find.byIcon(Icons.copy_rounded).first);
    await tester.pumpAndSettle();

    // Switch to Editor tab
    await tester.tap(find.text('Editor de Prompt'));
    await tester.pumpAndSettle();

    // Edit text field
    final textFieldFinder = find.byType(TextFormField);
    expect(textFieldFinder, findsOneWidget);

    // Test Restore Default action
    expect(find.text('Restaurar por Defecto'), findsOneWidget);
    await tester.tap(find.text('Restaurar por Defecto'));
    await tester.pumpAndSettle();

    // Re-enter custom text
    await tester.enterText(textFieldFinder, 'Prompt modificado por el usuario');
    await tester.pumpAndSettle();

    // Tap Guardar Prompt
    expect(find.text('Guardar Prompt'), findsOneWidget);
    await tester.tap(find.text('Guardar Prompt'));
    await tester.pumpAndSettle();

    expect(savedPrompt, equals('Prompt modificado por el usuario'));
    expect(find.text('Prompt Maestro'), findsNothing);
  });

  testWidgets('MasterPromptBottomSheet renders accurately in English', (tester) async {
    final profile = UserProfile(
      id: 'test_user_en',
      name: 'Tester EN',
      age: 25,
      gender: 'female',
      height: 165.0,
      weight: 60.0,
      activityLevel: 'sedentary',
      bodyGoal: 'deficit',
      estimatedSteps: 5000,
      bmr: 1300.0,
      tdee: 1600.0,
      targetCalories: 1300.0,
      targetProtein: 100.0,
      targetCarbs: 140.0,
      targetFat: 40.0,
      masterPrompt: 'Initial prompt EN',
      updatedAt: DateTime(2026, 10, 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => MasterPromptBottomSheet.show(
                context,
                profile: profile,
                onSaved: (_) {},
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Prompt Maestro'), findsOneWidget);
    expect(find.text('Resumen Bento'), findsOneWidget);
    expect(find.text('Editor de Prompt'), findsOneWidget);

    await tester.tap(find.text('Editor de Prompt'));
    await tester.pumpAndSettle();

    expect(find.text('Restore Default'), findsOneWidget);
    expect(find.text('Save Prompt'), findsOneWidget);
  });
}