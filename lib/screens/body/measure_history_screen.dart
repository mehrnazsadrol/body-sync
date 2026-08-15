import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../data/formulas.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../util/units.dart';
import '../../widgets/bs_button.dart';
import '../../widgets/bs_common.dart';
import '../../widgets/bs_empty.dart';
import '../../widgets/bs_field.dart';
import '../../widgets/bs_list_row.dart';
import '../../widgets/bs_trend.dart';

class MeasureHistoryScreen extends StatelessWidget {
  final String measure;

  const MeasureHistoryScreen({super.key, required this.measure});

  double? _valueOf(BodySnapshot s) => switch (measure) {
        'Neck' => s.neckCm,
        'Waist' => s.waistCm,
        _ => s.hipCm,
      };

  void _editLatest(BuildContext context, AppStore store) {
    final snap = store.latestSnapshot;
    if (snap == null) return;
    showBSSheet<void>(
      context,
      title: 'Edit reading',
      sub: fmtDayShort(snap.date),
      builder: (_) => _EditReadingBody(store: store, snap: snap),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    final store = context.watch<AppStore>();
    final snaps = store.snapshots
        .where((s) => _valueOf(s) != null)
        .toList(growable: false);
    final latestSnap = store.latestSnapshot;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            BSTitleBar(
              title: measure,
              sub: '${snaps.length} check-ins',
              icon: 'chevronLeft',
              onIconTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: snaps.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(
                          BSSpace.screen, 0, BSSpace.screen, 12),
                      children: [
                        BSEmpty(
                          icon: 'ruler',
                          hue: 'pro',
                          title: 'No ${measure.toLowerCase()} readings yet',
                          body:
                              'A 30-day check-in adds the first point to this ledger.',
                        ),
                      ],
                    )
                  : _buildLedger(context, store, snaps),
            ),
            if (snaps.isNotEmpty && latestSnap != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    BSSpace.screen, 0, BSSpace.screen, 10),
                child: BSButton(
                  'Edit the ${fmtDayShort(latestSnap.date)} reading',
                  variant: BSButtonVariant.quiet,
                  block: true,
                  onTap: () => _editLatest(context, store),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedger(
      BuildContext context, AppStore store, List<BodySnapshot> snaps) {
    final c = context.bs;
    final units = Units.of(store.settings);
    final values = [for (final s in snaps) units.cmOut(_valueOf(s)!)];
    final latest = snaps.last;
    final first = snaps.first;
    final isCurrentCycle = store.latestSnapshot != null &&
        latest.date == store.latestSnapshot!.date;

    return ListView(
      padding: const EdgeInsets.fromLTRB(BSSpace.screen, 0, BSSpace.screen, 26),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BSOverline('LATEST · ${fmtDayShort(latest.date)}'),
              const SizedBox(height: 8),
              BSHero(
                value: fmt1(values.last),
                unit: units.lengthUnit,
                size: 58,
                right: snaps.length >= 2
                    ? '${fmtDelta1(values.last - values.first)} ${units.lengthUnit} since ${fmtDayShort(first.date)}'
                    : null,
                hue: snaps.length >= 2 && values.last - values.first < 0
                    ? 'cal'
                    : null,
              ),
            ],
          ),
        ),
        if (snaps.length >= 2)
          BSTrend(
            values: values,
            mode: BSTrendMode.area,
            hue: 'pro',
            height: 72,
            labels: [fmtDayShort(first.date), fmtDayShort(latest.date)],
            margin: const EdgeInsets.only(top: 24),
          ),
        const BSSecHead('EVERY CHECK-IN'),
        for (var i = snaps.length - 1; i >= 0; i--)
          BSListRow(
            first: i == snaps.length - 1,
            title: fmtDay(snaps[i].date),
            meta: i == 0
                ? 'First check-in'
                : (i == snaps.length - 1 && isCurrentCycle
                    ? 'Day ${store.checkinCycle().day} of this cycle'
                    : null),
            value: fmt1(values[i]),
            valueMetaWidget: i == 0
                ? Text(
                    '—',
                    style: TextStyle(
                      fontFamily: BSType.font,
                      fontSize: BSType.micro,
                      height: 1.2,
                      color: c.ink3,
                    ),
                  )
                : Text(
                    fmtDelta1(values[i] - values[i - 1]),
                    style: TextStyle(
                      fontFamily: BSType.font,
                      fontSize: BSType.micro,
                      height: 1.2,
                      color: values[i] - values[i - 1] < 0 ? c.calInk : c.ink3,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: BSM2(
            '$measure feeds the body-fat estimate, so a mis-measured cycle shows up there too.',
          ),
        ),
      ],
    );
  }
}

class _EditReadingBody extends StatefulWidget {
  final AppStore store;
  final BodySnapshot snap;

  const _EditReadingBody({required this.store, required this.snap});

  @override
  State<_EditReadingBody> createState() => _EditReadingBodyState();
}

class _EditReadingBodyState extends State<_EditReadingBody> {
  static const _ranges = {
    'Neck': (20, 80),
    'Waist': (50, 200),
    'Hip': (50, 200),
  };
  static const _measureHints = {
    'Neck': 'Below the larynx, tape sloping slightly down at the front',
    'Waist': 'At the navel, relaxed, at the end of a normal breath',
    'Hip': 'At the widest point, feet together',
  };

