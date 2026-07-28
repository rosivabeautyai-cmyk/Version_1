import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rosivia/core/styles/colors.dart';


/// Snackbar variants used to color and icon-match the message type.
enum SnackType { success, error, warning, info }

/// Centralized service for showing consistent, beautiful snackbars
/// throughout the ROSIVA app. Keeping this in one place avoids
/// duplicated SnackBar-building logic across screens.
class SnackbarService {
  SnackbarService._();

  static void show(
    BuildContext context, {
    required String message,
    SnackType type = SnackType.info,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final Color backgroundColor = _colorFor(type);
    final IconData icon = _iconFor(type);

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        margin: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          bottom: 16.h,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        elevation: 6,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: SnackType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: SnackType.error);

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: SnackType.warning);

  static void info(BuildContext context, String message) =>
      show(context, message: message, type: SnackType.info);

  static Color _colorFor(SnackType type) {
    switch (type) {
      case SnackType.success:
        return AppColors.primary;
      case SnackType.error:
        return AppColors.errorcolor;
      case SnackType.warning:
        return AppColors.graycolor;
      case SnackType.info:
        return AppColors.bordercolor;
    }
  }

  static IconData _iconFor(SnackType type) {
    switch (type) {
      case SnackType.success:
        return Icons.check_circle_rounded;
      case SnackType.error:
        return Icons.error_rounded;
      case SnackType.warning:
        return Icons.warning_rounded;
      case SnackType.info:
        return Icons.info_rounded;
    }
  }
}
