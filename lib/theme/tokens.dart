import 'package:flutter/material.dart';

class BSColors extends ThemeExtension<BSColors> {
  final Color bg;
  final Color surface;
  final Color sunk;
  final Color raised;
  final Color scrim;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color line;
  final Color track;
  final Color cal;
  final Color calInk;
  final Color calSoft;
  final Color pro;
  final Color proInk;
  final Color proSoft;
  final Color carb;
  final Color carbInk;
  final Color carbSoft;
  final Color fat;
  final Color fatInk;
  final Color fatSoft;
  final Color onAccent;
  final Color danger;
  final Color dangerSoft;
  final List<BoxShadow> eCard;
  final List<BoxShadow> eNav;
  final List<BoxShadow> eSheet;

  const BSColors({
    required this.bg,
    required this.surface,
    required this.sunk,
    required this.raised,
    required this.scrim,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.line,
    required this.track,
    required this.cal,
    required this.calInk,
    required this.calSoft,
    required this.pro,
    required this.proInk,
    required this.proSoft,
    required this.carb,
    required this.carbInk,
    required this.carbSoft,
    required this.fat,
    required this.fatInk,
    required this.fatSoft,
    required this.onAccent,
    required this.danger,
    required this.dangerSoft,
    required this.eCard,
    required this.eNav,
    required this.eSheet,
  });

  Color get accent => cal;
  Color get accentInk => calInk;
  Color get accentSoft => calSoft;

  Color hue(String h) => switch (h) {
        'pro' => pro,
        'carb' => carb,
        'fat' => fat,
        _ => cal,
      };
  Color hueInk(String h) => switch (h) {
        'pro' => proInk,
        'carb' => carbInk,
        'fat' => fatInk,
        _ => calInk,
      };
  Color hueSoft(String h) => switch (h) {
        'pro' => proSoft,
        'carb' => carbSoft,
        'fat' => fatSoft,
        _ => calSoft,
      };

