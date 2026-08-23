import 'package:flutter/painting.dart';

/// ROSIVA brand palette.
///
/// [primary] / [primaryLight] / [primaryDark] drive the pink-magenta
/// beauty-tech identity used across every screen. Dark-mode specific
/// tokens are prefixed with `dark`.
abstract class AppColors {
  // Brand
  static const Color primary = Color(0xffA82763);
  static const Color primaryDark = Color(0xff7A1B49);
  static const Color primaryLight = Color(0xffE85D8A);
  static const Color accent = Color(0xffD4A574);

  // Light theme surfaces
  static const Color background = Color(0xffFAE6EC);
  static const Color scaffoldLight = Color(0xffFFFFFF);
  static const Color surfaceLight = Color(0xffFFF6F8);
  static const Color cardLight = Color(0xffFFFFFF);

  // Neutral
  static const Color graycolor = Color(0xff8391A1);
  static const Color bordercolor = Color(0xffF6F3F2);
  static const Color errorcolor = Color(0xffE43B3B);
  static const Color successColor = Color(0xff2FA76F);
  static const Color blackcolor = Color(0xff1B1B1C);
  static const Color continerbg = Color(0xffFFFFFF);

  // Dark theme surfaces
  static const Color scaffoldDark = Color(0xff120A10);
  static const Color surfaceDark = Color(0xff1E1116);
  static const Color cardDark = Color(0xff271620);
  static const Color borderDark = Color(0xff3A2530);
  static const Color textDark = Color(0xffF5EAEE);
  static const Color grayDark = Color(0xffB7A2AC);
}
