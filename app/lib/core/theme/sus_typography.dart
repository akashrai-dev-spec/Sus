import 'package:flutter/material.dart';

class SusTypography {
  SusTypography._();

  static const String fontFamily = 'Inter';

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    height: 44 / 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    height: 32 / 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 26 / 20,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
  );
}
