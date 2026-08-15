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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppStore get _store => context.read<AppStore>();

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    final store = context.watch<AppStore>();
    final units = Units.of(store.settings);
    final profile = store.profile;
    final stats = store.currentBodyStats();
    final weights = store.weightEntries();
    final activity = profile.activity;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            BSTitleBar(
              title: 'Profile',
              icon: 'chevronLeft',
              onIconTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    BSSpace.screen, 0, BSSpace.screen, BSSpace.s6),
                children: [
                  const BSSecHead('BASICS', right: 'feeds the estimates'),
                  BSListRow(
                    first: true,
                    title: 'Sex',
                    meta: 'Mifflin-St Jeor uses it',
                    value: profile.sex != null ? _sexLabel(profile.sex!) : null,
                    valueWidget: profile.sex == null ? _notSet(context) : null,
                    chevron: true,
                    onTap: _editSex,
                  ),
                  BSListRow(
                    title: 'Age',
                    meta: 'Mifflin-St Jeor uses it',
                    value: profile.age?.toString(),
                    valueWidget: profile.age == null ? _notSet(context) : null,
                    valueMeta: profile.age != null ? 'years' : null,
                    chevron: true,
                    onTap: _editAge,
                  ),
                  BSListRow(
                    title: 'Height',
                    value: profile.heightCm != null
                        ? fmtG(units.cmOut(profile.heightCm!))
                        : null,
                    valueWidget:
                        profile.heightCm == null ? _notSet(context) : null,
                    valueMeta:
                        profile.heightCm != null ? units.lengthUnit : null,
                    chevron: true,
                    onTap: _editHeight,
                  ),
                  if (weights.isNotEmpty) ...[
                    const BSSecHead('STARTING POINT'),
                    BSListRow(
                      first: true,
                      title: 'Starting weight',
                      meta: fmtDayFull(weights.first.key),
                      value: fmt1(units.kgOut(weights.first.value)),
                      valueMeta: units.weightUnit,
                    ),
                    BSListRow(
                      title: 'Today',
                      meta: fmtDayFull(weights.last.key),
                      value: fmt1(units.kgOut(weights.last.value)),
                      valueMeta: units.weightUnit,
                    ),
                    if (weights.length > 1)
                      BSListRow(
                        title: 'Change',
                        valueWidget: Text(
                          fmtDelta1(units
                              .kgOut(weights.last.value - weights.first.value)),
                          style: TextStyle(
                            fontFamily: BSType.font,
                            fontSize: BSType.body,
                            fontWeight: BSType.wBold,
                            height: 1.2,
                            color: weights.last.value < weights.first.value
                                ? c.calInk
                                : c.ink,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        valueMeta: units.weightUnit,
                      ),
                  ],
                  const BSSecHead('WHAT THIS PRODUCES', right: 'read-only'),
                  if (!profile.complete)
                    Padding(
                      padding: const EdgeInsets.only(top: BSSpace.s3),
                      child: BSEmpty(
                        hue: 'pro',
                        icon: 'target',
                        title: 'No estimate yet',
                        body:
                            'BMR and TDEE need ${_missingPhrase(profile)}. Weight, food and workouts all keep logging without them.',
                        action: BSButton(
                          _missingButtonLabel(profile),
                          variant: BSButtonVariant.tint,
                          hue: 'pro',
                          onTap: _addMissing,
                        ),
                      ),
                    )
                  else if (stats.bmr == null)
                    const Padding(
                      padding: EdgeInsets.only(top: BSSpace.s3),
                      child: BSEmpty(
                        hue: 'pro',
                        icon: 'target',
                        title: 'No estimate yet',
                        body:
                            'BMR and TDEE need a weigh-in. Log one on the Today tab and the estimates appear here.',
                      ),
                    )
                  else ...[
                    BSListRow(
                      first: true,
                      title: 'BMR',
                      meta: _bmrMeta(stats.bmrSource),
                      value: fmtKcal(stats.bmr!),
                      valueMeta: 'kcal',
                    ),
                    BSListRow(
                      title: 'TDEE',
                      meta:
                          'BMR × ${_mult(activity.multiplier)} ${activity.label.toLowerCase()}',
                      value: fmtKcal(stats.tdee!),
                      valueMeta: 'kcal',
                    ),
                    if (stats.fatPct != null)
                      BSListRow(
                        title: 'Body fat',
                        meta: stats.source ?? 'Navy method · neck, waist, hip',
                        value: fmt1(stats.fatPct!),
                        valueMeta: '%',
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: BSM2(
                          'Changing height or age re-runs both estimates. Your calorie target stays at ${fmtKcal(store.targets.kcal)} until you change it.'),
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

  Future<void> _editSex() async {
    final store = _store;
    var pending = store.profile.sex ?? Sex.female;
    await showBSSheet(
      context,
      title: 'Sex',
      sub: 'Mifflin-St Jeor uses it',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BSSeg(
              items: const ['Female', 'Male'],
              value: _sexLabel(pending),
              onChanged: (v) => setSheet(
                  () => pending = v == 'Female' ? Sex.female : Sex.male),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: BSSpace.s4),
              child: BSM2(_previewLine(store.profile.copyWith(sex: pending))),
            ),
            BSButton(
              'Save',
              size: BSButtonSize.lg,
              block: true,
              onTap: () {
                store.saveProfile(store.profile.copyWith(sex: pending));
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editAge() {
    final store = _store;
    return showBSSheet(
      context,
      title: 'Age',
      sub: 'years',
      builder: (_) => _FieldSheetBody(
        label: 'Age',
        unit: 'years',
        initial: store.profile.age?.toString() ?? '',
        preview: (text) {
          final pending = int.tryParse(text.trim());
          return _previewLine(store.profile.copyWith(age: pending));
        },
        onSave: (text) {
          final v = int.tryParse(text.trim());
          if (v != null && v >= 5 && v <= 120) {
            store.saveProfile(store.profile.copyWith(age: v));
          }
        },
      ),
    );
  }

  Future<void> _editHeight() {
    final store = _store;
    final units = Units.of(store.settings);
    double? cmOf(String text) {
      final v = double.tryParse(text.trim());
      return v == null ? null : units.cmIn(v);
    }

    return showBSSheet(
      context,
      title: 'Height',
      sub: units.imperial ? 'inches' : 'centimetres',
      builder: (_) => _FieldSheetBody(
        label: 'Height',
        unit: units.lengthUnit,
        initial: store.profile.heightCm != null
            ? fmtG(units.cmOut(store.profile.heightCm!))
            : '',
        preview: (text) =>
            _previewLine(store.profile.copyWith(heightCm: cmOf(text))),
        onSave: (text) {
          final v = cmOf(text);
          if (v != null && v >= 50 && v <= 260) {
            store.saveProfile(store.profile.copyWith(heightCm: v));
          }
        },
      ),
    );
  }

  Future<void> _addMissing() async {
    if (_store.profile.sex == null) {
      await _editSex();
      if (!mounted) return;
    }
    if (_store.profile.age == null) {
      await _editAge();
      if (!mounted) return;
    }
    if (_store.profile.heightCm == null) {
      await _editHeight();
    }
  }

  String _previewLine(Profile pending) {
    final store = _store;
    final cur = _estimates(store, store.profile);
    final next = _estimates(store, pending);
    final target = fmtKcal(store.targets.kcal);
    if (next.bmr == null) {
      return 'BMR and TDEE need sex, age, height and a weigh-in. Your calorie target stays at $target until you change it.';
    }
    if (cur.bmr == null) {
      return 'BMR becomes ${fmtKcal(next.bmr!)} kcal and TDEE ${fmtKcal(next.tdee!)} kcal. Your calorie target stays at $target until you change it.';
    }
    return 'BMR ${fmtKcal(cur.bmr!)} → ${fmtKcal(next.bmr!)} kcal and TDEE ${fmtKcal(cur.tdee!)} → ${fmtKcal(next.tdee!)} kcal. Your calorie target stays at $target until you change it.';
  }

  static ({double? bmr, double? tdee}) _estimates(AppStore store, Profile p) {
    final snap = store.latestSnapshot;
    final weight = store.latestWeight ?? snap?.weightKg;
    final bmr = Formulas.bmr(
      sex: p.sex,
      age: p.age,
      heightCm: p.heightCm,
      weightKg: weight,
      fatPct: snap?.bodyFatPct,
      overrideKcal: p.bmrOverrideKcal,
    );
    return (bmr: bmr, tdee: Formulas.tdee(bmr, p.activity));
  }

  Widget _notSet(BuildContext context) => Text(
        'Not set',
        style: TextStyle(
          fontFamily: BSType.font,
          fontSize: BSType.body,
          fontWeight: BSType.wBold,
          height: 1.2,
          color: context.bs.ink3,
        ),
      );

  static String _sexLabel(Sex s) => s == Sex.female ? 'Female' : 'Male';

  static String _bmrMeta(String source) => switch (source) {
        'Metabolic test' => 'Metabolic test',
        'Katch-McArdle' => 'Katch-McArdle · lean mass',
        _ => 'Mifflin-St Jeor · sex, age, height, weight',
      };

  static List<String> _missing(Profile p) => [
        if (p.sex == null) 'sex',
        if (p.age == null) 'age',
        if (p.heightCm == null) 'height',
      ];

  static String _missingPhrase(Profile p) {
    final m = _missing(p);
    if (m.length <= 1) return m.join();
    return '${m.sublist(0, m.length - 1).join(', ')} and ${m.last}';
  }

  static String _missingButtonLabel(Profile p) => switch (_missing(p).length) {
        1 => 'Add the one missing',
        2 => 'Add the two missing',
        _ => 'Add the three missing',
      };

  static String _mult(double m) {
    var s = m.toString();
    if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
    return s;
  }
}

class _FieldSheetBody extends StatefulWidget {
  final String label;
  final String unit;
  final String initial;
  final String Function(String text) preview;
  final void Function(String text) onSave;

  const _FieldSheetBody({
    required this.label,
    required this.unit,
    required this.initial,
    required this.preview,
    required this.onSave,
  });

  @override
  State<_FieldSheetBody> createState() => _FieldSheetBodyState();
}

class _FieldSheetBodyState extends State<_FieldSheetBody> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BSField(
          label: widget.label,
          controller: _controller,
          unit: widget.unit,
          onChanged: (_) => setState(() {}),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: BSSpace.s4),
          child: BSM2(widget.preview(_controller.text)),
        ),
        BSButton(
          'Save',
          size: BSButtonSize.lg,
          block: true,
          onTap: () {
            widget.onSave(_controller.text);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
