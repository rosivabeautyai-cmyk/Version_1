import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/core/functions/validators.dart';
import 'package:rosivia/core/styles/colors.dart';

import '../../../../core/services/snackbar_service.dart';
import '../../provider/auth_provider.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_textfield.dart';
import '../widgets/loading_button.dart';

/// The forgot password screen: collects an email address and sends
/// a Firebase password reset link, then shows a success dialog.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _handleReset(AuthProvider auth) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await auth.forgotPassword();
    if (!mounted) return;

    if (success) {
      _showSuccessDialog(auth.forgotEmailController.text.trim());
    } else {
      SnackbarService.error(
        context,
        auth.errorMessage ?? 'Failed to send reset email.',
      );
    }
  }

  void _showSuccessDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(28.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 72.h,
                  width: 72.h,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_read_rounded,
                    color: AppColors.primary,
                    size: 36.sp,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Check your inbox',
                  style: Theme.of(dialogContext).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.h),
                Text(
                  'We sent a password reset link to $email. '
                  'Follow the instructions to create a new password.',
                  textAlign: TextAlign.center,
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: LoadingButton(
                    label: 'Back to Login',
                    isLoading: false,
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 12.h),
                const AuthHeader(
                  icon: Icons.lock_reset_rounded,
                  title: 'Forgot password?',
                  subtitle:
                      "No worries, we'll send you reset instructions.",
                ),
                SizedBox(height: 36.h),
                AuthTextField(
                  controller: auth.forgotEmailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: Validators.email,
                  onFieldSubmitted: (_) => _handleReset(auth),
                ),
                SizedBox(height: 28.h),
                LoadingButton(
                  label: 'Send Reset Link',
                  isLoading: auth.isLoading,
                  onPressed: () => _handleReset(auth),
                ),
                SizedBox(height: 24.h),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back_rounded, size: 18.sp),
                    label: const Text('Back to Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
