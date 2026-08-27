import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/core/functions/validators.dart';
import 'package:rosivia/core/styles/colors.dart';
import 'package:rosivia/l10n/app_localizations.dart';

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
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _handleReset(AuthProvider auth) async {
    final lang = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final success = await auth.forgotPassword();

    if (!mounted) return;

    if (success) {
      _showSuccessDialog(auth.forgotEmailController.text.trim());
    } else {
      SnackbarService.error(
        context,
        auth.errorMessage ?? lang.forgotPasswordFailed,
      );
    }
  }

  void _showSuccessDialog(String email) {
    final lang = AppLocalizations.of(context)!;

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
                  lang.checkYourInbox,
                  style: Theme.of(dialogContext)
                      .textTheme
                      .headlineSmall,
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 10.h),

                Text(
                  lang.resetLinkSentMessage(email),
                  textAlign: TextAlign.center,
                  style: Theme.of(dialogContext)
                      .textTheme
                      .bodyMedium,
                ),

                SizedBox(height: 24.h),

                SizedBox(
                  width: double.infinity,
                  child: LoadingButton(
                    label: lang.backToLogin,
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
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                  icon: Icons.lock_reset_rounded,
                  title: lang.forgotPasswordTitle,
                  subtitle: lang.forgotPasswordSubtitle,
                ),

                SizedBox(height: 32.h),

                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 24.h,
                  ),
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
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      AuthTextField(
                        controller: auth.forgotEmailController,
                        label: lang.email,
                        hint: lang.emailHint,
                        prefixIcon: Icons.email_outlined,
                        keyboardType:
                            TextInputType.emailAddress,
                        textInputAction:
                            TextInputAction.done,
                        validator: (value) =>
                            Validators.email(value, lang),
                        onFieldSubmitted: (_) =>
                            _handleReset(auth),
                      ),

                      SizedBox(height: 24.h),

                      LoadingButton(
                        label: lang.sendResetLink,
                        isLoading: auth.isLoading,
                        onPressed: () => _handleReset(auth),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                Center(
                  child: TextButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      size: 18.sp,
                    ),
                    label: Text(lang.backToLogin),
                  ),
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