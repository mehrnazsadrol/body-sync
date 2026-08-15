import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../widgets/bs_calendar.dart';
import '../../widgets/bs_common.dart';
import '../../widgets/bs_empty.dart';
import '../../widgets/bs_list_row.dart';
import '../../widgets/bs_trend.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _page(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final now = DateTime.now();
    final marked = store.markedDays(_month);
    final isCurrentMonth = _month.year == now.year && _month.month == now.month;
    final monthName = _monthNames[_month.month - 1];
    final totals = store.workoutTotals();
    final streak = store.workoutStreak();
    final streakEnd = store.streakEnd();
    final last = store.lastWorkout();
    final gap = _longestGap(marked);

    return Column(
      children: [
        BSTitleBar(
          title: 'Workout',
          sub: fmtDayLong(now),
          icon: 'calendar',
          onIconTap: () =>
              setState(() => _month = DateTime(now.year, now.month)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                BSSpace.screen, 0, BSSpace.screen, BSSpace.s3),
            children: [
              BSMonthHead(
                month: _month,
                onPrev: () => _page(-1),
                onNext: () => _page(1),
              ),
              BSCalendar(
                month: _month,
                markedDays: marked,
                startOfWeek: store.settings.startOfWeek,
                onDayTap: (d) =>
                    store.toggleWorkout(DateTime(_month.year, _month.month, d)),
                onFutureTap: (d) => showBSToast(
                  context,
                  "${fmtDayMonth(DateTime(_month.year, _month.month, d))} hasn't happened yet",
                ),
              ),
              if (marked.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: BSM2(
                      'Tap a day to mark it worked out. Nothing else is asked — no type, no duration, no notes.'),
                ),
                const BSSecHead('THIS MONTH'),
                BSListRow(
                  first: true,
                  title: 'Sessions',
                  meta: isCurrentMonth ? '$monthName, so far' : monthName,
                  value: '${marked.length}',
                  valueMeta: 'days',
                ),
                if (isCurrentMonth)
                  BSListRow(
                    title: 'Current streak',
                    meta: streak > 0 && streakEnd != null
                        ? 'Ended ${fmtDayShort(streakEnd)}'
                        : null,
                    value: '$streak',
                    valueMeta: 'days',
                  ),
                if (gap != null)
                  BSListRow(
                    title: 'Longest gap',
                    meta: gap.meta,
                    value: '${gap.len}',
                    valueMeta: 'days',
                  ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: BSRule(
                    padding: EdgeInsets.only(top: BSSpace.s3),
                    child: BSEmpty(
                      icon: 'workout',
                      hue: 'carb',
                      title: 'No days marked yet',
                      body:
                          'Tap any day above to mark it. Past days can be filled in at any time.',
                    ),
                  ),
                ),
                const BSSecHead('THIS MONTH'),
                BSListRow(
                  first: true,
                  title: 'Sessions',
                  meta: monthName,
                  value: '0',
                  valueMeta: 'days',
                ),
                BSListRow(
                  title: 'Last marked',
                  meta: last == null ? 'No history on this device' : null,
                  value: last == null ? '—' : fmtDay(last),
                ),
              ],
              if (marked.isNotEmpty && totals.total > 0) ...[
                const BSSecHead('SESSIONS A MONTH', right: '12 months'),
                BSTrend(
                  values: store.workoutMonthlySeries(12),
                  mode: BSTrendMode.columns,
                  hue: 'carb',
                  height: 52,
                  margin: const EdgeInsets.only(top: BSSpace.s3),
                  labels: [
                    _monLabel(DateTime(now.year, now.month - 11)),
                    _monLabel(now),
                  ],
                ),
                if (totals.since != null)
                  Padding(
                    padding: const EdgeInsets.only(top: BSSpace.s3),
                    child: BSM2(
                        'Logged ${totals.total} days since ${fmtDayShort(totals.since!)}'),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _monLabel(DateTime d) {
    final yy = (d.year % 100).toString().padLeft(2, '0');
    return '${_monthNames[d.month - 1].substring(0, 3)} $yy';
  }

  ({int len, String meta})? _longestGap(Set<int> marked) {
    if (marked.length < 2) return null;
    final sorted = marked.toList()..sort();
    var best = 0, from = 0, to = 0;
    for (var i = 1; i < sorted.length; i++) {
      final gapLen = sorted[i] - sorted[i - 1] - 1;
      if (gapLen > best) {
        best = gapLen;
        from = sorted[i - 1];
        to = sorted[i];
      }
    }
    if (best <= 0) return null;
    final mon = _monthNames[_month.month - 1].substring(0, 3);
    return (len: best, meta: '$from – $to $mon');
  }
}
