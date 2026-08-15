import 'dart:math' as math;
import 'models.dart';

abstract final class Formulas {
  static double? navyBodyFat({
    required Sex? sex,
    required double? heightCm,
    required double? neckCm,
    required double? waistCm,
    double? hipCm,
  }) {
    if (sex == null) return null;
    if (heightCm == null || neckCm == null || waistCm == null) return null;
    if (heightCm <= 0 || neckCm <= 0 || waistCm <= 0) return null;
    double pct;
    if (sex == Sex.male) {
      if (waistCm - neckCm <= 0) return null;
      pct = 495 /
              (1.0324 -
                  0.19077 * _log10(waistCm - neckCm) +
                  0.15456 * _log10(heightCm)) -
          450;
    } else {
      final hip = hipCm ?? waistCm * 1.24;
      if (waistCm + hip - neckCm <= 0) return null;
      pct = 495 /
              (1.29579 -
                  0.35004 * _log10(waistCm + hip - neckCm) +
                  0.22100 * _log10(heightCm)) -
          450;
    }
    if (pct.isNaN || pct.isInfinite) return null;
    return pct.clamp(2.0, 60.0);
  }

  static double? mifflinStJeor({
    required Sex? sex,
    required int? age,
    required double? heightCm,
    required double? weightKg,
  }) {
    if (sex == null || age == null || heightCm == null || weightKg == null) {
      return null;
    }
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return sex == Sex.male ? base + 5 : base - 161;
  }

  static double? katchMcArdle(double? leanKg) =>
      leanKg == null || leanKg <= 0 ? null : 370 + 21.6 * leanKg;

  static double? bmr({
    required Sex? sex,
    required int? age,
    required double? heightCm,
    required double? weightKg,
    double? fatPct,
    double? overrideKcal,
  }) =>
      overrideKcal ??
      katchMcArdle(leanMass(weightKg, fatPct)) ??
      mifflinStJeor(sex: sex, age: age, heightCm: heightCm, weightKg: weightKg);

  static String bmrSource(double? leanKg, {double? overrideKcal}) =>
      overrideKcal != null
          ? 'Metabolic test'
          : leanKg != null && leanKg > 0
              ? 'Katch-McArdle'
              : 'Mifflin-St Jeor';

  static double? tdee(double? bmr, ActivityLevel activity) =>
      bmr == null ? null : bmr * activity.multiplier;

  static double? leanMass(double? weightKg, double? fatPct) =>
      weightKg == null || fatPct == null ? null : weightKg * (1 - fatPct / 100);

  static double roundTarget(double tdee) => (tdee / 10).floorToDouble() * 10;

  static double _log10(double x) => math.log(x) / math.ln10;
}
