import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/widgets/common/ve_animated_counter.dart';

void main() {
  group('VeAnimatedCounter Widget Tests', () {
    testWidgets('animates numerical values towards target value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VeAnimatedCounter(
              value: 1200,
              duration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('1200'), findsOneWidget);
    });

    testWidgets('applies custom formatter and style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VeAnimatedCounter(
              value: 45.5,
              duration: const Duration(milliseconds: 200),
              formatter: (v) => '${v.toStringAsFixed(1)} kcal',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('45.5 kcal'), findsOneWidget);
    });
  });
}
