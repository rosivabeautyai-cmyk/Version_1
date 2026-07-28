import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rosivia/core/styles/colors.dart';


/// A centered "Don't have an account? Sign up" style prompt used at
/// the bottom of the login and register screens.
class BottomAuthText extends StatelessWidget {
  final String question;
  final String actionLabel;
  final VoidCallback onPressed;

  const BottomAuthText({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          question,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        GestureDetector(
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
            child: Text(
              actionLabel,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.background,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
