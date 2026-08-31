import 'package:flutter/material.dart';
import 'package:rosivia/Feature/intro/language/language_view.dart';
import 'package:rosivia/Feature/intro/onboarding/presentation/page/onboarding_view.dart';
import 'package:rosivia/Feature/intro/splash/page/splash.dart';

import 'presentation/auth_gate/auth_gate.dart';
import 'presentation/complete_registration/complete_registration_screen.dart';
import 'presentation/forgot_password/forgot_password_screen.dart';
import 'presentation/legal/privacy_policy_screen.dart';
import 'presentation/legal/terms_of_service_screen.dart';
import 'presentation/login/login_screen.dart';
import 'presentation/register/register_screen.dart';
import 'presentation/verify_email/verify_email_screen.dart';

/// Centralized route names and a route map for the whole app.
///
/// Register [routes] inside your [MaterialApp.routes], and use
/// [AuthRoutes.splash] as your app's [initialRoute].
class AuthRoutes {
  AuthRoutes._();

  static const String splash = '/splash';
  static const String language = '/language';
  static const String onboarding = '/onboarding';
  static const String gate = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String completeRegistration = '/complete-registration';
  static const String termsOfService = '/terms-of-service';
  static const String privacyPolicy = '/privacy-policy';

  /// The authenticated shopper shell. Reached ONLY by [AuthGate]
  /// rendering [MainScreen] directly once auth + registration checks
  /// pass — it is intentionally NOT a named route, so a bare
  /// `#/home` URL can't bypass the gate.
  static const String home = '/home';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),

    language: (_) => const LanguageView(),

    onboarding: (_) => const OnboardingView(),

    gate: (_) => const AuthGate(),

    login: (_) => const LoginScreen(),

    register: (_) => const RegisterScreen(),

    forgotPassword: (_) => const ForgotPasswordScreen(),

    verifyEmail: (_) => const VerifyEmailScreen(),

    completeRegistration: (_) => const CompleteRegistrationScreen(),

    termsOfService: (_) => const TermsOfServiceScreen(),

    privacyPolicy: (_) => const PrivacyPolicyScreen(),
  };
}
