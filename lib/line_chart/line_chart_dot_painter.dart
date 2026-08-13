import 'package:flutter/material.dart';
import 'package:body_sync/layout/theme.dart';

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
      ..color = AppTheme.cranberryPink
      ..style = PaintingStyle.fill;

    final textStyle = TextStyle(
      color: AppTheme.cranberryPink,
      fontSize: 11,
    );
    // Draw red dots for points
    for (int idx = 0; idx < points.length; idx++) {
      final point = points[idx];
      if (!quadraticBezierPoints.contains(point)) {
        canvas.drawCircle(point, 3.0, redPaint);
      }
      if (idx > 0) {
        final entry = data[idx - 1];
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${entry.value}',
            style: textStyle,
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(
          minWidth: 0,
          maxWidth: 80,
        );
        final offset = Offset(point.dx - textPainter.width / 2, point.dy - 15);
        textPainter.paint(canvas, offset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
