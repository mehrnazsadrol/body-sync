import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:body_sync/workout_view/calendar/calendar_title.dart';

void main() {
  group('CalendarTitle', () {
    testWidgets('shows the year and abbreviated month of the current date',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarTitle(
              currDate: DateTime(2026, 8, 13),
              onPreviousMonth: () {},
              onNextMonth: () {},
            ),
          ),
        ),
      );

      expect(find.text('2026'), findsOneWidget);
      expect(find.text('Aug'), findsOneWidget);
    });

    testWidgets('invokes the month-navigation callbacks', (tester) async {
      var previousTaps = 0;
      var nextTaps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarTitle(
              currDate: DateTime(2026, 1, 1),
              onPreviousMonth: () => previousTaps++,
              onNextMonth: () => nextTaps++,
            ),
          ),
        ),
      );

      final arrows = find.byType(IconButton);
      expect(arrows, findsNWidgets(2));

      await tester.tap(arrows.first);
      await tester.tap(arrows.last);

      expect(previousTaps, 1);
      expect(nextTaps, 1);
    });
  });
}
