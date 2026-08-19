// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/Feature/auth/auth_routes.dart';
import 'package:rosivia/Feature/intro/language/language_provider.dart';
import 'package:rosivia/core/constants/app_fonts.dart';
import 'package:rosivia/core/styles/colors.dart';
import 'package:rosivia/l10n/app_localizations.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          // ==============================
          // APP THEME
          // ==============================
          theme: appTheme(),

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

  ThemeData appTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
    );

    return ThemeData(
      // ==============================
      // MATERIAL 3
      // ==============================
      useMaterial3: true,

      // ==============================
      // FONT
      // ==============================
      fontFamily: AppFonts.beVietnamPro,

      // ==============================
      // BACKGROUND
      // ==============================
      scaffoldBackgroundColor: AppColors.continerbg,

      // ==============================
      // COLOR SCHEME
      // ==============================
      colorScheme: colorScheme,

      // ==============================
      // APP BAR
      // ==============================
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.continerbg,
        foregroundColor: AppColors.blackcolor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: AppColors.primary,
        ),
      ),

      // ==============================
      // TEXT THEME
      // ==============================
      textTheme: const TextTheme(
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.blackcolor,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.blackcolor,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.blackcolor,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.blackcolor,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.blackcolor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.graycolor,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: AppColors.graycolor,
        ),
      ),

      // ==============================
      // BOTTOM NAVIGATION BAR
      // ==============================
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.continerbg,
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
                  : AppColors.graycolor,
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
                  : AppColors.graycolor,
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
          side: const BorderSide(
            color: AppColors.bordercolor,
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

        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.bordercolor,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.bordercolor,
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

        hintStyle: const TextStyle(
          color: AppColors.graycolor,
          fontSize: 14,
        ),
      ),
    );
  }
}