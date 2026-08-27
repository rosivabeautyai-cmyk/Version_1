import 'package:flutter/material.dart';

import 'package:rosivia/l10n/app_localizations.dart';

/// Small "Quick Actions" row. Every action here is real — they just
/// switch to an existing shell tab or push the existing Settings
/// screen, nothing fake.
class AdminQuickActions extends StatelessWidget {
  final VoidCallback onSyncCatalogTap;
  final VoidCallback onViewProductsTap;
  final VoidCallback onViewUsersTap;
  final VoidCallback onSettingsTap;

  const AdminQuickActions({
    super.key,
    required this.onSyncCatalogTap,
    required this.onViewProductsTap,
    required this.onViewUsersTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.adminQuickActions,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickActionChip(
                icon: Icons.sync_rounded,
                label: lang.adminSyncCatalogButton,
                onTap: onSyncCatalogTap,
              ),
              _QuickActionChip(
                icon: Icons.inventory_2_outlined,
                label: lang.adminViewProducts,
                onTap: onViewProductsTap,
              ),
              _QuickActionChip(
                icon: Icons.people_alt_outlined,
                label: lang.adminViewUsers,
                onTap: onViewUsersTap,
              ),
              _QuickActionChip(
                icon: Icons.settings_outlined,
                label: lang.navSettings,
                onTap: onSettingsTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
