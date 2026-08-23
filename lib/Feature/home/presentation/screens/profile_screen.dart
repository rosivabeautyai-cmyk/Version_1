import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/core/widgets/main_button.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../../auth/provider/auth_provider.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang.profile,
          style: theme.textTheme.titleMedium,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(20.w),
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(
                    alpha: 0.15,
                  ),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38.r,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.10),
                    child: Icon(
                      Icons.person_rounded,
                      size: 40.sp,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    lang.yourProfile,
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    lang.profileManageSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            MainButton(
              text: lang.logOut,
              onpress: () {
                context.read<AuthProvider>().logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}