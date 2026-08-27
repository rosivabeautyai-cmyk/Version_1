import 'package:flutter/material.dart';

import 'package:rosivia/l10n/app_localizations.dart';

import '../../../auth/data/models/user_model.dart';

/// Primary admin navigation: the 4 shell tabs (Dashboard/Users/
/// Products/Platforms) plus Settings (a real pushed screen, not a
/// tab) and Logout. Used both as a permanent desktop rail and as the
/// content of the mobile/tablet [Drawer].
class AdminSidebar extends StatelessWidget {
  final UserModel? adminUser;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onSettingsTap;
  final VoidCallback onLogout;

  const AdminSidebar({
    super.key,
    required this.adminUser,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onSettingsTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'ROSIVA AI',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            _NavItem(
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard_rounded,
              label: lang.navDashboard,
              selected: currentIndex == 0,
              onTap: () => _select(context, 0),
            ),
            _NavItem(
              icon: Icons.people_alt_outlined,
              selectedIcon: Icons.people_alt_rounded,
              label: lang.navUsers,
              selected: currentIndex == 1,
              onTap: () => _select(context, 1),
            ),
            _NavItem(
              icon: Icons.inventory_2_outlined,
              selectedIcon: Icons.inventory_2_rounded,
              label: lang.navProducts,
              selected: currentIndex == 2,
              onTap: () => _select(context, 2),
            ),
            _NavItem(
              icon: Icons.hub_outlined,
              selectedIcon: Icons.hub_rounded,
              label: lang.navPlatforms,
              selected: currentIndex == 3,
              onTap: () => _select(context, 3),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Divider(height: 1),
            ),
            _NavItem(
              icon: Icons.settings_outlined,
              label: lang.navSettings,
              selected: false,
              onTap: () {
                Navigator.maybeOf(context)?.pop();
                onSettingsTap();
              },
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1),
            ),
            _AdminProfileTile(adminUser: adminUser, onLogout: onLogout),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _select(BuildContext context, int index) {
    Navigator.maybeOf(context)?.pop();
    onTabSelected(index);
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(selected ? (selectedIcon ?? icon) : icon, size: 19, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminProfileTile extends StatelessWidget {
  final UserModel? adminUser;
  final VoidCallback onLogout;

  const _AdminProfileTile({required this.adminUser, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = AppLocalizations.of(context)!;

    final name = adminUser?.fullName.isNotEmpty == true
        ? adminUser!.fullName
        : lang.adminFallbackName;
    final photoUrl = adminUser?.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
            backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
            child: hasPhoto
                ? null
                : Icon(Icons.person_rounded, size: 17, color: colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: lang.logOut,
            icon: Icon(Icons.logout_rounded, size: 18, color: colorScheme.error),
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}
