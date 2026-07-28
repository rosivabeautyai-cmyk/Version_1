import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rosivia/core/styles/colors.dart';


/// The primary call-to-action button used across the auth flow
/// (Login, Register, Reset Password, etc.).
class AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final IconData? icon;

  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isOutlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20.sp),
          SizedBox(width: 8.w),
        ],
        Text(label),
      ],
    );

    if (isOutlined) {
      return SizedBox(
        height: 54.h,
        child: OutlinedButton(
          onPressed: onPressed,
          child: child,
        ),
      );
    }

    return SizedBox(
      height: 54.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: onPressed == null ? AppColors.primary : null,
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: AppColors.bordercolor,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
          ),
          child: child,
        ),
      ),
    );
  }
}
