import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../widgets/bs_button.dart';
import '../../widgets/bs_common.dart';
import '../../widgets/bs_field.dart';
import '../../widgets/bs_icon.dart';
import '../../widgets/bs_list_row.dart';
import '../../widgets/bs_press.dart';
import '../../widgets/bs_trend.dart';

class FoodDetailScreen extends StatefulWidget {
  final Food food;
  final FoodPortion portion;

  const FoodDetailScreen(
      {super.key, required this.food, required this.portion});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  late FoodPortion _portion = widget.portion;
  late final TextEditingController _kcal;
  late final TextEditingController _p;
  late final TextEditingController _c;
  late final TextEditingController _f;

  @override
  void initState() {
    super.initState();
    final store = context.read<AppStore>();
    final eff = store.foods.effective(widget.food, _portion);
    _kcal = TextEditingController(text: fmtG(eff.kcal));
    _p = TextEditingController(text: fmtG(eff.p));
    _c = TextEditingController(text: fmtG(eff.c));
    _f = TextEditingController(text: fmtG(eff.f));
  }

  @override
  void dispose() {
    _kcal.dispose();
    _p.dispose();
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  void _switchPortion(AppStore store, FoodPortion p) {
    setState(() {
      _portion = p;
      final eff = store.foods.effective(widget.food, p);
      _kcal.text = fmtG(eff.kcal);
      _p.text = fmtG(eff.p);
      _c.text = fmtG(eff.c);
      _f.text = fmtG(eff.f);
    });
  }

  double? get _kcalValue => double.tryParse(_kcal.text);

  bool get _kcalInvalid {
    final v = _kcalValue;
    if (v == null) return true;
    final cap = (_portion.kcal * 8).clamp(900, 4000).toDouble();
    return v < 0 || v > cap;
  }

  double get _macroKcal =>
      (double.tryParse(_p.text) ?? 0) * 4 +
      (double.tryParse(_c.text) ?? 0) * 4 +
      (double.tryParse(_f.text) ?? 0) * 9;

  bool get _macroMismatch {
    final v = _kcalValue;
    if (v == null || v <= 0) return false;
    return (_macroKcal - v).abs() / v > .35;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final c = context.bs;
    final override = store.foods.overrideFor(widget.food, _portion);
    final hasOverride = override != null;
    final cap = (_portion.kcal * 8).clamp(900, 4000).round();

    final today = dayOnly(DateTime.now());
    final counts = List<double>.filled(15, 0);
    for (var i = 0; i < 30; i++) {
      final d = today.subtract(Duration(days: 29 - i));
      for (final e in store.entriesFor(d)) {
        if (e.foodId == widget.food.id) counts[i ~/ 2] += 1;
      }
    }
    final hasHistory = counts.any((v) => v > 0);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BSTitleBar(
              title: widget.food.displayName(_portion),
              sub: _portion.per,
              icon: 'close',
              onIconTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    BSSpace.screen, 0, BSSpace.screen, 12),
                children: [
                  if (hasOverride)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const BSBadge('your values'),
                          const SizedBox(width: BSSpace.s2),
                          Expanded(
                            child: Text(
                              'edited ${fmtDay(override.edited)} · database said ${fmtG(_portion.kcal)} kcal',
                              style: TextStyle(
                                fontFamily: BSType.font,
                                fontSize: BSType.meta,
                                color: c.ink3,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const BSSecHead('Nutrition facts'),
                  const SizedBox(height: 10),
                  BSField(
                    label: 'Calories',
                    controller: _kcal,
                    unit: 'kcal',
                    invalid: _kcalInvalid,
                    hint: _kcalInvalid
                        ? 'Enter a value between 0 and $cap kcal ${_portion.per.replaceFirst('per', 'per')}.'
                        : null,
                    onChanged: (_) => setState(() {}),
                    right: hasOverride
                        ? BSPress(
                            onTap: () => setState(
                                () => _kcal.text = fmtG(_portion.kcal)),
                            scale: .92,
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: Center(
                                child: BSIcon('undo', size: 17, color: c.ink2),
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: BSField(
                          label: 'Protein',
                          controller: _p,
                          unit: 'g',
                          placeholder: '0',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: BSField(
                          label: 'Carbs',
                          controller: _c,
                          unit: 'g',
                          placeholder: '0',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: BSField(
                          label: 'Fat',
                          controller: _f,
                          unit: 'g',
                          placeholder: '0',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  if (_macroMismatch)
                    BSBanner(
                      tone: BSBannerTone.warn,
                      icon: 'info',
                      title: 'Macros add up to ${fmtKcal(_macroKcal)} kcal',
                      body:
                          'Protein, carbs and fat account for ${fmtKcal(_macroKcal)} of the ${fmtKcal(_kcalValue ?? 0)} kcal entered. Save anyway if the label says so.',
                      margin: const EdgeInsets.only(top: 14),
                    ),
                  if (widget.food.portions.length > 1) ...[
                    const BSSecHead('Portions'),
                    for (var i = 0; i < widget.food.portions.length; i++)
                      _portionRow(store, c, widget.food.portions[i], i == 0),
                  ],
                  if (hasHistory) ...[
                    const BSSecHead('Logged', right: 'last 30 days'),
                    BSTrend(
                      values: counts,
                      mode: BSTrendMode.columns,
                      hue: 'cal',
                      height: 44,
                      margin: const EdgeInsets.only(top: 12),
                      labels: [
                        fmtDayShort(today.subtract(const Duration(days: 29))),
                        fmtDayShort(today),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  BSSpace.screen, 0, BSSpace.screen, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BSButton(
                    'Save as my version',
                    size: BSButtonSize.lg,
                    block: true,
                    onTap: _kcalInvalid
                        ? null
                        : () async {
                            await store.saveOverride(FoodOverride(
                              foodId: widget.food.id,
                              portionLabel: _portion.label,
                              kcal: _kcalValue!,
                              p: double.tryParse(_p.text) ?? 0,
                              c: double.tryParse(_c.text) ?? 0,
                              f: double.tryParse(_f.text) ?? 0,
                              edited: DateTime.now(),
                            ));
                            if (context.mounted) Navigator.of(context).pop();
                          },
                  ),
                  const SizedBox(height: 6),
                  BSButton(
                    hasOverride
                        ? 'Revert to database values'
                        : 'Discard changes',
                    variant: BSButtonVariant.quiet,
                    block: true,
                    onTap: () async {
                      if (hasOverride) {
                        await store.removeOverride(
                            '${widget.food.id}|${_portion.label}');
                        if (context.mounted) {
                          _switchPortion(store, _portion);
                        }
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _portionRow(AppStore store, BSColors c, FoodPortion p, bool first) {
    final o = store.foods.overrideFor(widget.food, p);
    final kcal = o?.kcal ?? p.kcal;
    final current = p.label == _portion.label;
    return BSListRow(
      first: first,
      title: p.label,
      meta: '${o != null ? 'your values' : 'database'} · ${fmtG(kcal)} kcal',
      valueWidget: current ? BSIcon('check', size: 18, color: c.calInk) : null,
      chevron: !current,
      onTap: () => _switchPortion(store, p),
    );
  }
}
