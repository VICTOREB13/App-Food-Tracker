import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/widgets/common/ve_logo.dart';
import 'package:food_tracker/widgets/dashboard/streak_badge.dart';

void main() {
  group('VeLogo and StreakBadge Widget Tests', () {
    testWidgets('VeLogo renders fallback or SVG without exceptions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VeLogo(size: 32),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(VeLogo), findsOneWidget);
    });

    testWidgets('StreakBadge displays flame emoji and streak days count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakBadge(streakDays: 5),
          ),
        ),
      );

      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('5 días'), findsOneWidget);
    });
  });
}
