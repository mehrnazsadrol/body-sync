import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'food_repository.dart';
import 'formulas.dart';
import 'models.dart';

class AppStore extends ChangeNotifier {
  final FoodRepository foods = FoodRepository();

  static const _kFoodLog = 'bs.foodLog';
  static const _kOverrides = 'bs.overrides';
  static const _kCustomFoods = 'bs.customFoods';
  static const _kProfile = 'bs.profile';
  static const _kTargets = 'bs.targets';
  static const _kSettings = 'bs.settings';
  static const _kSnapshots = 'bs.snapshots';
  static const _kOnboarded = 'bs.onboarded';
  static const _kLegacy = 'savedData';

  SharedPreferences? _prefs;

  bool loaded = false;
  bool onboarded = false;
  bool writeFailed = false;

  int unreadableCount = 0;
  int readableDays = 0;
  bool get recoveryNeeded => unreadableCount > 0;

  bool notifDenied = false;
  static const _kNotifDenied = 'bs.notifDenied';
  static const _kLastExport = 'bs.lastExport';

  DateTime? get lastExport {
    final raw = _prefs?.getString(_kLastExport);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  String? uid;

  bool authKnown = false;

  bool syncingInitial = false;

  final List<StreamSubscription<dynamic>> _subs = [];
  Timer? _syncTimer;

  FirebaseFirestore get _fs => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _fs.collection('users').doc(uid).collection(name);

  bool get _migrated => _prefs?.getBool('bs.migrated.$uid') ?? false;

  final Map<String, List<LogEntry>> _log = {};

  Map<String, dynamic> _days = {};

  Profile profile = const Profile();
  Targets targets = const Targets();
  AppSettings settings = const AppSettings();
  List<BodySnapshot> snapshots = [];

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    await foods.load();
    _loadPrefsData(p);
    loaded = true;
    notifyListeners();
  }

  void _loadPrefsData(SharedPreferences p) {
    unreadableCount = 0;
    onboarded = p.getBool(_kOnboarded) ?? false;
    notifDenied = p.getBool(_kNotifDenied) ?? false;

    _days = {};
    _salvage(() {
      final raw = _readJson(p, _kLegacy);
      raw?.forEach((k, v) {
        _salvage(() {
          if (v is! Map) throw const FormatException();
          _days[k] = v;
        });
      });
    });

    _log.clear();
    _salvage(() {
      final logJson = _readJson(p, _kFoodLog) ?? {};
      logJson.forEach((k, v) {
        _salvage(() {
          _log[k] = [
            for (final e in v as List)
              LogEntry.fromJson(e as Map<String, dynamic>)
          ]..sort((a, b) => b.time.compareTo(a.time));
        });
      });
    });

    foods.overrides = {};
    _salvage(() {
      final ovJson = _readJson(p, _kOverrides) ?? {};
      for (final e in ovJson.entries) {
        _salvage(() {
          foods.overrides[e.key] =
              FoodOverride.fromJson(e.value as Map<String, dynamic>);
        });
      }
    });

    foods.customFoods = [];
    _salvage(() {
      final cfRaw = p.getString(_kCustomFoods);
      if (cfRaw != null) {
        for (final f in jsonDecode(cfRaw) as List) {
          _salvage(() {
            foods.customFoods
                .add(Food.fromJson(f as Map<String, dynamic>, custom: true));
          });
        }
      }
    });

    _salvage(() {
      final profJson = _readJson(p, _kProfile);
      if (profJson != null) profile = Profile.fromJson(profJson);
    });
    _salvage(() {
      final tJson = _readJson(p, _kTargets);
      if (tJson != null) targets = Targets.fromJson(tJson);
    });
    _salvage(() {
      final sJson = _readJson(p, _kSettings);
      if (sJson != null) settings = AppSettings.fromJson(sJson);
    });

    snapshots = [];
    _salvage(() {
      final snapRaw = p.getString(_kSnapshots);
      if (snapRaw != null) {
        for (final s in jsonDecode(snapRaw) as List) {
          _salvage(() {
            snapshots.add(BodySnapshot.fromJson(s as Map<String, dynamic>));
          });
        }
        snapshots.sort((a, b) => a.date.compareTo(b.date));
      }
    });

    final withData = <String>{..._log.keys, ..._days.keys};
    readableDays = withData.length;
  }

