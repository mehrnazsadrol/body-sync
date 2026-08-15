import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum BSTrendMode { area, line, columns }

class BSTrend extends StatelessWidget {
  final List<double> values;
  final BSTrendMode mode;
  final String hue;
  final double height;
  final List<String>? labels;
  final EdgeInsets margin;
  final int? dimLastCount;
  final int? selectedIndex;
  final ValueChanged<int>? onBarTap;

  const BSTrend({
    super.key,
    required this.values,
    this.mode = BSTrendMode.columns,
    this.hue = 'cal',
    this.height = 62,
    this.labels,
    this.margin = EdgeInsets.zero,
    this.dimLastCount,
    this.selectedIndex,
    this.onBarTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: height,
            child: LayoutBuilder(
              builder: (context, box) {
                final paint = CustomPaint(
                  painter: _TrendPainter(
                    values: values,
                    mode: mode,
                    color: c.hue(hue),
                    dimLastCount: dimLastCount ?? 0,
                    selectedIndex: selectedIndex,
                  ),
                );
                if (onBarTap == null || values.isEmpty) return paint;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => onBarTap!(
                    (d.localPosition.dx / box.maxWidth * values.length)
                        .floor()
                        .clamp(0, values.length - 1),
                  ),
                  child: paint,
                );
              },
            ),
          ),
          if (labels != null && labels!.length >= 2)
            Padding(
              padding: const EdgeInsets.only(top: BSSpace.s2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final l in labels!)
                    Text(
                      l,
                      style: TextStyle(
                        fontFamily: BSType.font,
                        fontSize: 10.5,
                        fontWeight: BSType.wMedium,
                        height: 1,
                        letterSpacing: .05 * 10.5,
                        color: c.ink3,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> values;
  final BSTrendMode mode;
  final Color color;
  final int dimLastCount;
  final int? selectedIndex;

  _TrendPainter({
    required this.values,
    required this.mode,
    required this.color,
    required this.dimLastCount,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final n = values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = (max - min) == 0 ? 1.0 : (max - min);
    final w = size.width;
    final h = size.height;

    if (mode == BSTrendMode.columns) {
      final bw = w / n;
      for (var i = 0; i < n; i++) {
        final x = i * bw + 1.5;
        final barW = (bw - 3).clamp(2.0, double.infinity);
        final top = (1 - (values[i] - min) / range) * (h - 12);
        var opacity = n > 1 ? 0.38 + 0.62 * i / (n - 1) : 1.0;
        if (dimLastCount > 0 && i >= n - dimLastCount) opacity *= .45;
        if (selectedIndex != null) {
          opacity = i == selectedIndex ? 1.0 : opacity * .45;
        }
        final paint = Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(x, top, x + barW, h),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      return;
    }

    double px(int i) => n > 1 ? i / (n - 1) * w : w / 2;
    double py(int i) => 3 + (1 - (values[i] - min) / range) * (h - 6);

    final line = Path()..moveTo(px(0), py(0));
    for (var i = 1; i < n; i++) {
      line.lineTo(px(i), py(i));
    }

    if (mode == BSTrendMode.area) {
      final fill = Path.from(line)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      final gradient = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: .34),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h));
      canvas.drawPath(fill, gradient);
    }

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = mode == BSTrendMode.area ? 2.5 : 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas.drawPath(line, stroke);
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.values != values ||
      old.mode != mode ||
      old.color != color ||
      old.dimLastCount != dimLastCount ||
      old.selectedIndex != selectedIndex;
}
