import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/widgets/dashboard/calories_hero_ring.dart';
import 'package:food_tracker/widgets/dashboard/macro_bento_card.dart';

void main() {
  group('CaloriesHeroRing and MacroBentoCard Widget Tests', () {
    testWidgets('CaloriesHeroRing displays percentage and flame icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CaloriesHeroRing(
              current: 1500,
              goal: 2000,
            ),
          ),
        ),
      );

      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('MacroBentoCard displays label, emoji, metrics and progress', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MacroBentoCard(
              label: 'Proteína',
              iconEmoji: '🍗',
              current: 120,
              goal: 150,
              color: Colors.red,
            ),
          ),
        ),
      );

      expect(find.text('Proteína'), findsOneWidget);
      expect(find.text('🍗'), findsOneWidget);
      expect(find.text('120/150g'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
