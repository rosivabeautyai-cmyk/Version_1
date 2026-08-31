import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/core/styles/colors.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../../../core/services/snackbar_service.dart';
import '../../auth_routes.dart';
import '../../provider/auth_provider.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_of_service_screen.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_shell.dart';
import '../widgets/loading_button.dart';
import '../widgets/terms_checkbox.dart';

/// One-step consent gate for a first-time social sign-in.
///
/// A brand-new Google/Apple account is authenticated but has NOT yet
/// accepted the Terms of Service / Privacy Policy, so [AuthGate] routes
/// it here instead of Home. This is deliberately NOT the full Register
/// screen (no name/email/password) — the account already exists; all
/// that's missing is consent. Accepting it writes `termsAcceptedAt` +
/// `registrationCompleted: true` and returns to [AuthGate], which then
/// lets the user into the app.
class CompleteRegistrationScreen extends StatefulWidget {
  const CompleteRegistrationScreen({super.key});

  @override
  State<CompleteRegistrationScreen> createState() =>
      _CompleteRegistrationScreenState();
}

class _CompleteRegistrationScreenState
    extends State<CompleteRegistrationScreen> {
  bool _agreed = false;
  bool _submitting = false;

  Future<void> _continue(AuthProvider auth) async {
    final lang = AppLocalizations.of(context)!;
    if (!_agreed) {
      SnackbarService.warning(context, lang.agreeTermsMessage);
      return;
    }
    setState(() => _submitting = true);
    final ok = await auth.completeRegistration();
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AuthRoutes.gate, (route) => false);
    } else {
      SnackbarService.error(
        context,
        auth.errorMessage ?? lang.somethingWentWrong,
      );
    }
  }

  Future<void> _signOut(AuthProvider auth) async {
    await auth.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AuthRoutes.gate, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final lang = AppLocalizations.of(context)!;

    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            icon: Icons.verified_user_rounded,
            title: lang.welcome,
            subtitle: lang.agreeTermsMessage,
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
                TermsCheckbox(
                  value: _agreed,
                  onChanged: (_) => setState(() => _agreed = !_agreed),
                  onTermsTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TermsOfServiceScreen(),
                    ),
                  ),
                  onPrivacyTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                LoadingButton(
                  label: lang.continueButton,
                  isLoading: _submitting || auth.isLoading,
                  onPressed: () => _continue(auth),
                  icon: Icons.arrow_forward_rounded,
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          Center(
            child: TextButton(
              onPressed: _submitting ? null : () => _signOut(auth),
              child: Text(lang.logOut),
            ),
          ),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}
