import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/core/functions/validators.dart';
import 'package:rosivia/core/styles/colors.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../../../core/services/snackbar_service.dart';
import '../../auth_routes.dart';
import '../../provider/auth_provider.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_shell.dart';
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
    final lang = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await auth.login();
    if (!mounted) return;

    if (success) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AuthRoutes.gate, (route) => false);
    } else {
      SnackbarService.error(context, auth.errorMessage ?? lang.loginFailed);
    }
  }

  Future<void> _handleGoogleLogin(AuthProvider auth) async {
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

  Future<void> _handleAppleLogin(AuthProvider auth) async {
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

    return AuthShell(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              icon: Icons.spa_rounded,
              title: lang.welcomeBack,
              subtitle: lang.loginSubtitle,
            ),

            SizedBox(height: 32.h),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                    hint: lang.passwordHint,
                    obscureText: auth.obscurePassword,
                    onToggleVisibility: auth.togglePassword,
                    validator: (value) => Validators.loginPassword(value, lang),
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
                        lang.rememberMe,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushNamed(AuthRoutes.forgotPassword);
                        },
                        child: Text(lang.forgotPassword),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  LoadingButton(
                    label: lang.login,
                    isLoading: auth.isLoading,
                    onPressed: () => _handleLogin(auth),
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
              onPressed: auth.isLoading ? null : () => _handleGoogleLogin(auth),
            ),

            if (auth.isAppleSignInAvailable) ...[
              SizedBox(height: 14.h),
              SocialButton(
                provider: SocialProvider.apple,
                isLoading: _isAppleLoading,
                onPressed: auth.isLoading
                    ? null
                    : () => _handleAppleLogin(auth),
              ),
            ],

            SizedBox(height: 32.h),

            BottomAuthText(
              question: '${lang.dontHaveAccount} ',
              actionLabel: lang.signUp,
              onPressed: () {
                Navigator.of(context).pushReplacementNamed(AuthRoutes.register);
              },
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
