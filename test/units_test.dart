import 'package:body_sync/util/units.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Units', () {
    const metric = Units(false);
    const imperial = Units(true);

    test('metric passes values through unchanged', () {
      expect(metric.kgOut(68.4), 68.4);
      expect(metric.kgIn(68.4), 68.4);
      expect(metric.cmOut(172), 172);
      expect(metric.cmIn(172), 172);
      expect(metric.weightUnit, 'kg');
      expect(metric.lengthUnit, 'cm');
    });

    test('imperial converts and round-trips', () {
      expect(imperial.kgOut(68.4), closeTo(150.8, 0.05));
      expect(imperial.kgIn(imperial.kgOut(68.4)), closeTo(68.4, 1e-9));
      expect(imperial.cmOut(172), closeTo(67.7, 0.05));
      expect(imperial.cmIn(imperial.cmOut(172)), closeTo(172, 1e-9));
      expect(imperial.weightUnit, 'lb');
      expect(imperial.lengthUnit, 'in');
    });

    test('deltas convert linearly through kgOut', () {
      expect(imperial.kgOut(-1.2), closeTo(-2.65, 0.01));
    });
  });
}
