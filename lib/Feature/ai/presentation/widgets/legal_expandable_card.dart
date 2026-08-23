import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Collapsible card used to surface required legal/transparency
/// disclosures (AI accuracy, medical advice, affiliate disclosure)
/// without cluttering the primary UI — matches the ROSIVA reference
/// design's expandable disclosure sections.
class LegalExpandableCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color? accentColor;
  final bool initiallyExpanded;

  const LegalExpandableCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.accentColor,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: EdgeInsets.symmetric(horizontal: 14.w),
          childrenPadding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
          leading: Icon(icon, color: color, size: 20.sp),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(color: color),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(body, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
