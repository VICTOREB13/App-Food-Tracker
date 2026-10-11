import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/l10n/app_localizations.dart';
import 'package:food_tracker/models/user_profile.dart';
import 'package:food_tracker/widgets/profile/metabolic_summary_bento_card.dart';

void main() {
  group('MetabolicSummaryBentoCard UI Tests', () {
    final sampleProfile = UserProfile(
      id: 'test_user_bento',
      name: 'Victor',
      age: 28,
      gender: 'male',
      height: 178,
      weight: 78,
      bmr: 1750,
      tdee: 2500,
      targetCalories: 2000,
      targetProtein: 150,
      targetCarbs: 200,
      targetFat: 60,
      masterPrompt: 'Prompt de prueba bento',
      updatedAt: DateTime(2026, 10, 10),
    );

    testWidgets('MetabolicSummaryBentoCard renders explicit prompt action button and interactive trigger', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: MetabolicSummaryBentoCard(profile: sampleProfile),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and bio data
      expect(find.text('RESUMEN METABÓLICO'), findsOneWidget);
      expect(find.text('2000'), findsOneWidget);

      // Check Master Prompt section elements
      expect(find.byKey(const Key('master_prompt_bento_trigger')), findsOneWidget);
      expect(find.byKey(const Key('master_prompt_open_sheet_button')), findsOneWidget);
      expect(find.byKey(const Key('master_prompt_quick_copy_button')), findsOneWidget);
      expect(find.text('Ver / Configurar'), findsOneWidget);
      expect(find.text('Toca para ver o personalizar el prompt'), findsOneWidget);

      // Tap explicit Ver / Configurar button -> opens MasterPromptBottomSheet
      await tester.tap(find.byKey(const Key('master_prompt_open_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.text('Master Prompt IA Multimodal (Editable)'), findsOneWidget);
      expect(find.text('Prompt de prueba bento'), findsOneWidget);
    });

    testWidgets('Tapping Master Prompt banner trigger opens bottom sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: MetabolicSummaryBentoCard(profile: sampleProfile),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the entire banner InkWell
      await tester.tap(find.byKey(const Key('master_prompt_bento_trigger')));
      await tester.pumpAndSettle();

      expect(find.text('Master Prompt IA Multimodal (Editable)'), findsOneWidget);
    });

    testWidgets('Tapping quick copy button shows feedback snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: MetabolicSummaryBentoCard(profile: sampleProfile),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('master_prompt_quick_copy_button')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
