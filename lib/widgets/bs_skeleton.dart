import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class BSSkeleton extends StatefulWidget {
  final double? w;
  final double? wFactor;
  final double h;
  final double radius;
  final bool circle;

  const BSSkeleton({
    super.key,
    this.w,
    this.wFactor,
    this.h = 14,
    this.radius = BSRadius.xs,
    this.circle = false,
  });

  @override
  State<BSSkeleton> createState() => _BSSkeletonState();
}

class _BSSkeletonState extends State<BSSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    Widget box = AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: 1 - .55 * Curves.easeInOut.transform(_ctrl.value),
        child: Container(
          width: widget.w,
          height: widget.h,
          decoration: BoxDecoration(
            color: c.track,
            shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius:
                widget.circle ? null : BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
    if (widget.wFactor != null) {
      box = FractionallySizedBox(widthFactor: widget.wFactor, child: box);
    }
    return box;
  }
}

class BSSkeletonRow extends StatelessWidget {
  const BSSkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line, width: 1)),
      ),
      child: Row(
        children: [
          const BSSkeleton(w: 30, h: 10, radius: 5),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                BSSkeleton(wFactor: .58, h: 13, radius: 5),
                SizedBox(height: 6),
                BSSkeleton(wFactor: .34, h: 10, radius: 5),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              BSSkeleton(w: 38, h: 13, radius: 5),
              SizedBox(height: 6),
              BSSkeleton(w: 62, h: 10, radius: 5),
            ],
          ),
        ],
      ),
    );
  }
}
