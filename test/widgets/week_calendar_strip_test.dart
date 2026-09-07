import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/widgets/dashboard/week_calendar_strip.dart';

void main() {
  group('WeekCalendarStrip Widget Tests', () {
    testWidgets('renders 7 days of the week and handles day selection', (tester) async {
      DateTime? selected;
      final testDate = DateTime(2026, 9, 6); // Sunday

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeekCalendarStrip(
              selectedDate: testDate,
              onDateSelected: (d) => selected = d,
            ),
          ),
        ),
      );

      // Verify weekdays abbreviations exist
      expect(find.text('L'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('X'), findsOneWidget);
      expect(find.text('J'), findsOneWidget);
      expect(find.text('V'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);

      // Verify selected day 6 is visible
      expect(find.text('6'), findsOneWidget);

      // Tap on day 'D' (Sunday, day 6)
      await tester.tap(find.text('6'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.day, equals(6));
    });
  });
}
