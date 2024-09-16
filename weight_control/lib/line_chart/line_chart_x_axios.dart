import 'package:flutter/material.dart';
import 'calculate_interval.dart';
import 'dart:developer';

class LineChartXAxios extends StatelessWidget {
  final double zoomLevel;
  final int daysInMonth;
  final CalculateInterval calculateInterval;

    LineChartXAxios({required this.zoomLevel, required this.calculateInterval})
      : daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;

  @override
  Widget build(BuildContext context) {
    final intervalData = calculateInterval.getInterval();
    final int interval = intervalData['interval']!;
    final int totalDays = intervalData['totalDays']!;

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 5, // Define a height for the X-axis painter
      child: CustomPaint(
        painter: XAxisPainter(totalDays: totalDays, interval: interval, zoomLevel: zoomLevel),
      ),
    );
  }
}


class XAxisPainter extends CustomPainter {
  final int totalDays;
  final int interval;
  final double zoomLevel;

  XAxisPainter({required this.totalDays, required this.interval, required this.zoomLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 255, 255, 255)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);



    final double spacing = size.width / totalDays;
    final DateTime today = DateTime.now();

    for (int i = 0; i <= totalDays; i += interval) {
      final double x = i * spacing;
      canvas.drawLine(Offset(x, size.height / 2 - 5), Offset(x, size.height / 2 + 5), paint);

      // Calculate the date
      final DateTime date = today.subtract(Duration(days: totalDays - i));
      final String formattedDate = zoomLevel <= 0.3? 
        '${date.year - 2000}${_monthAbbreviation(date.month)}${date.day}' : '${_monthAbbreviation(date.month)}${date.day}';


      // Draw the day/month number
      final textPainter = TextPainter(
        text: TextSpan(
          text: formattedDate,
          style: TextStyle(
            color: Color.fromARGB(137, 255, 255, 255),
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