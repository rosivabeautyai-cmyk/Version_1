import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/core/styles/colors.dart';
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
    Navigator.of(context).pushNamedAndRemoveUntil(
      AuthRoutes.gate,
      (route) => false,
    );
  }

  Future<void> _handleOpenMail() async {
    // Best-effort deep link into the default mail app.
    final uri = Uri(scheme: 'mailto');
    try {
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        SnackbarService.info(context, 'Please open your mail app manually.');
      }
    } catch (_) {
      if (mounted) {
        SnackbarService.info(context, 'Please open your mail app manually.');
      }
    }
  }

  Future<void> _handleIveVerified(AuthProvider auth) async {
    final verified = await auth.reloadUser();
    if (!mounted) return;

    if (verified) {
      _navigateToHome();
    } else {
      SnackbarService.warning(
        context,
        'Your email is not verified yet. Please tap the link we sent you.',
      );
    }
  }

  Future<void> _handleResend(AuthProvider auth) async {
    if (_resendCooldown > 0) return;
    final success = await auth.sendVerificationEmail();
    if (!mounted) return;

    if (success) {
      SnackbarService.success(context, 'Verification email sent!');
      _startCooldown();
    } else {
      SnackbarService.error(
        context,
        auth.errorMessage ?? 'Failed to resend email.',
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
    final email = auth.currentUser?.email ?? 'your email';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  height: 140.h,
                  width: 140.h,
                  decoration: BoxDecoration(
                    
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.background,
                        blurRadius: 32,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.mark_email_unread_rounded,
                    color: Colors.white,
                    size: 64.sp,
                  ),
                ),
              ),
              SizedBox(height: 36.h),
              Text(
                'Verify your email',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: 12.h),
              Text(
                "We've sent a verification link to\n$email.\n"
                'Tap the link in that email to activate your account.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 40.h),
              LoadingButton(
                label: 'Open Mail App',
                isLoading: false,
                onPressed: _handleOpenMail,
                icon: Icons.open_in_new_rounded,
              ),
              SizedBox(height: 14.h),
              LoadingButton(
                label: "I've Verified",
                isLoading: auth.isCheckingVerification,
                onPressed: () => _handleIveVerified(auth),
                icon: Icons.check_circle_outline_rounded,
              ),
              SizedBox(height: 20.h),
              Center(
                child: TextButton(
                  onPressed: _resendCooldown > 0 || auth.isResendingEmail
                      ? null
                      : () => _handleResend(auth),
                  child: Text(
                    auth.isResendingEmail
                        ? 'Sending...'
                        : _resendCooldown > 0
                            ? 'Resend in ${_resendCooldown}s'
                            : "Didn't get the email? Resend",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
