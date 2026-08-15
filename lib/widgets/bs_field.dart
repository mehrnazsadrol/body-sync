import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class BSField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final String? placeholder;
  final String? unit;
  final Widget? right;
  final String? hint;
  final bool invalid;
  final bool numeric;
  final bool obscure;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  const BSField({
    super.key,
    required this.label,
    this.controller,
    this.placeholder,
    this.unit,
    this.right,
    this.hint,
    this.invalid = false,
    this.numeric = true,
    this.obscure = false,
    this.readOnly = false,
    this.onChanged,
  });

  @override
  State<BSField> createState() => _BSFieldState();
}

class _BSFieldState extends State<BSField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    final borderColor = widget.invalid
        ? c.danger
        : _focus.hasFocus
            ? c.accent
            : Colors.transparent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: BSMotion.fast,
          constraints: const BoxConstraints(minHeight: BSSpace.hit),
          padding:
              const EdgeInsets.symmetric(vertical: 9, horizontal: BSSpace.s4),
          decoration: BoxDecoration(
            color: c.sunk,
            borderRadius: BorderRadius.circular(BSRadius.md),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label.toUpperCase(),
                      style: TextStyle(
                        fontFamily: BSType.font,
                        fontSize: BSType.micro,
                        fontWeight: BSType.wBold,
                        height: 1,
                        letterSpacing: BSType.trOverline * BSType.micro,
                        color: widget.invalid ? c.danger : c.ink3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      readOnly: widget.readOnly,
                      onChanged: widget.onChanged,
                      obscureText: widget.obscure,
                      autocorrect: !widget.obscure,
                      enableSuggestions: !widget.obscure,
                      keyboardType: widget.obscure
                          ? TextInputType.visiblePassword
                          : widget.numeric
                              ? const TextInputType.numberWithOptions(
                                  decimal: true)
                              : TextInputType.text,
                      style: TextStyle(
                        fontFamily: BSType.font,
                        fontSize: BSType.heading,
                        fontWeight: BSType.wBold,
                        height: 1.15,
                        letterSpacing: -.015 * BSType.heading,
                        color: c.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: widget.placeholder,
                        hintStyle: TextStyle(color: c.ink3),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.unit != null) ...[
                const SizedBox(width: BSSpace.s3),
                Text(
                  widget.unit!,
                  style: TextStyle(
                    fontFamily: BSType.font,
                    fontSize: BSType.bodySm,
                    fontWeight: BSType.wMedium,
                    height: 1,
                    color: c.ink3,
                  ),
                ),
              ],
              if (widget.right != null) ...[
                const SizedBox(width: BSSpace.s3),
                widget.right!,
              ],
            ],
          ),
        ),
        if (widget.hint != null)
          Padding(
            padding: const EdgeInsets.only(
                top: 6, left: BSSpace.s2, right: BSSpace.s2),
            child: Text(
              widget.hint!,
              style: TextStyle(
                fontFamily: BSType.font,
                fontSize: BSType.meta,
                fontWeight: BSType.wRegular,
                height: 1.35,
                color: widget.invalid ? c.danger : c.ink3,
              ),
            ),
          ),
      ],
    );
  }
}
