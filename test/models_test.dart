import 'package:flutter_test/flutter_test.dart';
import 'package:body_sync/data/models.dart';
import 'package:body_sync/util/format.dart';

void main() {
  group('LogEntry', () {
    LogEntry at(int hour, [int minute = 0]) => LogEntry(
          id: 'x',
          time: DateTime(2026, 8, 13, hour, minute),
          name: 'Test',
          portion: '1',
          kcal: 100,
          p: 1,
          c: 1,
          f: 1,
        );

    test('meal inference follows time of day', () {
      expect(at(8).meal, 'Breakfast');
      expect(at(12, 30).meal, 'Lunch');
      expect(at(19).meal, 'Dinner');
      expect(at(15, 20).meal, 'Snack');
      expect(at(23).meal, 'Snack');
    });

    test('round-trips through JSON', () {
      final e = LogEntry(
        id: 'a1',
        time: DateTime(2026, 8, 13, 9, 40),
        name: 'Eggs, large',
        foodId: 'egg',
        portionLabel: 'Large',
        portion: '2 eggs',
        qty: 2,
        kcal: 156,
        p: 13,
        c: 1,
        f: 11,
        own: true,
      );
      final back = LogEntry.fromJson(e.toJson());
      expect(back.name, e.name);
      expect(back.kcal, e.kcal);
      expect(back.own, isTrue);
      expect(back.timeLabel, '09:40');
    });
  });

  group('DayTotals', () {
    test('sums entries', () {
      final totals = DayTotals.of([
        LogEntry(
            id: '1',
            time: DateTime(2026),
            name: 'a',
            portion: '',
            kcal: 620,
            p: 46,
            c: 72,
            f: 14),
        LogEntry(
            id: '2',
            time: DateTime(2026),
            name: 'b',
            portion: '',
            kcal: 145,
            p: 17,
            c: 9,
            f: 4),
      ]);
      expect(totals.kcal, 765);
      expect(totals.p, 63);
      expect(totals.c, 81);
      expect(totals.f, 18);
    });
  });

  group('format', () {
    test('kcal gets thousands commas', () {
      expect(fmtKcal(1420), '1,420');
      expect(fmtKcal(89), '89');
      expect(fmtKcal(1234567), '1,234,567');
    });

    test('deltas use a true minus', () {
      expect(fmtDelta1(-1.2), '−1.2');
      expect(fmtDelta1(0.3), '+0.3');
      expect(fmtDelta1(0), '0.0');
    });

    test('date formats match the design language', () {
      final d = DateTime(2026, 8, 13);
      expect(fmtDayLong(d), 'Thursday 13 August');
      expect(fmtDayShort(d), '13 Aug');
      expect(fmtMonthYear(d), 'August 2026');
    });
  });

  group('dateKey', () {
    test('pads and matches only the calendar day', () {
      expect(dateKey(DateTime(2026, 8, 3, 23, 59)), '2026-08-03');
      expect(dateKey(DateTime(2026, 8, 3)), dateKey(DateTime(2026, 8, 3, 12)));
    });
  });
}
