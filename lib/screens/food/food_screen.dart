import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../widgets/bs_button.dart';
import '../../widgets/bs_common.dart';
import '../../widgets/bs_empty.dart';
import '../../widgets/bs_icon.dart';
import '../../widgets/bs_macro_rings.dart';
import 'food_chart_screen.dart';
import 'food_detail_screen.dart';
import 'food_search_sheet.dart';
import 'log_row.dart';
import 'quick_add_sheet.dart';
import 'recents_sheet.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  DateTime _date = DateTime.now();

  bool get _isToday => dateKey(_date) == dateKey(DateTime.now());

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _deleteEntry(AppStore store, LogEntry entry) async {
    final confirmed = await showBSDialog<bool>(
      context,
      title: 'Delete “${entry.name}”?',
      body:
          "${fmtKcal(entry.kcal)} kcal comes off ${_isToday ? "today's" : "the day's"} total. "
          'This cannot be undone once the toast clears.',
      actions: [
        BSButton(
          'Delete entry',
          variant: BSButtonVariant.danger,
          size: BSButtonSize.lg,
          block: true,
          onTap: () => Navigator.of(context, rootNavigator: true).pop(true),
        ),
        BSButton(
          'Keep it',
          variant: BSButtonVariant.quiet,
          block: true,
          onTap: () => Navigator.of(context, rootNavigator: true).pop(false),
        ),
      ],
    );
    if (confirmed != true || !mounted) return;
    final removed = await store.deleteEntry(_date, entry.id);
    if (removed == null || !mounted) return;
    showBSToast(
      context,
      '${entry.name} deleted',
      action: 'Undo',
      onAction: () => store.addEntry(_date, removed),
      duration: const Duration(seconds: 5),
    );
  }

  void _openEntry(AppStore store, LogEntry entry) {
    final food = entry.foodId != null ? store.foods.byId(entry.foodId!) : null;
    if (food == null) {
      showBSSheet<void>(
        context,
        title: entry.quickAdd
            ? 'Quick add · ${fmtKcal(entry.kcal)} kcal'
            : '${entry.name} · ${fmtKcal(entry.kcal)} kcal',
        sub: entry.timeLabel,
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BSButton(
              'Delete entry',
              variant: BSButtonVariant.danger,
              block: true,
              onTap: () {
                Navigator.pop(ctx);
                _deleteEntry(store, entry);
              },
            ),
            const SizedBox(height: 6),
            BSButton(
              'Cancel',
              variant: BSButtonVariant.quiet,
              block: true,
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
      return;
    }
    FoodPortion? portion;
    for (final p in food.portions) {
      if (p.label == entry.portionLabel) portion = p;
    }
    showBSSheet<void>(
      context,
      title: entry.name,
      sub: '${entry.portion} · ${fmtKcal(entry.kcal)} kcal',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BSButton(
            'Nutrition — edit your version',
            variant: BSButtonVariant.tint,
            hue: 'pro',
            block: true,
            onTap: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => FoodDetailScreen(
                  food: food,
                  portion: portion ?? food.portions.first,
                ),
              ));
            },
          ),
          const SizedBox(height: 6),
          BSButton(
            'Delete entry',
            variant: BSButtonVariant.danger,
            block: true,
            onTap: () {
              Navigator.pop(ctx);
              _deleteEntry(store, entry);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final entries = store.entriesFor(_date);
    final totals = store.totalsFor(_date);
    final goal = store.targets;
    final over = totals.kcal > goal.kcal;
    final c = context.bs;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BSTitleBar(
              title: 'Food',
              sub: fmtDayLong(_date),
              icon: 'calendar',
              onIconTap: _pickDay,
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
                        BSHero(
                          value: over
                              ? fmtKcal(totals.kcal - goal.kcal)
                              : fmtKcal(goal.kcal - totals.kcal),
                          unit: over ? 'kcal over' : 'kcal left',
                          right:
                              '${fmtKcal(totals.kcal)} / ${fmtKcal(goal.kcal)}',
                          valueColor: over ? c.fatInk : null,
                          unitColor: over ? c.fatInk : null,
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
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: BSChips(
                            items: const ['Recents', 'Quick add calories'],
                            grow: true,
                            onChanged: (v) {
                              if (v == 'Recents') {
                                showRecentsSheet(context, date: _date);
                              } else {
                                showQuickAddSheet(context, date: _date);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (store.writeFailed)
                    BSBanner(
                      tone: BSBannerTone.err,
                      icon: 'info',
                      title: "Couldn't save to this device",
                      body:
                          'Storage is full or unavailable. One entry is held in memory and will be lost if the app closes.',
                      action: 'Retry now',
                      onAction: () => store.retryWrites(),
                      margin: const EdgeInsets.only(top: 8),
                    ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const FoodChartScreen())),
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: BSSpace.s5, bottom: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: BSOverline(
                                _isToday ? 'Logged today' : 'Logged'),
                          ),
                          Text(
                            entries.isEmpty
                                ? 'over time'
                                : '${entries.length} item${entries.length == 1 ? '' : 's'} · over time',
                            style: TextStyle(
                              fontFamily: BSType.font,
                              fontSize: BSType.micro,
                              fontWeight: BSType.wRegular,
                              height: 1,
                              color: c.ink3,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          const SizedBox(width: 2),
                          BSIcon('chevronRight', size: 13, color: c.ink3),
                        ],
                      ),
                    ),
                  ),
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: BSRule(
                        child: BSEmpty(
                          icon: 'food',
                          title: _isToday
                              ? 'Nothing logged yet'
                              : 'No food logged',
                          body: _isToday
                              ? 'Entries are timestamped as you log them, so the day builds up rather than being entered at the end.'
                              : 'Nothing was logged on this day. Adding it now backdates the entry to ${fmtDayMonth(_date)}.',
                          action: BSButton(
                            'Log food',
                            icon: 'plus',
                            onTap: () =>
                                showFoodSearchSheet(context, date: _date),
                          ),
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < entries.length; i++)
                      LogRow(
                        entry: entries[i],
                        first: i == 0,
                        onTap: () => _openEntry(store, entries[i]),
                      ),
                  const SizedBox(height: 84),
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
              onTap: () => showFoodSearchSheet(context, date: _date),
            ),
          ),
      ],
    );
  }
}
