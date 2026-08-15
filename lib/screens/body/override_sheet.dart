import 'package:flutter/material.dart';

import '../../util/format.dart';
import '../../widgets/bs_button.dart';
import '../../widgets/bs_common.dart';
import '../../widgets/bs_field.dart';

typedef OverrideResult = ({double value, String source});

sealed class OverrideOutcome {
  const OverrideOutcome();
}

class OverrideUse extends OverrideOutcome {
  final double value;
  final String source;
  const OverrideUse(this.value, this.source);
}

class OverrideCleared extends OverrideOutcome {
  const OverrideCleared();
}

Future<OverrideResult?> showOverrideSheet(
  BuildContext context, {
  required double? estimate,
  double? initialValue,
  String? initialSource,
}) async {
  final o = await showBodyFatOverrideSheet(
    context,
    estimate: estimate,
    initialValue: initialValue,
    initialSource: initialSource,
  );
  return o is OverrideUse ? (value: o.value, source: o.source) : null;
}

Future<OverrideOutcome?> showBodyFatOverrideSheet(
  BuildContext context, {
  required double? estimate,
  double? initialValue,
  String? initialSource,
  bool overrideActive = false,
}) {
  return showBSSheet<OverrideOutcome>(
    context,
    title: 'Body fat',
    sub: 'from a scale or scan',
    builder: (_) => _OverrideBody(
      estimate: estimate,
      initialValue: initialValue,
      initialSource: initialSource,
      overrideActive: overrideActive,
    ),
  );
}

class _OverrideBody extends StatefulWidget {
  final double? estimate;
  final double? initialValue;
  final String? initialSource;
  final bool overrideActive;

  const _OverrideBody({
    required this.estimate,
    this.initialValue,
    this.initialSource,
    this.overrideActive = false,
  });

  @override
  State<_OverrideBody> createState() => _OverrideBodyState();
}

class _OverrideBodyState extends State<_OverrideBody> {
  late final TextEditingController _ctrl = TextEditingController(
      text: widget.initialValue != null ? fmt1(widget.initialValue!) : '');
  late String _source = widget.initialSource ?? 'DEXA';

  double? get _parsed => double.tryParse(_ctrl.text.trim());

  bool get _invalid {
    if (_ctrl.text.trim().isEmpty) return false;
    final v = _parsed;
    return v == null || v < 2 || v > 60;
  }

  double? get _value => _invalid ? null : _parsed;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = _value;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BSField(
            label: 'Body fat',
            controller: _ctrl,
            unit: '%',
            placeholder: '0.0',
            invalid: _invalid,
            hint: _invalid
                ? 'Between 2 and 60 %.'
                : 'Replaces the estimate from today on. Past check-ins keep their own values.',
            onChanged: (_) => setState(() {}),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 14, bottom: 4),
            child: BSOverline('MEASURED WITH'),
          ),
          BSChips(
            items: const ['Smart scale', 'DEXA', 'Calipers', 'Other'],
            value: _source,
            onChanged: (s) => setState(() => _source = s),
          ),
          if (widget.estimate != null)
            BSBanner(
              tone: BSBannerTone.info,
              icon: 'info',
              body:
                  'The Navy-method estimate was ${fmt1(widget.estimate!)} %. It stays on file and reappears if you clear this value.',
              margin: const EdgeInsets.only(top: 18, bottom: 16),
            )
          else
            const SizedBox(height: 18),
          BSButton(
            v != null ? 'Use ${fmt1(v)} %' : 'Use this value',
            variant: BSButtonVariant.solid,
            size: BSButtonSize.lg,
            block: true,
            onTap: v == null
                ? null
                : () => Navigator.of(context)
                    .pop<OverrideOutcome>(OverrideUse(v, _source)),
          ),
          const SizedBox(height: 10),
          BSButton(
            widget.overrideActive ? 'Clear this value' : 'Keep the estimate',
            variant: BSButtonVariant.quiet,
            block: true,
            onTap: widget.overrideActive
                ? () => Navigator.of(context)
                    .pop<OverrideOutcome>(const OverrideCleared())
                : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
