import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/core/functions/validators.dart';

import '../../../../core/services/snackbar_service.dart';
import '../../auth_routes.dart';
import '../../provider/auth_provider.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_textfield.dart';
import '../widgets/bottom_auth_text.dart';
import '../widgets/loading_button.dart';
import '../widgets/password_textfield.dart';
import '../widgets/social_button.dart';

/// The login screen: email/password sign-in plus Google and Apple.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  Future<void> _handleLogin(AuthProvider auth) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await auth.login();
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AuthRoutes.gate,
        (route) => false,
      );
    } else {
      SnackbarService.error(
        context,
        auth.errorMessage ?? 'Login failed. Please try again.',
      );
    }
  }

  Future<void> _handleGoogleLogin(AuthProvider auth) async {
    setState(() => _isGoogleLoading = true);
    final success = await auth.googleSignIn();
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AuthRoutes.gate,
        (route) => false,
      );
    } else if (auth.errorMessage != null) {
      SnackbarService.error(context, auth.errorMessage!);
    }
  }

  Future<void> _handleAppleLogin(AuthProvider auth) async {
    setState(() => _isAppleLoading = true);
    final success = await auth.appleSignIn();
    if (!mounted) return;
    setState(() => _isAppleLoading = false);

    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AuthRoutes.gate,
        (route) => false,
      );
    } else if (auth.errorMessage != null) {
      SnackbarService.error(context, auth.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 32.h),
                const AuthHeader(
                  icon: Icons.spa_rounded,
                  title: 'Welcome back',
                  subtitle: 'Sign in to continue your ROSIVA journey',
                ),
                SizedBox(height: 36.h),
                AuthTextField(
                  controller: auth.emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                SizedBox(height: 18.h),
                PasswordTextField(
                  controller: auth.passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  obscureText: auth.obscurePassword,
                  onToggleVisibility: auth.togglePassword,
                  validator: Validators.loginPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(auth),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    SizedBox(
                      height: 22.h,
                      width: 22.h,
                      child: Checkbox(
                        value: auth.rememberMe,
                        onChanged: (_) => auth.toggleRememberMe(),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Remember me',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed(AuthRoutes.forgotPassword);
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                LoadingButton(
                  label: 'Log In',
                  isLoading: auth.isLoading,
                  onPressed: () => _handleLogin(auth),
                ),
                SizedBox(height: 28.h),
                const AuthDivider(),
                SizedBox(height: 20.h),
                SocialButton(
                  provider: SocialProvider.google,
                  isLoading: _isGoogleLoading,
                  onPressed:
                      auth.isLoading ? null : () => _handleGoogleLogin(auth),
                ),
                if (auth.isAppleSignInAvailable) ...[
                  SizedBox(height: 14.h),
                  SocialButton(
                    provider: SocialProvider.apple,
                    isLoading: _isAppleLoading,
                    onPressed:
                        auth.isLoading ? null : () => _handleAppleLogin(auth),
                  ),
                ],
                SizedBox(height: 32.h),
                BottomAuthText(
                  question: "Don't have an account? ",
                  actionLabel: 'Sign Up',
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(
                      AuthRoutes.register,
                    );
                  },
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
