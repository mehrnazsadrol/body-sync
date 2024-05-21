import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color yellow = Color(0xFFFDC63A);
  static const Color lightPink = Color(0xFFFCB5B0);
  static const Color darkPink1 = Color(0xFFFC8B98);
  static const Color darkPink2 = Color(0xFFF8655E);
  static const Color backgroundColor = Color(0xFFFDFCE7);
  static const Color lightGreen = Color(0xff51C5AC);
  static const Color darkGreen1 = Color(0xFF54A09C); 
  static const Color darkGreen2 = Color(0xFF3A8F92); 
  static const Color darkGreen3 = Color(0xFF4C7677); 
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF000000);

  // Font Sizes
  static const double headlineSize = 24.0;
  static const double bodyTextSize = 16.0;

  // Padding and Margins
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;

  // Border Radius
  static const double borderRadius = 30.0;
  static const TextStyle bodyText = TextStyle(
    fontSize: bodyTextSize,
    color: blackColor,
  );

  // Button Style
  static final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    padding: EdgeInsets.all(defaultPadding),
  );
}
