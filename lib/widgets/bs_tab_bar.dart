import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'bs_icon.dart';

class BSTab {
  final String key;
  final String label;
  final String icon;
  const BSTab({required this.key, required this.label, required this.icon});
}

const bsNavTabs = [
  BSTab(key: 'today', label: 'Today', icon: 'today'),
  BSTab(key: 'food', label: 'Food', icon: 'food'),
  BSTab(key: 'body', label: 'Body', icon: 'body'),
  BSTab(key: 'workout', label: 'Workout', icon: 'workout'),
];

class BSNavBar extends StatelessWidget {
  final String active;
  final ValueChanged<String> onTap;

  const BSNavBar({super.key, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line, width: 1)),
      ),
      padding: EdgeInsets.only(
        left: 6,
        right: 6,
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          for (final tab in bsNavTabs)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(tab.key),
                child: Container(
                  constraints: const BoxConstraints(minHeight: BSSpace.hit),
                  padding: const EdgeInsets.only(top: 9, bottom: 7),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BSIcon(
                        tab.icon,
                        size: 22,
                        stroke: tab.key == active ? 2.1 : 1.7,
                        color: tab.key == active ? c.ink : c.ink3,
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: BSMotion.base,
                        style: TextStyle(
                          fontFamily: BSType.font,
                          fontSize: 10.5,
                          fontWeight:
                              tab.key == active ? BSType.wBold : BSType.wMedium,
                          height: 1,
                          color: tab.key == active ? c.ink : c.ink3,
                        ),
                        child: Text(tab.label),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: tab.key == active ? c.ink : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
