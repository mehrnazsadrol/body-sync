import 'package:app_settings/app_settings.dart' as sys;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
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
import '../../widgets/bs_toggle.dart';
import 'data_transfer.dart';
import 'my_foods_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppStore get _store => context.read<AppStore>();

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    final store = context.watch<AppStore>();
    final s = store.settings;
    final t = store.targets;
    final activity = store.profile.activity;
    final stats = store.storageStats();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            BSTitleBar(
              title: 'Settings',
              icon: 'close',
              onIconTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    BSSpace.screen, 0, BSSpace.screen, BSSpace.s3),
                children: [
                  const BSSecHead('YOU'),
                  BSListRow(
                    first: true,
                    title: 'Profile',
                    meta: 'Sex, age, height',
                    value: _profileValue(store.profile),
                    valueWidget: _profileValue(store.profile) == null
                        ? Text(
                            'Not set',
                            style: TextStyle(
                              fontFamily: BSType.font,
                              fontSize: BSType.body,
                              fontWeight: BSType.wBold,
                              height: 1.2,
                              color: c.ink3,
                            ),
                          )
                        : null,
                    valueMeta: store.profile.heightCm != null
                        ? '${fmtG(Units.of(s).cmOut(store.profile.heightCm!))} ${Units.of(s).lengthUnit}'
                        : null,
                    chevron: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                  ),
                  const BSSecHead('TARGETS'),
                  BSListRow(
                    first: true,
                    title: 'Daily calories',
                    meta: 'Held at daily energy use',
                    value: fmtKcal(t.kcal),
                    valueMeta: 'kcal',
                    chevron: true,
                    onTap: _editCalories,
                  ),
                  BSListRow(
                    title: 'Macro split',
                    meta:
                        '${_splitLabel(t)} · ${fmtG(t.p)} / ${fmtG(t.c)} / ${fmtG(t.f)} g',
                    chevron: true,
                    onTap: _editMacros,
                  ),
                  BSListRow(
                    title: 'Activity',
                    meta: '${activity.label} · ${activity.description}',
                    tag: '×${_mult(activity.multiplier)}',
                    chevron: true,
                    onTap: _editActivity,
                  ),
                  const BSSecHead('REMINDERS'),
                  if (store.notifDenied) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: BSBanner(
                        tone: BSBannerTone.err,
                        icon: 'bell',
                        title: 'Notifications are turned off for BodySync',
                        body:
                            'The reminder cannot fire until the system allows it: Settings › Notifications › BodySync › Allow Notifications.',
                        action: defaultTargetPlatform == TargetPlatform.iOS
                            ? 'Open iOS Settings'
                            : 'Open Settings',
                        onAction: () => sys.AppSettings.openAppSettings(
                            type: sys.AppSettingsType.notification),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Opacity(
                        opacity: .55,
                        child: Column(
                          children: [
                            BSListRow(
                              first: true,
                              title: 'Weight reminder',
                              meta: 'Blocked by the system',
                              value: s.reminderLabel,
                              trailing:
                                  const BSToggle(value: false, onChanged: null),
                            ),
                            const BSListRow(
                              title: 'Check-in nudge',
                              meta: 'Blocked by the system',
                              trailing: BSToggle(value: false, onChanged: null),
                            ),
                          ],
                        ),
                      ),
                    ),
                    BSListRow(
                      title: 'Check-in cadence',
                      meta: 'Measurements and estimates',
                      value: '${s.checkinCadenceDays}',
                      valueMeta: 'days',
                      chevron: true,
                      onTap: _editCadence,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: BSSpace.s4),
                      child: BSM2(
                          'Everything else keeps working. Without notifications the reminder becomes a banner on the Today tab instead.'),
                    ),
                    const BSSecHead('IN-APP INSTEAD'),
                    BSListRow(
                      first: true,
                      title: 'Banner on Today',
                      meta:
                          'Shown after ${s.reminderLabel} when no weight is logged',
                      trailing: BSToggle(
                        value: s.todayBannerOn,
                        onChanged: (v) => store.saveSettings(
                            store.settings.copyWith(todayBannerOn: v)),
                      ),
                    ),
                  ] else ...[
                    BSListRow(
                      first: true,
                      title: 'Weight reminder',
                      meta: 'Only when the day has no weight',
                      value: s.reminderLabel,
                      trailing: BSToggle(
                          value: s.reminderOn, onChanged: _setReminderOn),
                      onTap: _editReminderTime,
                    ),
                    BSListRow(
                      title: 'Check-in nudge',
                      meta: 'One nudge when measurements are due',
                      trailing: BSToggle(
                          value: s.checkinNudgeOn, onChanged: _setCheckinNudge),
                    ),
                    BSListRow(
                      title: 'Check-in cadence',
                      meta: 'Measurements and estimates',
                      value: '${s.checkinCadenceDays}',
                      valueMeta: 'days',
                      chevron: true,
                      onTap: _editCadence,
                    ),
                  ],
                  const BSSecHead('APP'),
                  BSListRow(
                    first: true,
                    title: 'Appearance',
                    meta: _appearanceMeta(s.themeMode),
                    value: _appearanceValue(s.themeMode),
                    chevron: true,
                    onTap: _editAppearance,
                  ),
                  BSListRow(
                    title: 'Units',
                    meta: s.imperial
                        ? 'Pounds, inches'
                        : 'Kilograms, centimetres',
                    value: s.imperial ? 'Imperial' : 'Metric',
                    chevron: true,
                    onTap: _editUnits,
                  ),
                  BSListRow(
                    title: 'Start of week',
                    value: s.startOfWeek == 'mon' ? 'Monday' : 'Sunday',
                    chevron: true,
                    onTap: _editStartOfWeek,
                  ),
                  const BSSecHead('DATA'),
                  BSListRow(
                    first: true,
                    title: 'My foods and overrides',
                    meta: 'Edited nutrition facts you have saved',
                    value: '${stats.overrides}',
                    chevron: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyFoodsScreen()),
                    ),
                  ),
                  BSListRow(
                    title: 'Export and reset',
                    meta: 'One JSON file backup of everything',
                    chevron: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ExportResetScreen()),
                    ),
                  ),
                  const BSSecHead('ACCOUNT'),
                  BSListRow(
                    first: true,
                    title: 'Signed in',
                    meta: FirebaseAuth.instance.currentUser?.email ??
                        'Syncing to your account',
                  ),
                  BSListRow(
                    title: 'Sign out',
                    meta: 'Your log stays in the cloud and on this device',
                    chevron: true,
                    onTap: _signOut,
                  ),
                  const Padding(
                    padding:
                        EdgeInsets.only(top: BSSpace.s5, bottom: BSSpace.s2),
                    child: BSM2(
                        'BodySync 3.1 · offline food database, revision 2026-06 · synced to your account, no analytics.'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    Navigator.of(context).popUntil((r) => r.isFirst);
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _editCalories() {
    final store = _store;
    return showBSSheet(
      context,
      title: 'Daily calories',
      sub: 'kcal a day',
      builder: (_) => _CaloriesSheetBody(store: store),
    );
  }

  Future<void> _editMacros() {
    final store = _store;
    return showBSSheet(
      context,
      title: 'Macro split',
      sub: 'grams a day',
      builder: (_) => _MacrosSheetBody(store: store),
    );
  }

  Future<void> _editActivity() {
    final store = _store;
    return showBSSheet(
      context,
      title: 'Activity',
      builder: (ctx) {
        final current = store.profile.activity;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < ActivityLevel.values.length; i++)
              BSListRow(
                first: i == 0,
                title: ActivityLevel.values[i].label,
                meta: ActivityLevel.values[i].description,
                tag: '×${_mult(ActivityLevel.values[i].multiplier)}',
                trailing: ActivityLevel.values[i] == current
                    ? BSIcon('check', size: 18, color: ctx.bs.ink)
                    : null,
                onTap: () {
                  store.saveProfile(store.profile
                      .copyWith(activity: ActivityLevel.values[i]));
                  Navigator.of(ctx).pop();
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _setReminderOn(bool v) async {
    final store = _store;
    final notifs = context.read<NotificationService>();
    if (v) {
      final granted = await notifs.requestPermission();
      await store.setNotifDenied(!granted);
      await store.saveSettings(store.settings.copyWith(reminderOn: granted));
    } else {
      await store.saveSettings(store.settings.copyWith(reminderOn: false));
    }
    await notifs.sync(store);
  }

  Future<void> _setCheckinNudge(bool v) async {
    final store = _store;
    final notifs = context.read<NotificationService>();
    await store.saveSettings(store.settings.copyWith(checkinNudgeOn: v));
    await notifs.sync(store);
  }

  Future<void> _editReminderTime() async {
    final store = _store;
    final notifs = context.read<NotificationService>();
    final s = store.settings;
    var index = s.reminderHour * 2 + (s.reminderMinute >= 30 ? 1 : 0);
    final wheel = FixedExtentScrollController(initialItem: index);
    await showBSSheet(
      context,
      title: 'Remind me at',
      sub: 'if no weight is logged',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final c = ctx.bs;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 10),
                child: SizedBox(
                  height: 220,
                  child: Stack(
                    children: [
                      ListWheelScrollView(
                        controller: wheel,
                        itemExtent: BSSpace.hit,
                        physics: const FixedExtentScrollPhysics(),
                        diameterRatio: 40,
                        perspective: 0.0001,
                        onSelectedItemChanged: (i) => setSheet(() => index = i),
                        children: [
                          for (var i = 0; i < 48; i++)
                            Center(
                              child: AnimatedDefaultTextStyle(
                                duration: BSMotion.fast,
                                style: TextStyle(
                                  fontFamily: BSType.font,
                                  fontSize: i == index ? 24 : 19,
                                  fontWeight: BSType.wRegular,
                                  height: 1,
                                  color: i == index
                                      ? c.ink
                                      : c.ink3.withValues(alpha: .6),
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                                child: Text(_hhmm(i)),
                              ),
                            ),
                        ],
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              height: BSSpace.hit,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: c.line, width: 1),
                                  bottom: BorderSide(color: c.line, width: 1),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              BSButton(
                'Set ${_hhmm(index)}',
                size: BSButtonSize.lg,
                block: true,
                onTap: () async {
                  await store.saveSettings(store.settings.copyWith(
                    reminderHour: index ~/ 2,
                    reminderMinute: (index % 2) * 30,
                  ));
                  await notifs.sync(store);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 10),
              BSButton(
                'Turn the reminder off',
                variant: BSButtonVariant.quiet,
                block: true,
                onTap: () async {
                  await store
                      .saveSettings(store.settings.copyWith(reminderOn: false));
                  await notifs.sync(store);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
            ],
          );
        },
      ),
    );
    wheel.dispose();
  }

  Future<void> _editCadence() {
    final store = _store;
    final notifs = context.read<NotificationService>();
    return showBSSheet(
      context,
      title: 'Check-in cadence',
      sub: 'days between measurements',
      builder: (ctx) => Padding(
        padding: const EdgeInsets.only(bottom: BSSpace.s2),
        child: BSChips(
          items: const ['30', '45', '60'],
          value: '${store.settings.checkinCadenceDays}',
          grow: true,
          onChanged: (v) async {
            await store.saveSettings(
                store.settings.copyWith(checkinCadenceDays: int.parse(v)));
            await notifs.sync(store);
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }

  Future<void> _editAppearance() {
    final store = _store;
    return showBSSheet(
      context,
      title: 'Appearance',
      builder: (ctx) => Padding(
        padding: const EdgeInsets.only(bottom: BSSpace.s2),
        child: BSSeg(
          items: const ['System', 'Light', 'Dark'],
          value: _appearanceValue(store.settings.themeMode),
          onChanged: (v) {
            store.saveSettings(
                store.settings.copyWith(themeMode: v.toLowerCase()));
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }

  Future<void> _editUnits() {
    final store = _store;
    return showBSSheet(
      context,
      title: 'Units',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, (value, title, meta)) in const [
            ('metric', 'Metric', 'kg, cm'),
            ('imperial', 'Imperial', 'lb, in'),
          ].indexed)
            BSListRow(
              first: i == 0,
              title: title,
              meta: meta,
              trailing: store.settings.units == value
                  ? BSIcon('check', size: 18, color: ctx.bs.ink)
                  : null,
              onTap: () {
                store.saveSettings(store.settings.copyWith(units: value));
                Navigator.of(ctx).pop();
              },
            ),
        ],
      ),
    );
  }

  Future<void> _editStartOfWeek() {
    final store = _store;
    return showBSSheet(
      context,
      title: 'Start of week',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, (value, title)) in const [
            ('sun', 'Sunday'),
            ('mon', 'Monday'),
          ].indexed)
            BSListRow(
              first: i == 0,
              title: title,
              trailing: store.settings.startOfWeek == value
                  ? BSIcon('check', size: 18, color: ctx.bs.ink)
                  : null,
              onTap: () {
                store.saveSettings(store.settings.copyWith(startOfWeek: value));
                Navigator.of(ctx).pop();
              },
            ),
        ],
      ),
    );
  }

  static String? _profileValue(Profile p) {
    final parts = [
      if (p.sex != null) p.sex == Sex.female ? 'Female' : 'Male',
      if (p.age != null) '${p.age}',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static String _appearanceValue(String mode) => switch (mode) {
        'light' => 'Light',
        'dark' => 'Dark',
        _ => 'System',
      };

  static String _appearanceMeta(String mode) => switch (mode) {
        'light' => 'Always light',
        'dark' => 'Always dark',
        _ => 'Following the phone',
      };

  static String _mult(double m) {
    var s = m.toString();
    if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
    return s;
  }

  static String _hhmm(int i) =>
      '${(i ~/ 2).toString().padLeft(2, '0')}:${((i % 2) * 30).toString().padLeft(2, '0')}';

  static String _splitLabel(Targets t) {
    bool near(double a, double b) => (a - b).abs() <= 1;
    bool matches(Targets other) =>
        near(t.p, other.p) && near(t.c, other.c) && near(t.f, other.f);
    if (matches(Targets.balanced(t.kcal))) return 'Balanced';
    if (matches(Targets.higherProtein(t.kcal))) return 'Higher protein';
    return 'Custom';
  }
}

class ExportResetScreen extends StatelessWidget {
  const ExportResetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    final store = context.watch<AppStore>();
    final stats = store.storageStats();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            BSTitleBar(
              title: 'Export and reset',
              icon: 'chevronLeft',
              onIconTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    BSSpace.screen, 0, BSSpace.screen, BSSpace.s3),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BSOverline('ON THIS PHONE'),
                        const SizedBox(height: BSSpace.s3),
                        BSHero(
                          value: fmtKcal(stats.daysLogged),
                          unit: 'days logged',
                          right: fmtStorage(store.storageBytes()),
                          size: 52,
                        ),
                      ],
                    ),
                  ),
                  const BSSecHead('WHAT IS STORED'),
                  BSListRow(
                    first: true,
                    title: 'Food entries',
                    meta: stats.since != null
                        ? 'Since ${fmtDayFull(stats.since!)}'
                        : null,
                    value: fmtKcal(stats.foodEntries),
                  ),
                  BSListRow(title: 'Weigh-ins', value: fmtKcal(stats.weighIns)),
                  BSListRow(
                      title: 'Workout days', value: fmtKcal(stats.workoutDays)),
                  BSListRow(
                    title: 'Check-ins',
                    meta: 'Measurements and estimates',
                    value: fmtKcal(stats.checkins),
                  ),
                  BSListRow(
                      title: 'My foods and overrides',
                      value: fmtKcal(stats.overrides)),
                  const BSSecHead('MOVE IT'),
                  Padding(
                    padding: const EdgeInsets.only(top: BSSpace.s3),
                    child: BSButton(
                      'Export as JSON',
                      variant: BSButtonVariant.tint,
                      block: true,
                      icon: 'undo',
                      onTap: () => shareExport(store),
                    ),
                  ),
                  const SizedBox(height: 10),
                  BSButton(
                    'Import from a file',
                    variant: BSButtonVariant.tint,
                    hue: 'pro',
                    block: true,
                    onTap: () => _import(context),
                  ),
                  const SizedBox(height: BSSpace.s2),
                  BSListRow(
                    first: true,
                    title: 'Last export',
                    value: store.lastExport != null
                        ? fmtDay(store.lastExport!)
                        : 'Never',
                  ),
                  const BSSecHead('START OVER'),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: BSSpace.s3),
                    child: BSM2(store.uid != null
                        ? 'Deletes every entry, override and estimate from this phone and your account. Export first if you want a copy.'
                        : 'Deletes every entry, override and estimate on this phone. Export first — there is no copy anywhere else.'),
                  ),
                  BSButton(
                    'Erase all data',
                    variant: BSButtonVariant.danger,
                    block: true,
                    icon: 'trash',
                    iconSize: 18,
                    onTap: () => _confirmErase(context),
                  ),
                  const SizedBox(height: BSSpace.s5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    final store = context.read<AppStore>();
    try {
      final r = await pickAndImport(store);
      if (r == null || !context.mounted) return;
      showBSToast(context, importSummary(r));
    } on FormatException catch (e) {
      if (context.mounted) showBSToast(context, e.message);
    }
  }

  Future<void> _confirmErase(BuildContext context) async {
    final store = context.read<AppStore>();
    final stats = store.storageStats();
    final where = store.uid != null
        ? 'from this phone and your account'
        : 'from this phone';
    await showBSDialog(
      context,
      title: 'Erase ${fmtKcal(stats.daysLogged)} days?',
      body:
          '${fmtKcal(stats.foodEntries)} food entries, ${fmtKcal(stats.weighIns)} weigh-ins, ${fmtKcal(stats.workoutDays)} workout days and ${fmtKcal(stats.checkins)} check-ins are deleted $where. There is no backup and no undo.',
      actions: [
        BSButton(
          'Export first',
          variant: BSButtonVariant.tint,
          size: BSButtonSize.lg,
          block: true,
          onTap: () => shareExport(store),
        ),
        BSButton(
          'Erase everything',
          variant: BSButtonVariant.danger,
          block: true,
          onTap: () async {
            await store.eraseAll();
            if (!context.mounted) return;
            Navigator.of(context).popUntil((r) => r.isFirst);
          },
        ),
        Builder(
          builder: (dctx) => BSButton(
            'Cancel',
            variant: BSButtonVariant.quiet,
            block: true,
            onTap: () => Navigator.of(dctx).pop(),
          ),
        ),
      ],
    );
  }
}

class _CaloriesSheetBody extends StatefulWidget {
  final AppStore store;

  const _CaloriesSheetBody({required this.store});

  @override
  State<_CaloriesSheetBody> createState() => _CaloriesSheetBodyState();
}

class _CaloriesSheetBodyState extends State<_CaloriesSheetBody> {
  late final _controller =
      TextEditingController(text: fmtG(widget.store.targets.kcal));

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
        BSField(label: 'Calories', controller: _controller, unit: 'kcal'),
        const SizedBox(height: BSSpace.s4),
        BSButton(
          'Save',
          size: BSButtonSize.lg,
          block: true,
          onTap: () {
            final v = double.tryParse(_controller.text.replaceAll(',', ''));
            if (v != null && v > 0) {
              final t = widget.store.targets;
              widget.store
                  .saveTargets(Targets(kcal: v, p: t.p, c: t.c, f: t.f));
            }
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class _MacrosSheetBody extends StatefulWidget {
  final AppStore store;

  const _MacrosSheetBody({required this.store});

  @override
  State<_MacrosSheetBody> createState() => _MacrosSheetBodyState();
}

class _MacrosSheetBodyState extends State<_MacrosSheetBody> {
  late final _pC = TextEditingController(text: fmtG(widget.store.targets.p));
  late final _cC = TextEditingController(text: fmtG(widget.store.targets.c));
  late final _fC = TextEditingController(text: fmtG(widget.store.targets.f));

  @override
  void dispose() {
    _pC.dispose();
    _cC.dispose();
    _fC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
                child: BSField(label: 'Protein', controller: _pC, unit: 'g')),
            const SizedBox(width: BSSpace.s2),
            Expanded(
                child: BSField(label: 'Carbs', controller: _cC, unit: 'g')),
            const SizedBox(width: BSSpace.s2),
            Expanded(child: BSField(label: 'Fat', controller: _fC, unit: 'g')),
          ],
        ),
        const SizedBox(height: BSSpace.s4),
        BSButton(
          'Save',
          size: BSButtonSize.lg,
          block: true,
          onTap: () {
            final p = double.tryParse(_pC.text);
            final cg = double.tryParse(_cC.text);
            final f = double.tryParse(_fC.text);
            if (p != null && cg != null && f != null) {
              widget.store.saveTargets(
                  Targets(kcal: widget.store.targets.kcal, p: p, c: cg, f: f));
            }
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
