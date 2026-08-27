import 'package:flutter/material.dart';

import 'package:rosivia/core/widgets/state_views.dart';

/// A compact KPI card: icon, label, a large metric value, and a small
/// supporting line underneath. Used for Total Products, per-category
/// counts, Users, etc. across the admin dashboard.
class AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String supportingText;
  final Color? accentColor;

  const AdminStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.supportingText,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = accentColor ?? colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 26,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            supportingText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder shown for [AdminStatCard] while its data is
/// still loading — avoids a bare spinner per card.
class AdminStatCardSkeleton extends StatelessWidget {
  const AdminStatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeletonBox(width: 34, height: 34, borderRadius: BorderRadius.all(Radius.circular(9))),
          const SizedBox(height: 16),
          const AppSkeletonBox(width: 70, height: 24, borderRadius: BorderRadius.all(Radius.circular(6))),
          const SizedBox(height: 8),
          const AppSkeletonBox(width: 110, height: 12, borderRadius: BorderRadius.all(Radius.circular(4))),
        ],
      ),
    );
  }
}
