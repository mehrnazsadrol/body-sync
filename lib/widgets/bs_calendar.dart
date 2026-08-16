import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'bs_common.dart';

class BSCalendar extends StatelessWidget {
  final DateTime month;
  final Set<int> markedDays;
  final ValueChanged<int> onDayTap;
  final ValueChanged<int>? onFutureTap;
  final String startOfWeek;

  const BSCalendar({
    super.key,
    required this.month,
    required this.markedDays,
    required this.onDayTap,
    this.onFutureTap,
    this.startOfWeek = 'sun',
  });

  static const _sunFirst = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _monFirst = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    final now = DateTime.now();
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final mondayFirst = startOfWeek == 'mon';
    final startCol = mondayFirst ? first.weekday - 1 : first.weekday % 7;
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final isPastMonth = DateTime(month.year, month.month)
        .isBefore(DateTime(now.year, now.month));
    final today = isCurrentMonth ? now.day : -1;

    final cells = <Widget>[
      for (final wd in mondayFirst ? _monFirst : _sunFirst)
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: BSSpace.s2),
            child: Text(
              wd.toUpperCase(),
              style: TextStyle(
                fontFamily: BSType.font,
                fontSize: 10.5,
                fontWeight: BSType.wMedium,
                height: 1,
                letterSpacing: .08 * 10.5,
                color: c.ink3,
              ),
            ),
          ),
        ),
      for (var i = 0; i < startCol; i++) const SizedBox(),
      for (var d = 1; d <= daysInMonth; d++)
        _DayCell(
          day: d,
          on: markedDays.contains(d),
          today: d == today,
          mute: !isPastMonth && (isCurrentMonth ? d > today : true),
          onTap: () {
            final future = !isPastMonth && (isCurrentMonth ? d > today : true);
            if (future) {
              onFutureTap?.call(d);
            } else {
              onDayTap(d);
            }
          },
        ),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      childAspectRatio: 1.05,
      children: cells,
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool on;
  final bool today;
  final bool mute;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.on,
    required this.today,
    required this.mute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: BSMotion.base,
          width: BSSpace.hit,
          height: BSSpace.hit,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? c.proSoft : Colors.transparent,
            shape: BoxShape.circle,
            border: today ? Border.all(color: c.ink3, width: 1) : null,
          ),
          child: Opacity(
            opacity: mute ? .45 : 1,
            child: Text(
              '$day',
              style: TextStyle(
                fontFamily: BSType.font,
                fontSize: 14.5,
                fontWeight: on ? BSType.wBold : BSType.wMedium,
                height: 1,
                color: mute
                    ? c.ink3
                    : on
                        ? c.proInk
                        : c.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BSMonthHead extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const BSMonthHead({
    super.key,
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  static const _months = [
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

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: BSSpace.s4),
      child: Row(
        children: [
          Text(
            '${_months[month.month - 1]} ${month.year}',
            style: TextStyle(
              fontFamily: BSType.font,
              fontSize: 17,
              fontWeight: BSType.wBold,
              height: 1,
              letterSpacing: -.01 * 17,
              color: c.ink,
            ),
          ),
          const Spacer(),
          BSIconButton(icon: 'chevronLeft', iconSize: 18, onTap: onPrev),
          BSIconButton(icon: 'chevronRight', iconSize: 18, onTap: onNext),
        ],
      ),
    );
  }
}
