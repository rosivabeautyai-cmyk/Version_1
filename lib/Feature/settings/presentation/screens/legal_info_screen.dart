import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Minimal single-topic legal/transparency detail page, used by
/// Settings rows that link to a disclosure (affiliate transparency,
/// medical disclaimer) that isn't a full multi-section document.
class LegalInfoScreen extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  const LegalInfoScreen({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title, style: theme.textTheme.titleMedium)),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(20.w),
          children: [
            Icon(icon, size: 32.sp, color: theme.colorScheme.primary),
            SizedBox(height: 16.h),
            Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
          ],
        ),
      ),
    );
  }
}
