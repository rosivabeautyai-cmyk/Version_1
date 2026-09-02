/// ROSIVA design tokens.
///
/// A single source of truth for the small values that make an app feel
/// like one coherent product — spacing, corner radii, elevation and
/// motion timing. Nothing here changes ROSIVA's look; it just replaces
/// scattered magic numbers with a consistent scale so new/edited UI
/// stays on-system.
///
/// These are plain logical pixels. On mobile, wrap with `.w/.h/.r` at
/// the call site if scaling is wanted; on web the app already renders
/// 1:1 (see `main_app.dart`).
library;

import 'package:flutter/widgets.dart';

/// 4-pt spacing scale. Prefer these over ad-hoc numbers.
abstract final class AppSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
}

/// Corner-radius scale.
abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;
}

/// Motion durations. Fast first — the app should feel quick, not
/// "animated". (Guideline: micro 120–200ms, small 200–300ms, page
/// 250–400ms.)
abstract final class AppDuration {
  static const Duration micro = Duration(milliseconds: 160);
  static const Duration button = Duration(milliseconds: 180);
  static const Duration short = Duration(milliseconds: 240);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration page = Duration(milliseconds: 300);
  static const Duration shimmer = Duration(milliseconds: 1200);
}

/// Motion curves.
abstract final class AppCurve {
  static const Curve enter = Curves.fastOutSlowIn;
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubic;
}

/// A small, consistent elevation system. Pass the surface/shadow colour
/// (usually `theme.colorScheme.shadow` or `AppColors.primary`).
abstract final class AppShadow {
  /// Barely-there lift for list cards.
  static List<BoxShadow> low(Color c) => [
    BoxShadow(
      color: c.withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Standard resting card / sheet.
  static List<BoxShadow> medium(Color c) => [
    BoxShadow(
      color: c.withValues(alpha: 0.07),
      blurRadius: 20,
      spreadRadius: -2,
      offset: const Offset(0, 8),
    ),
  ];
}
