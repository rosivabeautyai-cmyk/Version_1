import 'package:flutter/material.dart';

import 'package:rosivia/core/widgets/state_views.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../data/models/affiliate_store_model.dart';
import '../../data/models/affiliate_sync_log_model.dart';
import '../../data/repositories/affiliate_store_repository.dart';
import '../widgets/admin_time_format.dart';

/// Read-only history of sync runs for one affiliate store
/// (`affiliateSyncLogs`). Written by the backend sync engine.
class AdminAffiliateSyncHistoryScreen extends StatelessWidget {
  final AffiliateStoreRepository repository;
  final AffiliateStore store;

  const AdminAffiliateSyncHistoryScreen({
    super.key,
    required this.repository,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${lang.affiliateSyncHistoryTitle} · ${store.name}'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<AffiliateSyncLog>>(
          stream: repository.watchSyncLogs(store.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: AppErrorView(
                  title: lang.somethingWentWrong,
                  description: lang.somethingWentWrongDesc,
                  retryLabel: lang.retry,
                  onRetry: () {},
                ),
              );
            }
            final logs = snapshot.data;
            if (logs == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (logs.isEmpty) {
              return AppEmptyView(
                icon: Icons.history_rounded,
                title: lang.affiliateSyncHistoryEmpty,
                description: store.isManual
                    ? lang.affiliateManualNoSync
                    : lang.affiliateStoresSubtitle,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _LogTile(log: logs[i]),
            );
          },
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final AffiliateSyncLog log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = AppLocalizations.of(context)!;

    final Color statusColor = log.isError
        ? colorScheme.error
        : (log.isPartial || log.isNeedsReview)
            ? colorScheme.tertiary
            : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                log.isError
                    ? Icons.error_outline_rounded
                    : (log.isPartial || log.isNeedsReview)
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline_rounded,
                size: 18,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Text(
                log.statusValue.replaceAll('_', ' ').toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                log.startedAt != null
                    ? formatRelativeTime(lang, log.startedAt!)
                    : '—',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lang.affiliateSyncResult(
              log.newProducts,
              log.updatedProducts,
              log.deactivatedProducts,
              log.failedProducts,
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${log.totalFetched} ${lang.affiliateColProducts.toLowerCase()} · '
            '${_triggeredBy(lang, log.triggeredBy)}'
            '${formatSyncDuration(log.startedAt, log.completedAt) != null ? ' · ${formatSyncDuration(log.startedAt, log.completedAt)}' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (log.errorSummary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              log.errorSummary,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ],
          if (log.failureSamples.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final s in log.failureSamples.take(5))
              Text(
                '• ${s['code']}: ${s['detail']}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ],
      ),
    );
  }

  static String _triggeredBy(AppLocalizations lang, String who) {
    switch (who) {
      case 'admin':
        return 'admin';
      case 'scheduled':
        return 'scheduled';
      default:
        return 'system';
    }
  }
}
