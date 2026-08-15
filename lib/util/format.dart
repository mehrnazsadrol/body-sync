library;

const _months = [
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
const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String fmtKcal(num v) {
  final s = v.round().abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${v < 0 ? '−' : ''}$buf';
}

String fmt1(num v) => v.toStringAsFixed(1);

String fmtDelta1(num v) {
  if (v > 0) return '+${v.toStringAsFixed(1)}';
  if (v < 0) return '−${v.abs().toStringAsFixed(1)}';
  return '0.0';
}

String fmtDayShort(DateTime d) =>
    '${d.day} ${_months[d.month - 1].substring(0, 3)}';

String fmtDay(DateTime d) {
  final now = DateTime.now();
  final base = fmtDayShort(d);
  return d.year == now.year ? base : '$base ${d.year}';
}

String fmtDayLong(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

String fmtDayMonth(DateTime d) => '${d.day} ${_months[d.month - 1]}';

String fmtDayFull(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String fmtMonthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';

String fmtG(num v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
