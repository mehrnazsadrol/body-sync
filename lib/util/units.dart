import '../data/models.dart';

class Units {
  final bool imperial;
  const Units(this.imperial);
  factory Units.of(AppSettings s) => Units(s.imperial);

  static const kgPerLb = 0.45359237;
  static const cmPerIn = 2.54;

  String get weightUnit => imperial ? 'lb' : 'kg';
  String get lengthUnit => imperial ? 'in' : 'cm';

  double kgOut(num kg) => imperial ? kg / kgPerLb : kg.toDouble();

  double kgIn(num typed) => imperial ? typed * kgPerLb : typed.toDouble();

  double cmOut(num cm) => imperial ? cm / cmPerIn : cm.toDouble();

  double cmIn(num typed) => imperial ? typed * cmPerIn : typed.toDouble();
}
