import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/core/functions/validators.dart';
import 'package:rosivia/l10n/app_localizations.dart';

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
    final lang = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!auth.agreedToTerms) {
      SnackbarService.warning(
        context,
        lang.agreeTermsMessage,
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
        auth.errorMessage ?? lang.registrationFailed,
      );
    }
  }

  Future<void> _handleGoogleSignUp(AuthProvider auth) async {
    setState(() => _isGoogleLoading = true);
    final success = await auth.googleSignIn();
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (success) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AuthRoutes.gate, (route) => false);
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
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AuthRoutes.gate, (route) => false);
    } else if (auth.errorMessage != null) {
      SnackbarService.error(context, auth.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 24.h),
                AuthHeader(
                  icon: Icons.auto_awesome_rounded,
                  title: lang.createAccount,
                  subtitle: lang.registerSubtitle,
                ),
                SizedBox(height: 32.h),

                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 24.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 30,
                        spreadRadius: 2,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthTextField(
                        controller: auth.nameController,
                        label: lang.fullName,
                        hint: lang.fullNameHint,
                        prefixIcon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            Validators.fullName(value, lang),
                      ),

                      SizedBox(height: 18.h),

                      AuthTextField(
                        controller: auth.emailController,
                        label: lang.email,
                        hint: lang.emailHint,
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => Validators.email(value, lang),
                      ),

                      SizedBox(height: 18.h),

                      PasswordTextField(
                        controller: auth.passwordController,
                        label: lang.password,
                        hint: lang.createStrongPassword,
                        obscureText: auth.obscurePassword,
                        onToggleVisibility: auth.togglePassword,
                        validator: (value) =>
                            Validators.password(value, lang),
                      ),

                      SizedBox(height: 18.h),

                      PasswordTextField(
                        controller: auth.confirmPasswordController,
                        label: lang.confirmPassword,
                        hint: lang.confirmPasswordHint,
                        obscureText: auth.obscureConfirmPassword,
                        onToggleVisibility: auth.toggleConfirmPassword,
                        textInputAction: TextInputAction.done,
                        validator: (value) => Validators.confirmPassword(
                          value,
                          auth.passwordController.text,
                          lang,
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
                        label: lang.createAccountButton,
                        isLoading: auth.isLoading,
                        onPressed: () => _handleRegister(auth),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30.h),

                const AuthDivider(),

                SizedBox(height: 20.h),
                SocialButton(
                  provider: SocialProvider.google,
                  isLoading: _isGoogleLoading,
                  onPressed: auth.isLoading
                      ? null
                      : () => _handleGoogleSignUp(auth),
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
                  question: '${lang.alreadyHaveAccount} ',
                  actionLabel: lang.logIn,
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushReplacementNamed(AuthRoutes.login);
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
