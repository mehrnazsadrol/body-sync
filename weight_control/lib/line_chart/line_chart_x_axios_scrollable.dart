import 'package:flutter/material.dart';
import 'calculate_interval.dart';
import 'dart:developer';

class LineChartXAxiosScrollable extends StatelessWidget {
  final List<MapEntry<DateTime, int>> data;
  final CalculateInterval calculateInterval;

    LineChartXAxiosScrollable({
      required this.calculateInterval,
      required this.data});

  @override
  Widget build(BuildContext context) {
    final size = Size(
      MediaQuery.of(context).size.width * 0.85,
      MediaQuery.of(context).size.height * 0.5,
    );
    final intervalData = calculateInterval.getInterval();
    final int interval = intervalData['interval']!;
    final double widthPerDay = calculateInterval.getWidthPerDay(size);
    final DateTime earliestDate = data[0].key;
    final double totalWidth = widthPerDay * (DateTime.now().difference(earliestDate).inDays + 2);

    return Container(
      width: totalWidth,
      height: 40,
      child: CustomPaint(
        painter: XAxisPainter(interval: interval, widthPerDay: widthPerDay, earliestDate: earliestDate),
      ),
    );
  }
}


class XAxisPainter extends CustomPainter {
  final int interval;
  final double widthPerDay;
  final DateTime earliestDate;
  final int totalDays;

  XAxisPainter({ required this.interval, required this.widthPerDay, required this.earliestDate}) : totalDays = DateTime.now().difference(earliestDate).inDays;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFd5626a)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);

    for (int i = totalDays%interval; i <= totalDays; i += interval) {
      final double x = i * widthPerDay;
      canvas.drawLine(Offset(x, size.height / 2), Offset(x, size.height / 2 + 5), paint);

      final DateTime currDate = earliestDate.add(Duration(days: i));
      final String formattedDate = currDate.year < DateTime.now().year ? 
        '${currDate.year - 2000}${_monthAbbreviation(currDate.month)}${currDate.day}' : '${_monthAbbreviation(currDate.month)}${currDate.day}';


      final textPainter = TextPainter(
        text: TextSpan(
          text: formattedDate,
          style: TextStyle(
            color: Color(0xFFd5626a),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height / 2 + 10));
    }
  }

  String _monthAbbreviation(int month) {
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}