import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rosivia/core/styles/colors.dart';


/// A labeled divider used to separate email auth from social auth,
/// e.g. "or continue with".
class AuthDivider extends StatelessWidget {
  final String label;

  const AuthDivider({super.key, this.label = 'or continue with'});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? AppColors.bordercolor : AppColors.bordercolor;

    return Row(
      children: [
        Expanded(child: Divider(color: lineColor, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(child: Divider(color: lineColor, thickness: 1)),
      ],
    );
  }
}
