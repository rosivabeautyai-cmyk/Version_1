import 'package:flutter/material.dart';
import 'package:rosivia/core/constants/app_fonts.dart';
import 'package:rosivia/core/styles/colors.dart';

abstract class TextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(fontSize: 16);

  static const TextStyle caption1 = TextStyle(fontSize: 14);

  static const TextStyle caption2 = TextStyle(fontSize: 12);

  static const TextStyle splash = TextStyle(
    fontSize: 60,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    fontFamily: AppFonts.playfairDisplaySC,
  );
}
