import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class BSRingItem {
  final String label;
  final double value;
  final double goal;
  final String display;
  final String hue;

  const BSRingItem({
    required this.label,
    required this.value,
    required this.goal,
    required this.display,
    required this.hue,
  });
}

class BSMacroRings extends StatefulWidget {
  final List<BSRingItem> items;
  final double size;
  final double thickness;
  final double gap;
  final EdgeInsets margin;

  const BSMacroRings({
    super.key,
    required this.items,
    this.size = 40,
    this.thickness = 3,
    this.gap = 6,
    this.margin = const EdgeInsets.only(top: 22),
  });

  @override
  State<BSMacroRings> createState() => _BSMacroRingsState();
}

class _BSMacroRingsState extends State<BSMacroRings>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: BSMotion.slow,
  );
  late final Animation<double> _anim =
      CurvedAnimation(parent: _ctrl, curve: BSMotion.out);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Padding(
      padding: widget.margin,
      child: Row(
        children: [
          for (var i = 0; i < widget.items.length; i++) ...[
            if (i > 0) SizedBox(width: widget.gap),
            Expanded(child: _ring(c, widget.items[i])),
          ],
        ],
      ),
    );
  }

  Widget _ring(BSColors c, BSRingItem item) {
    final over = item.goal > 0 && item.value > item.goal;
    final pct = item.goal > 0
        ? math.min(100.0, (item.value / item.goal * 100).roundToDouble())
        : 0.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => CustomPaint(
            size: Size.square(widget.size),
            painter: _RingPainter(
              pct: pct * _anim.value,
              thickness: widget.thickness * widget.size / 40,
              track: c.track,
              color: over ? c.danger : c.hue(item.hue),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          item.display,
          style: TextStyle(
            fontFamily: BSType.font,
            fontSize: BSType.bodySm,
            fontWeight: BSType.wBold,
            height: 1,
            letterSpacing: -.01 * BSType.bodySm,
            color: c.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 7),
        Text(
          item.label.toUpperCase(),
          style: TextStyle(
            fontFamily: BSType.font,
            fontSize: 10.5,
            fontWeight: BSType.wMedium,
            height: 1,
            letterSpacing: .06 * 10.5,
            color: c.ink3,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double pct;
  final double thickness;
  final Color track;
  final Color color;

  _RingPainter({
    required this.pct,
    required this.thickness,
    required this.track,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 16 / 40;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);
    if (pct <= 0) return;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * pct / 100,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.pct != pct || old.color != color || old.track != track;
}

List<BSRingItem> ringItems({
  required double kcal,
  required double p,
  required double carbs,
  required double f,
  required double goalKcal,
  required double goalP,
  required double goalC,
  required double goalF,
  bool overAsFat = false,
}) {
  String g(num v) => v.round().toString();
  return [
    BSRingItem(
      label: 'Cals',
      value: kcal,
      goal: goalKcal,
      display: g(kcal),
      hue: overAsFat && kcal > goalKcal ? 'fat' : 'cal',
    ),
    BSRingItem(
        label: 'Protein',
        value: p,
        goal: goalP,
        display: '${g(p)}g',
        hue: 'pro'),
    BSRingItem(
        label: 'Carbs',
        value: carbs,
        goal: goalC,
        display: '${g(carbs)}g',
        hue: 'carb'),
    BSRingItem(
        label: 'Fat', value: f, goal: goalF, display: '${g(f)}g', hue: 'fat'),
  ];
}
