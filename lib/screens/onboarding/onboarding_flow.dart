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
import '../../widgets/bs_empty.dart';
import '../../widgets/bs_field.dart';
import '../../widgets/bs_icon.dart';
import '../../widgets/bs_list_row.dart';
import '../../widgets/bs_stat_tile.dart';
import '../../widgets/bs_toggle.dart';
import '../body/override_sheet.dart';

enum _Step {
  welcome,
  basics,
  weight,
  activity,
  measure,
  estimates,
  targets,
  reminder,
  theme,
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  _Step _step = _Step.welcome;

  Sex? _sex;
  final _age = TextEditingController();
  final _height = TextEditingController();
  bool _metric = true;

  String _weightStr = '0';
  String _weightUnit = 'Kilograms';

  ActivityLevel _activity = ActivityLevel.moderate;

  final _neck = TextEditingController();
  final _waist = TextEditingController();
  final _hip = TextEditingController();
  OverrideResult? _fatOverride;
  double? _bmrOverride;

  String _goal = 'Hold';
  String _split = 'Balanced';
  bool _calEdited = false;
  final _cal = TextEditingController();
  final _p = TextEditingController();
  final _c = TextEditingController();
  final _f = TextEditingController();

  int _remHour = 21;
  int _remMinute = 0;
  bool _remDaily = true;
  bool _remCheckin = true;

  String _theme = 'system';

  @override
  void initState() {
    super.initState();
    _metric = !context.read<AppStore>().settings.imperial;
    if (!_metric) _weightUnit = 'Pounds';
  }

