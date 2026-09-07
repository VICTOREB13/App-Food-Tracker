import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/weight_log.dart';
import 'package:food_tracker/widgets/metrics/weight_line_chart_painter.dart';

void main() {
  group('WeightLineChartPainter Tests', () {
    testWidgets('renders empty state placeholder when logs is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 180,
              child: CustomPaint(
                painter: WeightLineChartPainter(logs: []),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is WeightLineChartPainter),
        findsOneWidget,
      );
    });

    testWidgets('renders single log baseline and marker without errors', (tester) async {
      final singleLog = [
        WeightLog(
          id: 'w1',
          weight: 75.5,
          date: DateTime(2026, 9, 1),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 180,
              child: CustomPaint(
                painter: WeightLineChartPainter(logs: singleLog),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is WeightLineChartPainter),
        findsOneWidget,
      );
    });

    testWidgets('renders multi-point trend curve with gradient and grid lines', (tester) async {
      final logs = [
        WeightLog(id: 'w1', weight: 80.0, date: DateTime(2026, 8, 1)),
        WeightLog(id: 'w2', weight: 79.2, date: DateTime(2026, 8, 10)),
        WeightLog(id: 'w3', weight: 78.4, date: DateTime(2026, 8, 20)),
        WeightLog(id: 'w4', weight: 77.5, date: DateTime(2026, 9, 1)),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              height: 200,
              child: CustomPaint(
                painter: WeightLineChartPainter(logs: logs),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is WeightLineChartPainter),
        findsOneWidget,
      );
    });

    testWidgets('handles identical min and max weight without division by zero', (tester) async {
      final flatLogs = [
        WeightLog(id: 'f1', weight: 70.0, date: DateTime(2026, 9, 1)),
        WeightLog(id: 'f2', weight: 70.0, date: DateTime(2026, 9, 2)),
        WeightLog(id: 'f3', weight: 70.0, date: DateTime(2026, 9, 3)),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 180,
              child: CustomPaint(
                painter: WeightLineChartPainter(logs: flatLogs),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is WeightLineChartPainter),
        findsOneWidget,
      );
    });

    testWidgets('handles zero or tiny canvas size gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 0,
              height: 0,
              child: CustomPaint(
                painter: WeightLineChartPainter(
                  logs: [WeightLog(id: 'w1', weight: 75.0, date: DateTime.now())],
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is WeightLineChartPainter),
        findsOneWidget,
      );
    });

    test('shouldRepaint detects changes accurately', () {
      final log1 = WeightLog(id: '1', weight: 75.0, date: DateTime(2026, 1, 1));
      final log2 = WeightLog(id: '2', weight: 76.0, date: DateTime(2026, 1, 2));

      final painter1 = WeightLineChartPainter(logs: [log1]);
      final painter2 = WeightLineChartPainter(logs: [log1]);
      final painter3 = WeightLineChartPainter(logs: [log1, log2]);
      final painter4 = WeightLineChartPainter(
        logs: [log1],
        lineColor: Colors.blue,
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
      expect(painter1.shouldRepaint(painter3), isTrue);
      expect(painter1.shouldRepaint(painter4), isTrue);
    });
  });
}
