import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rosivia/core/styles/colors.dart';

/// A primary button that shows a loading spinner in place of its
/// label while an async action is in progress, and disables itself.
class LoadingButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final IconData? icon;

  const LoadingButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = isLoading || onPressed == null;
    final theme = Theme.of(context);

    return SizedBox(
      height: 54.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: disabled ? theme.colorScheme.surfaceContainerHighest : null,
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary,
                    blurRadius: 0,
                    offset: const Offset(0, 0),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    height: 22.h,
                    width: 22.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    key: const ValueKey('label'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20.sp),
                        SizedBox(width: 8.w),
                      ],
                      Text(label),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
