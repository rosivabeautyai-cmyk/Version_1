// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/Feature/intro/language/language_provider.dart';
import 'package:rosivia/Feature/intro/splash/page/splash.dart';
import 'package:rosivia/core/constants/app_fonts.dart';
import 'package:rosivia/core/styles/colors.dart';
import 'package:rosivia/l10n/app_localizations.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: appTheme(),

      /// اللغة الحالية
      locale: context.watch<LanguageProvider>().locale,

      /// اللغات المدعومة
      supportedLocales: AppLocalizations.supportedLocales,

      /// ملفات الترجمة
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      builder: (context, child) {
        return SafeArea(
          top: false,
          bottom: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
          child: child ?? const SizedBox(),
        );
      },

      home: const SplashScreen(),
    );
  }

  ThemeData appTheme() {
    return ThemeData(
      fontFamily: AppFonts.beVietnamPro,
      scaffoldBackgroundColor: AppColors.background,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),

      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    );
  }
}
