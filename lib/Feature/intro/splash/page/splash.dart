import 'package:flutter/material.dart';
import 'package:rosivia/Feature/auth/auth_routes.dart';
import 'package:rosivia/core/constants/app_images.dart';
import 'package:rosivia/core/services/intro_prefs.dart';
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
    // Fade the logo in on the first frame — a visual flourish only; it
    // never gates navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1.0);
    });
    _route();
  }

  /// The launch decision is data-driven — NOT a fixed timer:
  ///  * first run (intro not seen yet) -> the language / onboarding flow;
  ///  * every later run -> [AuthGate], which resolves Firebase Auth +
  ///    the Firestore user doc (verified? registration complete? admin?)
  ///    and routes to Login / VerifyEmail / CompleteRegistration / Home.
  ///
  /// The only wait here is the SharedPreferences read (a few ms).
  Future<void> _route() async {
    final seenIntro = await IntroPrefs.hasSeenIntro();
    if (!mounted) return;

    // Named replacements so the browser URL always reflects the real
    // screen (never stays stuck on `#/splash`).
    Navigator.of(context).pushReplacementNamed(
      seenIntro ? AuthRoutes.gate : AuthRoutes.language,
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
