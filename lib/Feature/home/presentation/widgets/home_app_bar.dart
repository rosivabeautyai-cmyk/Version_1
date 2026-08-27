import 'package:flutter/material.dart';
import 'package:rosivia/l10n/app_localizations.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onLogout;
  final VoidCallback? onNotificationsTap;

  const HomeAppBar({
    super.key,
    required this.title,
    required this.onLogout,
    this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    return AppBar(
      title: Text(title),
      actions: [
        if (onNotificationsTap != null)
          IconButton(
            tooltip: lang.notifications,
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: onNotificationsTap,
          ),
        IconButton(
          tooltip: lang.logOut,
          icon: const Icon(Icons.logout_rounded),
          onPressed: onLogout,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}