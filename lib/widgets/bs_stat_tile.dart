import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'bs_press.dart';

class BSStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final String? note;
  final String hue;
  final VoidCallback? onTap;

  const BSStatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.note,
    this.hue = 'cal',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return BSPress(
      onTap: onTap,
      scale: .985,
      child: Container(
        padding: const EdgeInsets.all(BSSpace.s4),
        decoration: BoxDecoration(
          color: c.hueSoft(hue),
          borderRadius: BorderRadius.circular(BSRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: BSType.font,
                fontSize: BSType.micro,
                fontWeight: BSType.wBold,
                height: 1,
                letterSpacing: BSType.trOverline * BSType.micro,
                color: c.hueInk(hue),
              ),
            ),
            const SizedBox(height: BSSpace.s2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: BSType.font,
                    fontSize: 26,
                    fontWeight: BSType.wBold,
                    height: 1,
                    letterSpacing: -.025 * 26,
                    color: c.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit!,
                    style: TextStyle(
                      fontFamily: BSType.font,
                      fontSize: BSType.meta,
                      fontWeight: BSType.wMedium,
                      height: 1,
                      color: c.ink2,
                    ),
                  ),
                ],
              ],
            ),
            if (note != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  note!,
                  style: TextStyle(
                    fontFamily: BSType.font,
                    fontSize: BSType.micro,
                    height: 1.3,
                    color: c.ink2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BSTiles extends StatelessWidget {
  final List<Widget> tiles;
  const BSTiles({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: tiles[i]),
            const SizedBox(width: 6),
            Expanded(
              child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox(),
            ),
          ],
        ),
      ));
      if (i + 2 < tiles.length) rows.add(const SizedBox(height: 6));
    }
    return Column(children: rows);
  }
}
