import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/styles/colors.dart';

/// A single section within a legal document: a bold heading followed
/// by a paragraph of body text.
class LegalSection {
  final String title;
  final String body;

  const LegalSection({required this.title, required this.body});
}

/// Generic scrollable "legal document" page — used for both the
/// Terms of Service and the Privacy Policy so they always look and
/// behave the same way.
///
/// This widget only handles layout. All of the actual wording lives
/// in [terms_of_service_screen.dart] and [privacy_policy_screen.dart]
/// — edit the text there, not here.
class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final List<LegalSection> sections;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        // Cap the reading column on wide screens so lines stay a
        // comfortable length instead of stretching edge-to-edge.
        child: PageContainer(
          maxWidth: 760,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            children: [
              Text(
                lastUpdated,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 16.h),
              for (final section in sections) ...[
                Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  section.body,
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.6,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
