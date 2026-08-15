library;

class FoodPortion {
  final String label;
  final String per;
  final double kcal;
  final double p;
  final double c;
  final double f;

  const FoodPortion({
    required this.label,
    required this.per,
    required this.kcal,
    required this.p,
    required this.c,
    required this.f,
  });

  factory FoodPortion.fromJson(Map<String, dynamic> json) => FoodPortion(
        label: json['label'] as String,
        per: json['per'] as String,
        kcal: (json['kcal'] as num).toDouble(),
        p: (json['p'] as num).toDouble(),
        c: (json['c'] as num).toDouble(),
        f: (json['f'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() =>
      {'label': label, 'per': per, 'kcal': kcal, 'p': p, 'c': c, 'f': f};

  FoodPortion copyWith({double? kcal, double? p, double? c, double? f}) =>
      FoodPortion(
        label: label,
        per: per,
        kcal: kcal ?? this.kcal,
        p: p ?? this.p,
        c: c ?? this.c,
        f: f ?? this.f,
      );
}

class Food {
  final String id;
  final String name;
  final List<FoodPortion> portions;
  final bool custom;

  const Food({
    required this.id,
    required this.name,
    required this.portions,
    this.custom = false,
  });

  factory Food.fromJson(Map<String, dynamic> json, {bool custom = false}) =>
      Food(
        id: json['id'] as String,
        name: json['name'] as String,
        custom: custom || (json['custom'] as bool? ?? false),
        portions: [
          for (final p in json['portions'] as List)
            FoodPortion.fromJson(p as Map<String, dynamic>)
        ],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (custom) 'custom': true,
        'portions': [for (final p in portions) p.toJson()],
      };

  String displayName(FoodPortion portion) {
    if (portions.length <= 1) return name;
    final label = portion.label;
    const sizes = {'Large', 'Medium', 'Small', 'Half', 'Whole'};
    if (sizes.contains(label)) {
      return '$name, ${label.toLowerCase()}';
    }
    return name;
  }
}

class FoodOverride {
  final String foodId;
  final String portionLabel;
  final double kcal;
  final double p;
  final double c;
  final double f;
  final DateTime edited;

  const FoodOverride({
    required this.foodId,
    required this.portionLabel,
    required this.kcal,
    required this.p,
    required this.c,
    required this.f,
    required this.edited,
  });

  String get key => '$foodId|$portionLabel';

  factory FoodOverride.fromJson(Map<String, dynamic> json) => FoodOverride(
        foodId: json['foodId'] as String,
        portionLabel: json['portionLabel'] as String,
        kcal: (json['kcal'] as num).toDouble(),
        p: (json['p'] as num).toDouble(),
        c: (json['c'] as num).toDouble(),
        f: (json['f'] as num).toDouble(),
        edited: DateTime.parse(json['edited'] as String),
      );

  Map<String, dynamic> toJson() => {
        'foodId': foodId,
        'portionLabel': portionLabel,
        'kcal': kcal,
        'p': p,
        'c': c,
        'f': f,
        'edited': edited.toIso8601String(),
      };
}

class LogEntry {
  final String id;
  final DateTime time;
  final String name;
  final String? foodId;
  final String? portionLabel;
  final String portion;
  final double qty;
  final double kcal;
  final double p;
  final double c;
  final double f;
  final bool own;
  final bool quickAdd;

  const LogEntry({
    required this.id,
    required this.time,
    required this.name,
    this.foodId,
    this.portionLabel,
    required this.portion,
    this.qty = 1,
    required this.kcal,
    required this.p,
    required this.c,
    required this.f,
    this.own = false,
    this.quickAdd = false,
  });

  static String mealOf(DateTime time) {
    final h = time.hour + time.minute / 60;
    if (h >= 5 && h < 11) return 'Breakfast';
    if (h >= 11.5 && h < 14.5) return 'Lunch';
    if (h >= 17.5 && h < 21.5) return 'Dinner';
    return 'Snack';
  }

  String get meal => mealOf(time);

  String get timeLabel =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        id: json['id'] as String,
        time: DateTime.parse(json['time'] as String),
        name: json['name'] as String,
        foodId: json['foodId'] as String?,
        portionLabel: json['portionLabel'] as String?,
        portion: json['portion'] as String? ?? '',
        qty: (json['qty'] as num?)?.toDouble() ?? 1,
        kcal: (json['kcal'] as num).toDouble(),
        p: (json['p'] as num?)?.toDouble() ?? 0,
        c: (json['c'] as num?)?.toDouble() ?? 0,
        f: (json['f'] as num?)?.toDouble() ?? 0,
        own: json['own'] as bool? ?? false,
        quickAdd: json['quickAdd'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time.toIso8601String(),
        'name': name,
        if (foodId != null) 'foodId': foodId,
        if (portionLabel != null) 'portionLabel': portionLabel,
        'portion': portion,
        'qty': qty,
        'kcal': kcal,
        'p': p,
        'c': c,
        'f': f,
        if (own) 'own': true,
        if (quickAdd) 'quickAdd': true,
      };
}

class DayTotals {
  final double kcal;
  final double p;
  final double c;
  final double f;
  const DayTotals(this.kcal, this.p, this.c, this.f);

  static DayTotals of(Iterable<LogEntry> entries) {
    var kcal = 0.0, p = 0.0, c = 0.0, f = 0.0;
    for (final e in entries) {
      kcal += e.kcal;
      p += e.p;
      c += e.c;
      f += e.f;
    }
    return DayTotals(kcal, p, c, f);
  }
}

enum Sex { female, male }

enum ActivityLevel {
  sedentary(1.2, 'Sedentary', 'Desk work, little walking'),
  light(1.375, 'Light', '1–3 sessions a week'),
  moderate(1.5, 'Moderate', '3–5 sessions a week'),
  active(1.725, 'Active', '6–7 sessions a week'),
  veryActive(1.9, 'Very active', 'Physical job or two-a-days');

  final double multiplier;
  final String label;
  final String description;
  const ActivityLevel(this.multiplier, this.label, this.description);
}

class Profile {
  final int? age;

  final Sex? sex;
  final double? heightCm;
  final ActivityLevel activity;

  final double? bmrOverrideKcal;

  const Profile({
    this.age,
    this.sex,
    this.heightCm,
    this.activity = ActivityLevel.moderate,
    this.bmrOverrideKcal,
  });

  bool get complete => age != null && sex != null && heightCm != null;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        age: json['age'] as int?,
        sex: switch (json['sex']) {
          'male' => Sex.male,
          'female' => Sex.female,
          _ => null,
        },
        heightCm: (json['heightCm'] as num?)?.toDouble(),
        activity: ActivityLevel.values.firstWhere(
          (a) => a.name == json['activity'],
          orElse: () => ActivityLevel.moderate,
        ),
        bmrOverrideKcal: (json['bmrOverrideKcal'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        if (age != null) 'age': age,
        if (sex != null) 'sex': sex!.name,
        if (heightCm != null) 'heightCm': heightCm,
        'activity': activity.name,
        if (bmrOverrideKcal != null) 'bmrOverrideKcal': bmrOverrideKcal,
      };

  static const _unset = Object();

  Profile copyWith({
    Object? age = _unset,
    Object? sex = _unset,
    Object? heightCm = _unset,
    ActivityLevel? activity,
    Object? bmrOverrideKcal = _unset,
  }) =>
      Profile(
        age: identical(age, _unset) ? this.age : age as int?,
        sex: identical(sex, _unset) ? this.sex : sex as Sex?,
        heightCm:
            identical(heightCm, _unset) ? this.heightCm : heightCm as double?,
        activity: activity ?? this.activity,
        bmrOverrideKcal: identical(bmrOverrideKcal, _unset)
            ? this.bmrOverrideKcal
            : bmrOverrideKcal as double?,
      );
}

class BodySnapshot {
  final DateTime date;
  final double? weightKg;
  final double? neckCm;
  final double? waistCm;
  final double? hipCm;
  final double? bodyFatPct;
  final double? leanKg;
  final double? bmr;
  final double? tdee;
  final String? overrideSource;
  final double? estimatedFatPct;

  const BodySnapshot({
    required this.date,
    this.weightKg,
    this.neckCm,
    this.waistCm,
    this.hipCm,
    this.bodyFatPct,
    this.leanKg,
    this.bmr,
    this.tdee,
    this.overrideSource,
    this.estimatedFatPct,
  });

  factory BodySnapshot.fromJson(Map<String, dynamic> json) => BodySnapshot(
        date: DateTime.parse(json['date'] as String),
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        neckCm: (json['neckCm'] as num?)?.toDouble(),
        waistCm: (json['waistCm'] as num?)?.toDouble(),
        hipCm: (json['hipCm'] as num?)?.toDouble(),
        bodyFatPct: (json['bodyFatPct'] as num?)?.toDouble(),
        leanKg: (json['leanKg'] as num?)?.toDouble(),
        bmr: (json['bmr'] as num?)?.toDouble(),
        tdee: (json['tdee'] as num?)?.toDouble(),
        overrideSource: json['overrideSource'] as String?,
        estimatedFatPct: (json['estimatedFatPct'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        if (weightKg != null) 'weightKg': weightKg,
        if (neckCm != null) 'neckCm': neckCm,
        if (waistCm != null) 'waistCm': waistCm,
        if (hipCm != null) 'hipCm': hipCm,
        if (bodyFatPct != null) 'bodyFatPct': bodyFatPct,
        if (leanKg != null) 'leanKg': leanKg,
        if (bmr != null) 'bmr': bmr,
        if (tdee != null) 'tdee': tdee,
        if (overrideSource != null) 'overrideSource': overrideSource,
        if (estimatedFatPct != null) 'estimatedFatPct': estimatedFatPct,
      };

  static const _unset = Object();

  BodySnapshot copyWith({
    DateTime? date,
    Object? weightKg = _unset,
    Object? neckCm = _unset,
    Object? waistCm = _unset,
    Object? hipCm = _unset,
    Object? bodyFatPct = _unset,
    Object? leanKg = _unset,
    Object? bmr = _unset,
    Object? tdee = _unset,
    Object? overrideSource = _unset,
    Object? estimatedFatPct = _unset,
  }) =>
      BodySnapshot(
        date: date ?? this.date,
        weightKg:
            identical(weightKg, _unset) ? this.weightKg : weightKg as double?,
        neckCm: identical(neckCm, _unset) ? this.neckCm : neckCm as double?,
        waistCm: identical(waistCm, _unset) ? this.waistCm : waistCm as double?,
        hipCm: identical(hipCm, _unset) ? this.hipCm : hipCm as double?,
        bodyFatPct: identical(bodyFatPct, _unset)
            ? this.bodyFatPct
            : bodyFatPct as double?,
        leanKg: identical(leanKg, _unset) ? this.leanKg : leanKg as double?,
        bmr: identical(bmr, _unset) ? this.bmr : bmr as double?,
        tdee: identical(tdee, _unset) ? this.tdee : tdee as double?,
        overrideSource: identical(overrideSource, _unset)
            ? this.overrideSource
            : overrideSource as String?,
        estimatedFatPct: identical(estimatedFatPct, _unset)
            ? this.estimatedFatPct
            : estimatedFatPct as double?,
      );
}

class Targets {
  final double kcal;
  final double p;
  final double c;
  final double f;

  const Targets({
    this.kcal = 2000,
    this.p = 125,
    this.c = 225,
    this.f = 67,
  });

  factory Targets.fromJson(Map<String, dynamic> json) => Targets(
        kcal: (json['kcal'] as num).toDouble(),
        p: (json['p'] as num).toDouble(),
        c: (json['c'] as num).toDouble(),
        f: (json['f'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'kcal': kcal, 'p': p, 'c': c, 'f': f};

  factory Targets.balanced(double kcal) => Targets(
        kcal: kcal,
        p: (kcal * .26 / 4).roundToDouble(),
        c: (kcal * .44 / 4).roundToDouble(),
        f: (kcal * .30 / 9).roundToDouble(),
      );

  factory Targets.higherProtein(double kcal) => Targets(
        kcal: kcal,
        p: (kcal * .34 / 4).roundToDouble(),
        c: (kcal * .38 / 4).roundToDouble(),
        f: (kcal * .28 / 9).roundToDouble(),
      );
}

class AppSettings {
  final String themeMode;
  final bool reminderOn;
  final int reminderHour;
  final int reminderMinute;
  final bool checkinNudgeOn;
  final int checkinCadenceDays;
  final String units;
  final String startOfWeek;

  final bool todayBannerOn;

  final String checkinSnoozedUntil;

  const AppSettings({
    this.themeMode = 'system',
    this.reminderOn = true,
    this.reminderHour = 21,
    this.reminderMinute = 0,
    this.checkinNudgeOn = true,
    this.checkinCadenceDays = 30,
    this.units = 'metric',
    this.startOfWeek = 'sun',
    this.todayBannerOn = true,
    this.checkinSnoozedUntil = '',
  });

  String get reminderLabel =>
      '${reminderHour.toString().padLeft(2, '0')}:${reminderMinute.toString().padLeft(2, '0')}';

  bool get imperial => units == 'imperial';

  DateTime? get snoozedUntil => checkinSnoozedUntil.isEmpty
      ? null
      : DateTime.tryParse(checkinSnoozedUntil);

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: json['themeMode'] as String? ?? 'system',
        reminderOn: json['reminderOn'] as bool? ?? true,
        reminderHour: json['reminderHour'] as int? ?? 21,
        reminderMinute: json['reminderMinute'] as int? ?? 0,
        checkinNudgeOn: json['checkinNudgeOn'] as bool? ?? true,
        checkinCadenceDays: json['checkinCadenceDays'] as int? ?? 30,
        units: json['units'] as String? ?? 'metric',
        startOfWeek: json['startOfWeek'] as String? ?? 'sun',
        todayBannerOn: json['todayBannerOn'] as bool? ?? true,
        checkinSnoozedUntil: json['checkinSnoozedUntil'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'reminderOn': reminderOn,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'checkinNudgeOn': checkinNudgeOn,
        'checkinCadenceDays': checkinCadenceDays,
        'units': units,
        'startOfWeek': startOfWeek,
        'todayBannerOn': todayBannerOn,
        if (checkinSnoozedUntil.isNotEmpty)
          'checkinSnoozedUntil': checkinSnoozedUntil,
      };

  AppSettings copyWith({
    String? themeMode,
    bool? reminderOn,
    int? reminderHour,
    int? reminderMinute,
    bool? checkinNudgeOn,
    int? checkinCadenceDays,
    String? units,
    String? startOfWeek,
    bool? todayBannerOn,
    String? checkinSnoozedUntil,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        reminderOn: reminderOn ?? this.reminderOn,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
        checkinNudgeOn: checkinNudgeOn ?? this.checkinNudgeOn,
        checkinCadenceDays: checkinCadenceDays ?? this.checkinCadenceDays,
        units: units ?? this.units,
        startOfWeek: startOfWeek ?? this.startOfWeek,
        todayBannerOn: todayBannerOn ?? this.todayBannerOn,
        checkinSnoozedUntil: checkinSnoozedUntil ?? this.checkinSnoozedUntil,
      );
}

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
