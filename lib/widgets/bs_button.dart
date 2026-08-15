import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'bs_icon.dart';
import 'bs_press.dart';

enum BSButtonVariant { solid, tint, quiet, danger }

enum BSButtonSize { md, lg }

class BSButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final BSButtonVariant variant;
  final BSButtonSize size;
  final bool block;
  final String? icon;
  final double iconSize;
  final String hue;
  final Color? labelColor;

  const BSButton(
    this.label, {
    super.key,
    this.onTap,
    this.variant = BSButtonVariant.solid,
    this.size = BSButtonSize.md,
    this.block = false,
    this.icon,
    this.iconSize = 19,
    this.hue = 'cal',
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    final enabled = onTap != null;
    final hueColor = c.hue(hue);

    final (Color bg, Color fg, List<BoxShadow> shadow) = switch (variant) {
      BSButtonVariant.solid => (
          hueColor,
          c.onAccent,
          enabled
              ? [
                  BoxShadow(
                    color: hueColor,
                    offset: const Offset(0, 10),
                    blurRadius: 22,
                    spreadRadius: -12,
                  ),
                ]
              : const <BoxShadow>[],
        ),
      BSButtonVariant.tint => (c.hueSoft(hue), c.hueInk(hue), const []),
      BSButtonVariant.quiet => (Colors.transparent, c.hueInk(hue), const []),
      BSButtonVariant.danger => (c.dangerSoft, c.danger, const []),
    };

    final child = Opacity(
      opacity: enabled ? 1 : .4,
      child: Container(
        constraints: BoxConstraints(
          minHeight: size == BSButtonSize.lg ? 52 : 44,
        ),
        width: block ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: size == BSButtonSize.lg ? BSSpace.s6 : BSSpace.s5,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(BSRadius.pill),
          boxShadow: shadow,
        ),
        child: Row(
          mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              BSIcon(icon!, size: iconSize, color: labelColor ?? fg),
              const SizedBox(width: BSSpace.s2),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: BSType.font,
                fontSize: BSType.body,
                fontWeight: BSType.wBold,
                height: 1,
                letterSpacing: .005 * BSType.body,
                color: labelColor ?? fg,
              ),
            ),
          ],
        ),
      ),
    );

    return BSPress(onTap: onTap, child: child);
  }
}
