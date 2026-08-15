import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../widgets/bs_button.dart';
import '../../widgets/bs_common.dart';

Future<void> showQuickAddSheet(BuildContext context, {DateTime? date}) {
  final target = date ?? DateTime.now();
  final now = DateTime.now();
  final entryTime = dateKey(target) == dateKey(now)
      ? now
      : DateTime(target.year, target.month, target.day, 12);
  final meal = LogEntry(
    id: '',
    time: entryTime,
    name: '',
    portion: '',
    kcal: 0,
    p: 0,
    c: 0,
    f: 0,
  ).meal;
  final timeLabel =
      '${entryTime.hour.toString().padLeft(2, '0')}:${entryTime.minute.toString().padLeft(2, '0')}';

  return showBSSheet<void>(
    context,
    title: 'Quick add',
    sub: '$meal · $timeLabel',
    builder: (ctx) => _QuickAddBody(date: target, time: entryTime),
  );
}

class _QuickAddBody extends StatefulWidget {
  final DateTime date;
  final DateTime time;
  const _QuickAddBody({required this.date, required this.time});

  @override
  State<_QuickAddBody> createState() => _QuickAddBodyState();
}

class _QuickAddBodyState extends State<_QuickAddBody> {
  String _value = '0';

  void _key(String k) {
    setState(() {
      if (k == 'back') {
        _value =
            _value.length > 1 ? _value.substring(0, _value.length - 1) : '0';
      } else if (k == '.') {
      } else {
        if (_value == '0') {
          _value = k;
        } else if (_value.length < 5) {
          _value += k;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BSKeypad(
            label: 'Calories',
            value: _value,
            unit: 'kcal',
            onKey: _key,
          ),
          const BSBanner(
            tone: BSBannerTone.info,
            icon: 'info',
            body:
                'Logged as calories only. Protein, carbs and fat stay unknown for the day, and the macro rings will read low.',
            margin: EdgeInsets.only(top: 16, bottom: 14),
          ),
          BSButton(
            'Add to log',
            size: BSButtonSize.lg,
            block: true,
            onTap: () {
              final kcal = double.tryParse(_value) ?? 0;
              if (kcal <= 0) return;
              store.addEntry(
                widget.date,
                LogEntry(
                  id: '${DateTime.now().microsecondsSinceEpoch}',
                  time: widget.time,
                  name: 'Quick add',
                  portion: 'calories only',
                  kcal: kcal,
                  p: 0,
                  c: 0,
                  f: 0,
                  quickAdd: true,
                ),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
