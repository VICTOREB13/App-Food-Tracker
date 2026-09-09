import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/weight_log.dart';
import 'package:food_tracker/widgets/metrics/weight_history_bento_card.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
  });

  group('WeightHistoryBentoCard Widget Tests', () {
    testWidgets('muestra mensaje cuando no hay registros de peso', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeightHistoryBentoCard(logs: []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HISTORIAL DE PESO'), findsOneWidget);
      expect(find.text('0 registros'), findsOneWidget);
      expect(find.text('Sin registros de peso en este período.'), findsOneWidget);
    });

    testWidgets('muestra registros ordenados y notas asociadas', (tester) async {
      final now = DateTime(2026, 9, 8, 10, 0);
      final logs = [
        WeightLog(
          id: 'w1',
          date: now.subtract(const Duration(days: 1)),
          weight: 79.5,
          notes: 'En ayunas',
        ),
        WeightLog(
          id: 'w2',
          date: now,
          weight: 79.2,
          notes: 'Post-entreno',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WeightHistoryBentoCard(logs: logs),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 registros'), findsOneWidget);
      expect(find.text('79.2'), findsOneWidget);
      expect(find.text('79.5'), findsOneWidget);
      expect(find.text('Post-entreno'), findsOneWidget);
      expect(find.text('En ayunas'), findsOneWidget);
    });

    testWidgets('soporta expansión y contracción cuando hay más de 4 registros', (tester) async {
      final baseDate = DateTime(2026, 9, 1);
      final logs = List.generate(
        6,
        (i) => WeightLog(
          id: 'w_$i',
          date: baseDate.add(Duration(days: i)),
          weight: 80.0 - (i * 0.2),
          notes: 'Día $i',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WeightHistoryBentoCard(logs: logs),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('6 registros'), findsOneWidget);
      expect(find.text('Ver todos (6)'), findsOneWidget);

      // Tap on expand button
      await tester.tap(find.text('Ver todos (6)'));
      await tester.pumpAndSettle();

      expect(find.text('Ver menos'), findsOneWidget);

      // Tap on collapse button
      await tester.tap(find.text('Ver menos'));
      await tester.pumpAndSettle();

      expect(find.text('Ver todos (6)'), findsOneWidget);
    });
  });
}
