import 'package:flutter/material.dart';
import 'package:weight_control/layout/theme.dart';

class TooltipPainter extends CustomPainter {
  double height;
  final Offset touchPosition;
  final int value;
  final formattedText;

  TooltipPainter({
    required this.height,
    required this.touchPosition,
    required this.value}) : formattedText = value<0 ? 'No data' : value.toStringAsFixed(0);



  @override
  void paint(Canvas canvas, Size size) {

    Paint linePaint = Paint()
      ..color = AppTheme.cranberryPink
      ..strokeWidth = 2.0;

    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: formattedText,
        style: TextStyle(color:Colors.white, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.layout(
            minWidth: 0,
            maxWidth: 80,
    );
    final offset = Offset(touchPosition.dx - textPainter.width -5  , touchPosition.dy - 30);


    final rect = Rect.fromLTWH(
      offset.dx - 5,
      offset.dy - 5,
      textPainter.width + 10,
      textPainter.height + 10,
    );
    Paint rectPaint = Paint()
      ..color = AppTheme.cranberryPink
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, rectPaint);
    textPainter.paint(canvas, offset);

    canvas.drawLine(
      Offset(touchPosition.dx, height+12),
      Offset(touchPosition.dx, touchPosition.dy),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

