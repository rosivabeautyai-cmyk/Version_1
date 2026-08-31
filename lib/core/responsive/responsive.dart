import 'package:flutter/widgets.dart';

/// ROSIVA responsive strategy for Flutter Web.
///
/// The mobile design is authored against a 375px canvas with
/// `flutter_screenutil`. On the web `flutter_screenutil` is configured
/// 1:1 (see `main_app.dart`), so `.w/.h/.sp/.r` render at their
/// authored pixel values — a compact, professional baseline. Layout
/// responsiveness (content width, grid columns, navigation) is driven
/// from the **real** `MediaQuery` width via the helpers here — never by
/// scaling the whole UI.
///
/// Native Android/iOS are unaffected: on mobile the widths are always
/// below the tablet breakpoint, so these helpers return the mobile
/// values and `PageContainer` is a no-op.
class Breakpoints {
  Breakpoints._();

  /// < 600 : phone
  static const double tablet = 600;

  /// 600–1023 : tablet
  static const double desktop = 1024;

  /// 1024–1439 : desktop
  static const double largeDesktop = 1440;

  /// Width above which the shopper shell uses a side navigation rail
  /// instead of the bottom navigation bar.
  static const double sideNav = 1000;

  /// Maximum width of a centred content column on large screens. Wide
  /// enough to feel like a real desktop app (5–6 product columns), but
  /// still capped so cards and text lines never stretch edge-to-edge on
  /// an ultrawide monitor.
  static const double contentMaxWidth = 1440;
}

enum ScreenType { mobile, tablet, desktop, largeDesktop }

ScreenType screenTypeForWidth(double width) {
  if (width >= Breakpoints.largeDesktop) return ScreenType.largeDesktop;
  if (width >= Breakpoints.desktop) return ScreenType.desktop;
  if (width >= Breakpoints.tablet) return ScreenType.tablet;
  return ScreenType.mobile;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  ScreenType get screenType => screenTypeForWidth(screenWidth);
  bool get isMobile => screenType == ScreenType.mobile;
  bool get isTabletUp => screenWidth >= Breakpoints.tablet;
  bool get isDesktopUp => screenWidth >= Breakpoints.desktop;
  bool get useSideNav => screenWidth >= Breakpoints.sideNav;
}

/// Product-grid column count for a given *available* width (i.e. the
/// width the grid itself is laid out in, after [PageContainer] has
/// capped it). 2 on phones → up to 6 on large desktops. Card width stays
/// ~200–260px across the range so cards never balloon on wide screens.
int responsiveGridColumns(double width, {int min = 2, int max = 6}) {
  int cols;
  if (width < 560) {
    cols = 2;
  } else if (width < 820) {
    cols = 3;
  } else if (width < 1080) {
    cols = 4;
  } else if (width < 1340) {
    cols = 5;
  } else {
    cols = 6;
  }
  return cols.clamp(min, max);
}

/// Centres its [child] and caps it at [maxWidth] on large screens.
///
/// On phones/tablets narrower than [maxWidth] this is a **no-op**
/// (`Center` of a full-width child, `ConstrainedBox` wider than the
/// viewport) — so the existing mobile layout is untouched.
class PageContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const PageContainer({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.contentMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
