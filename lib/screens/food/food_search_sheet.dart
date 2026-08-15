import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../widgets/bs_button.dart';
import '../../widgets/bs_common.dart';
import '../../widgets/bs_empty.dart';
import '../../widgets/bs_field.dart';
import '../../widgets/bs_icon.dart';
import '../../widgets/bs_list_row.dart';
import '../../widgets/bs_press.dart';
import 'food_detail_screen.dart';
import 'quick_add_sheet.dart';

Future<void> showFoodSearchSheet(BuildContext context, {DateTime? date}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FoodSearchScreen(date: date ?? DateTime.now()),
    ),
  );
}

class _FoodSearchScreen extends StatefulWidget {
  final DateTime date;
  const _FoodSearchScreen({required this.date});

  @override
  State<_FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<_FoodSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  int? _selected;
  String? _portionLabel;
  int _qty = 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isToday => dateKey(widget.date) == dateKey(DateTime.now());

  String get _contextLabel =>
      _isToday ? LogEntry.mealOf(DateTime.now()) : fmtDayMonth(widget.date);

  void _add(AppStore store, Food food, FoodPortion portion, int qty) {
    final eff = store.foods.effective(food, portion);
    final own = store.foods.hasOverride(food, portion);
    final now = DateTime.now();
    final entryTime = dateKey(widget.date) == dateKey(now)
        ? now
        : DateTime(widget.date.year, widget.date.month, widget.date.day, 12);
    store.addEntry(
      widget.date,
      LogEntry(
        id: '${now.microsecondsSinceEpoch}',
        time: entryTime,
        name: food.displayName(portion),
        foodId: food.id,
        portionLabel: portion.label,
        portion: _portionText(food, portion, qty),
        qty: qty.toDouble(),
        kcal: eff.kcal * qty,
        p: eff.p * qty,
        c: eff.c * qty,
        f: eff.f * qty,
        own: own,
      ),
    );
    if (!mounted) return;
    setState(() => _selected = null);
    showBSToast(context, 'Added · ${fmtKcal(eff.kcal * qty)} kcal');
  }

  String _portionText(Food food, FoodPortion portion, int qty) {
    final per = portion.per;
    final unit = per.startsWith('per ') ? per.substring(4) : portion.label;
    if (unit.contains(RegExp(r'^\d'))) {
      final m = RegExp(r'^([\d.]+)\s*(.*)$').firstMatch(unit)!;
      final base = double.parse(m.group(1)!);
      return '${fmtG(base * qty)} ${m.group(2)}';
    }
    return qty == 1 ? '1 $unit' : '$qty ${_plural(unit)}';
  }

