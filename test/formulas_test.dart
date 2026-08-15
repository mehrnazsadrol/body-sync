import 'package:flutter_test/flutter_test.dart';
import 'package:body_sync/data/formulas.dart';
import 'package:body_sync/data/models.dart';

void main() {
  group('Mifflin-St Jeor', () {
    test('matches the design sample: female, 29, 172 cm, 68.4 kg → 1453', () {
      final bmr = Formulas.mifflinStJeor(
        sex: Sex.female,
        age: 29,
        heightCm: 172,
        weightKg: 68.4,
      );
      expect(bmr, isNotNull);
      expect(bmr!.round(), 1453);
    });

    test('matches the onboarding sample: 69.6 kg → 1465', () {
      final bmr = Formulas.mifflinStJeor(
        sex: Sex.female,
        age: 29,
        heightCm: 172,
        weightKg: 69.6,
      );
      expect(bmr!.round(), 1465);
    });

    test('male adds 5 instead of subtracting 161', () {
      final f = Formulas.mifflinStJeor(
          sex: Sex.female, age: 30, heightCm: 180, weightKg: 80)!;
      final m = Formulas.mifflinStJeor(
          sex: Sex.male, age: 30, heightCm: 180, weightKg: 80)!;
      expect(m - f, 166);
    });

    test('returns null when inputs are missing', () {
      expect(
        Formulas.mifflinStJeor(
            sex: Sex.female, age: null, heightCm: 172, weightKg: 68),
        isNull,
      );
    });
  });

  group('TDEE', () {
    test('moderate ×1.5 rounds to the sample targets', () {
      final bmr = Formulas.mifflinStJeor(
        sex: Sex.female,
        age: 29,
        heightCm: 172,
        weightKg: 68.4,
      );
      final tdee = Formulas.tdee(bmr, ActivityLevel.moderate)!;
      expect(tdee.round(), 2180);
      expect(Formulas.roundTarget(tdee.roundToDouble()), 2180);
    });

    test('target rounds down to nearest 10', () {
      expect(Formulas.roundTarget(2198), 2190);
      expect(Formulas.roundTarget(2199.9), 2190);
      expect(Formulas.roundTarget(2200), 2200);
    });
  });

  group('Navy body fat', () {
    test('female estimate lands in a plausible range for sample inputs', () {
      final pct = Formulas.navyBodyFat(
        sex: Sex.female,
        heightCm: 172,
        neckCm: 34.5,
        waistCm: 78.0,
        hipCm: 96.5,
      );
      expect(pct, isNotNull);
      expect(pct!, greaterThan(20));
      expect(pct, lessThan(35));
    });

    test('hip skipped falls back to a default ratio, still estimates', () {
      final pct = Formulas.navyBodyFat(
        sex: Sex.female,
        heightCm: 172,
        neckCm: 35.0,
        waistCm: 80.0,
        hipCm: null,
      );
      expect(pct, isNotNull);
      expect(pct!, greaterThan(15));
      expect(pct, lessThan(45));
    });

    test('male formula needs waist > neck', () {
      expect(
        Formulas.navyBodyFat(
            sex: Sex.male, heightCm: 180, neckCm: 40, waistCm: 38),
        isNull,
      );
    });

    test('missing measurements return null', () {
      expect(
        Formulas.navyBodyFat(
            sex: Sex.female, heightCm: 172, neckCm: null, waistCm: 78),
        isNull,
      );
    });
  });

  group('Lean mass', () {
    test('weight × (1 − fat%)', () {
      expect(Formulas.leanMass(68.4, 27.1)!.toStringAsFixed(1), '49.9');
    });
  });

  group('Katch-McArdle', () {
    test('370 + 21.6 × lean mass', () {
      expect(Formulas.katchMcArdle(49.9)!.round(), 1448);
    });

    test('missing or non-positive lean mass returns null', () {
      expect(Formulas.katchMcArdle(null), isNull);
      expect(Formulas.katchMcArdle(0), isNull);
    });
  });

  group('Best-available BMR', () {
    test('prefers Katch-McArdle when body fat is known', () {
      final bmr = Formulas.bmr(
        sex: Sex.female,
        age: 29,
        heightCm: 172,
        weightKg: 68.4,
        fatPct: 27.1,
      );
      final lean = Formulas.leanMass(68.4, 27.1);
      expect(bmr, Formulas.katchMcArdle(lean));
    });

    test('falls back to Mifflin-St Jeor without body fat', () {
      final bmr = Formulas.bmr(
        sex: Sex.female,
        age: 29,
        heightCm: 172,
        weightKg: 68.4,
      );
      expect(bmr!.round(), 1453);
    });

    test('Katch-McArdle path needs no age or height', () {
      final bmr = Formulas.bmr(
        sex: Sex.female,
        age: null,
        heightCm: null,
        weightKg: 68.4,
        fatPct: 27.1,
      );
      expect(bmr, isNotNull);
    });

    test('source label follows lean-mass availability', () {
      expect(Formulas.bmrSource(49.9), 'Katch-McArdle');
      expect(Formulas.bmrSource(null), 'Mifflin-St Jeor');
    });
  });

  group('Targets macro splits', () {
    test('balanced split adds back to roughly the calorie target', () {
      final t = Targets.balanced(2180);
      final macroKcal = t.p * 4 + t.c * 4 + t.f * 9;
      expect((macroKcal - t.kcal).abs(), lessThan(25));
    });
  });
}
