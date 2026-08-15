import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/bs_common.dart';
import '../../widgets/bs_list_row.dart';
import '../../util/format.dart';

class LogRow extends StatelessWidget {
  final LogEntry entry;
  final bool first;
  final VoidCallback? onTap;

  const LogRow(
      {super.key, required this.entry, this.first = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return BSListRow(
      first: first,
      onTap: onTap,
      leading: SizedBox(
        width: 38,
        child: Text(
          entry.timeLabel,
          style: TextStyle(
            fontFamily: BSType.font,
            fontSize: BSType.micro,
            fontWeight: BSType.wRegular,
            height: 1,
            color: c.ink3,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      title: entry.name,
      badge: entry.own ? const BSBadge('your values') : null,
      meta: entry.portion,
      tag: entry.meal,
      value: fmtKcal(entry.kcal),
      valueMetaWidget: entry.quickAdd
          ? Text(
              'kcal only',
              style: TextStyle(
                fontFamily: BSType.font,
                fontSize: BSType.micro,
                height: 1.2,
                color: c.ink3,
              ),
            )
          : BSMac(p: entry.p, carbs: entry.c, f: entry.f),
    );
  }
}
