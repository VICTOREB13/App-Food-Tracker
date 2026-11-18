import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/core/models/diet_pattern_insight.dart';
import 'package:food_tracker/core/interfaces/diet_advisor_service_interface.dart';
import 'package:food_tracker/features/dashboard/widgets/recommendations/ai_diet_pattern_sheet.dart';

class _FakeDietPatternService implements IDietAdvisorService {
  int requestedDays = 0;
  bool requestedForceRefresh = false;
  final DietPatternInsight insightToReturn;

  _FakeDietPatternService(this.insightToReturn);

  @override
  Future<DietPatternInsight> getDietPatternInsights({int days = 7, bool forceRefresh = false}) async {
    requestedDays = days;
    requestedForceRefresh = forceRefresh;
    return insightToReturn;
  }
}

void main() {
  testWidgets('AiDietPatternSheet renders bento cards, summary, and lists', (tester) async {
    final sampleInsight = DietPatternInsight(
      daysAnalyzed: 7,
      fatInsight: 'Modera aceites de freír y frituras.',
      proteinInsight: 'Asegura proteína magra en cada comida.',
      fiberInsight: 'Incrementa vegetales y legumbres.',
      sodiumInsight: 'Modera embutidos y quesos.',
      visualHandMenu: const [
        'Desayuno: 2 huevos + 1 rebanada integral',
        'Almuerzo: Pechuga a la plancha + ensalada mixta',
      ],
      suggestedSwaps: const [
        'Cambia embutidos por pavo horneado.',
        'Sustituye mayonesa por yogur griego.',
      ],
      generalSummary: 'Tus patrones muestran una buena base.',
      analyzedAt: DateTime(2026, 11, 17),
    );

    final service = _FakeDietPatternService(sampleInsight);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AiDietPatternSheet.show(context, initialDays: 7, service: service),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Verify title and header
    expect(find.text('Diagnóstico de Hábitos IA'), findsOneWidget);
    expect(find.text('7 días'), findsWidgets);
    expect(find.text('14 días'), findsOneWidget);
    expect(find.text('30 días'), findsOneWidget);

    // Verify hero card
    expect(find.text('Tus patrones muestran una buena base.'), findsOneWidget);

    // Verify bento thematic cards
    expect(find.text('GRASAS Y ACEITES'), findsOneWidget);
    expect(find.text('Modera aceites de freír y frituras.'), findsOneWidget);
    expect(find.text('PROTEÍNA Y METAS'), findsOneWidget);
    expect(find.text('Asegura proteína magra en cada comida.'), findsOneWidget);
    expect(find.text('FIBRA Y VEGETALES'), findsOneWidget);
    expect(find.text('CONTROL DE SODIO'), findsOneWidget);

    // Verify list items
    expect(find.text('Desayuno: 2 huevos + 1 rebanada integral'), findsOneWidget);
    expect(find.text('Cambia embutidos por pavo horneado.'), findsOneWidget);

    // Tap 14 days chip
    await tester.tap(find.text('14 días'));
    await tester.pumpAndSettle();
    expect(service.requestedDays, equals(14));

    // Tap refresh button
    await tester.tap(find.byTooltip('Actualizar auditoría'));
    await tester.pumpAndSettle();
    expect(service.requestedForceRefresh, isTrue);
  });
}
