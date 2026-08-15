import 'package:flutter/widgets.dart';
import '../theme/tokens.dart';

class BSPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const BSPress({super.key, required this.child, this.onTap, this.scale = .96});

  @override
  State<BSPress> createState() => _BSPressState();
}

class _BSPressState extends State<BSPress> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: BSMotion.fast,
        curve: BSMotion.out,
        child: widget.child,
      ),
    );
  }
}
