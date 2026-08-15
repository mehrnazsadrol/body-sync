import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../data/formulas.dart';
import '../../data/models.dart';
import '../../data/notification_service.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../util/units.dart';
import '../../widgets/bs_button.dart';
import '../../widgets/bs_common.dart';
import '../../widgets/bs_field.dart';
import '../../widgets/bs_icon.dart';
import '../../widgets/bs_list_row.dart';
import '../../widgets/bs_stat_tile.dart';
import 'override_sheet.dart';

class CheckinFlow extends StatefulWidget {
  const CheckinFlow({super.key});

  @override
  State<CheckinFlow> createState() => _CheckinFlowState();
}

class _CheckinFlowState extends State<CheckinFlow> {
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

  int _step = 1;
  String _unit = 'Centimetres';
  bool _skipped = false;
  OverrideResult? _override;

  final _neck = TextEditingController();
  final _waist = TextEditingController();
  final _hip = TextEditingController();
  late final TextEditingController _weightCtrl;

  BodySnapshot? _prev;
  double? _weight;

  bool _weightIsToday = false;
  DateTime? _weightAt;
  DateTime? _weightDate;

  @override
  void initState() {
    super.initState();
    final store = context.read<AppStore>();
    if (store.settings.imperial) _unit = 'Inches';
    _prev = store.latestSnapshot;
    final today = store.weightFor(DateTime.now());
    if (today != null) {
      _weight = today;
      _weightIsToday = true;
      _weightAt = store.weightTimeFor(DateTime.now());
    } else {
      final entries = store.weightEntries();
      if (entries.isNotEmpty) {
        _weight = entries.last.value;
        _weightDate = entries.last.key;
      } else {
        _weight = _prev?.weightKg;
        _weightDate = _prev?.date;
      }
    }
    final inches = _unit == 'Inches';
    String len(double cm) => fmt1(inches ? cm / 2.54 : cm);
    if (_prev?.neckCm != null) _neck.text = len(_prev!.neckCm!);
    if (_prev?.waistCm != null) _waist.text = len(_prev!.waistCm!);
    if (_prev?.hipCm != null) _hip.text = len(_prev!.hipCm!);
    final units = Units.of(store.settings);
    _weightCtrl = TextEditingController(
        text: _weight != null ? fmt1(units.kgOut(_weight!)) : '');
  }

