import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'tokens.dart';

abstract final class BSTheme {
  static ThemeData light() => _build(BSColors.light, Brightness.light);
  static ThemeData dark() => _build(BSColors.dark, Brightness.dark);

  static ThemeData _build(BSColors c, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: BSType.font,
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.cal,
        brightness: brightness,
        surface: c.surface,
        error: c.danger,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );

    TextStyle t(double size, FontWeight w,
            {double height = BSType.lhSnug, double? tracking, Color? color}) =>
        TextStyle(
          fontFamily: BSType.font,
          fontSize: size,
          fontWeight: w,
          height: height,
          letterSpacing: tracking != null ? tracking * size : 0,
          color: color ?? c.ink,
        );

    return base.copyWith(
      extensions: [c],
      textTheme: base.textTheme.copyWith(
        displayLarge: t(BSType.hero, BSType.wLight,
            height: BSType.lhTight, tracking: BSType.trHero),
        displayMedium: t(BSType.display, BSType.wLight,
            height: BSType.lhTight, tracking: BSType.trHero),
        headlineMedium: t(BSType.title, BSType.wBold,
            height: BSType.lhTight, tracking: BSType.trTitle),
        titleLarge: t(BSType.heading, BSType.wBold, tracking: BSType.trTitle),
        bodyLarge: t(BSType.body, BSType.wRegular, height: BSType.lhBody),
        bodyMedium: t(BSType.bodySm, BSType.wRegular, height: BSType.lhBody),
        bodySmall: t(BSType.meta, BSType.wRegular, color: c.ink2),
        labelSmall: t(BSType.overline, BSType.wBold,
            tracking: BSType.trOverline, color: c.ink3),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(BSRadius.sheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BSRadius.card),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
