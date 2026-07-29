import 'package:flutter/material.dart';
import 'package:rosivia/Feature/intro/splash/page/splash.dart';

import 'presentation/auth_gate/auth_gate.dart';
import 'presentation/forgot_password/forgot_password_screen.dart';
import 'presentation/login/login_screen.dart';
import 'presentation/register/register_screen.dart';
import 'presentation/verify_email/verify_email_screen.dart';

/// Centralized route names and a route map for the whole app.
///
/// Register [routes] inside your `MaterialApp.routes`, and use
/// [AuthRoutes.splash] as your app's `initialRoute`.
class AuthRoutes {
  AuthRoutes._();

  static const String splash = '/splash';
  static const String gate = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        gate: (_) => const AuthGate(),
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
        forgotPassword: (_) => const ForgotPasswordScreen(),
        verifyEmail: (_) => const VerifyEmailScreen(),
      };
}
