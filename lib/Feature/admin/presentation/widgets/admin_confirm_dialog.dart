import 'package:flutter/material.dart';
import 'package:rosivia/l10n/app_localizations.dart';

/// Shared confirmation dialog for every destructive / consequential
/// admin action (save product, disable user, delete country, …).
/// Returns `true` only if the admin explicitly confirmed.
Future<bool> showAdminConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  bool destructive = false,
}) async {
  final lang = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(lang.adminCancel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel ?? lang.adminSave),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
