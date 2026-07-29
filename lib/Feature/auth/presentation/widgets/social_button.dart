import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rosivia/core/styles/colors.dart';

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
                  Text(
                    isGoogle ? 'Continue with Google' : 'Continue with Apple',
                    style: Theme.of(context).textTheme.titleSmall,
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
      // Simplified 'G' glyph to avoid bundling brand image assets.
      return Container(
        height: 20.sp,
        width: 20.sp,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.bordercolor, width: 1),
        ),
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.errorcolor,
          ),
        ),
      );
    }
    return Icon(
      Icons.apple_rounded,
      size: 22.sp,
      color: isDark ? Colors.white : AppColors.blackcolor,
    );
  }
}
