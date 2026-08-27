import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:rosivia/core/widgets/state_views.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import 'admin_time_format.dart';

/// Firestore only keeps the *latest* sync run (`admin/awinSyncStatus`
/// is a single document, overwritten each sync) — there is no
/// historical log collection. So rather than inventing a fake
/// timeline, this derives at most two real events (started/
/// finished) from that one document's own real timestamps, and shows
/// an honest empty state when nothing has run yet.
class AdminRecentActivityCard extends StatelessWidget {
  final String? title;

  const AdminRecentActivityCard({super.key, this.title});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title ?? lang.adminRecentActivity,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.doc('admin/awinSyncStatus').snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data();
              final events = _eventsFrom(data);

              if (events.isEmpty) {
                return AppEmptyView(
                  icon: Icons.history_rounded,
                  title: lang.adminNoActivityTitle,
                  description: lang.adminNoHistoricalActivity,
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < events.length; i++) ...[
                    _ActivityRow(event: events[i], lang: lang),
                    if (i != events.length - 1) const SizedBox(height: 14),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<_ActivityEvent> _eventsFrom(Map<String, dynamic>? data) {
    if (data == null) return const [];

    final status = data['status'] as String?;
    final startedAt = parseIsoTimestamp(data['startedAt']);
    final finishedAt = parseIsoTimestamp(data['finishedAt']);
    final processed = (data['processed'] as num?)?.toInt();

    final events = <_ActivityEvent>[];

    if (finishedAt != null && (status == 'success' || status == 'error')) {
      events.add(
        _ActivityEvent(
          isFailure: status == 'error',
          time: finishedAt,
          processed: processed,
          isCompletion: true,
        ),
      );
    }
    if (startedAt != null) {
      events.add(_ActivityEvent(time: startedAt, isCompletion: false));
    }

    events.sort((a, b) => b.time.compareTo(a.time));
    return events;
  }
}

class _ActivityEvent {
  final DateTime time;
  final bool isCompletion;
  final bool isFailure;
  final int? processed;

  const _ActivityEvent({
    required this.time,
    required this.isCompletion,
    this.isFailure = false,
    this.processed,
  });
}

class _ActivityRow extends StatelessWidget {
  final _ActivityEvent event;
  final AppLocalizations lang;

  const _ActivityRow({required this.event, required this.lang});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final color = !event.isCompletion
        ? colorScheme.onSurfaceVariant
        : event.isFailure
            ? colorScheme.error
            : colorScheme.tertiary;

    final title = !event.isCompletion
        ? lang.adminActivityStarted
        : event.isFailure
            ? lang.adminActivityFailedEvent
            : lang.adminActivityCompleted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (event.isCompletion && event.processed != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${event.processed} ${lang.adminProductsProcessed.toLowerCase()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                formatRelativeTime(lang, event.time),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