  @override
  void dispose() {
    for (final ctrl in [_age, _height, _neck, _waist, _hip, _cal, _p, _c, _f]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  int? get _ageV => int.tryParse(_age.text.trim());

  String get _lenUnit => _metric ? 'cm' : 'in';

  double? get _heightV => _cmOf(_height);

  double? get _weightKg {
    final v = double.tryParse(_weightStr);
    if (v == null || v <= 0) return null;
    return _weightUnit == 'Pounds' ? v * 0.45359237 : v;
  }

  double? _cmOf(TextEditingController ctrl) {
    final v = double.tryParse(ctrl.text.trim());
    if (v == null || v <= 0) return null;
    return _metric ? v : v * 2.54;
  }

  double? get _estimate => Formulas.navyBodyFat(
        sex: _sex,
        heightCm: _heightV,
        neckCm: _cmOf(_neck),
        waistCm: _cmOf(_waist),
        hipCm: _cmOf(_hip),
      );

  double? get _fat => _fatOverride?.value ?? _estimate;

  double? get _bmr => Formulas.bmr(
        sex: _sex,
        age: _ageV,
        heightCm: _heightV,
        weightKg: _weightKg,
        fatPct: _fat,
        overrideKcal: _bmrOverride,
      );

  double? get _tdee => Formulas.tdee(_bmr, _activity);

  double? get _lean => Formulas.leanMass(_weightKg, _fat);

  void _go(_Step s) {
    if (s == _Step.targets) _seedTargets();
    setState(() => _step = s);
  }

  _Step get _back => switch (_step) {
        _Step.basics => _Step.welcome,
        _Step.weight => _Step.basics,
        _Step.activity => _Step.weight,
        _Step.measure => _Step.activity,
        _Step.estimates => _Step.measure,
        _Step.targets => _Step.estimates,
        _Step.reminder => _Step.targets,
        _ => _Step.reminder,
      };

  Future<void> _skipEverything() async {
    await context.read<AppStore>().finishOnboarding();
  }

  Future<void> _finish() async {
    final store = context.read<AppStore>();
    final notif = context.read<NotificationService>();
    final today = dayOnly(DateTime.now());
    final w = _weightKg;

    await store.saveProfile(Profile(
      age: _ageV,
      sex: _sex,
      heightCm: _heightV,
      activity: _activity,
      bmrOverrideKcal: _bmrOverride,
    ));
    await store.saveTargets(Targets(
      kcal: double.tryParse(_cal.text.trim()) ?? 2000,
      p: double.tryParse(_p.text.trim()) ?? 125,
      c: double.tryParse(_c.text.trim()) ?? 225,
      f: double.tryParse(_f.text.trim()) ?? 67,
    ));
    await store.saveSettings(store.settings.copyWith(
      themeMode: _theme,
      reminderOn: _remDaily,
      reminderHour: _remHour,
      reminderMinute: _remMinute,
      checkinNudgeOn: _remCheckin,
    ));
    if (w != null) {
      await store.setWeight(today, w);
      await store.addSnapshot(BodySnapshot(
        date: today,
        weightKg: w,
        neckCm: _cmOf(_neck),
        waistCm: _cmOf(_waist),
        hipCm: _cmOf(_hip),
        bodyFatPct: _fat,
        leanKg: _lean,
        bmr: _bmr,
        tdee: _tdee,
        overrideSource: _fatOverride?.source,
        estimatedFatPct: _fatOverride != null ? _estimate : null,
      ));
    }
    await store.finishOnboarding();
    await notif.sync(store);
  }

  void _seedTargets() {
    if (_calEdited) return;
    final kcal = Formulas.roundTarget((_tdee ?? 2000) + _goalAdjust);
    _cal.text = kcal.round().toString();
    _applySplit(kcal);
  }

  double get _goalAdjust => switch (_goal) {
        'Lose' => -250.0,
        'Gain' => 250.0,
        _ => 0.0,
      };

  void _setGoal(String g) {
    setState(() {
      _goal = g;
      final kcal = Formulas.roundTarget((_tdee ?? 2000) + _goalAdjust);
      _cal.text = kcal.round().toString();
      _calEdited = false;
      _applySplit(kcal);
    });
  }

  void _applySplit(double kcal) {
    if (_split == 'Custom') return;
    final t = _split == 'Balanced'
        ? Targets.balanced(kcal)
        : Targets.higherProtein(kcal);
    _p.text = t.p.round().toString();
    _c.text = t.c.round().toString();
    _f.text = t.f.round().toString();
  }

  void _setSplit(String s) {
    setState(() {
      _split = s;
      final kcal = double.tryParse(_cal.text.trim());
      if (kcal != null) _applySplit(kcal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: switch (_step) {
          _Step.welcome => _welcome(context),
          _Step.basics => _basics(context),
          _Step.weight => _weight(context),
          _Step.activity => _activityStep(context),
          _Step.measure => _measure(context),
          _Step.estimates =>
            _fat != null ? _estimates(context) : _noEstimates(context),
          _Step.targets => _targets(context),
          _Step.reminder => _reminder(context),
          _Step.theme => _themeStep(context),
        },
      ),
    );
  }

  Widget _chrome({
    required String title,
    required String sub,
    double? progress,
    required List<Widget> children,
    required List<Widget> actions,
  }) {
    return Column(
      children: [
        BSTitleBar(
          title: title,
          sub: sub,
          icon: 'chevronLeft',
          onIconTap: () => _go(_back),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                BSSpace.screen, 0, BSSpace.screen, 12),
            children: [
              if (progress != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: BSProg(pct: progress, hue: 'pro'),
                ),
              ...children,
            ],
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.fromLTRB(BSSpace.screen, 0, BSSpace.screen, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                actions[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _welcome(BuildContext context) {
    final c = context.bs;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  BSSpace.screen, 20, BSSpace.screen, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BodySync',
                    style: TextStyle(
                      fontFamily: BSType.font,
                      fontSize: 42,
                      fontWeight: BSType.wHeavy,
                      height: 1,
                      letterSpacing: -.035 * 42,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      'A private log of what you eat, what you weigh, and the days you trained. Everything is stored on this phone — there is no account and nothing is uploaded.',
                      style: TextStyle(
                        fontFamily: BSType.font,
                        fontSize: BSType.body,
                        height: 1.55,
                        color: c.ink2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  BSRule(
                    padding: const EdgeInsets.only(top: 18),
                    child: Column(
                      children: [
                        _welcomeRow(c, 'ruler', 'Six questions',
                            'Age, height, weight, activity and three tape measurements.'),
                        const SizedBox(height: 12),
                        _welcomeRow(c, 'target', 'Two estimates',
                            'Body fat and lean mass, then BMR and daily energy from them.'),
                        const SizedBox(height: 12),
                        _welcomeRow(c, 'clock', 'One minute',
                            'Skip anything you would rather not answer.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.fromLTRB(BSSpace.screen, 0, BSSpace.screen, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BSButton(
                'Set up',
                variant: BSButtonVariant.solid,
                size: BSButtonSize.lg,
                block: true,
                onTap: () => _go(_Step.basics),
              ),
              const SizedBox(height: 10),
              BSButton(
                'Skip — just let me log',
                variant: BSButtonVariant.quiet,
                block: true,
                onTap: _skipEverything,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _welcomeRow(BSColors c, String icon, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: BSIcon(icon, size: 19, color: c.calInk),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: BSType.font,
                  fontSize: BSType.bodySm,
                  fontWeight: BSType.wBold,
                  height: 1.3,
                  color: c.ink,
                ),
              ),
              Text(
                body,
                style: TextStyle(
                  fontFamily: BSType.font,
                  fontSize: BSType.meta,
                  height: 1.45,
                  color: c.ink2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _basics(BuildContext context) {
    return _chrome(
      title: 'About you',
      sub: '1 of 6',
      progress: 1 / 6 * 100,
      children: [
        const SizedBox(height: 16),
        const BSOverline('SEX'),
        const SizedBox(height: 8),
        BSSeg(
          items: const ['Female', 'Male'],
          value: switch (_sex) {
            Sex.female => 'Female',
            Sex.male => 'Male',
            null => null,
          },
          onChanged: (v) =>
              setState(() => _sex = v == 'Female' ? Sex.female : Sex.male),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BSField(
                label: 'Age',
                controller: _age,
                unit: 'years',
                placeholder: '0',
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: BSField(
                label: 'Height',
                controller: _height,
                unit: _lenUnit,
                placeholder: '0',
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const BSM2(
          'These start the BMR estimate with Mifflin-St Jeor, the formula behind most online calculators. Tape measurements later upgrade it to Katch-McArdle, which works from lean mass. Nothing here is shared, and everything can be changed later in Settings.',
        ),
        const BSSecHead('UNITS', right: 'optional'),
        BSListRow(
          first: true,
          title: 'Metric',
          meta: 'kg, cm, kcal',
          value: _metric ? '✓' : null,
          chevron: !_metric,
          onTap: () => _setUnits(metric: true),
        ),
        BSListRow(
          title: 'Imperial',
          meta: 'lb, in, kcal',
          value: _metric ? null : '✓',
          chevron: _metric,
          onTap: () => _setUnits(metric: false),
        ),
      ],
      actions: [
        BSButton(
          'Continue',
          variant: BSButtonVariant.solid,
          size: BSButtonSize.lg,
          block: true,
          onTap: () => _go(_Step.weight),
        ),
        BSButton(
          'Skip — estimates get rougher',
          variant: BSButtonVariant.quiet,
          block: true,
          onTap: () {
            setState(() {
              _sex = null;
              _age.clear();
              _height.clear();
            });
            _go(_Step.weight);
          },
        ),
      ],
    );
  }

  void _setUnits({required bool metric}) {
    if (metric == _metric) return;
    setState(() {
      _metric = metric;
      _weightUnit = metric ? 'Kilograms' : 'Pounds';
    });
    final store = context.read<AppStore>();
    store.saveSettings(
        store.settings.copyWith(units: metric ? 'metric' : 'imperial'));
  }

  void _weightKey(String k) {
    setState(() {
      if (k == 'back') {
        _weightStr = _weightStr.length > 1
            ? _weightStr.substring(0, _weightStr.length - 1)
            : '0';
        if (_weightStr.endsWith('.')) {
          _weightStr = _weightStr.substring(0, _weightStr.length - 1);
        }
      } else if (k == '.') {
        if (!_weightStr.contains('.')) _weightStr += '.';
      } else {
        if (_weightStr == '0') {
          _weightStr = k;
        } else {
          final dot = _weightStr.indexOf('.');
          if (dot < 0 && _weightStr.length >= 3) return;
          if (dot >= 0 && _weightStr.length - dot > 1) return;
          _weightStr += k;
        }
      }
    });
  }

  void _setWeightUnit(String u) {
    if (u == _weightUnit) return;
    setState(() {
      final v = double.tryParse(_weightStr);
      if (v != null && v > 0) {
        _weightStr = fmt1(u == 'Pounds' ? v * 2.20462262 : v / 2.20462262);
      }
      _weightUnit = u;
      _metric = u == 'Kilograms';
    });
    final store = context.read<AppStore>();
    store.saveSettings(
        store.settings.copyWith(units: _metric ? 'metric' : 'imperial'));
  }

  Widget _weight(BuildContext context) {
    return _chrome(
      title: 'Current weight',
      sub: '2 of 6',
      progress: 2 / 6 * 100,
      children: [
        const SizedBox(height: 10),
        BSKeypad(
          label: 'WEIGHT',
          value: _weightStr,
          unit: _weightUnit == 'Pounds' ? 'lb' : 'kg',
          onKey: _weightKey,
        ),
        const SizedBox(height: 18),
        BSSeg(
          items: const ['Kilograms', 'Pounds'],
          value: _weightUnit,
          onChanged: _setWeightUnit,
        ),
        const SizedBox(height: 16),
        const BSM2(
          'This becomes the first point on the weight trend and the weight the estimates use.',
        ),
      ],
      actions: [
        BSButton(
          'Continue',
          variant: BSButtonVariant.solid,
          size: BSButtonSize.lg,
          block: true,
          onTap: _weightKg == null ? null : () => _go(_Step.activity),
        ),
      ],
    );
  }

  Widget _activityStep(BuildContext context) {
    final c = context.bs;
    return _chrome(
      title: 'Activity',
      sub: '3 of 6',
      progress: 3 / 6 * 100,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 2),
          child: BSM2(
            _bmr != null
                ? 'Everyday movement, not just training. Each level multiplies your ${fmtKcal(_bmr!)} kcal BMR (${Formulas.bmrSource(_lean, overrideKcal: _bmrOverride)}) into daily energy use.'
                : 'Everyday movement, not just training. This multiplies BMR into daily energy use.',
          ),
        ),
        const BSSecHead('PICK THE CLOSEST', right: 'daily energy'),
        for (var i = 0; i < ActivityLevel.values.length; i++)
          BSListRow(
            first: i == 0,
            title: ActivityLevel.values[i].label,
            meta: ActivityLevel.values[i].description,
            tag: '×${ActivityLevel.values[i].multiplier}',
            value: _bmr != null
                ? fmtKcal(_bmr! * ActivityLevel.values[i].multiplier)
                : '—',
            valueMeta: 'kcal',
            trailing: _activity == ActivityLevel.values[i]
                ? BSIcon('check', size: 19, color: c.calInk)
                : null,
            onTap: () => setState(() => _activity = ActivityLevel.values[i]),
          ),
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: BSM2(
              'Change it whenever your weeks change — the target follows.'),
        ),
      ],
      actions: [
        BSButton(
          'Continue',
          variant: BSButtonVariant.solid,
          size: BSButtonSize.lg,
          block: true,
          onTap: () => _go(_Step.measure),
        ),
      ],
    );
  }

  Widget _measure(BuildContext context) {
    return _chrome(
      title: 'Measurements',
      sub: '4 of 6',
      progress: 4 / 6 * 100,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 18),
          child: BSM2(
            'Three circumferences estimate body fat with the U.S. Navy method. A soft tape is enough. You will be asked again every 30 days.',
          ),
        ),
        BSField(
          label: 'Neck',
          controller: _neck,
          unit: _lenUnit,
          placeholder: '0.0',
          hint: 'Below the larynx, tape sloping slightly down at the front',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        BSField(
          label: 'Waist',
          controller: _waist,
          unit: _lenUnit,
          placeholder: '0.0',
          hint: 'At the navel, relaxed, at the end of a normal breath',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        BSField(
          label: 'Hip',
          controller: _hip,
          unit: _lenUnit,
          placeholder: '0.0',
          hint: 'At the widest point, feet together',
          onChanged: (_) => setState(() {}),
        ),
      ],
      actions: [
        BSButton(
          'See my estimates',
          variant: BSButtonVariant.solid,
          size: BSButtonSize.lg,
          block: true,
          onTap: () => _go(_Step.estimates),
        ),
        BSButton(
          'Skip measurements',
          variant: BSButtonVariant.quiet,
          block: true,
          onTap: () {
            _neck.clear();
            _waist.clear();
            _hip.clear();
            _go(_Step.estimates);
          },
        ),
      ],
    );
  }

  Future<void> _openOverride() async {
    final r = await showOverrideSheet(
      context,
      estimate: _estimate,
      initialSource: _fatOverride?.source,
    );
    if (!mounted) return;
    setState(() => _fatOverride = r);
  }

  Future<void> _openBmrOverride() async {
    final r = await _showBmrSheet(context, current: _bmrOverride);
    if (!mounted || r == null) return;
    setState(() => _bmrOverride = r.kcal);
  }

  String _estimateCopy() {
    if (_estimate == null && _fatOverride != null) {
      return 'From your ${_fatOverride!.source} reading of ${fmt1(_fatOverride!.value)} % — the tape measurements were skipped.';
    }
    final neck = fmt1(_cmOf(_neck)!);
    final waist = fmt1(_cmOf(_waist)!);
    final h = fmtG(_heightV!);
    final hip = _cmOf(_hip);
    if (_sex == Sex.female && hip == null) {
      return 'From neck $neck, waist $waist cm and height $h cm, using the U.S. Navy circumference method. Hip was skipped, so a default ratio stands in — expect ±3 points.';
    }
    if (_sex == Sex.female) {
      return 'From neck $neck, waist $waist and hip ${fmt1(hip!)} cm and height $h cm, using the U.S. Navy circumference method.';
    }
    return 'From neck $neck, waist $waist cm and height $h cm, using the U.S. Navy circumference method.';
  }

  Widget _estimates(BuildContext context) {
    return _chrome(
      title: 'Your estimates',
      sub: '5 of 6',
      progress: 5 / 6 * 100,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BSOverline('BODY FAT'),
              const SizedBox(height: 8),
              BSHero(
                value: fmt1(_fat!),
                unit: '%',
                size: 58,
                right: _lean != null ? '${fmt1(_lean!)} kg lean' : null,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 2),
          child: BSM2(_estimateCopy()),
        ),
        const BSSecHead('CALCULATED FOR YOU'),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: BSTiles(tiles: [
            BSStatTile(
              label: 'Body fat',
              value: fmt1(_fat!),
              unit: '%',
              note: _fatOverride?.source ?? 'estimated',
              hue: 'pro',
            ),
            BSStatTile(
              label: 'Lean mass',
              value: _lean != null ? fmt1(Units(!_metric).kgOut(_lean!)) : '—',
              unit: Units(!_metric).weightUnit,
              note: 'estimated',
              hue: 'cal',
            ),
            BSStatTile(
              label: 'BMR',
              value: _bmr != null ? fmtKcal(_bmr!) : '—',
              unit: 'kcal',
              note: Formulas.bmrSource(_lean, overrideKcal: _bmrOverride),
              hue: 'carb',
            ),
            BSStatTile(
              label: 'TDEE',
              value: _tdee != null ? fmtKcal(_tdee!) : '—',
              unit: 'kcal',
              note: '${_activity.label.toLowerCase()} ×${_activity.multiplier}',
              hue: 'fat',
            ),
          ]),
        ),
        const BSSecHead('IF YOU ALREADY KNOW BETTER', right: 'optional'),
        BSListRow(
          first: true,
          title: 'Body fat from a scale or scan',
          meta: 'Overrides the estimate',
          chevron: true,
          onTap: _openOverride,
        ),
        BSListRow(
          title: 'BMR from a metabolic test',
          meta: 'Overrides the formula',
          value: _bmrOverride != null ? fmtKcal(_bmrOverride!) : null,
          valueMeta: _bmrOverride != null ? 'kcal' : null,
          chevron: true,
          onTap: _openBmrOverride,
        ),
      ],
      actions: [
        BSButton(
          'These look right',
          variant: BSButtonVariant.solid,
          size: BSButtonSize.lg,
          block: true,
          onTap: () => _go(_Step.targets),
        ),
        BSButton(
          'Enter a value I know',
          variant: BSButtonVariant.quiet,
          hue: 'pro',
          block: true,
          onTap: _openOverride,
        ),
      ],
    );
  }

  Widget _noEstimates(BuildContext context) {
    return _chrome(
      title: 'Your estimates',
      sub: '5 of 6',
      progress: 5 / 6 * 100,
      children: [
        const SizedBox(height: 8),
        BSEmpty(
          icon: 'ruler',
          hue: 'pro',
          title: 'No body composition yet',
          body:
              'Body fat and lean mass need neck, waist and hip. Everything else is ready, and a check-in can add them any time.',
          action: BSButton(
            'Measure now — one minute',
            variant: BSButtonVariant.tint,
            hue: 'pro',
            onTap: () => _go(_Step.measure),
          ),
        ),
        const BSSecHead('STILL CALCULATED'),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: BSTiles(tiles: [
            BSStatTile(
              label: 'BMR',
              value: _bmr != null ? fmtKcal(_bmr!) : '—',
              unit: 'kcal',
              note: Formulas.bmrSource(_lean, overrideKcal: _bmrOverride),
              hue: 'carb',
            ),
            BSStatTile(
              label: 'TDEE',
              value: _tdee != null ? fmtKcal(_tdee!) : '—',
              unit: 'kcal',
              note: '${_activity.label.toLowerCase()} ×${_activity.multiplier}',
              hue: 'fat',
            ),
          ]),
        ),
        const BSSecHead('WAITING ON MEASUREMENTS'),
        const BSListRow(
          first: true,
          title: 'Body fat',
          meta: 'Needs neck, waist, hip',
          value: '—',
        ),
        const BSListRow(
          title: 'Lean mass',
          meta: 'Needs body fat',
          value: '—',
        ),
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: BSM2(
              'The Body tab will show these as missing rather than guessing.'),
        ),
      ],
      actions: [
        BSButton(
          'Continue without them',
          variant: BSButtonVariant.solid,
          size: BSButtonSize.lg,
          block: true,
          onTap: () => _go(_Step.targets),
        ),
      ],
    );
  }

  Widget _targets(BuildContext context) {
    final kcal = double.tryParse(_cal.text.trim());
    final p = double.tryParse(_p.text.trim());
    final carbs = double.tryParse(_c.text.trim());
    final f = double.tryParse(_f.text.trim());

    return _chrome(
      title: 'Daily targets',
      sub: '6 of 6',
      progress: 100,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 14),
          child: BSM2(
            _tdee != null
                ? 'Starting from your ${fmtKcal(_tdee!)} kcal daily energy use. Hold it to stay level, or take a deficit to lose about 0.25 kg a week.'
                : 'Without your basics, a 2,000 kcal default stands in. Hold it to stay level, or take a deficit to lose about 0.25 kg a week.',
          ),
        ),
        BSChips(
          items: const ['Lose', 'Hold', 'Gain'],
          value: _goal,
          onChanged: _setGoal,
        ),
        const SizedBox(height: 16),
        BSField(
          label: 'Calories',
          controller: _cal,
          unit: 'kcal',
          placeholder: '0',
          hint: _tdee == null
              ? null
              : switch (_goal) {
                  'Lose' => 'A 250 kcal deficit, rounded down.',
                  'Gain' => 'A 250 kcal surplus, rounded down.',
                  _ => 'Rounded down from ${fmtKcal(_tdee!)}.',
                },
          onChanged: (_) => setState(() {
            _calEdited = true;
            final v = double.tryParse(_cal.text.trim());
            if (v != null) _applySplit(v);
          }),
        ),
        const SizedBox(height: 14),
        const BSOverline('MACRO SPLIT'),
        const SizedBox(height: 8),
        BSSeg(
          items: const ['Balanced', 'Higher protein', 'Custom'],
          value: _split,
          onChanged: _setSplit,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: BSField(
                label: 'Protein',
                controller: _p,
                unit: 'g',
                placeholder: '0',
                onChanged: (_) => setState(() => _split = 'Custom'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: BSField(
                label: 'Carbs',
                controller: _c,
                unit: 'g',
                placeholder: '0',
                onChanged: (_) => setState(() => _split = 'Custom'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: BSField(
                label: 'Fat',
                controller: _f,
                unit: 'g',
                placeholder: '0',
                onChanged: (_) => setState(() => _split = 'Custom'),
              ),
            ),
          ],
        ),
        if (kcal != null && p != null && carbs != null && f != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _arithmeticBanner(kcal, p, carbs, f),
          ),
      ],
      actions: [
        BSButton(
          'Save targets',
          variant: BSButtonVariant.solid,
          size: BSButtonSize.lg,
          block: true,
          onTap: kcal == null ? null : () => _go(_Step.reminder),
        ),
      ],
    );
  }

  Widget _arithmeticBanner(double kcal, double p, double carbs, double f) {
    final sum = p * 4 + carbs * 4 + f * 9;
    final diff = (kcal - sum).round();
    final lead =
        '${fmtG(p)} P and ${fmtG(carbs)} C at 4 kcal, ${fmtG(f)} F at 9 kcal add up to ${fmtKcal(sum)}';
    if (diff == 0) {
      return BSBanner(
        tone: BSBannerTone.ok,
        icon: 'check',
        body: '$lead — exactly the target.',
      );
    }
    final word = diff > 0 ? 'under' : 'over';
    if (diff.abs() <= 60) {
      return BSBanner(
        tone: BSBannerTone.ok,
        icon: 'check',
        body:
            '$lead — ${diff.abs()} $word the target, which is close enough to round.',
      );
    }
    return BSBanner(
      tone: BSBannerTone.warn,
      icon: 'info',
      body:
          '$lead — ${diff.abs()} $word the target. Nudge a macro or the calories.',
    );
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _remHour, minute: _remMinute),
    );
    if (t == null || !mounted) return;
    setState(() {
      _remHour = t.hour;
      _remMinute = t.minute;
    });
  }

  Future<void> _allowAndFinish() async {
    final notif = context.read<NotificationService>();
    await notif.requestPermission();
    if (!mounted) return;
    _go(_Step.theme);
  }

  Widget _reminder(BuildContext context) {
    final c = context.bs;
    final time =
        '${_remHour.toString().padLeft(2, '0')}:${_remMinute.toString().padLeft(2, '0')}';
    return _chrome(
      title: 'Weight reminder',
      sub: '6 of 6',
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 10, bottom: 18),
          child: BSM2(
            'If no weight is logged by this time, BodySync sends one reminder. Log before then and nothing fires.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  time,
                  style: TextStyle(
                    fontFamily: BSType.font,
                    fontSize: 56,
                    fontWeight: BSType.wRegular,
                    height: 1,
                    letterSpacing: BSType.trHero * 56,
                    color: c.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              BSIconButton(icon: 'edit', onTap: _pickTime),
            ],
          ),
        ),
        BSListRow(
          first: true,
          title: 'Daily reminder',
          meta: 'Only when the day has no weight',
          trailing: BSToggle(
            value: _remDaily,
            onChanged: (v) => setState(() => _remDaily = v),
          ),
        ),
        BSListRow(
          title: '30-day check-in',
          meta: 'One nudge when measurements are due',
          trailing: BSToggle(
            value: _remCheckin,
            onChanged: (v) => setState(() => _remCheckin = v),
          ),
        ),
        const BSListRow(
          title: 'Anything else',
          meta: 'There is nothing else — no streaks, no summaries',
          trailing: BSToggle(value: false, onChanged: null),
        ),
        const BSBanner(
          tone: BSBannerTone.info,
          icon: 'bell',
          title: 'iOS will ask next',
          body:
              'Allow notifications on the system prompt or the reminder stays off. It can be turned on later in Settings.',
          margin: EdgeInsets.only(top: 18),
        ),
      ],
      actions: [
        BSButton(
          'Allow and finish',
          variant: BSButtonVariant.solid,
          size: BSButtonSize.lg,
          block: true,
          onTap: _allowAndFinish,
        ),
        BSButton(
          'No reminders',
          variant: BSButtonVariant.quiet,
          block: true,
          onTap: () {
            setState(() {
              _remDaily = false;
              _remCheckin = false;
            });
            _go(_Step.theme);
          },
        ),
      ],
    );
  }

  Future<void> _setTheme(String mode) async {
    setState(() => _theme = mode);
    final store = context.read<AppStore>();
    await store.saveSettings(store.settings.copyWith(themeMode: mode));
  }

  Widget _themeStep(BuildContext context) {
    final kcal = double.tryParse(_cal.text.trim());
    final p = double.tryParse(_p.text.trim());
    final carbs = double.tryParse(_c.text.trim());
    final f = double.tryParse(_f.text.trim());
    final due = dayOnly(DateTime.now()).add(const Duration(days: 30));
    final time =
        '${_remHour.toString().padLeft(2, '0')}:${_remMinute.toString().padLeft(2, '0')}';

    final estimateParts = <String>[
      if (_fat != null) '${fmt1(_fat!)} % body fat',
      if (_tdee != null) '${fmtKcal(_tdee!)} kcal TDEE',
    ];

    return _chrome(
      title: 'Appearance',
      sub: '6 of 6',
      children: [
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ThemeSwatch(
                  tokens: BSColors.light,
                  label: 'Light',
                  selected: _theme == 'light',
                  onTap: () => _setTheme('light'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ThemeSwatch(
                  tokens: BSColors.dark,
                  label: 'Dark',
                  selected: _theme == 'dark',
                  onTap: () => _setTheme('dark'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BSSeg(
          items: const ['System', 'Light', 'Dark'],
          value: switch (_theme) {
            'light' => 'Light',
            'dark' => 'Dark',
            _ => 'System',
          },
          onChanged: (v) => _setTheme(v.toLowerCase()),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 14),
          child: BSM2(
            'Following the system means the app turns dark with the phone at sunset. Pick one to pin it instead.',
          ),
        ),
        const BSSecHead('READY'),
        BSListRow(
          first: true,
          title: 'Targets',
          meta: kcal != null && p != null && carbs != null && f != null
              ? '${fmtKcal(kcal)} kcal · ${fmtG(p)} P · ${fmtG(carbs)} C · ${fmtG(f)} F'
              : 'Defaults',
          value: '✓',
        ),
        BSListRow(
          title: 'Estimates',
          meta: estimateParts.isNotEmpty
              ? estimateParts.join(' · ')
              : 'Skipped — a check-in can add them',
          value: estimateParts.isNotEmpty ? '✓' : '—',
        ),
        BSListRow(
          title: 'Reminder',
          meta: _remDaily ? '$time, only when weight is missing' : 'Off',
          value: _remDaily ? '✓' : '—',
        ),
        BSListRow(
          title: 'First check-in',
          meta: 'Due ${fmtDayMonth(due)}',
          value: '30',
          valueMeta: 'days',
        ),
      ],
      actions: [
        BSButton(
          'Start logging',
          variant: BSButtonVariant.solid,
          size: BSButtonSize.lg,
          block: true,
          onTap: _finish,
        ),
      ],
    );
  }
}

Future<({double? kcal})?> _showBmrSheet(
  BuildContext context, {
  double? current,
}) {
  return showBSSheet<({double? kcal})>(
    context,
    title: 'BMR',
    sub: 'from a metabolic test',
    builder: (_) => _BmrSheetBody(current: current),
  );
}

class _BmrSheetBody extends StatefulWidget {
  final double? current;

  const _BmrSheetBody({this.current});

  @override
  State<_BmrSheetBody> createState() => _BmrSheetBodyState();
}

class _BmrSheetBodyState extends State<_BmrSheetBody> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.current?.round().toString() ?? '',
  );

  double? get _value {
    final v = double.tryParse(_ctrl.text.trim());
    if (v == null || v < 500 || v > 5000) return null;
    return v;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = _value;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BSField(
            label: 'BMR',
            controller: _ctrl,
            unit: 'kcal',
            placeholder: '0',
            hint: 'Replaces the estimate everywhere.',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          BSButton(
            v != null ? 'Use ${fmtKcal(v)} kcal' : 'Use this value',
            variant: BSButtonVariant.solid,
            size: BSButtonSize.lg,
            block: true,
            onTap: v == null
                ? null
                : () => Navigator.of(context).pop<({double? kcal})>((kcal: v)),
          ),
          const SizedBox(height: 10),
          if (widget.current != null)
            BSButton(
              'Use the estimate instead',
              variant: BSButtonVariant.quiet,
              block: true,
              onTap: () =>
                  Navigator.of(context).pop<({double? kcal})>((kcal: null)),
            )
          else
            BSButton(
              'Keep the estimate',
              variant: BSButtonVariant.quiet,
              block: true,
              onTap: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  final BSColors tokens;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeSwatch({
    required this.tokens,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: BSMotion.base,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.bg,
          border: Border.all(
            color: selected ? tokens.ink : tokens.line,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(BSRadius.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FractionallySizedBox(
              widthFactor: .62,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: tokens.ink,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 7),
            FractionallySizedBox(
              widthFactor: .84,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: tokens.ink3,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                for (final hue in [
                  tokens.cal,
                  tokens.pro,
                  tokens.carb,
                  tokens.fat,
                ])
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(right: 5),
                    decoration:
                        BoxDecoration(color: hue, shape: BoxShape.circle),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                fontFamily: BSType.font,
                fontSize: BSType.micro,
                fontWeight: BSType.wBold,
                height: 1,
                color: tokens.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
