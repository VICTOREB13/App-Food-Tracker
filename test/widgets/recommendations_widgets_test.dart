import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/nutritional_recommendation.dart';
import 'package:food_tracker/widgets/recommendations/recommendation_diagnostic_card.dart';
import 'package:food_tracker/widgets/recommendations/what_to_eat_sheet.dart';

void main() {
  group('Recommendation Widgets UI Tests', () {
    testWidgets('WhatToEatSheet renders remaining macros and dish recommendations', (tester) async {
      const samplePlan = TodayRecommendationPlan(
        remainingCalories: 550,
        remainingProtein: 45,
        remainingCarbs: 60,
        remainingFat: 15,
        nextMealType: 'Almuerzo',
        generalAdvice: 'Tienes un margen favorable para tu próxima comida.',
        recommendedOptions: [
          RecommendedDish(
            id: 'd1',
            name: 'Pechuga de Pollo con Quinoa y Espárragos',
            mealType: 'Almuerzo',
            calories: 450,
            protein: 42,
            carbs: 45,
            fat: 8,
            fitScore: 95,
            description: 'Plato alto en proteína y bajo en grasas',
            ingredients: ['Pollo', 'Quinoa', 'Espárragos'],
            whyRecommended: 'Excelente balance proteico y bajo en grasas',
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhatToEatSheet(initialPlan: samplePlan),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('¿Qué debería comer hoy?'), findsOneWidget);
      expect(find.text('Margen restante de hoy:'), findsOneWidget);
      expect(find.text('Calorías'), findsOneWidget);
      expect(find.text('Proteína'), findsOneWidget);
      expect(find.text('Carbos'), findsOneWidget);
      expect(find.text('Grasas'), findsOneWidget);
      expect(find.text('Platos recomendados a tu medida:'), findsOneWidget);
      expect(find.text('Pechuga de Pollo con Quinoa y Espárragos'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('RecommendationDiagnosticCard renders period chips and macro gauges', (tester) async {
      const sampleReport = NutritionalAnalysisReport(
        daysAnalyzed: 7,
        mealsLogged: 5,
        averageDailyCalories: 1900,
        averageDailyProtein: 130,
        averageDailyCarbs: 210,
        averageDailyFat: 55,
        targetCalories: 2000,
        targetProtein: 140,
        targetCarbs: 220,
        targetFat: 60,
        fatDiagnosis: 'Consumo de grasa equilibrado dentro de tu objetivo.',
        proteinDiagnosis: 'Consumo de proteína adecuado.',
        carbsDiagnosis: 'Balance adecuado.',
        calorieDiagnosis: 'Calorías en rango.',
        fatReductionSwaps: [
          FoodSwapSuggestion(
            originalFood: 'Aceite común',
            substituteFood: 'Spray antiadherente',
            rationale: 'Usa spray',
            fatSavedGrams: 10,
          ),
        ],
        proteinIncreaseSuggestions: [],
        suggestedPlates: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RecommendationDiagnosticCard(initialReport: sampleReport),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('MOTOR DE RECOMENDACIÓN NUTRICIONAL'), findsOneWidget);
      expect(find.text('7 días'), findsOneWidget);
      expect(find.text('15 días'), findsOneWidget);
      expect(find.text('30 días'), findsOneWidget);
      expect(find.text('Control de Grasas'), findsOneWidget);
      expect(find.text('Metas de Proteína'), findsOneWidget);
      expect(find.text('Energía y Carbohidratos'), findsOneWidget);
      expect(find.text('Sustituciones Inteligentes Sugeridas:'), findsOneWidget);
    });

    testWidgets('WhatToEatSheet has close button and dismisses modal', (tester) async {
      const samplePlan = TodayRecommendationPlan(
        remainingCalories: 550,
        remainingProtein: 45,
        remainingCarbs: 60,
        remainingFat: 15,
        nextMealType: 'Cena',
        generalAdvice: 'Prueba una cena ligera.',
        recommendedOptions: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: ctx,
                  isScrollControlled: true,
                  builder: (_) => const WhatToEatSheet(initialPlan: samplePlan),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('¿Qué debería comer hoy?'), findsOneWidget);
      expect(find.byKey(const Key('what_to_eat_close_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('what_to_eat_close_button')));
      await tester.pumpAndSettle();

      expect(find.text('¿Qué debería comer hoy?'), findsNothing);
    });

    testWidgets('showRecommendationDiagnosticDialog renders bounded dialog with close button', (tester) async {
      const sampleReport = NutritionalAnalysisReport(
        daysAnalyzed: 7,
        mealsLogged: 5,
        averageDailyCalories: 1900,
        averageDailyProtein: 130,
        averageDailyCarbs: 210,
        averageDailyFat: 55,
        targetCalories: 2000,
        targetProtein: 140,
        targetCarbs: 220,
        targetFat: 60,
        fatDiagnosis: 'Consumo de grasa equilibrado dentro de tu objetivo.',
        proteinDiagnosis: 'Consumo de proteína adecuado.',
        carbsDiagnosis: 'Balance adecuado.',
        calorieDiagnosis: 'Calorías en rango.',
        fatReductionSwaps: [],
        proteinIncreaseSuggestions: [],
        suggestedPlates: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showRecommendationDiagnosticDialog(ctx, initialReport: sampleReport),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Diagnóstico Nutricional'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Diagnóstico Nutricional'), findsNothing);
    });
  });
}
