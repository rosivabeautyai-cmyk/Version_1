import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/core/services/snackbar_service.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../../auth/provider/auth_provider.dart';
import '../../../settings/presentation/widgets/settings_widgets.dart';

/// Security page — currently a single row that emails the signed-in
/// user a password reset link.
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  Future<void> _confirmChangePassword(BuildContext context) async {
    final lang = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final email = auth.currentUser?.email ?? '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(lang.changePassword),
          content: Text(lang.sendPasswordResetConfirm(email)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(lang.cancel),
            ),
            TextButton(
              onPressed: () async {
                final success = await auth.sendPasswordResetToCurrentUser();

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);

                if (!context.mounted) return;
                if (success) {
                  SnackbarService.success(context, lang.passwordResetLinkSent);
                } else {
                  SnackbarService.error(
                    context,
                    auth.errorMessage ?? lang.somethingWentWrongDesc,
                  );
                }
              },
              child: Text(lang.changePassword),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(lang.security, style: theme.textTheme.titleMedium)),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(20.w),
          children: [
            Text(
              lang.securityScreenSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
            SizedBox(height: 20.h),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.lock_reset_rounded,
                  title: lang.changePassword,
                  subtitle: lang.changePasswordDesc,
                  onTap: () => _confirmChangePassword(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
