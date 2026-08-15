import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class BSToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const BSToggle({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    final enabled = onChanged != null;
    return Opacity(
      opacity: enabled ? 1 : .4,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        child: AnimatedContainer(
          duration: BSMotion.base,
          curve: BSMotion.inOut,
          width: 51,
          height: 31,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: value ? c.accent : c.track,
            borderRadius: BorderRadius.circular(BSRadius.pill),
          ),
          child: AnimatedAlign(
            duration: BSMotion.base,
            curve: BSMotion.spring,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 27,
              height: 27,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x47000000),
                    offset: Offset(0, 2),
                    blurRadius: 6,
                    spreadRadius: -1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
