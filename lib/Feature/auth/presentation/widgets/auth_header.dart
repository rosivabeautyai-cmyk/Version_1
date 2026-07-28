import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rosivia/core/styles/colors.dart';


/// A consistent header used at the top of login, register, and
/// forgot-password screens: an icon badge, a title, and a subtitle.
class AuthHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 64.h,
          width: 64.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.graycolor,
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 30.sp),
        ),
        SizedBox(height: 24.h),
        Text(
          title,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        SizedBox(height: 8.h),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
