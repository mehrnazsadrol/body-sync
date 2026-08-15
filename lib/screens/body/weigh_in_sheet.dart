import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../data/notification_service.dart';
import '../../util/format.dart';
import '../../util/units.dart';
import '../../widgets/bs_button.dart';
import '../../widgets/bs_common.dart';

Future<void> showWeighInSheet(BuildContext context) {
  final store = context.read<AppStore>();
  final notif = context.read<NotificationService>();
  return showBSSheet<void>(
    context,
    title: 'Weigh-in',
    sub: fmtDayShort(DateTime.now()),
    builder: (_) => _WeighInBody(store: store, notif: notif),
  );
}

class _WeighInBody extends StatefulWidget {
  final AppStore store;
  final NotificationService notif;

  const _WeighInBody({required this.store, required this.notif});

  @override
  State<_WeighInBody> createState() => _WeighInBodyState();
}

class _WeighInBodyState extends State<_WeighInBody> {
  late final Units _units = Units.of(widget.store.settings);
  late final double? _today = widget.store.weightFor(DateTime.now());
  late String _value = () {
    final seed = _today ?? widget.store.latestWeight;
    return seed != null ? fmt1(_units.kgOut(seed)) : '0';
  }();
  bool _touched = false;

  double? get _parsed {
    final v = double.tryParse(_value);
    if (v == null) return null;
    final kg = _units.kgIn(v);
    if (kg <= 0 || kg >= 500) return null;
    return kg;
  }

  void _key(String k) {
    setState(() {
      if (k == 'back') {
        if (!_touched) {
          _touched = true;
          _value = '0';
          return;
        }
        _value =
            _value.length > 1 ? _value.substring(0, _value.length - 1) : '0';
        if (_value.endsWith('.')) {
          _value = _value.substring(0, _value.length - 1);
        }
      } else if (k == '.') {
        if (!_touched) {
          _value = '0.';
          _touched = true;
        } else if (!_value.contains('.')) {
          _value += '.';
        }
      } else {
        if (!_touched) {
          _value = k;
          _touched = true;
        } else if (_value == '0') {
          _value = k;
        } else {
          final dot = _value.indexOf('.');
          if (dot < 0 && _value.length >= 3) return;
          if (dot >= 0 && _value.length - dot > 1) return;
          _value += k;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final v = _parsed;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BSKeypad(
            label: 'WEIGHT',
            value: _value,
            unit: _units.weightUnit,
            onKey: _key,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 14),
            child: BSM2(
              _today != null
                  ? "Replaces today's ${fmt1(_units.kgOut(_today))} ${_units.weightUnit}. First thing in the morning, after the bathroom, before food, is the reading that compares."
                  : 'First thing in the morning, after the bathroom, before food, is the reading that compares.',
            ),
          ),
          BSButton(
            "Set today's weight",
            icon: 'check',
            variant: BSButtonVariant.solid,
            size: BSButtonSize.lg,
            block: true,
            onTap: v == null
                ? null
                : () async {
                    Navigator.of(context).pop();
                    await widget.store.setWeight(dayOnly(DateTime.now()), v);
                    await widget.notif.sync(widget.store);
                  },
          ),
        ],
      ),
    );
  }
}