  late final Units _units = Units.of(widget.store.settings);
  late final _neck = TextEditingController(
      text: widget.snap.neckCm != null
          ? fmt1(_units.cmOut(widget.snap.neckCm!))
          : '');
  late final _waist = TextEditingController(
      text: widget.snap.waistCm != null
          ? fmt1(_units.cmOut(widget.snap.waistCm!))
          : '');
  late final _hip = TextEditingController(
      text: widget.snap.hipCm != null
          ? fmt1(_units.cmOut(widget.snap.hipCm!))
          : '');
  late final _weight = TextEditingController(
      text: widget.snap.weightKg != null
          ? fmt1(_units.kgOut(widget.snap.weightKg!))
          : '');

  @override
  void dispose() {
    _neck.dispose();
    _waist.dispose();
    _hip.dispose();
    _weight.dispose();
    super.dispose();
  }

  TextEditingController _ctrlFor(String name) => switch (name) {
        'Neck' => _neck,
        'Waist' => _waist,
        _ => _hip,
      };

  double? _valueOf(TextEditingController ctrl) {
    final t = ctrl.text.trim();
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    return v == null ? null : _units.cmIn(v);
  }

  bool _isInvalid(TextEditingController ctrl, int lo, int hi) {
    final t = ctrl.text.trim();
    if (t.isEmpty) return false;
    final cm = _valueOf(ctrl);
    return cm == null || cm < lo || cm > hi;
  }

  String _hintFor(String name, int lo, int hi) {
    final ctrl = _ctrlFor(name);
    final t = ctrl.text.trim();
    if (t.isEmpty) return 'Empty removes this measurement from the reading.';
    if (!_isInvalid(ctrl, lo, hi)) return _measureHints[name]!;
    if (_units.imperial) {
      return 'Between ${(lo / Units.cmPerIn).round()} and ${(hi / Units.cmPerIn).round()} in.';
    }
    final raw = double.tryParse(t);
    if (raw != null && raw * Units.cmPerIn >= lo && raw * Units.cmPerIn <= hi) {
      return 'Between $lo and $hi cm. $t looks like inches — enter centimetres.';
    }
    return 'Between $lo and $hi cm.';
  }

  double? get _weightKg {
    final t = _weight.text.trim();
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    return v == null ? null : _units.kgIn(v);
  }

  bool get _weightInvalid {
    if (_weight.text.trim().isEmpty) return false;
    final kg = _weightKg;
    return kg == null || kg <= 0 || kg >= 500;
  }

  bool get _anyInvalid =>
      _weightInvalid ||
      _ranges.entries
          .any((e) => _isInvalid(_ctrlFor(e.key), e.value.$1, e.value.$2));

  Future<void> _save() async {
    final store = widget.store;
    final snap = widget.snap;
    final profile = store.profile;
    final nav = Navigator.of(context);

    final neck = _valueOf(_neck);
    final waist = _valueOf(_waist);
    final hip = _valueOf(_hip);
    final weight = _weightKg;
    final estimate = Formulas.navyBodyFat(
      sex: profile.sex,
      heightCm: profile.heightCm,
      neckCm: neck,
      waistCm: waist,
      hipCm: hip,
    );
    final hasOverride = snap.overrideSource != null;
    final fat = hasOverride ? snap.bodyFatPct : (estimate ?? snap.bodyFatPct);
    final bmr = Formulas.bmr(
      sex: profile.sex,
      age: profile.age,
      heightCm: profile.heightCm,
      weightKg: weight,
      fatPct: fat,
      overrideKcal: profile.bmrOverrideKcal,
    );
    await store.replaceLatestSnapshot(snap.copyWith(
      weightKg: weight,
      neckCm: neck,
      waistCm: waist,
      hipCm: hip,
      bodyFatPct: fat,
      leanKg: Formulas.leanMass(weight, fat),
      bmr: bmr,
      tdee: Formulas.tdee(bmr, profile.activity),
      estimatedFatPct: hasOverride ? estimate : null,
    ));
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final e in _ranges.entries) ...[
            BSField(
              label: e.key,
              controller: _ctrlFor(e.key),
              unit: _units.lengthUnit,
              placeholder: '0.0',
              invalid: _isInvalid(_ctrlFor(e.key), e.value.$1, e.value.$2),
              hint: _hintFor(e.key, e.value.$1, e.value.$2),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
          ],
          BSField(
            label: 'Weight',
            controller: _weight,
            unit: _units.weightUnit,
            placeholder: '0.0',
            invalid: _weightInvalid,
            hint: _weightInvalid
                ? (_units.imperial
                    ? 'Between 0 and 1,100 lb.'
                    : 'Between 0 and 500 kg.')
                : 'The weight recorded with this check-in.',
            onChanged: (_) => setState(() {}),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 16),
            child: BSM2(
              widget.snap.overrideSource != null
                  ? 'Lean mass and TDEE recalculate from the corrected figures. Body fat keeps your ${widget.snap.overrideSource} value; the estimate updates underneath.'
                  : 'Body fat, lean mass and TDEE recalculate from the corrected figures.',
            ),
          ),
          BSButton(
            'Save the reading',
            variant: BSButtonVariant.solid,
            size: BSButtonSize.lg,
            block: true,
            onTap: _anyInvalid ? null : _save,
          ),
        ],
      ),
    );
  }
}
