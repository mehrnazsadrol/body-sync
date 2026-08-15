import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'bs_icon.dart';
import 'bs_press.dart';

class BSOverline extends StatelessWidget {
  final String text;
  const BSOverline(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: BSType.font,
        fontSize: 10.5,
        fontWeight: BSType.wMedium,
        height: 1,
        letterSpacing: .1 * 10.5,
        color: c.ink3,
      ),
    );
  }
}

class BSSecHead extends StatelessWidget {
  final String title;
  final String? right;
  const BSSecHead(this.title, {super.key, this.right});

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Padding(
      padding: const EdgeInsets.only(top: BSSpace.s5, bottom: 2),
      child: Row(
        children: [
          Expanded(child: BSOverline(title)),
          if (right != null)
            Text(
              right!,
              style: TextStyle(
                fontFamily: BSType.font,
                fontSize: BSType.micro,
                fontWeight: BSType.wRegular,
                height: 1,
                color: c.ink3,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }
}

class BSHero extends StatelessWidget {
  final String value;
  final String? unit;
  final String? right;
  final double size;
  final String? hue;
  final Color? valueColor;
  final Color? unitColor;

  const BSHero({
    super.key,
    required this.value,
    this.unit,
    this.right,
    this.size = 48,
    this.hue,
    this.valueColor,
    this.unitColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: BSType.font,
            fontSize: size,
            fontWeight: BSType.wRegular,
            height: 1,
            letterSpacing: BSType.trHero * size,
            color: valueColor ?? c.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (unit != null) ...[
          const SizedBox(width: 9),
          Padding(
            padding: EdgeInsets.only(bottom: size > 50 ? 10 : 6),
            child: Text(
              unit!,
              style: TextStyle(
                fontFamily: BSType.font,
                fontSize: 14,
                height: 1,
                color: unitColor ?? c.ink3,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (right != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              right!,
              style: TextStyle(
                fontFamily: BSType.font,
                fontSize: BSType.bodySm,
                fontWeight: BSType.wBold,
                height: 1,
                color: hue != null ? c.hueInk(hue!) : c.ink2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
      ],
    );
  }
}

class BSBadge extends StatelessWidget {
  final String text;
  const BSBadge(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      decoration: BoxDecoration(
        color: c.proSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: BSType.font,
          fontSize: 10,
          fontWeight: BSType.wBold,
          height: 1,
          letterSpacing: .05 * 10,
          color: c.proInk,
        ),
      ),
    );
  }
}

class BSMac extends StatelessWidget {
  final num p;
  final num carbs;
  final num f;
  const BSMac(
      {super.key, required this.p, required this.carbs, required this.f});

  static String fmtNum(num v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Text(
      '${fmtNum(p)}P · ${fmtNum(carbs)}C · ${fmtNum(f)}F',
      style: TextStyle(
        fontFamily: BSType.font,
        fontSize: BSType.micro,
        fontWeight: BSType.wRegular,
        height: 1.2,
        color: c.ink3,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class BSM2 extends StatelessWidget {
  final String text;
  final TextAlign? align;
  final double size;
  const BSM2(this.text, {super.key, this.align, this.size = BSType.meta});

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontFamily: BSType.font,
        fontSize: size,
        fontWeight: BSType.wRegular,
        height: 1.5,
        color: c.ink2,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class BSTitleBar extends StatelessWidget {
  final String title;
  final String? sub;
  final String? icon;
  final VoidCallback? onIconTap;
  final double size;

  const BSTitleBar({
    super.key,
    required this.title,
    this.sub,
    this.icon,
    this.onIconTap,
    this.size = 21,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Padding(
      padding: const EdgeInsets.fromLTRB(BSSpace.screen, 6, BSSpace.screen, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: BSType.font,
              fontSize: size,
              fontWeight: BSType.wBold,
              height: 1.08,
              letterSpacing: -.02 * size,
              color: c.ink,
            ),
          ),
          const SizedBox(width: BSSpace.s3),
          Expanded(
            child: sub != null
                ? Text(
                    sub!,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: BSType.font,
                      fontSize: BSType.meta,
                      height: 1,
                      color: c.ink3,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (icon != null) ...[
            const SizedBox(width: 4),
            BSIconButton(icon: icon!, onTap: onIconTap),
          ],
        ],
      ),
    );
  }
}

class BSIconButton extends StatelessWidget {
  final String icon;
  final VoidCallback? onTap;
  final double iconSize;
  final Color? background;

  const BSIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.iconSize = 19,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return BSPress(
      onTap: onTap,
      scale: .92,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background ?? Colors.transparent,
          borderRadius: BorderRadius.circular(BSRadius.xs),
        ),
        child: BSIcon(icon, size: iconSize, color: c.ink2),
      ),
    );
  }
}

class BSChips extends StatelessWidget {
  final List<String> items;
  final String? value;
  final ValueChanged<String>? onChanged;
  final bool grow;

  const BSChips({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.grow = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    final chips = [
      for (final item in items) _chip(c, item, item == value, grow),
    ];
    if (grow) {
      return Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: chips[i]),
          ],
        ],
      );
    }
    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  Widget _chip(BSColors c, String item, bool selected, bool grow) {
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(item) : null,
      child: AnimatedContainer(
        duration: BSMotion.base,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 13),
        alignment: grow ? Alignment.center : null,
        decoration: BoxDecoration(
          color: selected ? c.ink : Colors.transparent,
          border: Border.all(color: selected ? c.ink : c.line, width: 1),
          borderRadius: BorderRadius.circular(BSRadius.xs),
        ),
        child: Text(
          item,
          style: TextStyle(
            fontFamily: BSType.font,
            fontSize: BSType.meta,
            fontWeight: BSType.wMedium,
            height: 1,
            color: selected ? c.bg : c.ink2,
          ),
        ),
      ),
    );
  }
}

class BSSeg extends StatelessWidget {
  final List<String> items;
  final String? value;
  final ValueChanged<String>? onChanged;

  const BSSeg({super.key, required this.items, this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.line, width: 1),
        borderRadius: BorderRadius.circular(BSRadius.xs),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: onChanged != null ? () => onChanged!(items[i]) : null,
                child: AnimatedContainer(
                  duration: BSMotion.base,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                  decoration: BoxDecoration(
                    color: items[i] == value ? c.ink : Colors.transparent,
                    border: i > 0
                        ? Border(left: BorderSide(color: c.line, width: 1))
                        : null,
                  ),
                  child: Text(
                    items[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: BSType.font,
                      fontSize: 13,
                      fontWeight: BSType.wMedium,
                      height: 1,
                      color: items[i] == value ? c.bg : c.ink2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BSProg extends StatelessWidget {
  final double pct;
  final String hue;
  const BSProg({super.key, required this.pct, this.hue = 'pro'});

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Container(
        height: 3,
        color: c.track,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: (pct / 100).clamp(0.0, 1.0),
          child: Container(color: c.hue(hue)),
        ),
      ),
    );
  }
}

enum BSBannerTone { info, warn, ok, err }

class BSBanner extends StatelessWidget {
  final BSBannerTone tone;
  final String icon;
  final String? title;
  final String body;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsets margin;

  const BSBanner({
    super.key,
    this.tone = BSBannerTone.info,
    this.icon = 'info',
    this.title,
    required this.body,
    this.action,
    this.onAction,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    final (Color bg, Color fg) = switch (tone) {
      BSBannerTone.info => (c.proSoft, c.proInk),
      BSBannerTone.warn => (c.carbSoft, c.carbInk),
      BSBannerTone.ok => (c.calSoft, c.calInk),
      BSBannerTone.err => (c.dangerSoft, c.danger),
    };
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(BSRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: BSIcon(icon, size: 18, color: fg),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: TextStyle(
                      fontFamily: BSType.font,
                      fontSize: BSType.bodySm,
                      fontWeight: BSType.wBold,
                      height: 1.45,
                      color: fg,
                    ),
                  ),
                Text(
                  body,
                  style: TextStyle(
                    fontFamily: BSType.font,
                    fontSize: BSType.bodySm,
                    height: 1.45,
                    color: fg,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (action != null)
                  GestureDetector(
                    onTap: onAction,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        action!,
                        style: TextStyle(
                          fontFamily: BSType.font,
                          fontSize: BSType.bodySm,
                          fontWeight: BSType.wBold,
                          decoration: TextDecoration.underline,
                          decorationColor: fg,
                          color: fg,
                        ),
                      ),
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

class BSFab extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;

  const BSFab(
      {super.key,
      required this.label,
      this.icon = 'plus',
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return BSPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        decoration: BoxDecoration(
          color: c.ink,
          borderRadius: BorderRadius.circular(BSRadius.pill),
          boxShadow: c.eCard,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BSIcon(icon, size: 20, stroke: 2.2, color: c.bg),
            const SizedBox(width: BSSpace.s2),
            Text(
              label,
              style: TextStyle(
                fontFamily: BSType.font,
                fontSize: 14,
                fontWeight: BSType.wBold,
                height: 1,
                color: c.bg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> showBSSheet<T>(
  BuildContext context, {
  String? title,
  String? sub,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: context.bs.scrim,
    builder: (ctx) {
      final c = ctx.bs;
      return Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(BSRadius.sheet)),
          boxShadow: c.eSheet,
        ),
        padding: EdgeInsets.only(
          top: 8,
          left: BSSpace.screen,
          right: BSSpace.screen,
          bottom: 26 +
              MediaQuery.of(ctx).viewInsets.bottom +
              MediaQuery.of(ctx).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: c.track,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: BSType.font,
                          fontSize: 17,
                          fontWeight: BSType.wBold,
                          height: 1.2,
                          letterSpacing: -.015 * 17,
                          color: c.ink,
                        ),
                      ),
                    ),
                    if (sub != null)
                      Text(
                        sub,
                        style: TextStyle(
                          fontFamily: BSType.font,
                          fontSize: BSType.meta,
                          color: c.ink3,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ),
            Flexible(child: builder(ctx)),
          ],
        ),
      );
    },
  );
}

Future<T?> showBSDialog<T>(
  BuildContext context, {
  required String title,
  required String body,
  required List<Widget> actions,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: context.bs.scrim,
    builder: (ctx) {
      final c = ctx.bs;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: BSSpace.s6),
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BSRadius.lg),
        ),
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(BSSpace.s5, 22, BSSpace.s5, BSSpace.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: BSType.font,
                  fontSize: 17,
                  fontWeight: BSType.wBold,
                  height: 1.25,
                  letterSpacing: -.015 * 17,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: BSSpace.s2),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: BSType.font,
                  fontSize: BSType.bodySm,
                  height: 1.5,
                  color: c.ink2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 18),
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                actions[i],
              ],
            ],
          ),
        ),
      );
    },
  );
}

void showBSToast(
  BuildContext context,
  String message, {
  String? action,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final c = context.bs;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 86),
      backgroundColor: c.ink,
      duration: duration,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BSRadius.sm),
      ),
      padding: const EdgeInsets.only(left: 16, right: 14, top: 13, bottom: 13),
      content: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: BSType.font,
                fontSize: BSType.bodySm,
                color: c.bg,
              ),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                onAction?.call();
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  action,
                  style: TextStyle(
                    fontFamily: BSType.font,
                    fontSize: BSType.bodySm,
                    fontWeight: BSType.wBold,
                    decoration: TextDecoration.underline,
                    decorationColor: c.bg,
                    color: c.bg,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class BSKeypad extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final ValueChanged<String> onKey;

  const BSKeypad({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.onKey,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    const keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '.',
      '0',
      'back'
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 18),
          child: Column(
            children: [
              BSOverline(label),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: BSType.font,
                      fontSize: 52,
                      fontWeight: BSType.wRegular,
                      height: 1,
                      letterSpacing: BSType.trHero * 52,
                      color: c.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 7),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      unit,
                      style: TextStyle(
                        fontFamily: BSType.font,
                        fontSize: 15,
                        height: 1,
                        color: c.ink3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var row = 0; row < 4; row++)
                  Padding(
                    padding: EdgeInsets.only(top: row == 0 ? 0 : 4),
                    child: Row(
                      children: [
                        for (var col = 0; col < 3; col++) ...[
                          if (col > 0) const SizedBox(width: 4),
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: _Key(
                                label: keys[row * 3 + col],
                                onTap: () => onKey(keys[row * 3 + col]),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Key({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return BSPress(
      onTap: onTap,
      scale: .95,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BSRadius.sm),
        ),
        alignment: Alignment.center,
        child: label == 'back'
            ? BSIcon('backspace', size: 22, color: c.ink)
            : Text(
                label,
                style: TextStyle(
                  fontFamily: BSType.font,
                  fontSize: 24,
                  fontWeight: BSType.wRegular,
                  height: 1,
                  color: c.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
      ),
    );
  }
}

class BSRule extends StatelessWidget {
  final Widget? child;
  final EdgeInsets padding;
  const BSRule({super.key, this.child, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line, width: 1)),
      ),
      padding: padding,
      child: child,
    );
  }
}
