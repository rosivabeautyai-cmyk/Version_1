import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rosivia/core/styles/colors.dart';
import 'package:rosivia/l10n/app_localizations.dart';

/// A checkbox row for agreeing to the Terms of Service and Privacy
/// Policy, with tappable inline links.
class TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyTap;

  const TermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.onTermsTap,
    this.onPrivacyTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 22.h,
          width: 22.h,
          child: Checkbox(value: value, onChanged: onChanged),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                lang.agreeToThe,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              GestureDetector(
                onTap: onTermsTap,
                child: Text(
                  lang.termsOfService,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Text(lang.termsAnd, style: Theme.of(context).textTheme.bodySmall),
              GestureDetector(
                onTap: onPrivacyTap,
                child: Text(
                  lang.privacyPolicy,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
