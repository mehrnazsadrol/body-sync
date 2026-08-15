import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'bs_icon.dart';

class BSEmpty extends StatelessWidget {
  final String icon;
  final String title;
  final String? body;
  final Widget? action;
  final String hue;

  const BSEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
    this.hue = 'cal',
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: BSSpace.s7, horizontal: BSSpace.s5),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.hueSoft(hue),
              shape: BoxShape.circle,
            ),
            child: BSIcon(icon, size: 24, color: c.hueInk(hue)),
          ),
          const SizedBox(height: BSSpace.s4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: BSType.font,
              fontSize: BSType.heading,
              fontWeight: BSType.wBold,
              height: 1.25,
              letterSpacing: BSType.trTitle * BSType.heading,
              color: c.ink,
            ),
          ),
          if (body != null)
            Padding(
              padding: const EdgeInsets.only(top: BSSpace.s2),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  body!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: BSType.font,
                    fontSize: BSType.bodySm,
                    height: 1.45,
                    color: c.ink2,
                  ),
                ),
              ),
            ),
          if (action != null)
            Padding(
              padding: const EdgeInsets.only(top: BSSpace.s5),
              child: action!,
            ),
        ],
      ),
    );
  }
}
