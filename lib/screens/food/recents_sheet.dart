import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/bs_common.dart';
import '../../widgets/bs_list_row.dart';
import '../../util/format.dart';

Future<void> showRecentsSheet(BuildContext context, {DateTime? date}) {
  return showBSSheet<void>(
    context,
    title: 'Recents',
    builder: (ctx) => _RecentsBody(date: date ?? DateTime.now()),
  );
}

class _RecentsBody extends StatefulWidget {
  final DateTime date;
  const _RecentsBody({required this.date});

  @override
  State<_RecentsBody> createState() => _RecentsBodyState();
}

class _RecentsBodyState extends State<_RecentsBody> {
  String _mode = 'Recent';

  DateTime get _entryTime {
    final now = DateTime.now();
    return dateKey(widget.date) == dateKey(now)
        ? now
        : DateTime(widget.date.year, widget.date.month, widget.date.day, 12);
  }

  void _relog(AppStore store, LogEntry template) {
    store.addEntry(
      widget.date,
      LogEntry(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        time: _entryTime,
        name: template.name,
        foodId: template.foodId,
        portionLabel: template.portionLabel,
        portion: template.portion,
        qty: template.qty,
        kcal: template.kcal,
        p: template.p,
        c: template.c,
        f: template.f,
        own: template.own,
      ),
    );
    Navigator.pop(context);
  }

  void _logFood(AppStore store, Food food, FoodPortion portion) {
    final eff = store.foods.effective(food, portion);
    store.addEntry(
      widget.date,
      LogEntry(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        time: _entryTime,
        name: food.displayName(portion),
        foodId: food.id,
        portionLabel: portion.label,
        portion: _portionText(portion),
        kcal: eff.kcal,
        p: eff.p,
        c: eff.c,
        f: eff.f,
        own: store.foods.hasOverride(food, portion),
      ),
    );
    Navigator.pop(context);
  }

  String _portionText(FoodPortion p) {
    final unit = p.per.startsWith('per ') ? p.per.substring(4) : p.label;
    return unit.contains(RegExp(r'^\d')) ? unit : '1 $unit';
  }

  List<({Food food, FoodPortion portion, bool own})> _myFoods(AppStore store) {
    final repo = store.foods;
    final rows = <({Food food, FoodPortion portion, bool own})>[];
    final seen = <String>{};
    for (final f in repo.customFoods) {
      final p = f.portions.first;
      seen.add('${f.id}|${p.label}');
      rows.add((food: f, portion: p, own: repo.hasOverride(f, p)));
    }
    for (final o in store.foods.overrides.values) {
      if (!seen.add(o.key)) continue;
      final f = repo.byId(o.foodId);
      if (f == null) continue;
      FoodPortion? p;
      for (final pp in f.portions) {
        if (pp.label == o.portionLabel) p = pp;
      }
      if (p == null) continue;
      rows.add((food: f, portion: p, own: true));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    final Widget list;
    if (_mode == 'My foods') {
      final items = _myFoods(store);
      list = items.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: BSM2(
                  'Nothing here yet — created foods and edited values appear here.'),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (_, i) {
                final r = items[i];
                final eff = store.foods.effective(r.food, r.portion);
                return BSListRow(
                  first: i == 0,
                  title: r.food.displayName(r.portion),
                  badge: r.own ? const BSBadge('your values') : null,
                  meta: r.portion.per,
                  value: fmtKcal(eff.kcal),
                  valueMeta: 'kcal',
                  onTap: () => _logFood(store, r.food, r.portion),
                );
              },
            );
    } else {
      final items = store.recents(limit: 20, byTime: _mode == 'Recent');
      list = items.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: BSM2('Nothing here yet — foods appear as you log them.'),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (_, i) {
                final r = items[i];
                return BSListRow(
                  first: i == 0,
                  title: r.entry.name,
                  badge: r.entry.own ? const BSBadge('your values') : null,
                  meta: r.entry.portion,
                  value: fmtKcal(r.entry.kcal),
                  valueMeta: 'logged ${r.count} time${r.count == 1 ? '' : 's'}',
                  onTap: () => _relog(store, r.entry),
                );
              },
            );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BSSeg(
          items: const ['Recent', 'Frequent', 'My foods'],
          value: _mode,
          onChanged: (v) => setState(() => _mode = v),
        ),
        Padding(
          padding: const EdgeInsets.only(top: BSSpace.s5, bottom: 2),
          child: BSOverline(_mode == 'My foods'
              ? 'Tap to log one portion'
              : 'Tap to log at the same portion'),
        ),
        Flexible(child: list),
      ],
    );
  }
}