  static const light = BSColors(
    bg: Color(0xFFF4F4F3),
    surface: Color(0xFFFFFFFF),
    sunk: Color(0xFFEFEFEE),
    raised: Color(0xFFFFFFFF),
    scrim: Color(0x5718191C),
    ink: Color(0xFF1B1C1F),
    ink2: Color(0xFF575A61),
    ink3: Color(0xFF63676E),
    line: Color(0xFFE7E7E5),
    track: Color(0xFFECECEA),
    cal: Color(0xFF33A886),
    calInk: Color(0xFF1C7C60),
    calSoft: Color(0xFFE3F4EE),
    pro: Color(0xFF7B67DC),
    proInk: Color(0xFF5B48C0),
    proSoft: Color(0xFFECE7FC),
    carb: Color(0xFFF2988A),
    carbInk: Color(0xFF79392F),
    carbSoft: Color(0xFFF7E6E3),
    fat: Color(0xFFC93C84),
    fatInk: Color(0xFFA82A6B),
    fatSoft: Color(0xFFFBE4EF),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFC8443E),
    dangerSoft: Color(0xFFFBE7E5),
    eCard: [
      BoxShadow(
        color: Color(0x2E141628),
        offset: Offset(0, 8),
        blurRadius: 24,
        spreadRadius: -14,
      ),
    ],
    eNav: [
      BoxShadow(
        color: Color(0x24141628),
        offset: Offset(0, -1),
        blurRadius: 24,
        spreadRadius: -8,
      ),
    ],
    eSheet: [
      BoxShadow(
        color: Color(0x3D141628),
        offset: Offset(0, -16),
        blurRadius: 44,
        spreadRadius: -12,
      ),
    ],
  );

  static const dark = BSColors(
    bg: Color(0xFF121316),
    surface: Color(0xFF1C1E22),
    sunk: Color(0xFF22252A),
    raised: Color(0xFF282C32),
    scrim: Color(0x99000000),
    ink: Color(0xFFF2F3F5),
    ink2: Color(0xFFA8ACB4),
    ink3: Color(0xFF8E939B),
    line: Color(0xFF282B31),
    track: Color(0xFF2C2F35),
    cal: Color(0xFF8FE3C4),
    calInk: Color(0xFF8FE3C4),
    calSoft: Color(0xFF16302A),
    pro: Color(0xFFB9AEF7),
    proInk: Color(0xFFB9AEF7),
    proSoft: Color(0xFF221F3B),
    carb: Color(0xFFEDA297),
    carbInk: Color(0xFFE6B4AA),
    carbSoft: Color(0xFF311814),
    fat: Color(0xFFF084C4),
    fatInk: Color(0xFFF084C4),
    fatSoft: Color(0xFF32182A),
    onAccent: Color(0xFF0B211B),
    danger: Color(0xFFF1897F),
    dangerSoft: Color(0xFF331C1B),
    eCard: [
      BoxShadow(
        color: Color(0xB3000000),
        offset: Offset(0, 8),
        blurRadius: 24,
        spreadRadius: -14,
      ),
    ],
    eNav: [
      BoxShadow(
        color: Color(0x99000000),
        offset: Offset(0, -1),
        blurRadius: 24,
        spreadRadius: -6,
      ),
    ],
    eSheet: [
      BoxShadow(
        color: Color(0xB3000000),
        offset: Offset(0, -16),
        blurRadius: 44,
        spreadRadius: -10,
      ),
    ],
  );

  @override
  BSColors copyWith() => this;

  @override
  BSColors lerp(ThemeExtension<BSColors>? other, double t) {
    if (other is! BSColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return BSColors(
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      sunk: c(sunk, other.sunk),
      raised: c(raised, other.raised),
      scrim: c(scrim, other.scrim),
      ink: c(ink, other.ink),
      ink2: c(ink2, other.ink2),
      ink3: c(ink3, other.ink3),
      line: c(line, other.line),
      track: c(track, other.track),
      cal: c(cal, other.cal),
      calInk: c(calInk, other.calInk),
      calSoft: c(calSoft, other.calSoft),
      pro: c(pro, other.pro),
      proInk: c(proInk, other.proInk),
      proSoft: c(proSoft, other.proSoft),
      carb: c(carb, other.carb),
      carbInk: c(carbInk, other.carbInk),
      carbSoft: c(carbSoft, other.carbSoft),
      fat: c(fat, other.fat),
      fatInk: c(fatInk, other.fatInk),
      fatSoft: c(fatSoft, other.fatSoft),
      onAccent: c(onAccent, other.onAccent),
      danger: c(danger, other.danger),
      dangerSoft: c(dangerSoft, other.dangerSoft),
      eCard: t < 0.5 ? eCard : other.eCard,
      eNav: t < 0.5 ? eNav : other.eNav,
      eSheet: t < 0.5 ? eSheet : other.eSheet,
    );
  }
}

abstract final class BSType {
  static const String font = 'Assistant';

  static const double hero = 44;
  static const double display = 30;
  static const double title = 25;
  static const double heading = 19;
  static const double body = 15;
  static const double bodySm = 13.5;
  static const double meta = 12.5;
  static const double micro = 11;
  static const double overline = 11;

  static const FontWeight wLight = FontWeight.w300;
  static const FontWeight wRegular = FontWeight.w400;
  static const FontWeight wMedium = FontWeight.w500;
  static const FontWeight wBold = FontWeight.w600;
  static const FontWeight wHeavy = FontWeight.w700;

  static const double lhTight = 1.02;
  static const double lhSnug = 1.3;
  static const double lhBody = 1.5;

  static const double trHero = -.035;
  static const double trTitle = -.015;
  static const double trOverline = .07;
}

abstract final class BSSpace {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s7 = 32;
  static const double s8 = 40;
  static const double s9 = 56;
  static const double screen = 20;
  static const double hit = 44;
}

abstract final class BSRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double card = 24;
  static const double sheet = 28;
  static const double pill = 999;
}

abstract final class BSMotion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 380);
  static const Curve out = Cubic(.22, 1, .36, 1);
  static const Curve spring = Cubic(.34, 1.42, .64, 1);
  static const Curve inOut = Cubic(.4, 0, .2, 1);
}

extension BSContext on BuildContext {
  BSColors get bs => Theme.of(this).extension<BSColors>()!;
}
