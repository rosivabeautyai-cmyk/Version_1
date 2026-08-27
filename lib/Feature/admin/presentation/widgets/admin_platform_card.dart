import 'package:flutter/material.dart';

import 'package:rosivia/l10n/app_localizations.dart';

/// Awin's real card: connection/catalog status, last sync, and
/// product count — all sourced from real Firestore data by the
/// caller (Platforms screen), nothing invented here.
class AdminAwinPlatformCard extends StatelessWidget {
  final bool isConnected;
  final bool isCatalogActive;
  final String lastSyncText;
  final int productsCount;

  const AdminAwinPlatformCard({
    super.key,
    required this.isConnected,
    required this.isCatalogActive,
    required this.lastSyncText,
    required this.productsCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.hub_rounded, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Awin', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              _StatusChip(
                label: isConnected ? lang.adminPlatformConnected : lang.adminPlatformNotConnected,
                color: isConnected ? colorScheme.tertiary : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _PlatformStat(
                  label: lang.adminCatalogSync,
                  value: isCatalogActive ? lang.adminCatalogActive : lang.adminCatalogInactive,
                ),
              ),
              Expanded(
                child: _PlatformStat(label: lang.adminLastSync, value: lastSyncText),
              ),
              Expanded(
                child: _PlatformStat(
                  label: lang.adminTotalProducts,
                  value: '$productsCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A generic, honest "more platforms coming soon" placeholder — never
/// naming a real brand/integration that doesn't exist.
class AdminComingSoonPlatformCard extends StatelessWidget {
  const AdminComingSoonPlatformCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.add_rounded, color: colorScheme.onSurfaceVariant, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              lang.adminComingSoonPlatform,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PlatformStat extends StatelessWidget {
  final String label;
  final String value;

  const _PlatformStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
