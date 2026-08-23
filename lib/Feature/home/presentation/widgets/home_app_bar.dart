import 'package:flutter/material.dart';
import 'package:rosivia/l10n/app_localizations.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onLogout;

  const HomeAppBar({
    super.key,
    required this.title,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    return AppBar(
      title: Text(title),
      actions: [
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