  @override
  void dispose() {
    _neck.dispose();
    _waist.dispose();
    _hip.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  double? _cmOf(TextEditingController ctrl) {
    final t = ctrl.text.trim();
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    if (v == null) return null;
    return _unit == 'Inches' ? v * 2.54 : v;
  }

  bool _isInvalid(TextEditingController ctrl, int lo, int hi) {
    final t = ctrl.text.trim();
    if (t.isEmpty) return false;
    final cm = _cmOf(ctrl);
    return cm == null || cm < lo || cm > hi;
  }

  String _hintFor(TextEditingController ctrl, int lo, int hi, String base) {
    final t = ctrl.text.trim();
    if (t.isEmpty) return "Skipped values keep the last check-in's figure.";
    if (!_isInvalid(ctrl, lo, hi)) return base;
    if (_unit == 'Inches') {
      return 'Between ${(lo / 2.54).round()} and ${(hi / 2.54).round()} in.';
    }
    final raw = double.tryParse(t);
    if (raw != null && raw * 2.54 >= lo && raw * 2.54 <= hi) {
      return 'Between $lo and $hi cm. $t looks like inches — switch units below.';
    }
    return 'Between $lo and $hi cm.';
  }

  bool get _anyInvalid => _ranges.entries
      .any((e) => _isInvalid(_ctrlFor(e.key), e.value.$1, e.value.$2));

  TextEditingController _ctrlFor(String name) => switch (name) {
        'Neck' => _neck,
        'Waist' => _waist,
        _ => _hip,
      };

  void _setUnit(String u) {
    if (u == _unit) return;
    setState(() => _unit = u);
  }

  ({
    double? neck,
    double? waist,
    double? hip,
    double? estimate,
    double? fat,
    double? lean,
    double? bmr,
    double? tdee,
  }) _results(AppStore store) {
    final neck = _skipped ? _prev?.neckCm : (_cmOf(_neck) ?? _prev?.neckCm);
    final waist = _skipped ? _prev?.waistCm : (_cmOf(_waist) ?? _prev?.waistCm);
    final hip = _skipped ? _prev?.hipCm : (_cmOf(_hip) ?? _prev?.hipCm);
    final profile = store.profile;
    final estimate = Formulas.navyBodyFat(
      sex: profile.sex,
      heightCm: profile.heightCm,
      neckCm: neck,
      waistCm: waist,
      hipCm: hip,
    );
    final fat = _override?.value ?? estimate ?? _prev?.bodyFatPct;
    final bmr = Formulas.bmr(
      sex: profile.sex,
      age: profile.age,
      heightCm: profile.heightCm,
      weightKg: _weight,
      fatPct: fat,
      overrideKcal: profile.bmrOverrideKcal,
    );
    return (
      neck: neck,
      waist: waist,
      hip: hip,
      estimate: estimate,
      fat: fat,
      lean: Formulas.leanMass(_weight, fat),
      bmr: bmr,
      tdee: Formulas.tdee(bmr, profile.activity),
    );
  }

  Future<void> _openOverride() async {
    final store = context.read<AppStore>();
    final o = await showBodyFatOverrideSheet(
      context,
      estimate: _results(store).estimate,
      initialValue: _override?.value,
      initialSource: _override?.source,
      overrideActive: _override != null,
    );
    if (!mounted || o == null) return;
    setState(() => _override = switch (o) {
          OverrideUse(:final value, :final source) => (
              value: value,
              source: source
            ),
          OverrideCleared() => null,
        });
  }

  Future<void> _save() async {
    final store = context.read<AppStore>();
    final notif = context.read<NotificationService>();
    final nav = Navigator.of(context);
    final r = _results(store);
    await store.addSnapshot(BodySnapshot(
      date: dayOnly(DateTime.now()),
      weightKg: _weight,
      neckCm: r.neck,
      waistCm: r.waist,
      hipCm: r.hip,
      bodyFatPct: r.fat,
      leanKg: r.lean,
      bmr: r.bmr,
      tdee: r.tdee,
      overrideSource: _override?.source,
      estimatedFatPct: _override != null ? r.estimate : null,
    ));
    await notif.sync(store);
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: _step == 1 ? _buildStep1(context) : _buildStep2(context),
      ),
    );
  }

  Widget _buildStep1(BuildContext context) {
    final c = context.bs;
    final store = context.watch<AppStore>();
    return Column(
      children: [
        BSTitleBar(
          title: 'Check-in',
          sub: '1 of 2',
          icon: 'close',
          onIconTap: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                BSSpace.screen, 0, BSSpace.screen, 12),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: BSProg(pct: 50, hue: 'pro'),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 16, bottom: 18),
                child: BSM2(
                  'Measure against bare skin, tape snug but not compressing, at the end of a normal breath. Same time of day as last check-in if you can.',
                ),
              ),
              for (final name in const ['Neck', 'Waist', 'Hip']) ...[
                _measureField(name),
                const SizedBox(height: 14),
              ],
              BSField(
                label: 'Weight',
                controller: _weightCtrl,
                unit: Units.of(store.settings).weightUnit,
                readOnly: true,
                right: _weightIsToday
                    ? BSIcon('check', size: 18, color: c.calInk)
                    : null,
                hint: _weightHint(),
              ),
              const SizedBox(height: 16),
              BSSeg(
                items: const ['Centimetres', 'Inches'],
                value: _unit,
                onChanged: _setUnit,
              ),
              const BSSecHead('KNOWN VALUES', right: 'optional'),
              BSListRow(
                first: true,
                title: 'Body fat from a scale or scan',
                meta: 'Overrides the estimate below',
                chevron: true,
                onTap: _openOverride,
              ),
            ],
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.fromLTRB(BSSpace.screen, 0, BSSpace.screen, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BSButton(
                'See new estimates',
                variant: BSButtonVariant.solid,
                size: BSButtonSize.lg,
                block: true,
                onTap: _anyInvalid
                    ? null
                    : () => setState(() {
                          _skipped = false;
                          _step = 2;
                        }),
              ),
              const SizedBox(height: 10),
              BSButton(
                'Skip measurements this time',
                variant: BSButtonVariant.quiet,
                block: true,
                onTap: () => setState(() {
                  _skipped = true;
                  _step = 2;
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _weightHint() {
    if (_weight == null) return 'No weigh-in on file yet.';
    if (_weightIsToday) {
      return _weightAt != null && _weightAt!.hour < 12
          ? "Carried over from this morning's weigh-in."
          : "Carried over from today's weigh-in.";
    }
    if (_weightDate != null) {
      return 'Carried over from the ${fmtDayShort(_weightDate!)} weigh-in.';
    }
    return 'Carried over from the last weigh-in.';
  }

  Widget _measureField(String name) {
    final (lo, hi) = _ranges[name]!;
    final ctrl = _ctrlFor(name);
    return BSField(
      label: name,
      controller: ctrl,
      unit: _unit == 'Inches' ? 'in' : 'cm',
      placeholder: '0.0',
      invalid: _isInvalid(ctrl, lo, hi),
      hint: _hintFor(ctrl, lo, hi, _measureHints[name]!),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildStep2(BuildContext context) {
    final store = context.watch<AppStore>();
    final r = _results(store);
    final prevFat = _prev?.bodyFatPct;
    final prevLean = _prev?.leanKg;
    final prevTdee = _prev?.tdee;

    final changed =
        <({String title, String meta, String value, String unit})>[];
    if (prevFat != null && r.fat != null) {
      changed.add((
        title: 'Body fat',
        meta: '${fmt1(prevFat)} → ${fmt1(r.fat!)} %',
        value: fmtDelta1(r.fat! - prevFat),
        unit: 'pt',
      ));
    }
    if (prevLean != null && r.lean != null) {
      final u = Units.of(store.settings);
      changed.add((
        title: 'Lean mass',
        meta:
            '${fmt1(u.kgOut(prevLean))} → ${fmt1(u.kgOut(r.lean!))} ${u.weightUnit}',
        value: fmtDelta1(u.kgOut(r.lean! - prevLean)),
        unit: u.weightUnit,
      ));
    }
    if (prevTdee != null && r.tdee != null) {
      changed.add((
        title: 'TDEE',
        meta: '${fmtKcal(prevTdee)} → ${fmtKcal(r.tdee!)} kcal',
        value: _fmtDeltaInt(r.tdee! - prevTdee),
        unit: 'kcal',
      ));
    }

    return Column(
      children: [
        BSTitleBar(
          title: 'New estimates',
          sub: '2 of 2',
          icon: 'close',
          onIconTap: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                BSSpace.screen, 0, BSSpace.screen, 12),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: BSProg(pct: 100, hue: 'pro'),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BSOverline('BODY FAT'),
                    const SizedBox(height: 8),
                    BSHero(
                      value: r.fat != null ? fmt1(r.fat!) : '—',
                      unit: '%',
                      size: 58,
                      right: r.fat != null && prevFat != null && _prev != null
                          ? '${fmtDelta1(r.fat! - prevFat)} pt since ${fmtDayShort(_prev!.date)}'
                          : null,
                      hue: r.fat != null &&
                              prevFat != null &&
                              r.fat! - prevFat < 0
                          ? 'cal'
                          : null,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 2),
                child: BSM2(_methodCopy(store, r)),
              ),
              const BSSecHead('RECALCULATED'),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: BSTiles(tiles: [
                  BSStatTile(
                    label: 'Body fat',
                    value: r.fat != null ? fmt1(r.fat!) : '—',
                    unit: '%',
                    note: _override?.source ?? 'estimated',
                    hue: 'pro',
                  ),
                  BSStatTile(
                    label: 'Lean mass',
                    value: r.lean != null
                        ? fmt1(Units.of(store.settings).kgOut(r.lean!))
                        : '—',
                    unit: Units.of(store.settings).weightUnit,
                    note: 'estimated',
                    hue: 'cal',
                  ),
                  BSStatTile(
                    label: 'BMR',
                    value: r.bmr != null ? fmtKcal(r.bmr!) : '—',
                    unit: 'kcal',
                    note: Formulas.bmrSource(r.lean,
                        overrideKcal: store.profile.bmrOverrideKcal),
                    hue: 'carb',
                  ),
                  BSStatTile(
                    label: 'TDEE',
                    value: r.tdee != null ? fmtKcal(r.tdee!) : '—',
                    unit: 'kcal',
                    note: _activityNote(store.profile.activity),
                    hue: 'fat',
                  ),
                ]),
              ),
              if (changed.isNotEmpty) ...[
                const BSSecHead('CHANGED BY THIS CHECK-IN'),
                for (var i = 0; i < changed.length; i++)
                  BSListRow(
                    first: i == 0,
                    title: changed[i].title,
                    meta: changed[i].meta,
                    value: changed[i].value,
                    valueMeta: changed[i].unit,
                  ),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: BSM2(
                  'Your calorie target stays at ${fmtKcal(store.targets.kcal)} until you change it in Settings.',
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.fromLTRB(BSSpace.screen, 0, BSSpace.screen, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BSButton(
                'Save check-in',
                variant: BSButtonVariant.solid,
                size: BSButtonSize.lg,
                block: true,
                onTap: _save,
              ),
              const SizedBox(height: 10),
              BSButton(
                'Enter a value I already know',
                variant: BSButtonVariant.quiet,
                hue: 'pro',
                block: true,
                onTap: _openOverride,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _methodCopy(
    AppStore store,
    ({
      double? neck,
      double? waist,
      double? hip,
      double? estimate,
      double? fat,
      double? lean,
      double? bmr,
      double? tdee,
    }) r,
  ) {
    final profile = store.profile;
    if (r.estimate == null ||
        r.neck == null ||
        r.waist == null ||
        profile.heightCm == null) {
      return "Body fat needs neck, waist and height on file. Skipped values keep the last check-in's figure.";
    }
    final h = fmtG(profile.heightCm!);
    final neck = fmt1(r.neck!);
    final waist = fmt1(r.waist!);
    if (profile.sex == Sex.female && r.hip == null) {
      return 'Estimated with the U.S. Navy circumference method from neck $neck and waist $waist cm at $h cm tall. Hip was skipped, so a default ratio stands in — expect ±3 points.';
    }
    if (profile.sex == Sex.female) {
      return 'Estimated with the U.S. Navy circumference method from neck $neck, waist $waist and hip ${fmt1(r.hip!)} cm at $h cm tall.';
    }
    return 'Estimated with the U.S. Navy circumference method from neck $neck and waist $waist cm at $h cm tall.';
  }

  String _activityNote(ActivityLevel a) => a == ActivityLevel.veryActive
      ? 'very active'
      : '${a.label.toLowerCase()} activity';

  String _fmtDeltaInt(num v) {
    final n = v.round();
    if (n > 0) return '+$n';
    if (n < 0) return '−${n.abs()}';
    return '0';
  }
}
