import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/widgets/common/ve_loading_ring.dart';

void main() {
  group('VeLoadingRing Widget Tests', () {
    testWidgets('VeLoadingRing renders in indeterminate mode without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: VeLoadingRing(
                size: 60,
                strokeWidth: 4,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(VeLoadingRing), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Advance animation
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(VeLoadingRing), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(VeLoadingRing), findsOneWidget);
    });

    testWidgets('VeLoadingRing renders in determinate mode with custom progress and child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: VeLoadingRing(
                size: 80,
                strokeWidth: 5,
                progress: 0.75,
                child: Text('75%'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(VeLoadingRing), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('VeLoadingRing respects custom colors and size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: VeLoadingRing(
                size: 40,
                strokeWidth: 3,
                color: Colors.red,
                trackColor: Colors.blue,
              ),
            ),
          ),
        ),
      );

      final ringFinder = find.byType(VeLoadingRing);
      expect(ringFinder, findsOneWidget);

      final SizedBox sizedBox = tester.widget(
        find.descendant(of: ringFinder, matching: find.byType(SizedBox)).first,
      );
      expect(sizedBox.width, equals(40.0));
      expect(sizedBox.height, equals(40.0));
    });

    testWidgets('VeLoadingRing smoothly updates when progress changes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: VeLoadingRing(
                size: 50,
                progress: 0.2,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(VeLoadingRing), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: VeLoadingRing(
                size: 50,
                progress: 0.8,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(VeLoadingRing), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(VeLoadingRing), findsOneWidget);
    });
  });
}