  void _salvage(void Function() parse) {
    try {
      parse();
    } catch (_) {
      unreadableCount++;
    }
  }

  Future<void> resolveKeepReadable() async {
    unreadableCount = 0;
    notifyListeners();
    await _saveLog();
    await _write(_kLegacy, _days);
    await _saveSnapshots();
    await _persistOverrides();
  }

  Future<void> setNotifDenied(bool v) async {
    if (notifDenied == v) return;
    notifDenied = v;
    notifyListeners();
    await _prefs?.setBool(_kNotifDenied, v);
  }

  Map<String, dynamic>? _readJson(SharedPreferences p, String key) {
    final raw = p.getString(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _write(String key, Object value) async {
    if (recoveryNeeded) return;
    try {
      await _prefs?.setString(key, jsonEncode(value));
      if (writeFailed) {
        writeFailed = false;
        notifyListeners();
      }
    } catch (_) {
      writeFailed = true;
      notifyListeners();
    }
  }

  Future<void> setUser(String? newUid) async {
    if (newUid == uid) {
      if (!authKnown) {
        authKnown = true;
        notifyListeners();
      }
      return;
    }
    authKnown = true;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _syncTimer?.cancel();
    uid = newUid;

    if (uid == null) {
      syncingInitial = false;
      _resetMemory();
      final p = _prefs;
      if (p != null) _loadPrefsData(p);
      notifyListeners();
      return;
    }

    syncingInitial = !onboarded;
    _syncTimer = Timer(const Duration(seconds: 6), () {
      if (syncingInitial) {
        syncingInitial = false;
        notifyListeners();
      }
    });
    _attachCloud();
    unawaited(_migrateLocal());
    notifyListeners();
  }

  void _attachCloud() {
    _subs.add(_col('days').snapshots().listen((qs) {
      final cloud = {for (final d in qs.docs) d.id: d.data()};
      if (_migrated) {
        _days = cloud;
        unawaited(_write(_kLegacy, _days));
      } else {
        _days.addAll(cloud);
      }
      notifyListeners();
    }));

    _subs.add(_col('foodLog').snapshots().listen((qs) {
      final cloud = <String, List<LogEntry>>{};
      for (final d in qs.docs) {
        final raw = d.data()['entries'];
        if (raw is! List) continue;
        cloud[d.id] = [
          for (final e in raw)
            LogEntry.fromJson(Map<String, dynamic>.from(e as Map))
        ]..sort((a, b) => b.time.compareTo(a.time));
      }
      if (_migrated) {
        _log
          ..clear()
          ..addAll(cloud);
        unawaited(_saveLog());
      } else {
        _log.addAll(cloud);
      }
      notifyListeners();
    }));

    _subs.add(_col('meta').snapshots(includeMetadataChanges: true).listen((qs) {
      for (final d in qs.docs) {
        _applyMeta(d.id, d.data());
      }
      if (!qs.metadata.isFromCache && syncingInitial) {
        syncingInitial = false;
        _syncTimer?.cancel();
      }
      notifyListeners();
    }));
  }

  void _applyMeta(String id, Map<String, dynamic> data) {
    final p = _prefs;
    final mirror = _migrated;
    switch (id) {
      case 'profile':
        profile = Profile.fromJson(data);
        if (mirror) unawaited(_write(_kProfile, data));
      case 'targets':
        targets = Targets.fromJson(data);
        if (mirror) unawaited(_write(_kTargets, data));
      case 'settings':
        settings = AppSettings.fromJson(data);
        if (mirror) unawaited(_write(_kSettings, data));
      case 'app':
        if (data['onboarded'] == true && !onboarded) {
          onboarded = true;
          unawaited(p?.setBool(_kOnboarded, true) ?? Future.value());
        }
      case 'snapshots':
        final list = data['list'];
        if (list is List) {
          snapshots = [
            for (final s in list)
              BodySnapshot.fromJson(Map<String, dynamic>.from(s as Map))
          ]..sort((a, b) => a.date.compareTo(b.date));
          if (mirror && p != null) {
            unawaited(p.setString(_kSnapshots, jsonEncode(list)));
          }
        }
      case 'overrides':
        final map = data['map'];
        if (map is Map) {
          foods.overrides = {
            for (final e in map.entries)
              e.key as String: FoodOverride.fromJson(
                  Map<String, dynamic>.from(e.value as Map))
          };
          if (mirror) unawaited(_write(_kOverrides, map));
        }
      case 'customFoods':
        final list = data['list'];
        if (list is List) {
          foods.customFoods = [
            for (final f in list)
              Food.fromJson(Map<String, dynamic>.from(f as Map), custom: true)
          ];
          if (mirror && p != null) {
            unawaited(p.setString(_kCustomFoods, jsonEncode(list)));
          }
        }
    }
  }

  void _cloudSet(String collection, String doc, Map<String, dynamic> data) {
    if (uid == null) return;
    _col(collection).doc(doc).set(data).then((_) {
      if (writeFailed) {
        writeFailed = false;
        notifyListeners();
      }
    }).catchError((_) {
      writeFailed = true;
      notifyListeners();
    });
  }

  void _cloudDay(String key) {
    final day = _days[key];
    if (day is Map) {
      _cloudSet('days', key, Map<String, dynamic>.from(day));
    }
  }

  void _cloudFood(String key) => _cloudSet('foodLog', key, {
        'entries': [for (final e in _log[key] ?? const <LogEntry>[]) e.toJson()]
      });

  Future<void> _migrateLocal() async {
    final p = _prefs;
    final u = uid;
    if (p == null || u == null || _migrated) return;
    try {
      const server = GetOptions(source: Source.server);
      final haveDays = {
        for (final d in (await _col('days').get(server)).docs) d.id
      };
      final haveFood = {
        for (final d in (await _col('foodLog').get(server)).docs) d.id
      };
      final haveMeta = {
        for (final d in (await _col('meta').get(server)).docs) d.id
      };
      if (uid != u) return;

      final writes = <(String, String, Map<String, dynamic>)>[];

      final localDays = _readJson(p, _kLegacy) ?? {};
      localDays.forEach((k, v) {
        if (v is Map && !haveDays.contains(k)) {
          writes.add(('days', k, Map<String, dynamic>.from(v)));
        }
      });

      final localLog = _readJson(p, _kFoodLog) ?? {};
      localLog.forEach((k, v) {
        if (v is List && v.isNotEmpty && !haveFood.contains(k)) {
          writes.add(('foodLog', k, {'entries': v}));
        }
      });

      if (!haveMeta.contains('profile')) {
        final j = _readJson(p, _kProfile);
        if (j != null) writes.add(('meta', 'profile', j));
      }
      if (!haveMeta.contains('targets')) {
        final j = _readJson(p, _kTargets);
        if (j != null) writes.add(('meta', 'targets', j));
      }
      if (!haveMeta.contains('settings')) {
        final j = _readJson(p, _kSettings);
        if (j != null) writes.add(('meta', 'settings', j));
      }
      if (!haveMeta.contains('snapshots')) {
        final raw = p.getString(_kSnapshots);
        if (raw != null) {
          writes.add(('meta', 'snapshots', {'list': jsonDecode(raw)}));
        }
      }
      if (!haveMeta.contains('overrides')) {
        final j = _readJson(p, _kOverrides);
        if (j != null && j.isNotEmpty) {
          writes.add(('meta', 'overrides', {'map': j}));
        }
      }
      if (!haveMeta.contains('customFoods')) {
        final raw = p.getString(_kCustomFoods);
        if (raw != null) {
          writes.add(('meta', 'customFoods', {'list': jsonDecode(raw)}));
        }
      }
      if (!haveMeta.contains('app') && (p.getBool(_kOnboarded) ?? false)) {
        writes.add(('meta', 'app', {'onboarded': true}));
      }

      for (var i = 0; i < writes.length; i += 400) {
        final batch = _fs.batch();
        for (final (col, doc, data)
            in writes.sublist(i, (i + 400).clamp(0, writes.length))) {
          batch.set(_col(col).doc(doc), data);
        }
        await batch.commit();
      }
      await p.setBool('bs.migrated.$u', true);
    } catch (_) {}
  }

  void _resetMemory() {
    _log.clear();
    _days = {};
    foods.overrides = {};
    foods.customFoods = [];
    profile = const Profile();
    targets = const Targets();
    settings = const AppSettings();
    snapshots = [];
    onboarded = _prefs?.getBool(_kOnboarded) ?? false;
  }

  List<LogEntry> entriesFor(DateTime date) =>
      List.unmodifiable(_log[dateKey(date)] ?? const []);

  DayTotals totalsFor(DateTime date) => DayTotals.of(entriesFor(date));

  Future<void> addEntry(DateTime date, LogEntry entry) async {
    final key = dateKey(date);
    final list = _log.putIfAbsent(key, () => []);
    list.add(entry);
    list.sort((a, b) => b.time.compareTo(a.time));
    notifyListeners();
    _cloudFood(key);
    await _saveLog();
  }

  Future<LogEntry?> deleteEntry(DateTime date, String id) async {
    final key = dateKey(date);
    final list = _log[key];
    if (list == null) return null;
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return null;
    final removed = list.removeAt(i);
    notifyListeners();
    _cloudFood(key);
    await _saveLog();
    return removed;
  }

  Future<void> updateEntry(DateTime date, LogEntry entry) async {
    final key = dateKey(date);
    final list = _log[key];
    if (list == null) return;
    final i = list.indexWhere((e) => e.id == entry.id);
    if (i < 0) return;
    list[i] = entry;
    notifyListeners();
    _cloudFood(key);
    await _saveLog();
  }

  Future<void> _saveLog() => _write(_kFoodLog, {
        for (final e in _log.entries)
          e.key: [for (final x in e.value) x.toJson()]
      });

  List<double> calorieSeries(int days) {
    final today = dayOnly(DateTime.now());
    return [
      for (var i = days - 1; i >= 0; i--)
        _dayCalories(today.subtract(Duration(days: i))),
    ];
  }

  double _dayCalories(DateTime date) {
    final entries = _log[dateKey(date)];
    if (entries != null && entries.isNotEmpty) {
      return DayTotals.of(entries).kcal;
    }
    final legacy = _days[dateKey(date)];
    if (legacy is Map && legacy['calories'] is num) {
      return (legacy['calories'] as num).toDouble();
    }
    return 0;
  }

  List<({LogEntry entry, int count})> recents(
      {int limit = 12, bool byTime = false}) {
    final seen = <String, ({LogEntry entry, int count})>{};
    final all = _log.values.expand((e) => e).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    for (final e in all) {
      if (e.quickAdd) continue;
      final key = '${e.foodId ?? e.name}|${e.portionLabel ?? e.portion}';
      final cur = seen[key];
      seen[key] = (entry: cur?.entry ?? e, count: (cur?.count ?? 0) + 1);
    }
    final list = seen.values.toList()
      ..sort((a, b) => byTime
          ? b.entry.time.compareTo(a.entry.time)
          : b.count.compareTo(a.count));
    return list.take(limit).toList();
  }

  Future<void> saveOverride(FoodOverride o) async {
    foods.overrides[o.key] = o;
    notifyListeners();
    await _persistOverrides();
  }

  Future<void> removeOverride(String key) async {
    foods.overrides.remove(key);
    notifyListeners();
    await _persistOverrides();
  }

  Future<void> _persistOverrides() async {
    final json = {
      for (final e in foods.overrides.entries) e.key: e.value.toJson()
    };
    _cloudSet('meta', 'overrides', {'map': json});
    await _write(_kOverrides, json);
  }

  Future<void> addCustomFood(Food food) async {
    foods.customFoods.insert(0, food);
    notifyListeners();
    if (recoveryNeeded) return;
    final json = [for (final f in foods.customFoods) f.toJson()];
    _cloudSet('meta', 'customFoods', {'list': json});
    try {
      await _prefs?.setString(_kCustomFoods, jsonEncode(json));
    } catch (_) {
      writeFailed = true;
      notifyListeners();
    }
  }

  Future<void> retryWrites() async {
    await _saveLog();
    await _write(_kLegacy, _days);
    await _saveSnapshots();
    await _persistOverrides();
    final json = [for (final f in foods.customFoods) f.toJson()];
    try {
      await _prefs?.setString(_kCustomFoods, jsonEncode(json));
    } catch (_) {
      writeFailed = true;
      notifyListeners();
    }
  }

  double? weightFor(DateTime date) {
    final v = (_days[dateKey(date)] as Map?)?['weight'];
    return v is num ? v.toDouble() : null;
  }

  DateTime? weightTimeFor(DateTime date) {
    final v = (_days[dateKey(date)] as Map?)?['weightAt'];
    return v is String ? DateTime.tryParse(v) : null;
  }

  Future<void> setWeight(DateTime date, double kg) async {
    final key = dateKey(date);
    final day = (_days[key] as Map?)?.cast<String, dynamic>() ?? {};
    day['weight'] = kg;
    if (dateKey(date) == dateKey(DateTime.now())) {
      day['weightAt'] = DateTime.now().toIso8601String();
    }
    _days[key] = day;
    notifyListeners();
    _cloudDay(key);
    await _write(_kLegacy, _days);
  }

  List<MapEntry<DateTime, double>> weightEntries() {
    final out = <MapEntry<DateTime, double>>[];
    _days.forEach((k, v) {
      if (v is Map && v['weight'] is num) {
        out.add(MapEntry(DateTime.parse(k), (v['weight'] as num).toDouble()));
      }
    });
    out.sort((a, b) => a.key.compareTo(b.key));
    return out;
  }

  double? get latestWeight {
    final entries = weightEntries();
    return entries.isEmpty ? null : entries.last.value;
  }

  double? weightDelta(int days) {
    final entries = weightEntries();
    if (entries.length < 2) return null;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    MapEntry<DateTime, double>? ref;
    for (final e in entries) {
      if (!e.key.isBefore(cutoff)) {
        ref = e;
        break;
      }
    }
    ref ??= entries.first;
    return entries.last.value - ref.value;
  }

  bool workoutOn(DateTime date) =>
      (_days[dateKey(date)] as Map?)?['workout'] == true;

  Set<int> markedDays(DateTime month) {
    final out = <int>{};
    _days.forEach((k, v) {
      if (v is Map && v['workout'] == true) {
        final d = DateTime.parse(k);
        if (d.year == month.year && d.month == month.month) out.add(d.day);
      }
    });
    return out;
  }

  Future<void> toggleWorkout(DateTime date) async {
    final key = dateKey(date);
    final day = (_days[key] as Map?)?.cast<String, dynamic>() ?? {};
    day['workout'] = !(day['workout'] == true);
    _days[key] = day;
    notifyListeners();
    _cloudDay(key);
    await _write(_kLegacy, _days);
  }

  int workoutStreak() {
    var day = dayOnly(DateTime.now());
    if (!workoutOn(day)) day = day.subtract(const Duration(days: 1));
    var streak = 0;
    while (workoutOn(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  DateTime? streakEnd() {
    final today = dayOnly(DateTime.now());
    if (workoutOn(today)) return today;
    final y = today.subtract(const Duration(days: 1));
    if (workoutOn(y)) return y;
    return null;
  }

  int workoutCount(DateTime month) => markedDays(month).length;

  List<double> workoutMonthlySeries(int months) {
    final now = DateTime.now();
    return [
      for (var i = months - 1; i >= 0; i--)
        workoutCount(DateTime(now.year, now.month - i)).toDouble(),
    ];
  }

  ({int total, DateTime? since}) workoutTotals() {
    var total = 0;
    DateTime? earliest;
    _days.forEach((k, v) {
      if (v is Map && v['workout'] == true) {
        total++;
        final d = DateTime.parse(k);
        if (earliest == null || d.isBefore(earliest!)) earliest = d;
      }
    });
    return (total: total, since: earliest);
  }

  DateTime? lastWorkout() {
    DateTime? last;
    _days.forEach((k, v) {
      if (v is Map && v['workout'] == true) {
        final d = DateTime.parse(k);
        if (last == null || d.isAfter(last!)) last = d;
      }
    });
    return last;
  }

  BodySnapshot? get latestSnapshot => snapshots.isEmpty ? null : snapshots.last;

  Future<void> addSnapshot(BodySnapshot snap) async {
    snapshots.add(snap);
    snapshots.sort((a, b) => a.date.compareTo(b.date));
    notifyListeners();
    await _saveSnapshots();
  }

  Future<void> replaceLatestSnapshot(BodySnapshot snap) async {
    if (snapshots.isNotEmpty) snapshots.removeLast();
    snapshots.add(snap);
    notifyListeners();
    await _saveSnapshots();
  }

  Future<void> _saveSnapshots() async {
    if (recoveryNeeded) return;
    final json = [for (final s in snapshots) s.toJson()];
    _cloudSet('meta', 'snapshots', {'list': json});
    try {
      await _prefs?.setString(_kSnapshots, jsonEncode(json));
    } catch (_) {
      writeFailed = true;
      notifyListeners();
    }
  }

  ({int day, int remaining, DateTime? last}) checkinCycle() {
    final cadence = settings.checkinCadenceDays;
    final last = latestSnapshot?.date;
    if (last == null) return (day: 0, remaining: cadence, last: null);
    final elapsed = dayOnly(DateTime.now()).difference(dayOnly(last)).inDays;
    final day = elapsed.clamp(0, cadence);
    return (
      day: day,
      remaining: (cadence - elapsed).clamp(0, cadence),
      last: last
    );
  }

  bool get checkinDue {
    if (latestSnapshot == null || checkinCycle().remaining > 0) return false;
    final snooze = settings.snoozedUntil;
    return snooze == null || !dayOnly(DateTime.now()).isBefore(dayOnly(snooze));
  }

  Future<void> snoozeCheckin(int days) => saveSettings(settings.copyWith(
      checkinSnoozedUntil:
          dateKey(dayOnly(DateTime.now()).add(Duration(days: days)))));

  ({
    double? fatPct,
    double? lean,
    double? bmr,
    double? tdee,
    String? source,
    String bmrSource,
  }) currentBodyStats() {
    final snap = latestSnapshot;
    final weight = latestWeight ?? snap?.weightKg;
    final fatPct = snap?.bodyFatPct;
    final bmr = Formulas.bmr(
      sex: profile.sex,
      age: profile.age,
      heightCm: profile.heightCm,
      weightKg: weight,
      fatPct: fatPct,
      overrideKcal: profile.bmrOverrideKcal,
    );
    final lean = Formulas.leanMass(weight, fatPct);
    return (
      fatPct: fatPct,
      lean: lean,
      bmr: bmr,
      tdee: Formulas.tdee(bmr, profile.activity),
      source: snap?.overrideSource,
      bmrSource:
          Formulas.bmrSource(lean, overrideKcal: profile.bmrOverrideKcal),
    );
  }

  Future<void> saveProfile(Profile p) async {
    profile = p;
    notifyListeners();
    _cloudSet('meta', 'profile', p.toJson());
    await _write(_kProfile, p.toJson());
  }

  Future<void> saveTargets(Targets t) async {
    targets = t;
    notifyListeners();
    _cloudSet('meta', 'targets', t.toJson());
    await _write(_kTargets, t.toJson());
  }

  Future<void> saveSettings(AppSettings s) async {
    settings = s;
    notifyListeners();
    _cloudSet('meta', 'settings', s.toJson());
    await _write(_kSettings, s.toJson());
  }

  Future<void> finishOnboarding() async {
    onboarded = true;
    notifyListeners();
    _cloudSet('meta', 'app', {'onboarded': true});
    await _prefs?.setBool(_kOnboarded, true);
  }

  int storageBytes() {
    final p = _prefs;
    if (p == null) return 0;
    var total = 0;
    for (final k in [
      _kFoodLog,
      _kOverrides,
      _kCustomFoods,
      _kProfile,
      _kTargets,
      _kSettings,
      _kSnapshots,
      _kLegacy,
    ]) {
      total += p.getString(k)?.length ?? 0;
    }
    return total;
  }

  ({
    int foodEntries,
    int weighIns,
    int workoutDays,
    int checkins,
    int overrides,
    int daysLogged,
    DateTime? since
  }) storageStats() {
    var foodEntries = 0;
    final daysWithData = <String>{};
    for (final e in _log.entries) {
      if (e.value.isNotEmpty) {
        foodEntries += e.value.length;
        daysWithData.add(e.key);
      }
    }
    var weighIns = 0, workoutDays = 0;
    DateTime? since;
    _days.forEach((k, v) {
      if (v is! Map) return;
      var has = false;
      if (v['weight'] is num) {
        weighIns++;
        has = true;
      }
      if (v['workout'] == true) {
        workoutDays++;
        has = true;
      }
      if (has) {
        daysWithData.add(k);
        final d = DateTime.parse(k);
        if (since == null || d.isBefore(since!)) since = d;
      }
    });
    for (final k in _log.keys) {
      final d = DateTime.parse(k);
      if (since == null || d.isBefore(since!)) since = d;
    }
    return (
      foodEntries: foodEntries,
      weighIns: weighIns,
      workoutDays: workoutDays,
      checkins: snapshots.length,
      overrides: foods.overrides.length + foods.customFoods.length,
      daysLogged: daysWithData.length,
      since: since,
    );
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'exported': DateTime.now().toIso8601String(),
        'days': _days,
        'foodLog': {
          for (final e in _log.entries)
            e.key: [for (final x in e.value) x.toJson()]
        },
        'overrides': {
          for (final e in foods.overrides.entries) e.key: e.value.toJson()
        },
        'customFoods': [for (final f in foods.customFoods) f.toJson()],
        'profile': profile.toJson(),
        'targets': targets.toJson(),
        'settings': settings.toJson(),
        'snapshots': [for (final s in snapshots) s.toJson()],
      });

  Future<void> recordExport() async {
    await _prefs?.setString(_kLastExport, DateTime.now().toIso8601String());
    notifyListeners();
  }

  Future<({int days, int entries, int snapshots, int foods})> importJson(
      String raw) async {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('Not a readable JSON file');
    }
    if (data['foodLog'] == null && data['days'] == null) {
      throw const FormatException('Not a BodySync export');
    }

    var addedDays = 0, addedEntries = 0, addedSnaps = 0, addedFoods = 0;

    final days = data['days'];
    if (days is Map) {
      days.forEach((k, v) {
        if (v is! Map) return;
        final key = k.toString();
        final existing = (_days[key] as Map?)?.cast<String, dynamic>();
        if (existing == null) {
          _days[key] = Map<String, dynamic>.from(v);
          addedDays++;
        } else {
          var grew = false;
          v.forEach((f, val) {
            if (!existing.containsKey(f)) {
              existing[f] = val;
              grew = true;
            }
          });
          if (grew) {
            _days[key] = existing;
            addedDays++;
          }
        }
      });
    }

    final log = data['foodLog'];
    if (log is Map) {
      log.forEach((k, v) {
        if (v is! List) return;
        final key = k.toString();
        final list = _log.putIfAbsent(key, () => []);
        final have = {for (final e in list) e.id};
        for (final e in v) {
          try {
            final entry =
                LogEntry.fromJson(Map<String, dynamic>.from(e as Map));
            if (have.add(entry.id)) {
              list.add(entry);
              addedEntries++;
            }
          } catch (_) {}
        }
        list.sort((a, b) => b.time.compareTo(a.time));
      });
    }

    final snaps = data['snapshots'];
    if (snaps is List) {
      final have = {for (final s in snapshots) dateKey(s.date)};
      for (final s in snaps) {
        try {
          final snap =
              BodySnapshot.fromJson(Map<String, dynamic>.from(s as Map));
          if (have.add(dateKey(snap.date))) {
            snapshots.add(snap);
            addedSnaps++;
          }
        } catch (_) {}
      }
      snapshots.sort((a, b) => a.date.compareTo(b.date));
    }

    final ov = data['overrides'];
    if (ov is Map) {
      ov.forEach((k, v) {
        try {
          final o = FoodOverride.fromJson(Map<String, dynamic>.from(v as Map));
          if (!foods.overrides.containsKey(k)) {
            foods.overrides[k.toString()] = o;
            addedFoods++;
          }
        } catch (_) {}
      });
    }

    final cf = data['customFoods'];
    if (cf is List) {
      final have = {for (final f in foods.customFoods) f.id};
      for (final f in cf) {
        try {
          final food =
              Food.fromJson(Map<String, dynamic>.from(f as Map), custom: true);
          if (have.add(food.id)) {
            foods.customFoods.add(food);
            addedFoods++;
          }
        } catch (_) {}
      }
    }

    if (!onboarded) {
      final prof = data['profile'];
      if (prof is Map) {
        profile = Profile.fromJson(Map<String, dynamic>.from(prof));
      }
      final t = data['targets'];
      if (t is Map) targets = Targets.fromJson(Map<String, dynamic>.from(t));
      final s = data['settings'];
      if (s is Map) {
        settings = AppSettings.fromJson(Map<String, dynamic>.from(s));
      }
    }

    notifyListeners();
    await _saveLog();
    await _write(_kLegacy, _days);
    await _saveSnapshots();
    await _persistOverrides();
    final cfJson = [for (final f in foods.customFoods) f.toJson()];
    _cloudSet('meta', 'customFoods', {'list': cfJson});
    try {
      await _prefs?.setString(_kCustomFoods, jsonEncode(cfJson));
    } catch (_) {}
    if (!onboarded) {
      await _write(_kProfile, profile.toJson());
      await _write(_kTargets, targets.toJson());
      await _write(_kSettings, settings.toJson());
    }
    if (uid != null) {
      for (final e in _log.entries) {
        if (e.value.isNotEmpty) _cloudFood(e.key);
      }
      for (final k in _days.keys) {
        _cloudDay(k);
      }
    }

    return (
      days: addedDays,
      entries: addedEntries,
      snapshots: addedSnaps,
      foods: addedFoods,
    );
  }

  Future<void> eraseAll() async {
    final p = _prefs;
    if (p == null) return;
    for (final k in [
      _kFoodLog,
      _kOverrides,
      _kCustomFoods,
      _kProfile,
      _kTargets,
      _kSettings,
      _kSnapshots,
      _kOnboarded,
      _kLegacy,
    ]) {
      await p.remove(k);
    }
    if (uid != null) {
      try {
        for (final col in ['days', 'foodLog', 'meta']) {
          final docs = (await _col(col).get()).docs;
          for (var i = 0; i < docs.length; i += 400) {
            final batch = _fs.batch();
            for (final d in docs.sublist(i, (i + 400).clamp(0, docs.length))) {
              batch.delete(d.reference);
            }
            await batch.commit();
          }
        }
      } catch (_) {
        writeFailed = true;
      }
    }
    _log.clear();
    _days = {};
    foods.overrides = {};
    foods.customFoods = [];
    profile = const Profile();
    targets = const Targets();
    settings = const AppSettings();
    snapshots = [];
    onboarded = false;
    unreadableCount = 0;
    notifyListeners();
  }
}
