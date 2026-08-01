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
      // Base design size the auth screens (and the rest of the UI) were
      // designed against. Every `.w` / `.h` / `.sp` / `.r` call in the
      // app scales relative to this.
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          theme: appTheme(),

          /// اللغة الحالية
          locale: context.watch<LanguageProvider>().locale,

          /// اللغات المدعومة
          supportedLocales: AppLocalizations.supportedLocales,

          /// ملفات الترجمة
          localizationsDelegates: AppLocalizations.localizationsDelegates,

          /// جميع مسارات التطبيق مسجلة مركزيًا في AuthRoutes
          initialRoute: AuthRoutes.splash,
          routes: AuthRoutes.routes,

          builder: (context, child) {
            // Keep ScreenUtil's own builder in the tree so text scaling
            // keeps working, then apply the app-wide SafeArea handling.
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
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.primary);

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppFonts.beVietnamPro,
      scaffoldBackgroundColor: AppColors.continerbg,
      colorScheme: colorScheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.continerbg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.primary),
      ),

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
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.graycolor),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.graycolor),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.bordercolor, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.bordercolor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.bordercolor),
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
        hintStyle: const TextStyle(color: AppColors.graycolor, fontSize: 14),
      ),
    );
  }
}
