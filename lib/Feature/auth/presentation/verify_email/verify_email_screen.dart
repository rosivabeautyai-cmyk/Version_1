import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/core/styles/colors.dart';
import 'package:rosivia/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/snackbar_service.dart';
import '../../auth_routes.dart';
import '../../provider/auth_provider.dart';
import '../widgets/loading_button.dart';

/// The verify-email screen.
///
/// Firebase Authentication verifies emails via a link, NOT an OTP
/// code, so this screen never collects a code. Instead it:
///  - Lets the user open their mail app.
///  - Lets the user manually confirm they've verified.
///  - Lets the user resend the verification email.
///  - Silently polls in the background so verification is detected
///    automatically without any user action.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _pollTimer;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final auth = context.read<AuthProvider>();
      final verified = await auth.reloadUser();
      if (verified && mounted) {
        _pollTimer?.cancel();
        _navigateToHome();
      }
    });
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  void _navigateToHome() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AuthRoutes.gate, (route) => false);
  }

  Future<void> _handleOpenMail() async {
    final lang = AppLocalizations.of(context)!;
    // Best-effort deep link into the default mail app.
    final uri = Uri(scheme: 'mailto');
    try {
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        SnackbarService.info(context, lang.openMailManually);
      }
    } catch (_) {
      if (mounted) {
        SnackbarService.info(context, lang.openMailManually);
      }
    }
  }

  Future<void> _handleIveVerified(AuthProvider auth) async {
    final lang = AppLocalizations.of(context)!;
    final verified = await auth.reloadUser();
    if (!mounted) return;

    if (verified) {
      _navigateToHome();
    } else {
      SnackbarService.warning(context, lang.emailNotVerifiedYet);
    }
  }

  Future<void> _handleResend(AuthProvider auth) async {
    final lang = AppLocalizations.of(context)!;
    if (_resendCooldown > 0) return;
    final success = await auth.sendVerificationEmail();
    if (!mounted) return;

    if (success) {
      SnackbarService.success(context, lang.verificationEmailSent);
      _startCooldown();
    } else {
      SnackbarService.error(
        context,
        auth.errorMessage ?? lang.resendEmailFailed,
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final lang = AppLocalizations.of(context)!;
    final email = auth.currentUser?.email ?? lang.yourEmailFallback;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 24.h),

              Center(
                child: Container(
                  height: 120.h,
                  width: 120.h,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.mark_email_unread_rounded,
                    color: Colors.white,
                    size: 56.sp,
                  ),
                ),
              ),

              SizedBox(height: 28.h),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                decoration: BoxDecoration(
                  color: AppColors.background,
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
                    Text(
                      lang.verifyYourEmail,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),

                    SizedBox(height: 12.h),

                    Text(
                      lang.verifyEmailMessage(email),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    SizedBox(height: 28.h),

                    LoadingButton(
                      label: lang.openMailApp,
                      isLoading: false,
                      onPressed: _handleOpenMail,
                      icon: Icons.open_in_new_rounded,
                    ),

                    SizedBox(height: 14.h),

                    LoadingButton(
                      label: lang.iveVerified,
                      isLoading: auth.isCheckingVerification,
                      onPressed: () => _handleIveVerified(auth),
                      icon: Icons.check_circle_outline_rounded,
                    ),

                    SizedBox(height: 18.h),

                    Center(
                      child: TextButton(
                        onPressed: _resendCooldown > 0 || auth.isResendingEmail
                            ? null
                            : () => _handleResend(auth),
                        child: Text(
                          auth.isResendingEmail
                              ? lang.sending
                              : _resendCooldown > 0
                              ? lang.resendInSeconds(_resendCooldown)
                              : lang.resendEmailPrompt,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
