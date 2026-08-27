import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rosivia/core/functions/navigations.dart';
import 'package:rosivia/core/widgets/main_button.dart';
import 'package:rosivia/core/widgets/state_views.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import 'help_center_screen.dart';

/// Contact page. ROSIVA has no direct contact channel configured yet,
/// so this screen only points the user toward the Help Center instead
/// of showing a placeholder email/phone/address.
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(lang.contactUs, style: theme.textTheme.titleMedium)),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(20.w),
          children: [
            Text(
              lang.contactUsSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
            SizedBox(height: 24.h),
            AppEmptyView(
              icon: Icons.mail_outline_rounded,
              title: lang.contactUsNotConfiguredTitle,
              description: lang.contactUsNotConfiguredDesc,
              action: SizedBox(
                width: double.infinity,
                child: MainButton(
                  text: lang.contactUsHelpCenterCta,
                  onpress: () => pushTo(context, const HelpCenterScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
