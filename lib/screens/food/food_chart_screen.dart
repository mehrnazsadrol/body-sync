import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_store.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../widgets/bs_common.dart';
import '../../widgets/bs_list_row.dart';
import '../../widgets/bs_trend.dart';

class FoodChartScreen extends StatefulWidget {
  final DateTime? initialDay;
  const FoodChartScreen({super.key, this.initialDay});

  @override
  State<FoodChartScreen> createState() => _FoodChartScreenState();
}

class _FoodChartScreenState extends State<FoodChartScreen> {
  String _range = '30 days';
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDay;
    if (d != null) _selected = DateTime(d.year, d.month, d.day);
  }

  int get _days => switch (_range) {
        '6 months' => 182,
        '1 year' => 365,
        'All' => 730,
        _ => 30,
      };

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final c = context.bs;
    final today = DateTime.now();
    final series = store.calorieSeries(_days);
    final target = store.targets.kcal;

    final loggedDays = series.where((v) => v > 0).toList();
    final avg = loggedDays.isEmpty
        ? 0.0
        : loggedDays.reduce((a, b) => a + b) / loggedDays.length;
    final under = loggedDays.where((v) => v <= target).length;
    final overCount = loggedDays.where((v) => v > target).length;
    final nothing = series.length - loggedDays.length;

    var hi = 0.0, lo = double.infinity;
    var hiIdx = -1, loIdx = -1;
    for (var i = 0; i < series.length; i++) {
      final v = series[i];
      if (v <= 0) continue;
      if (v > hi) {
        hi = v;
        hiIdx = i;
      }
      if (v < lo) {
        lo = v;
        loIdx = i;
      }
    }
    DateTime dayAt(int i) =>
        today.subtract(Duration(days: series.length - 1 - i));
    final delta = avg - target;

    int? selIdx;
    if (_selected != null) {
      final todayDate = DateTime(today.year, today.month, today.day);
      final i = series.length - 1 - todayDate.difference(_selected!).inDays;
      if (i >= 0 && i < series.length) selIdx = i;
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BSTitleBar(
              title: 'Calories',
              sub: _range,
              icon: 'close',
              onIconTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    BSSpace.screen, 0, BSSpace.screen, 12),
                children: [
                  const BSOverline('daily average'),
                  const SizedBox(height: 8),
                  BSHero(
                    value: fmtKcal(avg),
                    unit: 'kcal',
                    size: 54,
                    right: loggedDays.isEmpty
                        ? null
                        : '${delta > 0 ? '+' : '−'}${fmtKcal(delta.abs())} vs target',
                    hue: delta <= 0 ? 'cal' : 'fat',
                  ),
                  BSTrend(
                    values: series,
                    mode: BSTrendMode.columns,
                    hue: 'cal',
                    height: 92,
                    margin: const EdgeInsets.only(top: 22),
                    labels: [
                      fmtDayShort(dayAt(0)),
                      fmtDayShort(today),
                    ],
                    dimLastCount: 1,
                    selectedIndex: selIdx,
                    onBarTap: (i) => setState(() {
                      final d = dayAt(i);
                      final day = DateTime(d.year, d.month, d.day);
                      _selected = _selected == day ? null : day;
                    }),
                  ),
                  if (selIdx != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        series[selIdx] > 0
                            ? '${fmtDay(dayAt(selIdx))} · ${fmtKcal(series[selIdx])} kcal'
                            : '${fmtDay(dayAt(selIdx))} · nothing logged',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: BSType.font,
                          fontSize: BSType.micro,
                          fontWeight: BSType.wMedium,
                          height: 1,
                          color: c.ink2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: BSSeg(
                      items: const ['30 days', '6 months', '1 year', 'All'],
                      value: _range,
                      onChanged: (v) => setState(() => _range = v),
                    ),
                  ),
                  const BSSecHead('Against target'),
                  BSListRow(
                    first: true,
                    title: 'Under ${fmtKcal(target)}',
                    meta: 'days',
                    value: '$under',
                    valueMeta: 'of ${series.length}',
                  ),
                  BSListRow(
                    title: 'Over ${fmtKcal(target)}',
                    meta: 'days',
                    value: '$overCount',
                    valueMeta: 'of ${series.length}',
                  ),
                  BSListRow(
                    title: 'Nothing logged',
                    meta: 'days',
                    value: '$nothing',
                    valueMeta: 'of ${series.length}',
                  ),
                  if (hiIdx >= 0) ...[
                    const BSSecHead('Highest and lowest'),
                    BSListRow(
                      first: true,
                      title: fmtDayShort(dayAt(hiIdx)),
                      meta: 'Highest day',
                      value: fmtKcal(hi),
                      valueMeta: 'kcal',
                    ),
                    if (loIdx >= 0)
                      BSListRow(
                        title: fmtDayShort(dayAt(loIdx)),
                        meta: 'Lowest day',
                        value: fmtKcal(lo),
                        valueMeta: 'kcal',
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
