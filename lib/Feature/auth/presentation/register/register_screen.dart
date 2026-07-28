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
import '../widgets/terms_checkbox.dart';

/// The registration screen: full name, email, password, confirm
/// password, terms agreement, plus Google and Apple sign-up.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  Future<void> _handleRegister(AuthProvider auth) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!auth.agreedToTerms) {
      SnackbarService.warning(
        context,
        'Please agree to the Terms of Service and Privacy Policy.',
      );
      return;
    }

    final success = await auth.register();
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacementNamed(AuthRoutes.verifyEmail);
    } else {
      SnackbarService.error(
        context,
        auth.errorMessage ?? 'Registration failed. Please try again.',
      );
    }
  }

  Future<void> _handleGoogleSignUp(AuthProvider auth) async {
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

  Future<void> _handleAppleSignUp(AuthProvider auth) async {
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
                SizedBox(height: 24.h),
                const AuthHeader(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Create account',
                  subtitle: 'Join ROSIVA and start your beauty ritual',
                ),
                SizedBox(height: 32.h),
                AuthTextField(
                  controller: auth.nameController,
                  label: 'Full Name',
                  hint: 'Jane Doe',
                  prefixIcon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: Validators.fullName,
                ),
                SizedBox(height: 18.h),
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
                  hint: 'Create a strong password',
                  obscureText: auth.obscurePassword,
                  onToggleVisibility: auth.togglePassword,
                  validator: Validators.password,
                ),
                SizedBox(height: 18.h),
                PasswordTextField(
                  controller: auth.confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  obscureText: auth.obscureConfirmPassword,
                  onToggleVisibility: auth.toggleConfirmPassword,
                  textInputAction: TextInputAction.done,
                  validator: (value) => Validators.confirmPassword(
                    value,
                    auth.passwordController.text,
                  ),
                  onFieldSubmitted: (_) => _handleRegister(auth),
                ),
                SizedBox(height: 18.h),
                TermsCheckbox(
                  value: auth.agreedToTerms,
                  onChanged: (_) => auth.toggleAgreedToTerms(),
                  onTermsTap: () {},
                  onPrivacyTap: () {},
                ),
                SizedBox(height: 24.h),
                LoadingButton(
                  label: 'Create Account',
                  isLoading: auth.isLoading,
                  onPressed: () => _handleRegister(auth),
                ),
                SizedBox(height: 28.h),
                const AuthDivider(),
                SizedBox(height: 20.h),
                SocialButton(
                  provider: SocialProvider.google,
                  isLoading: _isGoogleLoading,
                  onPressed:
                      auth.isLoading ? null : () => _handleGoogleSignUp(auth),
                ),
                if (auth.isAppleSignInAvailable) ...[
                  SizedBox(height: 14.h),
                  SocialButton(
                    provider: SocialProvider.apple,
                    isLoading: _isAppleLoading,
                    onPressed: auth.isLoading
                        ? null
                        : () => _handleAppleSignUp(auth),
                  ),
                ],
                SizedBox(height: 32.h),
                BottomAuthText(
                  question: 'Already have an account? ',
                  actionLabel: 'Log In',
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(
                      AuthRoutes.login,
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
