import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'bs_press.dart';

class BSListRow extends StatelessWidget {
  final bool first;
  final Widget? leading;
  final String title;
  final Widget? badge;
  final String? meta;
  final String? tag;
  final String? value;
  final Widget? valueWidget;
  final String? valueMeta;
  final Widget? valueMetaWidget;
  final Widget? trailing;
  final bool chevron;
  final VoidCallback? onTap;
  final Color? metaColor;

  const BSListRow({
    super.key,
    this.first = false,
    this.leading,
    required this.title,
    this.badge,
    this.meta,
    this.tag,
    this.value,
    this.valueWidget,
    this.valueMeta,
    this.valueMetaWidget,
    this.trailing,
    this.chevron = false,
    this.onTap,
    this.metaColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    final row = Container(
      constraints: const BoxConstraints(minHeight: BSSpace.hit),
      padding: const EdgeInsets.symmetric(vertical: BSSpace.s3),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: c.line, width: 1)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: BSSpace.s3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: BSType.font,
                          fontSize: BSType.body,
                          fontWeight: BSType.wBold,
                          height: 1.25,
                          letterSpacing: -.015 * BSType.body,
                          color: c.ink,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: BSSpace.s2),
                      badge!,
                    ],
                  ],
                ),
                if (meta != null || tag != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      children: [
                        if (meta != null)
                          Flexible(
                            child: Text(
                              meta!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: BSType.font,
                                fontSize: BSType.meta,
                                fontWeight: BSType.wRegular,
                                height: 1.3,
                                color: metaColor ?? c.ink2,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        if (tag != null) ...[
                          const SizedBox(width: BSSpace.s2),
                          Text(
                            tag!.toUpperCase(),
                            style: TextStyle(
                              fontFamily: BSType.font,
                              fontSize: 10,
                              fontWeight: BSType.wBold,
                              height: 1,
                              letterSpacing: .06 * 10,
                              color: c.ink3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (value != null ||
              valueWidget != null ||
              valueMeta != null ||
              valueMetaWidget != null) ...[
            const SizedBox(width: BSSpace.s3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (valueWidget != null)
                  valueWidget!
                else if (value != null)
                  Text(
                    value!,
                    style: TextStyle(
                      fontFamily: BSType.font,
                      fontSize: BSType.body,
                      fontWeight: BSType.wBold,
                      height: 1.2,
                      color: c.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                if (valueMetaWidget != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: valueMetaWidget!,
                  )
                else if (valueMeta != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      valueMeta!,
                      style: TextStyle(
                        fontFamily: BSType.font,
                        fontSize: BSType.micro,
                        fontWeight: BSType.wRegular,
                        height: 1.2,
                        color: c.ink3,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: BSSpace.s3),
            trailing!,
          ],
          if (chevron) ...[
            const SizedBox(width: BSSpace.s3),
            CustomPaint(
              size: const Size.square(18),
              painter: _ChevronPainter(color: c.ink3),
            ),
          ],
        ],
      ),
    );
    return BSPress(onTap: onTap, scale: .99, child: row);
  }
}

class _ChevronPainter extends CustomPainter {
  final Color color;
  _ChevronPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final path = Path()
      ..moveTo(9.5 * s, 6.5 * s)
      ..lineTo(15 * s, 12 * s)
      ..lineTo(9.5 * s, 17.5 * s);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}
