import 'package:flutter/material.dart';

import 'package:rosivia/l10n/app_localizations.dart';

/// Mobile bottom navigation for the 4 primary admin sections.
/// Settings is intentionally not here (per design: it's reached from
/// the profile/menu instead) so this never exceeds 4 items.
class AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const AdminBottomNav({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onItemSelected,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard_rounded),
                label: lang.navDashboard,
              ),
              NavigationDestination(
                icon: const Icon(Icons.people_alt_outlined),
                selectedIcon: const Icon(Icons.people_alt_rounded),
                label: lang.navUsers,
              ),
              NavigationDestination(
                icon: const Icon(Icons.inventory_2_outlined),
                selectedIcon: const Icon(Icons.inventory_2_rounded),
                label: lang.navProducts,
              ),
              NavigationDestination(
                icon: const Icon(Icons.storefront_outlined),
                selectedIcon: const Icon(Icons.storefront_rounded),
                label: lang.navAffiliateStores,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
