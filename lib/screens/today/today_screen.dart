import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_store.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../util/units.dart';
import '../../widgets/bs_button.dart';
import '../../widgets/bs_common.dart';
import '../../widgets/bs_empty.dart';
import '../../widgets/bs_icon.dart';
import '../../widgets/bs_list_row.dart';
import '../../widgets/bs_macro_rings.dart';
import '../../widgets/bs_skeleton.dart';
import '../../widgets/bs_trend.dart';
import '../body/weigh_in_sheet.dart';
import '../food/food_chart_screen.dart';
import '../food/food_search_sheet.dart';
import '../food/log_row.dart';
import '../shell.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final c = context.bs;
    final today = DateTime.now();

    if (!store.loaded) return const _TodayLoading();

    final entries = store.entriesFor(today);
    final totals = store.totalsFor(today);
    final goal = store.targets;
    final over = totals.kcal > goal.kcal;
    final weight = store.weightFor(today);
    final workedOut = store.workoutOn(today);
    final afterReminder = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute >=
        store.settings.reminderHour * 60 + store.settings.reminderMinute;
    final showWeightBanner = store.settings.todayBannerOn &&
        weight == null &&
        entries.isNotEmpty &&
        (over || afterReminder);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BSTitleBar(
              title: 'Today',
              sub: fmtDayLong(today),
              icon: 'calendar',
              onIconTap: () => HomeShell.of(context)?.switchTab('food'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    BSSpace.screen, 0, BSSpace.screen, 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        over
                            ? BSHero(
                                value: fmtKcal(totals.kcal - goal.kcal),
                                unit: 'kcal over',
                                right:
                                    '${fmtKcal(totals.kcal)} / ${fmtKcal(goal.kcal)}',
                                valueColor: c.fatInk,
                                unitColor: c.fatInk,
                              )
                            : BSHero(
                                value: fmtKcal(goal.kcal - totals.kcal),
                                unit: 'kcal left',
                                right:
                                    '${fmtKcal(totals.kcal)} / ${fmtKcal(goal.kcal)}',
                              ),
                        BSMacroRings(
                          items: ringItems(
                            kcal: totals.kcal,
                            p: totals.p,
                            carbs: totals.c,
                            f: totals.f,
                            goalKcal: goal.kcal,
                            goalP: goal.p,
                            goalC: goal.c,
                            goalF: goal.f,
                            overAsFat: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showWeightBanner)
                    BSBanner(
                      tone: BSBannerTone.warn,
                      icon: 'scale',
                      title: 'No weight for today',
                      body:
                          'Logging one takes a second and keeps the trend honest.'
                          '${store.settings.reminderOn ? ' The ${store.settings.reminderLabel} reminder is still due.' : ''}',
                      action: 'Log weight',
                      onAction: () => showWeighInSheet(context),
                      margin: const EdgeInsets.only(top: 22),
                    ),
                  if (entries.isEmpty) ...[
                    const BSSecHead('Logged today'),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: BSRule(
                        child: BSEmpty(
                          icon: 'food',
                          title: 'Nothing logged yet',
                          body:
                              'Entries are timestamped as you log them, so the day builds up rather than being entered at the end.',
                          action: BSButton(
                            'Log food',
                            icon: 'plus',
                            onTap: () => showFoodSearchSheet(context),
                          ),
                        ),
                      ),
                    ),
                    const BSSecHead('Also today'),
                    _summaryRows(context, store,
                        includeFood: false,
                        weight: weight,
                        workedOut: workedOut,
                        entriesCount: 0,
                        totalsKcal: 0),
                  ] else if (over) ...[
                    BSSecHead('Logged today',
                        right:
                            '${entries.length} item${entries.length == 1 ? '' : 's'}'),
                    for (var i = 0; i < entries.length; i++)
                      LogRow(
                        entry: entries[i],
                        first: i == 0,
                        onTap: () => HomeShell.of(context)?.switchTab('food'),
                      ),
                  ] else ...[
                    const BSSecHead('Logged today', right: 'tap to open'),
                    _summaryRows(context, store,
                        includeFood: true,
                        weight: weight,
                        workedOut: workedOut,
                        entriesCount: entries.length,
                        totalsKcal: totals.kcal,
                        lastTime: entries.isNotEmpty
                            ? entries.first.timeLabel
                            : null),
                    const BSSecHead('Calories', right: 'last 7 days'),
                    BSTrend(
                      values: store.calorieSeries(7),
                      mode: BSTrendMode.columns,
                      hue: 'cal',
                      height: 54,
                      margin: const EdgeInsets.only(top: 12),
                      labels: [
                        fmtDayShort(today.subtract(const Duration(days: 6))),
                        fmtDayShort(today),
                      ],
                      dimLastCount: 1,
                      onBarTap: (i) => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FoodChartScreen(
                              initialDay:
                                  today.subtract(Duration(days: 6 - i))),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ],
        ),
        if (entries.isNotEmpty)
          Positioned(
            right: BSSpace.screen,
            bottom: 18,
            child: BSFab(
              label: 'Log food',
              onTap: () => showFoodSearchSheet(context),
            ),
          ),
      ],
    );
  }

  Widget _summaryRows(
    BuildContext context,
    AppStore store, {
    required bool includeFood,
    required double? weight,
    required bool workedOut,
    required int entriesCount,
    required double totalsKcal,
    String? lastTime,
  }) {
    final c = context.bs;
    final rows = <Widget>[];
    var first = true;
    if (includeFood) {
      rows.add(BSListRow(
        first: first,
        title: 'Food',
        meta:
            '$entriesCount items${lastTime != null ? ' · last $lastTime' : ''}',
        value: fmtKcal(totalsKcal),
        valueMeta: 'kcal',
        chevron: true,
        onTap: () => HomeShell.of(context)?.switchTab('food'),
      ));
      first = false;
    }
    rows.add(BSListRow(
      first: first,
      title: 'Workout',
      meta: workedOut ? 'Logged' : 'Not logged',
      valueWidget: workedOut
          ? BSIcon('check', size: 18, color: c.ink)
          : Text('—',
              style: TextStyle(
                fontFamily: BSType.font,
                fontSize: BSType.body,
                fontWeight: BSType.wBold,
                color: c.ink,
              )),
      chevron: true,
      onTap: () => HomeShell.of(context)?.switchTab('workout'),
    ));
    final weightAt = store.weightTimeFor(DateTime.now());
    final units = Units.of(store.settings);
    rows.add(BSListRow(
      title: 'Weight',
      meta: weight == null
          ? 'Not logged'
          : weightAt != null
              ? 'Logged ${weightAt.hour.toString().padLeft(2, '0')}:${weightAt.minute.toString().padLeft(2, '0')}'
              : 'Logged today',
      value: weight != null ? fmt1(units.kgOut(weight)) : '—',
      valueMeta: weight != null ? units.weightUnit : null,
      chevron: true,
      onTap: () => weight == null
          ? showWeighInSheet(context)
          : HomeShell.of(context)?.switchTab('body'),
    ));
    return Column(children: rows);
  }
}

class _TodayLoading extends StatelessWidget {
  const _TodayLoading();

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BSTitleBar(title: 'Today', sub: fmtDayLong(today), icon: 'calendar'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                BSSpace.screen, 6, BSSpace.screen, 12),
            children: [
              const Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BSSkeleton(w: 148, h: 40, radius: 8),
                  Spacer(),
                  BSSkeleton(w: 78, h: 13, radius: 5),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 26),
                child: Row(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      const Expanded(
                        child: Column(
                          children: [
                            BSSkeleton(w: 40, h: 40, circle: true),
                            SizedBox(height: 7),
                            BSSkeleton(w: 34, h: 11, radius: 4),
                            SizedBox(height: 7),
                            BSSkeleton(w: 44, h: 9, radius: 4),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const BSSecHead('Logged today'),
              const BSSkeletonRow(),
              const BSSkeletonRow(),
              const BSSkeletonRow(),
            ],
          ),
        ),
      ],
    );
  }
}
