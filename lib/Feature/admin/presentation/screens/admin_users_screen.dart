import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import 'package:rosivia/core/widgets/state_views.dart';

import '../../../auth/data/models/user_model.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/admin_user_list_item.dart';

enum _StatusFilter { all, verified, unverified }

/// The "Users" tab. Reads the real `users` collection. `firestore.rules`
/// allows an admin (verified server-side via `isAdmin()`) to read any
/// user's document — but that rule only takes effect once it's been
/// deployed (`firebase deploy --only firestore:rules`). Until then,
/// or if deployment lags behind this code, Firestore will still
/// return `permission-denied` for anything beyond the admin's own
/// doc — this screen surfaces that honestly instead of pretending a
/// full list is available.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = true;
  bool _restricted = false;
  bool _hasError = false;
  List<UserModel> _users = const [];
  final _searchController = TextEditingController();
  String _query = '';
  _StatusFilter _filter = _StatusFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
      _restricted = false;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      if (!mounted) return;
      setState(() {
        _users = snapshot.docs.map((doc) => UserModel.fromSnapshot(doc)).toList();
        _loading = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _restricted = e.code == 'permission-denied';
        _hasError = !_restricted;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  List<UserModel> get _filtered {
    return _users.where((user) {
      final matchesQuery = _query.isEmpty ||
          user.fullName.toLowerCase().contains(_query) ||
          user.email.toLowerCase().contains(_query);
      final matchesFilter = switch (_filter) {
        _StatusFilter.all => true,
        _StatusFilter.verified => user.isEmailVerified,
        _StatusFilter.unverified => !user.isEmailVerified,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  int get _activeCount {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return _users.where((u) => u.lastLogin != null && u.lastLogin!.isAfter(cutoff)).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.navUsers,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                lang.adminUsersSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: lang.adminSearchUsersHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: _searchController.clear,
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  _FilterChip(
                    label: lang.adminFilterAll,
                    selected: _filter == _StatusFilter.all,
                    onTap: () => setState(() => _filter = _StatusFilter.all),
                  ),
                  _FilterChip(
                    label: lang.adminStatusVerified,
                    selected: _filter == _StatusFilter.verified,
                    onTap: () => setState(() => _filter = _StatusFilter.verified),
                  ),
                  _FilterChip(
                    label: lang.adminStatusUnverified,
                    selected: _filter == _StatusFilter.unverified,
                    onTap: () => setState(() => _filter = _StatusFilter.unverified),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loading)
                _buildSkeleton()
              else ...[
                _buildStatsGrid(theme, lang),
                if (_restricted) ...[
                  const SizedBox(height: 16),
                  _RestrictedNotice(text: lang.adminUserListRestricted),
                ],
                const SizedBox(height: 20),
                _buildList(theme, lang),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme, AppLocalizations lang) {
    final cards = <Widget>[
      AdminStatCard(
        icon: Icons.people_alt_rounded,
        label: lang.totalUsers,
        value: '${_users.length}',
        supportingText: lang.adminTotalUsersDesc,
      ),
      AdminStatCard(
        icon: Icons.verified_rounded,
        label: lang.verifiedEmails,
        value: '${_users.where((u) => u.isEmailVerified).length}',
        supportingText: lang.adminVerifiedUsersDesc,
        accentColor: theme.colorScheme.tertiary,
      ),
      AdminStatCard(
        icon: Icons.bolt_rounded,
        label: lang.adminActiveUsers,
        value: '$_activeCount',
        supportingText: lang.adminActiveUsersDesc,
        accentColor: theme.colorScheme.secondary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 760 ? 3 : (width >= 500 ? 2 : 1);
        const gap = 16.0;
        final cardWidth = (width - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final c in cards) SizedBox(width: cardWidth, child: c)],
        );
      },
    );
  }

  Widget _buildList(ThemeData theme, AppLocalizations lang) {
    if (_hasError) {
      return AppErrorView(
        title: lang.somethingWentWrong,
        description: lang.somethingWentWrongDesc,
        retryLabel: lang.retry,
        onRetry: _load,
      );
    }

    final filtered = _filtered;

    if (filtered.isEmpty) {
      return AppEmptyView(
        icon: Icons.people_outline_rounded,
        title: _users.isEmpty ? lang.adminNoUsersYet : lang.adminNoUsersFound,
        description: _users.isEmpty ? lang.adminUsersSubtitle : lang.adminNoUsersFoundDesc,
      );
    }

    return Column(
      children: [
        for (var i = 0; i < filtered.length; i++) ...[
          AdminUserListItem(
            user: filtered[i],
            onTap: () => _showUserDetails(context, filtered[i], lang),
          ),
          if (i != filtered.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 760 ? 3 : (width >= 500 ? 2 : 1);
        const gap = 16.0;
        final cardWidth = (width - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < columns; i++)
              SizedBox(width: cardWidth, child: const AdminStatCardSkeleton()),
          ],
        );
      },
    );
  }

  void _showUserDetails(BuildContext context, UserModel user, AppLocalizations lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName.isNotEmpty ? user.fullName : lang.adminFallbackName,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(user.email, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              if (user.country != null && user.country!.isNotEmpty)
                _DetailRow(label: lang.country, value: user.country!),
              if (user.language != null && user.language!.isNotEmpty)
                _DetailRow(label: lang.language, value: user.language!.toUpperCase()),
              _DetailRow(
                label: lang.adminStatusVerified,
                value: user.isEmailVerified ? lang.adminStatusVerified : lang.adminStatusUnverified,
              ),
              if (user.createdAt != null)
                _DetailRow(
                  label: lang.adminJoinedOn(
                    DateFormat.yMMMd(lang.localeName).format(user.createdAt!),
                  ),
                  value: '',
                ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(lang.adminDeleteNotAvailable)),
                  );
                },
                icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                label: Text(lang.adminDeleteUser, style: TextStyle(color: theme.colorScheme.error)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.4)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primary.withValues(alpha: 0.14),
      labelStyle: TextStyle(
        color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _RestrictedNotice extends StatelessWidget {
  final String text;

  const _RestrictedNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (value.isNotEmpty) Text(value, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
