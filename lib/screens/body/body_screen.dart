import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../data/formulas.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../util/units.dart';
import '../../widgets/bs_common.dart';
import '../../widgets/bs_empty.dart';
import '../../widgets/bs_list_row.dart';
import '../../widgets/bs_stat_tile.dart';
import '../../widgets/bs_trend.dart';
import '../settings/settings_screen.dart';
import 'checkin_flow.dart';
import 'measure_history_screen.dart';
import 'override_sheet.dart';
import 'weigh_in_sheet.dart';

class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen> {
  void _openCheckin() {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const CheckinFlow(),
    ));
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openHistory(String measure) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MeasureHistoryScreen(measure: measure)),
    );
  }

  Future<void> _openOverride() async {
    final store = context.read<AppStore>();
    final snap = store.latestSnapshot;
    if (snap == null) return;
    final profile = store.profile;
    final active = snap.overrideSource != null;
    final estimate = active
        ? (snap.estimatedFatPct ??
            Formulas.navyBodyFat(
              sex: profile.sex,
              heightCm: profile.heightCm,
              neckCm: snap.neckCm,
              waistCm: snap.waistCm,
              hipCm: snap.hipCm,
            ))
        : snap.bodyFatPct;
    final outcome = await showBodyFatOverrideSheet(
      context,
      estimate: estimate,
      initialValue: snap.bodyFatPct,
      initialSource: snap.overrideSource,
      overrideActive: active,
    );
    if (outcome == null || !mounted) return;

    final (double? fat, String? source, double? kept) = switch (outcome) {
      OverrideUse(:final value, :final source) => (value, source, estimate),
      OverrideCleared() => (estimate, null, null),
    };
    final weight = snap.weightKg ?? store.latestWeight;
    final bmr = Formulas.bmr(
      sex: profile.sex,
      age: profile.age,
      heightCm: profile.heightCm,
      weightKg: weight,
      fatPct: fat,
      overrideKcal: profile.bmrOverrideKcal,
    );
    await store.replaceLatestSnapshot(snap.copyWith(
      bodyFatPct: fat,
      leanKg: Formulas.leanMass(weight, fat),
      bmr: bmr,
      tdee: Formulas.tdee(bmr, profile.activity),
      overrideSource: source,
      estimatedFatPct: kept,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    final store = context.watch<AppStore>();

    final units = Units.of(store.settings);
    final weightEntries = store.weightEntries();
    final latestWeight = store.latestWeight;
    final delta30 = store.weightDelta(30);
    final loggedToday = store.weightFor(DateTime.now()) != null;

    final cycle = store.checkinCycle();
    final cadence = store.settings.checkinCadenceDays;
    final due = store.checkinDue;

    final snapshots = store.snapshots;
    final latestSnap = store.latestSnapshot;
    final prevSnap =
        snapshots.length >= 2 ? snapshots[snapshots.length - 2] : null;
    final stats = store.currentBodyStats();

    final fatSnaps =
        snapshots.where((s) => s.bodyFatPct != null).toList(growable: false);

    return Column(
      children: [
        BSTitleBar(
          title: 'Body',
          size: 29,
          icon: 'settings',
          onIconTap: _openSettings,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                BSSpace.screen, 0, BSSpace.screen, 12),
            children: [
              if (due)
                BSBanner(
                  tone: BSBannerTone.info,
                  icon: 'clock',
                  title: '$cadence-day check-in is due',
                  body:
                      'Three measurements refresh your body-fat, lean-mass and TDEE estimates. It takes about a minute.',
                  action: 'Log measurements',
                  onAction: _openCheckin,
                  margin: const EdgeInsets.only(bottom: 6),
                ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showWeighInSheet(context),
                child: Padding(
                  padding: EdgeInsets.only(top: due ? 20 : 2, bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BSOverline('WEIGHT'),
                      const SizedBox(height: 8),
                      BSHero(
                        value: latestWeight != null
                            ? fmt1(units.kgOut(latestWeight))
                            : '—',
                        unit: units.weightUnit,
                        size: 66,
                        right: delta30 != null
                            ? '${fmtDelta1(units.kgOut(delta30))} ${units.weightUnit} · 30 days'
                            : (loggedToday ? 'logged today' : 'not logged'),
                        hue: delta30 != null && delta30 < 0 ? 'cal' : null,
                      ),
                    ],
                  ),
                ),
              ),
              if (weightEntries.length >= 7)
                BSTrend(
                  values: [for (final e in weightEntries) units.kgOut(e.value)],
                  mode: BSTrendMode.area,
                  hue: 'cal',
                  height: due ? 56 : 62,
                  labels: [
                    fmtDayShort(weightEntries.first.key),
                    fmtDayShort(weightEntries.last.key),
                  ],
                  margin: const EdgeInsets.only(top: 24),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: BSRule(
                    padding: const EdgeInsets.only(top: 20),
                    child: BSEmpty(
                      icon: 'scale',
                      hue: 'cal',
                      title: weightEntries.isEmpty
                          ? 'No weigh-ins yet'
                          : weightEntries.length == 1
                              ? 'One weigh-in on file'
                              : '${weightEntries.length} weigh-ins on file',
                      body:
                          "A trend line needs at least a week. Log a weight most mornings and this becomes the screen's main graphic.",
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 26, bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BSOverline('NEXT CHECK-IN'),
                    const SizedBox(height: 8),
                    Text(
                      due
                          ? 'Today'
                          : latestSnap == null
                              ? 'No check-ins yet'
                              : 'In ${cycle.remaining} days',
                      style: TextStyle(
                        fontFamily: BSType.font,
                        fontSize: BSType.heading,
                        fontWeight: BSType.wRegular,
                        height: 1.2,
                        letterSpacing: -.015 * BSType.heading,
                        color: due ? c.proInk : c.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: Text(
                        _cycleMeta(cycle, cadence, snapshots.length),
                        style: TextStyle(
                          fontFamily: BSType.font,
                          fontSize: BSType.meta,
                          height: 1.3,
                          color: c.ink3,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    BSProg(
                      pct: cycle.last == null ? 0 : cycle.day / cadence * 100,
                      hue: 'pro',
                    ),
                    const SizedBox(height: 14),
                    if (due)
                      Row(
                        children: [
                          _link('Log now', c.proInk, _openCheckin),
                          const SizedBox(width: 14),
                          _link('Remind me in 3 days', c.ink3, () {
                            store.snoozeCheckin(3);
                          }),
                        ],
                      )
                    else
                      _link('Log measurements', c.proInk, _openCheckin),
                  ],
                ),
              ),
              if (due)
                BSSecHead(
                  'ESTIMATES, GOING STALE',
                  right: cycle.last != null
                      ? 'from ${fmtDayShort(cycle.last!)}'
                      : null,
                )
              else
                BSSecHead(
                  'CURRENT ESTIMATES',
                  right: snapshots.length == 1 ? 'from onboarding' : null,
                ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Opacity(
                  opacity: due ? .6 : 1,
                  child: BSTiles(tiles: [
                    BSStatTile(
                      label: 'Body fat',
                      value: stats.fatPct != null ? fmt1(stats.fatPct!) : '—',
                      unit: '%',
                      note: due
                          ? (stats.source != null
                              ? '${stats.source} · ${cycle.day} days old'
                              : '${cycle.day} days old')
                          : (stats.source ?? 'estimated'),
                      hue: 'pro',
                      onTap: latestSnap != null ? _openOverride : null,
                    ),
                    BSStatTile(
                      label: 'Lean mass',
                      value: stats.lean != null
                          ? fmt1(units.kgOut(stats.lean!))
                          : '—',
                      unit: units.weightUnit,
                      note: due ? '${cycle.day} days old' : 'estimated',
                      hue: 'cal',
                    ),
                    BSStatTile(
                      label: 'BMR',
                      value: stats.bmr != null ? fmtKcal(stats.bmr!) : '—',
                      unit: 'kcal',
                      note: stats.bmrSource,
                      hue: 'carb',
                    ),
                    BSStatTile(
                      label: 'TDEE',
                      value: stats.tdee != null ? fmtKcal(stats.tdee!) : '—',
                      unit: 'kcal',
                      note: _activityNote(store.profile.activity),
                      hue: 'fat',
                    ),
                  ]),
                ),
              ),
              if (fatSnaps.length >= 2) ...[
                BSSecHead(
                  'BODY FAT TREND',
                  right: '${fatSnaps.length} check-ins',
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: BSRule(
                    padding: const EdgeInsets.only(top: 14),
                    child: BSTrend(
                      values: [for (final s in fatSnaps) s.bodyFatPct!],
                      mode: BSTrendMode.line,
                      hue: 'pro',
                      height: 44,
                      labels: [
                        fmtDayShort(fatSnaps.first.date),
                        fmtDayShort(fatSnaps.last.date),
                      ],
                    ),
                  ),
                ),
              ],
              if (latestSnap != null) ...[
                BSSecHead(
                  'MEASUREMENTS',
                  right: fmtDayShort(latestSnap.date),
                ),
                _measureRow(
                  first: true,
                  name: 'Neck',
                  value: latestSnap.neckCm,
                  prev: prevSnap?.neckCm,
                ),
                _measureRow(
                  name: 'Waist',
                  value: latestSnap.waistCm,
                  prev: prevSnap?.waistCm,
                ),
                _measureRow(
                  name: 'Hip',
                  value: latestSnap.hipCm,
                  prev: prevSnap?.hipCm,
                ),
              ] else ...[
                const BSSecHead('MEASUREMENTS'),
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: BSRule(
                    padding: EdgeInsets.only(top: 14),
                    child: BSEmpty(
                      icon: 'ruler',
                      hue: 'pro',
                      title: 'No measurements yet',
                      body:
                          'Neck, waist and hip from your first check-in appear here, each with its own ledger.',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 26),
            ],
          ),
        ),
      ],
    );
  }

  String _cycleMeta(({int day, int remaining, DateTime? last}) cycle,
      int cadence, int count) {
    if (cycle.last == null) {
      return 'Three tape measurements start the ledger. It takes about a minute.';
    }
    if (count == 1) {
      return 'Day ${cycle.day} of $cadence · from onboarding, ${fmtDayShort(cycle.last!)}';
    }
    return 'Day ${cycle.day} of $cadence · last logged ${fmtDayShort(cycle.last!)}';
  }

  String _activityNote(ActivityLevel a) => a == ActivityLevel.veryActive
      ? 'very active'
      : '${a.label.toLowerCase()} activity';

  Widget _link(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: BSType.font,
            fontSize: BSType.body,
            fontWeight: BSType.wBold,
            height: 1,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _measureRow({
    bool first = false,
    required String name,
    required double? value,
    required double? prev,
  }) {
    final c = context.bs;
    final units = Units.of(context.read<AppStore>().settings);
    if (value == null) {
      return BSListRow(
        first: first,
        title: name,
        meta: 'Skipped — estimates use a default ratio',
        value: '—',
        chevron: true,
        onTap: () => _openHistory(name),
      );
    }
    return BSListRow(
      first: first,
      title: name,
      valueWidget: Text.rich(
        TextSpan(children: [
          TextSpan(
            text: fmt1(units.cmOut(value)),
            style: TextStyle(
              fontFamily: BSType.font,
              fontSize: BSType.body,
              fontWeight: BSType.wBold,
              height: 1.2,
              color: c.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          TextSpan(
            text: ' ${units.lengthUnit}',
            style: TextStyle(
              fontFamily: BSType.font,
              fontSize: BSType.micro,
              fontWeight: BSType.wRegular,
              color: c.ink3,
            ),
          ),
        ]),
      ),
      valueMetaWidget: prev == null
          ? Text(
              'first',
              style: TextStyle(
                fontFamily: BSType.font,
                fontSize: BSType.micro,
                height: 1.2,
                color: c.ink3,
              ),
            )
          : Text(
              fmtDelta1(units.cmOut(value - prev)),
              style: TextStyle(
                fontFamily: BSType.font,
                fontSize: BSType.micro,
                height: 1.2,
                color: value - prev < 0 ? c.calInk : c.ink3,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
      chevron: true,
      onTap: () => _openHistory(name),
    );
  }
}