  String _plural(String unit) {
    if (unit.endsWith('s')) return unit;
    return '${unit}s';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final c = context.bs;
    final results = store.foods.search(_query);
    final recents = store.recents(limit: 2);

    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(BSSpace.screen, 8, BSSpace.screen, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add food',
                        style: TextStyle(
                          fontFamily: BSType.font,
                          fontSize: 17,
                          fontWeight: BSType.wBold,
                          height: 1.2,
                          letterSpacing: -.015 * 17,
                          color: c.ink,
                        ),
                      ),
                    ),
                    BSIconButton(
                      icon: 'close',
                      iconSize: 20,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              BSField(
                label: 'Search',
                controller: _controller,
                numeric: false,
                placeholder: 'Food name',
                onChanged: (v) => setState(() {
                  _query = v;
                  _selected = null;
                }),
                right: _query.isNotEmpty
                    ? GestureDetector(
                        onTap: () => setState(() {
                          _controller.clear();
                          _query = '';
                          _selected = null;
                        }),
                        child: BSIcon('close', size: 18, color: c.ink3),
                      )
                    : null,
              ),
              if (_query.isNotEmpty && results.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: BSSpace.s5, bottom: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: BSOverline(
                            '${results.length} match${results.length == 1 ? '' : 'es'} · offline database'),
                      ),
                      Text(
                        _contextLabel,
                        style: TextStyle(
                          fontFamily: BSType.font,
                          fontSize: BSType.meta,
                          color: c.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (_, i) {
                      final r = results[i];
                      final eff = store.foods.effective(r.food, r.portion);
                      final own = store.foods.hasOverride(r.food, r.portion);
                      final row = BSListRow(
                        first: i == 0,
                        title: r.food.displayName(r.portion),
                        badge: own ? const BSBadge('your values') : null,
                        meta: r.portion.per,
                        value: fmtG(eff.kcal),
                        valueMetaWidget:
                            BSMac(p: eff.p, carbs: eff.c, f: eff.f),
                        onTap: () => setState(() {
                          if (_selected == i) {
                            _selected = null;
                          } else {
                            _selected = i;
                            _portionLabel = r.portion.label;
                            _qty = 1;
                          }
                        }),
                      );
                      if (_selected != i) return row;
                      return Column(
                        children: [
                          row,
                          _PortionPanel(
                            food: r.food,
                            initialLabel: _portionLabel ?? r.portion.label,
                            qty: _qty,
                            onQty: (q) => setState(() => _qty = q),
                            onPortion: (l) => setState(() => _portionLabel = l),
                            onAdd: (portion, qty) =>
                                _add(store, r.food, portion, qty),
                            onNutrition: (portion) {
                              Navigator.of(context).push(MaterialPageRoute(
                                fullscreenDialog: true,
                                builder: (_) => FoodDetailScreen(
                                  food: r.food,
                                  portion: portion,
                                ),
                              ));
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                BSRule(
                  padding: const EdgeInsets.only(top: 14, bottom: 10),
                  child: BSButton(
                    'Nothing matches — quick add calories',
                    variant: BSButtonVariant.quiet,
                    block: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      showQuickAddSheet(context, date: widget.date);
                    },
                  ),
                ),
              ] else if (_query.isNotEmpty) ...[
                Expanded(
                  child: Column(
                    children: [
                      BSEmpty(
                        icon: 'search',
                        title: 'No match for “$_query”',
                        body:
                            'The bundled database ships with the app and works offline, so it will not have everything.',
                        action: BSButton(
                          'Create this food',
                          variant: BSButtonVariant.tint,
                          icon: 'plus',
                          onTap: () => _createFood(store),
                        ),
                      ),
                      BSButton(
                        'Quick add calories instead',
                        variant: BSButtonVariant.quiet,
                        onTap: () {
                          Navigator.of(context).pop();
                          showQuickAddSheet(context, date: widget.date);
                        },
                      ),
                    ],
                  ),
                ),
                if (recents.isNotEmpty)
                  BSRule(
                    padding: const EdgeInsets.only(top: 14, bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const BSOverline('Recently logged'),
                        const SizedBox(height: 6),
                        for (var i = 0; i < recents.length; i++)
                          BSListRow(
                            first: i == 0,
                            title: recents[i].entry.name,
                            meta: recents[i].entry.portion,
                            value: fmtKcal(recents[i].entry.kcal),
                            valueMeta: 'kcal',
                            onTap: () => _relog(store, recents[i].entry),
                          ),
                      ],
                    ),
                  ),
              ] else ...[
                Expanded(
                  child: recents.isEmpty
                      ? const SizedBox()
                      : ListView(
                          children: [
                            const Padding(
                              padding:
                                  EdgeInsets.only(top: BSSpace.s5, bottom: 2),
                              child: BSOverline('Recently logged'),
                            ),
                            for (var i = 0; i < recents.length; i++)
                              BSListRow(
                                first: i == 0,
                                title: recents[i].entry.name,
                                badge: recents[i].entry.own
                                    ? const BSBadge('your values')
                                    : null,
                                meta: recents[i].entry.portion,
                                value: fmtKcal(recents[i].entry.kcal),
                                valueMeta: 'kcal',
                                onTap: () => _relog(store, recents[i].entry),
                              ),
                          ],
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _relog(AppStore store, LogEntry template) {
    final now = DateTime.now();
    final entryTime = dateKey(widget.date) == dateKey(now)
        ? now
        : DateTime(widget.date.year, widget.date.month, widget.date.day, 12);
    store.addEntry(
      widget.date,
      LogEntry(
        id: '${now.microsecondsSinceEpoch}',
        time: entryTime,
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
    Navigator.of(context).pop();
  }

  Future<void> _createFood(AppStore store) async {
    final name = _query.trim();
    final kcalCtrl = TextEditingController();
    final pCtrl = TextEditingController();
    final cCtrl = TextEditingController();
    final fCtrl = TextEditingController();
    final perCtrl = TextEditingController(text: '1 serving');
    await showBSSheet<void>(
      context,
      title: 'Create “$name”',
      sub: 'saved to My foods',
      builder: (ctx) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BSField(label: 'Portion', controller: perCtrl, numeric: false),
              const SizedBox(height: 10),
              BSField(label: 'Calories', controller: kcalCtrl, unit: 'kcal'),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: BSField(
                          label: 'Protein', controller: pCtrl, unit: 'g')),
                  const SizedBox(width: 6),
                  Expanded(
                      child: BSField(
                          label: 'Carbs', controller: cCtrl, unit: 'g')),
                  const SizedBox(width: 6),
                  Expanded(
                      child:
                          BSField(label: 'Fat', controller: fCtrl, unit: 'g')),
                ],
              ),
              const SizedBox(height: 16),
              BSButton(
                'Save and log',
                size: BSButtonSize.lg,
                block: true,
                onTap: () async {
                  final kcal = double.tryParse(kcalCtrl.text);
                  if (kcal == null) return;
                  final portion = FoodPortion(
                    label: perCtrl.text.trim().isEmpty
                        ? '1 serving'
                        : perCtrl.text.trim(),
                    per: 'per ${perCtrl.text.trim()}',
                    kcal: kcal,
                    p: double.tryParse(pCtrl.text) ?? 0,
                    c: double.tryParse(cCtrl.text) ?? 0,
                    f: double.tryParse(fCtrl.text) ?? 0,
                  );
                  final food = Food(
                    id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    portions: [portion],
                    custom: true,
                  );
                  await store.addCustomFood(food);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _add(store, food, portion, 1);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PortionPanel extends StatelessWidget {
  final Food food;
  final String initialLabel;
  final int qty;
  final ValueChanged<int> onQty;
  final ValueChanged<String> onPortion;
  final void Function(FoodPortion portion, int qty) onAdd;
  final void Function(FoodPortion portion) onNutrition;

  const _PortionPanel({
    required this.food,
    required this.initialLabel,
    required this.qty,
    required this.onQty,
    required this.onPortion,
    required this.onAdd,
    required this.onNutrition,
  });

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final c = context.bs;
    final labels = [for (final p in food.portions) p.label];
    final portion = food.portions.firstWhere(
      (p) => p.label == initialLabel,
      orElse: () => food.portions.first,
    );
    final eff = store.foods.effective(food, portion);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.sunk,
        borderRadius: BorderRadius.circular(BSRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labels.length > 1) ...[
            const BSOverline('Portion'),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 14),
              child: BSChips(
                items: labels,
                value: portion.label,
                onChanged: onPortion,
              ),
            ),
          ],
          Row(
            children: [
              const Expanded(child: BSOverline('Quantity')),
              _Stepper(qty: qty, onQty: onQty),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: c.ink.withValues(alpha: .85), width: 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  fmtG(eff.kcal * qty),
                  style: TextStyle(
                    fontFamily: BSType.font,
                    fontSize: BSType.heading,
                    fontWeight: BSType.wBold,
                    color: c.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'kcal',
                    style: TextStyle(
                      fontFamily: BSType.font,
                      fontSize: BSType.meta,
                      color: c.ink3,
                    ),
                  ),
                ),
                Text(
                  '${fmtG(eff.p * qty)}P · ${fmtG(eff.c * qty)}C · ${fmtG(eff.f * qty)}F',
                  style: TextStyle(
                    fontFamily: BSType.font,
                    fontSize: BSType.meta,
                    color: c.ink2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: [
                Expanded(
                  child: BSButton(
                    'Add to log',
                    block: true,
                    onTap: () => onAdd(portion, qty),
                  ),
                ),
                const SizedBox(width: 8),
                BSButton(
                  'Nutrition',
                  variant: BSButtonVariant.quiet,
                  hue: 'pro',
                  onTap: () => onNutrition(portion),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onQty;
  const _Stepper({required this.qty, required this.onQty});

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(c, 'minus', () => onQty((qty - 1).clamp(1, 99))),
        Container(
          constraints: const BoxConstraints(minWidth: 30),
          alignment: Alignment.center,
          child: Text(
            '$qty',
            style: TextStyle(
              fontFamily: BSType.font,
              fontSize: BSType.heading,
              fontWeight: BSType.wBold,
              color: c.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        _btn(c, 'plus', () => onQty((qty + 1).clamp(1, 99))),
      ],
    );
  }

  Widget _btn(BSColors c, String icon, VoidCallback onTap) {
    return BSPress(
      onTap: onTap,
      scale: .92,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(BSRadius.xs),
        ),
        child: BSIcon(icon, size: 18, color: c.ink2),
      ),
    );
  }
}
