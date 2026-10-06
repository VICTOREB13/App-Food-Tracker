import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/widgets/common/ve_bounceable.dart';

void main() {
  group('VeBounceable Widget Tests', () {
    testWidgets('renders child and triggers onTap callback on press', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VeBounceable(
              onTap: () => tapped = true,
              child: const Text('Bounce Me'),
            ),
          ),
        ),
      );

      expect(find.text('Bounce Me'), findsOneWidget);

      await tester.tap(find.text('Bounce Me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('scales down during tap down and returns on cancel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VeBounceable(
              onTap: () {},
              scaleFactor: 0.90,
              duration: const Duration(milliseconds: 100),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final transformFinder = find.byType(Transform);
      expect(transformFinder, findsOneWidget);
      final transform = tester.widget<Transform>(transformFinder);
      expect(transform.transform.getMaxScaleOnAxis(), closeTo(0.90, 0.05));

      await gesture.cancel();
      await tester.pumpAndSettle();

      final restoredTransform = tester.widget<Transform>(transformFinder);
      expect(restoredTransform.transform.getMaxScaleOnAxis(), closeTo(1.0, 0.01));
    });
  });
}
