// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/Feature/auth/auth_routes.dart';
import 'package:rosivia/Feature/auth/presentation/auth_gate/auth_gate.dart';
import 'package:rosivia/Feature/intro/language/language_provider.dart';
import 'package:rosivia/core/constants/app_fonts.dart';
import 'package:rosivia/core/providers/theme_provider.dart';
import 'package:rosivia/core/responsive/responsive.dart';
import 'package:rosivia/core/services/notification_service.dart';
import 'package:rosivia/core/styles/app_dimens.dart';
import 'package:rosivia/core/styles/colors.dart';
import 'package:rosivia/l10n/app_localizations.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  /// The mobile UI is authored on a 375-wide canvas and scaled by
  /// `flutter_screenutil`. On a desktop browser that same width-based
  /// scaling multiplies every `.w/.h/.sp/.r` by a 1400px+ viewport,
  /// which is what made icons, text and spacing look oversized.
  ///
  /// Instead of trapping the app in a fake phone frame, on the **web at
  /// tablet width and up** we hand `flutter_screenutil` a `designSize`
  /// equal to the real viewport, so every `.w/.h/.sp/.r` resolves 1:1 to
  /// the pixel value it was authored with — a compact, professional
  /// baseline. Real responsiveness (content max-width, grid columns,
  /// side vs. bottom navigation) is then driven from the true
  /// `MediaQuery` width by the helpers in `core/responsive`. Native
  /// Android / iOS and narrow mobile-web are untouched: they keep the
  /// 375x812 design canvas.
  static Size _designSize(BuildContext context) {
    if (!kIsWeb) return const Size(375, 812);
    final size = MediaQuery.maybeOf(context)?.size;
    if (size == null || size.width <= Breakpoints.tablet) {
      return const Size(375, 812);
    }
    return size;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: _designSize(context),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          // Lets a notification tap route without a BuildContext.
          navigatorKey: NotificationService.navigatorKey,

          // ==============================
          // APP THEME
          // ==============================
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          themeMode: context.watch<ThemeProvider>().themeMode,

          // ==============================
          // LANGUAGE
          // ==============================
          locale: context.watch<LanguageProvider>().locale,

          supportedLocales: AppLocalizations.supportedLocales,

          localizationsDelegates: AppLocalizations.localizationsDelegates,

          // ==============================
          // ROUTES
          // ==============================
          initialRoute: AuthRoutes.splash,
          routes: AuthRoutes.routes,
          // Any unknown deep link (a stale `#/home`, a typo, an old
          // bookmark) resolves to the auth gate — never a dead end, and
          // never a bypass of authentication.
          onUnknownRoute: (settings) => MaterialPageRoute(
            builder: (_) => const AuthGate(),
            settings: const RouteSettings(name: AuthRoutes.gate),
          ),

          // ==============================
          // GLOBAL BUILDER
          // ==============================
          builder: (context, child) {
            return SafeArea(
              top: false,
              bottom:
                  !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
              child: child ?? const SizedBox(),
            );
          },
        );
      },
    );
  }
}

/// Builds ROSIVA's [ThemeData] for either [Brightness.light] or
/// [Brightness.dark], sharing every structural choice (Material 3,
/// font, shapes, spacing) between the two and only swapping the
/// actual color tokens — so light/dark can never structurally drift
/// apart from each other.
ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
  );

  final scaffoldBg = isDark ? AppColors.scaffoldDark : AppColors.continerbg;
  final surface = isDark ? AppColors.surfaceDark : AppColors.continerbg;
  final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
  final borderColor = isDark ? AppColors.borderDark : AppColors.bordercolor;
  final textColor = isDark ? AppColors.textDark : AppColors.blackcolor;
  final mutedTextColor = isDark ? AppColors.grayDark : AppColors.graycolor;

  return ThemeData(
    // ==============================
    // MATERIAL 3
    // ==============================
    useMaterial3: true,
    brightness: brightness,

    // ==============================
    // PAGE TRANSITIONS — one calm fade+rise everywhere (RTL-safe:
    // no horizontal direction), instead of the default platform mix.
    // ==============================
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _RosivaPageTransitionsBuilder(),
        TargetPlatform.iOS: _RosivaPageTransitionsBuilder(),
        TargetPlatform.macOS: _RosivaPageTransitionsBuilder(),
        TargetPlatform.windows: _RosivaPageTransitionsBuilder(),
        TargetPlatform.linux: _RosivaPageTransitionsBuilder(),
        TargetPlatform.fuchsia: _RosivaPageTransitionsBuilder(),
      },
    ),

    // ==============================
    // FONT
    // ==============================
    fontFamily: AppFonts.beVietnamPro,

    // ==============================
    // BACKGROUND
    // ==============================
    scaffoldBackgroundColor: scaffoldBg,
    cardColor: cardColor,

    // ==============================
    // COLOR SCHEME
    // ==============================
    colorScheme: colorScheme,

    // ==============================
    // APP BAR
    // ==============================
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.primary),
    ),

    // ==============================
    // TEXT THEME
    // ==============================
    textTheme: TextTheme(
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyMedium: TextStyle(fontSize: 14, color: mutedTextColor),
      bodySmall: TextStyle(fontSize: 12, color: mutedTextColor),
    ),

    // ==============================
    // BOTTOM NAVIGATION BAR
    // ==============================
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      elevation: 0,
      height: 72.h,

      indicatorColor: AppColors.primary.withValues(alpha: 0.12),

      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);

        return TextStyle(
          fontFamily: AppFonts.beVietnamPro,
          fontSize: 11.sp,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : mutedTextColor,
        );
      }),

      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);

        return IconThemeData(
          size: isSelected ? 25.sp : 24.sp,
          color: isSelected ? AppColors.primary : mutedTextColor,
        );
      }),
    ),

    // ==============================
    // CHECKBOX
    // ==============================
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? AppColors.primary
            : Colors.transparent;
      }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // ==============================
    // TEXT BUTTON
    // ==============================
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    ),

    // ==============================
    // OUTLINED BUTTON
    // ==============================
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: borderColor, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),

    // ==============================
    // ELEVATED BUTTON
    // ==============================
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),

    // ==============================
    // INPUT FIELDS
    // ==============================
    inputDecorationTheme: InputDecorationTheme(
      filled: true,

      fillColor: cardColor,

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.errorcolor),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.errorcolor, width: 1.4),
      ),

      hintStyle: TextStyle(color: mutedTextColor, fontSize: 14),
    ),
  );
}

/// ROSIVA's single page transition: a quick fade with a small upward
/// rise and a barely-there scale. Direction-agnostic, so it behaves
/// identically in RTL and LTR. Duration/curve come from [AppDuration]/
/// [AppCurve] so it stays on-system.
class _RosivaPageTransitionsBuilder extends PageTransitionsBuilder {
  const _RosivaPageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppDuration.page;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppCurve.enter,
      reverseCurve: AppCurve.standard,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.995, end: 1).animate(curved),
          child: child,
        ),
      ),
    );
  }
}
