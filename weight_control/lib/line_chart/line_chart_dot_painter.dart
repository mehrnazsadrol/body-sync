import 'package:flutter/material.dart';

class LineChartDotPainter extends CustomPainter {
  final List<Offset> points;
  final List<Offset> quadraticBezierPoints;
  final List<MapEntry<DateTime, int>> data;

  LineChartDotPainter({
    required this.points,
    required this.quadraticBezierPoints,
    required this.data,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final redPaint = Paint()
      ..color = Color(0xFFd5626a)
      ..style = PaintingStyle.fill;

    final textStyle = TextStyle(
      color: Color(0xFFd5626a),
      fontSize: 12,
    );
    // Draw red dots for points
    for (var point in points) {
      if (!quadraticBezierPoints.contains(point)) {
        canvas.drawCircle(point, 3.0, redPaint);
      }
      int idx = points.indexOf(point);
      if(idx> 0) {
        MapEntry<DateTime, int> entry = data[idx-1];
        int date = entry.key.day;
        int value = entry.value;
        final textSpan = TextSpan(
            text: '${value}',
            style: textStyle,
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          );
          textPainter.layout(
            minWidth: 0,
            maxWidth: 80,
          );
          final offset = Offset(point.dx - textPainter.width, point.dy - 20);
          textPainter.paint(canvas, offset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}