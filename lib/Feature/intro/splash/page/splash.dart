import 'package:flutter/material.dart';
import 'package:rosivia/Feature/intro/language/language_view.dart';
import 'package:rosivia/core/constants/app_images.dart';
import 'package:rosivia/core/styles/colors.dart';
import 'package:rosivia/core/styles/text_style.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {
    // بدء الأنيميشن
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      setState(() {
        _opacity = 1.0;
      });
    }

    // انتظار 3 ثواني
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LanguageView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.continerbg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(seconds: 2),

              child: Image.asset(AppImages.splash, width: 400, height: 400),
            ),

            const SizedBox(height: 1),

            AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(seconds: 2),
              child: const Text("ROSIVA", style: TextStyles.splash),
            ),
          ],
        ),
      ),
    );
  }
}
