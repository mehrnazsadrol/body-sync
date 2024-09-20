import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color yellow = Color.fromRGBO(253, 198, 58, 1);
  static const Color peachyPink = Color(0xffFF9B82);
  static const Color sunsetOrange = Color(0xFFfd536a);
  static const Color cranberryPink = Color(0xFFd5626a);
  static const Color backgroundColor = Color(0xFFfff4ee);
  static const Color turquoise = Color(0xff7fd1ae);
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
