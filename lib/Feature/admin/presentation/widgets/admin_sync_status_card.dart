import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:rosivia/core/services/snackbar_service.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import 'admin_time_format.dart';

/// The URL admins use to manually trigger the Awin catalog sync — it
/// runs on GitHub Actions (see .github/workflows/awin-sync.yml), not
/// as a Firebase callable, so there's no in-app secret/token involved:
/// this just opens the page where the admin clicks "Run workflow"
/// themselves in their own authenticated GitHub session.
const _awinWorkflowUrl =
    'https://github.com/rosivabeautyai-cmyk/Version_1/actions/workflows/awin-sync.yml';

/// A subtle warning tone for a "syncing" state — AppColors has no
/// dedicated warning/amber color, so this is scoped locally to the
/// admin dashboard rather than added to the shared palette.
const _warningColor = Color(0xFFB98900);

enum _SyncState { never, running, success, error }

/// Large "Catalog Sync" section: live status (from `admin/
/// awinSyncStatus`), the last run's counts/duration, and a "Sync
/// Catalog" action that opens the GitHub Actions run page. Detects a
/// running -> success/error transition in real time and shows the
/// matching feedback automatically, whether the sync was triggered
/// from here, from another tab, or by the daily schedule.
class AdminSyncStatusCard extends StatefulWidget {
  const AdminSyncStatusCard({super.key});

  @override
  State<AdminSyncStatusCard> createState() => _AdminSyncStatusCardState();
}

class _AdminSyncStatusCardState extends State<AdminSyncStatusCard> {
  String? _previousStatus;
  bool _isOpeningLink = false;

  Future<void> _openWorkflow() async {
    if (_isOpeningLink) return;
    final lang = AppLocalizations.of(context)!;
    setState(() => _isOpeningLink = true);
    try {
      final uri = Uri.parse(_awinWorkflowUrl);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        SnackbarService.error(context, lang.adminSyncLinkFailed);
      }
    } catch (_) {
      if (mounted) SnackbarService.error(context, lang.adminSyncLinkFailed);
    } finally {
      if (mounted) setState(() => _isOpeningLink = false);
    }
  }

  void _handleStatusTransition(
    AppLocalizations lang,
    Map<String, dynamic>? data,
  ) {
    final status = data?['status'] as String?;
    if (status == null || status == _previousStatus) return;

    final wasRunning = _previousStatus == 'running';
    _previousStatus = status;

    if (!wasRunning) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (status == 'success') {
        final imported = (data?['imported'] as num?)?.toInt();
        SnackbarService.success(
          context,
          imported != null
              ? '${lang.adminCatalogSyncedSuccess} ${lang.adminSyncedProductsCount(imported)}'
              : lang.adminCatalogSyncedSuccess,
        );
      } else if (status == 'error') {
        SnackbarService.error(context, lang.adminSyncFailedDesc);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.doc('admin/awinSyncStatus').snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          _handleStatusTransition(lang, data);

          final status = data?['status'] as String?;
          final state = switch (status) {
            'running' => _SyncState.running,
            'success' => _SyncState.success,
            'error' => _SyncState.error,
            _ => _SyncState.never,
          };

          final finishedAt = parseIsoTimestamp(data?['finishedAt']);
          final startedAt = parseIsoTimestamp(data?['startedAt']);
          final imported = (data?['imported'] as num?)?.toInt();
          final skipped = (data?['skipped'] as num?)?.toInt();
          final processed = (data?['processed'] as num?)?.toInt();
          final duration = formatSyncDuration(startedAt, finishedAt);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    lang.adminCatalogSync,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusPill(state: state, lang: lang),
                ],
              ),
              const SizedBox(height: 20),
              if (state == _SyncState.never)
                Text(
                  lang.adminSyncNever,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: 32,
                  runSpacing: 16,
                  children: [
                    _SyncMetric(
                      label: lang.adminLastSuccessfulSync,
                      value: finishedAt != null
                          ? formatRelativeTime(lang, finishedAt)
                          : '—',
                    ),
                    if (imported != null)
                      _SyncMetric(
                        label: lang.adminProductsImported,
                        value: '$imported',
                      ),
                    if (skipped != null)
                      _SyncMetric(
                        label: lang.adminProductsSkipped,
                        value: '$skipped',
                      ),
                    if (processed != null)
                      _SyncMetric(
                        label: lang.adminProductsProcessed,
                        value: '$processed',
                      ),
                    if (duration != null)
                      _SyncMetric(
                        label: lang.adminSyncDuration,
                        value: duration,
                      ),
                  ],
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isOpeningLink ? null : _openWorkflow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isOpeningLink
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sync_rounded, size: 18),
                    label: Text(lang.adminSyncCatalogButton),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lang.adminSyncOpensGithub,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final _SyncState state;
  final AppLocalizations lang;

  const _StatusPill({required this.state, required this.lang});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (label, color) = switch (state) {
      _SyncState.running => (lang.adminSyncRunning, _warningColor),
      _SyncState.success => (lang.adminSyncSuccess, colorScheme.tertiary),
      _SyncState.error => (lang.adminSyncError, colorScheme.error),
      _SyncState.never => (lang.adminSyncNever, colorScheme.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SyncMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
