// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/Feature/auth/auth_routes.dart';
import 'package:rosivia/Feature/intro/language/language_provider.dart';
import 'package:rosivia/core/constants/app_fonts.dart';
import 'package:rosivia/core/providers/theme_provider.dart';
import 'package:rosivia/core/styles/colors.dart';
import 'package:rosivia/l10n/app_localizations.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  /// On the **web** at tablet/desktop widths, ROSIVA renders inside a
  /// centered, phone-width frame. This is the smallest change that makes
  /// the existing mobile design — and `flutter_screenutil`'s
  /// width-based scaling — render at its intended size instead of being
  /// multiplied by a 1400px+ desktop viewport (which is what made icons
  /// and spacing huge and forms stretch edge-to-edge). Native Android /
  /// iOS / desktop builds are completely untouched (`kIsWeb` guard).
  static const double _webFrameWidth = 480;

  static bool _shouldFrame(BuildContext context) {
    if (!kIsWeb) return false;
    final size = MediaQuery.maybeOf(context)?.size;
    return size != null && size.width > 600;
  }

  static MediaQueryData _framed(MediaQueryData data) =>
      data.copyWith(size: Size(_webFrameWidth, data.size.height));

  @override
  Widget build(BuildContext context) {
    final frame = _shouldFrame(context);

    final Widget app = ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

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

          // ==============================
          // GLOBAL BUILDER
          // ==============================
          builder: (context, child) {
            final Widget content = SafeArea(
              top: false,
              bottom:
                  !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
              child: child ?? const SizedBox(),
            );
            if (!frame) return content;
            // The screens live below `WidgetsApp`'s own MediaQuery
            // (derived from the physical view), so the clamp applied
            // above `ScreenUtilInit` doesn't reach them — re-assert the
            // framed size here, then physically constrain + centre the
            // render so nothing stretches across the full window.
            return ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: MediaQuery(
                  data: _framed(MediaQuery.of(context)),
                  child: SizedBox(width: _webFrameWidth, child: content),
                ),
              ),
            );
          },
        );
      },
    );

    if (!frame) return app;
    // Feed the clamped width to `flutter_screenutil`, which initialises
    // from the MediaQuery that sits *above* MaterialApp.
    return MediaQuery(data: _framed(MediaQuery.of(context)), child: app);
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
      iconTheme: IconThemeData(
        color: AppColors.primary,
      ),
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
      bodyMedium: TextStyle(
        fontSize: 14,
        color: mutedTextColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: mutedTextColor,
      ),
    ),

    // ==============================
    // BOTTOM NAVIGATION BAR
    // ==============================
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      elevation: 0,
      height: 72.h,

      indicatorColor: AppColors.primary.withValues(
        alpha: 0.12,
      ),

      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) {
          final isSelected = states.contains(
            WidgetState.selected,
          );

          return TextStyle(
            fontFamily: AppFonts.beVietnamPro,
            fontSize: 11.sp,
            fontWeight: isSelected
                ? FontWeight.w700
                : FontWeight.w500,
            color: isSelected
                ? AppColors.primary
                : mutedTextColor,
          );
        },
      ),

      iconTheme: WidgetStateProperty.resolveWith(
        (states) {
          final isSelected = states.contains(
            WidgetState.selected,
          );

          return IconThemeData(
            size: isSelected ? 25.sp : 24.sp,
            color: isSelected
                ? AppColors.primary
                : mutedTextColor,
          );
        },
      ),
    ),

    // ==============================
    // CHECKBOX
    // ==============================
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) {
          return states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent;
        },
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),

    // ==============================
    // TEXT BUTTON
    // ==============================
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
      ),
    ),

    // ==============================
    // OUTLINED BUTTON
    // ==============================
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(
          color: borderColor,
          width: 1.2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),

    // ==============================
    // ELEVATED BUTTON
    // ==============================
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),

    // ==============================
    // INPUT FIELDS
    // ==============================
    inputDecorationTheme: InputDecorationTheme(
      filled: true,

      fillColor: cardColor,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: borderColor,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: borderColor,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.4,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.errorcolor,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.errorcolor,
          width: 1.4,
        ),
      ),

      hintStyle: TextStyle(
        color: mutedTextColor,
        fontSize: 14,
      ),
    ),
  );
}
