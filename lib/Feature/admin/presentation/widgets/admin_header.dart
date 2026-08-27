import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/Feature/intro/language/language_provider.dart';
import 'package:rosivia/Feature/intro/language/language_tile.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../../auth/data/models/user_model.dart';

/// Top bar shared by every admin screen: branding, an optional menu
/// button (mobile/tablet, opens the nav drawer), a language selector,
/// and the signed-in admin's avatar. The avatar is a real menu
/// (Language / Settings / Logout) — this is how Settings is reached
/// on mobile, where there's no sidebar and Settings isn't one of the
/// 4 bottom-nav tabs.
class AdminHeader extends StatelessWidget implements PreferredSizeWidget {
  final UserModel? adminUser;
  final VoidCallback? onMenuTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onLogout;

  const AdminHeader({
    super.key,
    required this.adminUser,
    this.onMenuTap,
    required this.onSettingsTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = AppLocalizations.of(context)!;
    final isNarrow = MediaQuery.sizeOf(context).width < 500;

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      leadingWidth: onMenuTap != null ? 52 : 0,
      leading: onMenuTap != null
          ? IconButton(icon: const Icon(Icons.menu_rounded), onPressed: onMenuTap)
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ROSIVA AI',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isNarrow ? lang.adminMobileHeaderSubtitle : lang.adminDashboardTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (!isNarrow) ...[
          IconButton(
            tooltip: lang.language,
            icon: const Icon(Icons.translate_rounded),
            onPressed: () => _showLanguagePicker(context),
          ),
          _AdminIdentity(adminUser: adminUser),
        ],
        _ProfileMenuButton(
          adminUser: adminUser,
          onLanguageTap: () => _showLanguagePicker(context),
          onSettingsTap: onSettingsTap,
          onLogout: onLogout,
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final languageProvider = context.read<LanguageProvider>();
    final lang = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lang.language, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 18),
              LanguageTile(
                title: 'العربية',
                subtitle: 'Arabic',
                flag: '🇪🇬',
                isSelected: languageProvider.locale.languageCode == 'ar',
                onTap: () {
                  languageProvider.changeLanguage('ar');
                  Navigator.pop(sheetContext);
                },
              ),
              const SizedBox(height: 14),
              LanguageTile(
                title: 'English',
                subtitle: 'English',
                flag: '🇺🇸',
                isSelected: languageProvider.locale.languageCode == 'en',
                onTap: () {
                  languageProvider.changeLanguage('en');
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AdminIdentity extends StatelessWidget {
  final UserModel? adminUser;

  const _AdminIdentity({required this.adminUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = AppLocalizations.of(context)!;

    final name = adminUser?.fullName.isNotEmpty == true
        ? adminUser!.fullName
        : lang.adminFallbackName;
    final email = adminUser?.email;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (email != null && email.isNotEmpty)
            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileMenuButton extends StatelessWidget {
  final UserModel? adminUser;
  final VoidCallback onLanguageTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onLogout;

  const _ProfileMenuButton({
    required this.adminUser,
    required this.onLanguageTap,
    required this.onSettingsTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lang = AppLocalizations.of(context)!;
    final photoUrl = adminUser?.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final isNarrow = MediaQuery.sizeOf(context).width < 500;

    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        switch (value) {
          case 'language':
            onLanguageTap();
          case 'settings':
            onSettingsTap();
          case 'logout':
            onLogout();
        }
      },
      itemBuilder: (context) => [
        if (isNarrow)
          PopupMenuItem(
            value: 'language',
            child: Row(
              children: [
                const Icon(Icons.translate_rounded, size: 18),
                const SizedBox(width: 10),
                Text(lang.language),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              const Icon(Icons.settings_outlined, size: 18),
              const SizedBox(width: 10),
              Text(lang.navSettings),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: colorScheme.error),
              const SizedBox(width: 10),
              Text(lang.logOut, style: TextStyle(color: colorScheme.error)),
            ],
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 17,
        backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
        backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
        child: hasPhoto
            ? null
            : Icon(Icons.person_rounded, size: 18, color: colorScheme.primary),
      ),
    );
  }
}
