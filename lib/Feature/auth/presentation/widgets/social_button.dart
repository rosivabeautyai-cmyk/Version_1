import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rosivia/core/constants/app_images.dart';
import 'package:rosivia/core/styles/colors.dart';
import 'package:rosivia/l10n/app_localizations.dart';

enum SocialProvider { google, apple }

/// A rounded social sign-in button (Google / Apple) with a loading state.
class SocialButton extends StatelessWidget {
  final SocialProvider provider;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SocialButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isGoogle = provider == SocialProvider.google;
    final bool disabled = isLoading || onPressed == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = AppLocalizations.of(context)!;

    return SizedBox(
      height: 54.h,
      child: OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? AppColors.blackcolor : AppColors.primary,
          side: BorderSide(
            color: isDark ? AppColors.background : AppColors.bordercolor,
            width: 1.2,
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ProviderIcon(isGoogle: isGoogle, isDark: isDark),
                  SizedBox(width: 10.w),
                  Flexible(
                    child: Text(
                      isGoogle
                          ? lang.continueWithGoogle
                          : lang.continueWithApple,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProviderIcon extends StatelessWidget {
  final bool isGoogle;
  final bool isDark;

  const _ProviderIcon({required this.isGoogle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (isGoogle) {
      return SizedBox(
        height: 22,
        width: 22,
        child: Image.asset(AppImages.google, fit: BoxFit.contain),
      );
    }
    return Icon(
      Icons.apple_rounded,
      size: 24,
      color: isDark ? Colors.white : AppColors.blackcolor,
    );
  }
}
