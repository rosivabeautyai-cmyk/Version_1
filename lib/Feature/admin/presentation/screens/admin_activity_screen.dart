import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../data/models/activity_log_entry.dart';
import '../../data/repositories/admin_repository.dart';

/// Read-only view of the `activity_log` collection — recent admin
/// actions, newest first, paginated.
class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  final _repo = AdminRepository();
  final _items = <ActivityLogEntry>[];
  String? _cursorId;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      if (more) {
        _loadingMore = true;
      } else {
        _loading = true;
        _error = false;
      }
    });
    try {
      final page = await _repo.fetchActivity(
        limit: 30,
        afterId: more ? _cursorId : null,
      );
      setState(() {
        if (!more) _items.clear();
        _items.addAll(page.items);
        _cursorId = page.cursorId;
        _hasMore = page.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() {
        _error = _items.isEmpty;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(lang.adminActivityLog)),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error
                ? Center(child: Text(lang.somethingWentWrongDesc))
                : _items.isEmpty
                    ? Center(child: Text(lang.adminActivityEmpty))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (_hasMore &&
                                !_loadingMore &&
                                n.metrics.pixels >=
                                    n.metrics.maxScrollExtent - 200) {
                              _load(more: true);
                            }
                            return false;
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length + (_loadingMore ? 1 : 0),
                            separatorBuilder: (_, _) => const Divider(height: 12),
                            itemBuilder: (context, i) {
                              if (i >= _items.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                );
                              }
                              final e = _items[i];
                              return ListTile(
                                dense: true,
                                title: Text(
                                  e.summary.isNotEmpty ? e.summary : e.action,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                subtitle: Text(
                                  '${e.action} · ${e.entityType}'
                                  '${e.entityId != null ? ' (${e.entityId})' : ''}'
                                  '${e.createdAt != null ? ' · ${DateFormat.yMMMd(lang.localeName).add_Hm().format(e.createdAt!)}' : ''}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                trailing: Text(
                                  '${lang.adminActivityBy} ${_shortUid(e.actorUid)}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
      ),
    );
  }

  String _shortUid(String uid) =>
      uid.length <= 6 ? uid : '${uid.substring(0, 6)}…';
}
