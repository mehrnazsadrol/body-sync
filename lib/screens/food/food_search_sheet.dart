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
  final _qtyCtrl = TextEditingController();
  final _servingCtrl = TextEditingController();
  String _query = '';
  int? _selected;
  String? _portionLabel;
  double _qty = 1;

  @override
  void dispose() {
    _controller.dispose();
    _qtyCtrl.dispose();
    _servingCtrl.dispose();
    super.dispose();
  }

  static final _amountLabel = RegExp(r'^([\d.]+)\s*(g|ml)$');

  /// Base amount for weight/volume portions ("100 g", "250 ml"), else null.
  static double? servingBase(FoodPortion portion) {
    final m = _amountLabel.firstMatch(portion.label);
    return m == null ? null : double.tryParse(m.group(1)!);
  }

  static String? servingUnit(FoodPortion portion) =>
      _amountLabel.firstMatch(portion.label)?.group(2);

  void _resetPanel(Food food, String label) {
    _qty = 1;
    _qtyCtrl.text = '1';
    final portion = food.portions.firstWhere(
      (p) => p.label == label,
      orElse: () => food.portions.first,
    );
    final base = servingBase(portion);
    _servingCtrl.text = base == null ? '' : fmtG(base);
  }

  double? _servingAmount(FoodPortion portion) {
    if (servingBase(portion) == null) return null;
    final v = double.tryParse(_servingCtrl.text);
    return (v == null || v <= 0) ? servingBase(portion) : v;
  }

  bool get _isToday => dateKey(widget.date) == dateKey(DateTime.now());

  String get _contextLabel =>
      _isToday ? LogEntry.mealOf(DateTime.now()) : fmtDayMonth(widget.date);

  void _add(AppStore store, Food food, FoodPortion portion, double qty,
      double? servingAmount) {
    if (qty <= 0) return;
    final eff = store.foods.effective(food, portion);
    final own = store.foods.hasOverride(food, portion);
    final base = servingBase(portion);
    final factor = (base != null && servingAmount != null && base > 0)
        ? servingAmount / base
        : 1.0;
    final mult = factor * qty;
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
        portion: _portionText(food, portion, qty, servingAmount),
        qty: qty,
        kcal: eff.kcal * mult,
        p: eff.p * mult,
        c: eff.c * mult,
        f: eff.f * mult,
        own: own,
      ),
    );
    if (!mounted) return;
    setState(() => _selected = null);
    showBSToast(context, 'Added · ${fmtKcal(eff.kcal * mult)} kcal');
  }

  String _portionText(
      Food food, FoodPortion portion, double qty, double? servingAmount) {
    if (servingAmount != null) {
      final unit = servingUnit(portion) ?? 'g';
      return '${fmtG(servingAmount * qty)} $unit';
    }
    final per = portion.per;
    final unit = per.startsWith('per ') ? per.substring(4) : portion.label;
    if (unit.contains(RegExp(r'^\d'))) {
      final m = RegExp(r'^([\d.]+)\s*(.*)$').firstMatch(unit)!;
      final base = double.parse(m.group(1)!);
      return '${fmtG(base * qty)} ${m.group(2)}';
    }
    return qty == 1 ? '1 $unit' : '${fmtG(qty)} ${qty > 1 ? _plural(unit) : unit}';
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
                            _resetPanel(r.food, r.portion.label);
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
                            qtyCtrl: _qtyCtrl,
                            servingCtrl: _servingCtrl,
                            onQty: (q) => setState(() {
                              _qty = q;
                              _qtyCtrl.text = fmtG(q);
                            }),
                            onQtyText: (v) => setState(() {
                              final parsed = double.tryParse(v);
                              if (parsed != null && parsed > 0) {
                                _qty = parsed.clamp(0.1, 99).toDouble();
                              }
                            }),
                            onServing: () => setState(() {}),
                            onPortion: (l) => setState(() {
                              _portionLabel = l;
                              _resetPanel(r.food, l);
                            }),
                            onAdd: (portion, qty) => _add(store, r.food,
                                portion, qty, _servingAmount(portion)),
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
                  _add(store, food, portion, 1, null);
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
  final double qty;
  final TextEditingController qtyCtrl;
  final TextEditingController servingCtrl;
  final ValueChanged<double> onQty;
  final ValueChanged<String> onQtyText;
  final VoidCallback onServing;
  final ValueChanged<String> onPortion;
  final void Function(FoodPortion portion, double qty) onAdd;
  final void Function(FoodPortion portion) onNutrition;

  const _PortionPanel({
    required this.food,
    required this.initialLabel,
    required this.qty,
    required this.qtyCtrl,
    required this.servingCtrl,
    required this.onQty,
    required this.onQtyText,
    required this.onServing,
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
    final base = _FoodSearchScreenState.servingBase(portion);
    final unit = _FoodSearchScreenState.servingUnit(portion);
    final amount = base == null
        ? null
        : (double.tryParse(servingCtrl.text) ?? base);
    final factor =
        (base != null && amount != null && amount > 0) ? amount / base : 1.0;
    final mult = factor * qty;

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
          if (base != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: BSField(
                label: 'Serving',
                controller: servingCtrl,
                unit: unit,
                hint: 'Database values are per ${fmtG(base)} $unit — '
                    'enter what you actually had.',
                onChanged: (_) => onServing(),
              ),
            ),
          Row(
            children: [
              const Expanded(child: BSOverline('Quantity')),
              _Stepper(qty: qty, controller: qtyCtrl,
                  onQty: onQty, onText: onQtyText),
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
                  fmtG(eff.kcal * mult),
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
                  '${fmtG(eff.p * mult)}P · ${fmtG(eff.c * mult)}C · ${fmtG(eff.f * mult)}F',
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
  final double qty;
  final TextEditingController controller;
  final ValueChanged<double> onQty;
  final ValueChanged<String> onText;
  const _Stepper({
    required this.qty,
    required this.controller,
    required this.onQty,
    required this.onText,
  });

  // Below 1 the buttons step through the common food fractions
  // (1 → ¾ → ½ → ¼) instead of jumping straight to zero.
  static const _fractions = [0.25, 0.5, 0.75];

  double _down() {
    if (qty > 1) return qty - 1;
    for (final f in _fractions.reversed) {
      if (qty > f) return f;
    }
    return qty;
  }

  double _up() {
    if (qty >= 1) return (qty + 1).clamp(1, 99).toDouble();
    for (final f in _fractions) {
      if (qty < f) return f;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(c, 'minus', () => onQty(_down())),
        Container(
          constraints: const BoxConstraints(minWidth: 30, maxWidth: 64),
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            onChanged: onText,
            textAlign: TextAlign.center,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontFamily: BSType.font,
              fontSize: BSType.heading,
              fontWeight: BSType.wBold,
              color: c.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ),
        _btn(c, 'plus', () => onQty(_up())),
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
