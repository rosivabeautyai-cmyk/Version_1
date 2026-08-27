import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rosivia/core/widgets/state_views.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../../auth/data/models/user_model.dart';
import '../widgets/admin_quick_actions.dart';
import '../widgets/admin_recent_activity_card.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/admin_sync_status_card.dart';
import '../widgets/admin_user_list_item.dart';

/// The "Dashboard" tab: overview metrics, catalog sync status,
/// platform activity, quick actions, and recent users — all built
/// from real Firestore data, with honest empty/loading states where
/// data doesn't exist yet.
class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback onViewProductsTap;
  final VoidCallback onViewUsersTap;
  final VoidCallback onSettingsTap;

  const AdminDashboardScreen({
    super.key,
    required this.onViewProductsTap,
    required this.onViewUsersTap,
    required this.onSettingsTap,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  bool _hasError = false;
  int _totalUsers = 0;
  int _newUsers = 0;
  int _activeUsers = 0;
  int _verifiedUsers = 0;
  int _productsCount = 0;
  int _platformsCount = 0;
  List<UserModel> _recentUsers = const [];

  final _syncSectionKey = GlobalKey();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSync() {
    final syncContext = _syncSectionKey.currentContext;
    if (syncContext == null) return;
    Scrollable.ensureVisible(
      syncContext,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final usersRef = firestore.collection('users');
      final sevenDaysAgo = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 7)),
      );
      final thirtyDaysAgo = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 30)),
      );

      final results = await Future.wait([
        usersRef.count().get(),
        usersRef.where('isEmailVerified', isEqualTo: true).count().get(),
        usersRef.where('createdAt', isGreaterThanOrEqualTo: sevenDaysAgo).count().get(),
        usersRef.where('lastLogin', isGreaterThanOrEqualTo: thirtyDaysAgo).count().get(),
        firestore.collection('products').count().get(),
        usersRef.orderBy('createdAt', descending: true).limit(5).get(),
      ]);

      if (!mounted) return;

      final recentSnapshot = results[5] as QuerySnapshot<Map<String, dynamic>>;

      setState(() {
        _totalUsers = (results[0] as AggregateQuerySnapshot).count ?? 0;
        _verifiedUsers = (results[1] as AggregateQuerySnapshot).count ?? 0;
        _newUsers = (results[2] as AggregateQuerySnapshot).count ?? 0;
        _activeUsers = (results[3] as AggregateQuerySnapshot).count ?? 0;
        _productsCount = (results[4] as AggregateQuerySnapshot).count ?? 0;
        // ROSIVA currently integrates exactly one affiliate platform
        // (Awin) — this reflects that real fact about the codebase,
        // not a fabricated statistic (there's no Firestore collection
        // tracking configured platforms).
        _platformsCount = 1;
        _recentUsers = recentSnapshot.docs
            .map((doc) => UserModel.fromSnapshot(doc))
            .toList();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    if (_loading) {
      return _buildSkeleton();
    }

    if (_hasError) {
      return Center(
        child: AppErrorView(
          title: lang.somethingWentWrong,
          description: lang.somethingWentWrongDesc,
          retryLabel: lang.retry,
          onRetry: _loadStats,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.adminHelloWave,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                lang.adminDashboardSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              _buildKpiGrid(theme, lang),
              const SizedBox(height: 24),
              Container(key: _syncSectionKey),
              const AdminSyncStatusCard(),
              const SizedBox(height: 24),
              _buildResponsiveRow(
                context,
                left: AdminRecentActivityCard(title: lang.adminPlatformActivity),
                right: _RecentUsersCard(users: _recentUsers),
              ),
              const SizedBox(height: 24),
              AdminQuickActions(
                onSyncCatalogTap: _scrollToSync,
                onViewProductsTap: widget.onViewProductsTap,
                onViewUsersTap: widget.onViewUsersTap,
                onSettingsTap: widget.onSettingsTap,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiGrid(ThemeData theme, AppLocalizations lang) {
    final colorScheme = theme.colorScheme;
    final cards = <Widget>[
      AdminStatCard(
        icon: Icons.people_alt_rounded,
        label: lang.totalUsers,
        value: '$_totalUsers',
        supportingText: lang.adminTotalUsersDesc,
      ),
      AdminStatCard(
        icon: Icons.person_add_alt_1_rounded,
        label: lang.adminNewUsers,
        value: '$_newUsers',
        supportingText: lang.adminNewUsersDesc,
        accentColor: colorScheme.secondary,
      ),
      AdminStatCard(
        icon: Icons.bolt_rounded,
        label: lang.adminActiveUsers,
        value: '$_activeUsers',
        supportingText: lang.adminActiveUsersDesc,
        accentColor: colorScheme.secondary,
      ),
      AdminStatCard(
        icon: Icons.verified_rounded,
        label: lang.verifiedEmails,
        value: '$_verifiedUsers',
        supportingText: lang.adminVerifiedUsersDesc,
        accentColor: colorScheme.tertiary,
      ),
      AdminStatCard(
        icon: Icons.inventory_2_rounded,
        label: lang.adminTotalProducts,
        value: '$_productsCount',
        supportingText: lang.adminTotalProductsDesc,
        accentColor: colorScheme.primary,
      ),
      AdminStatCard(
        icon: Icons.hub_rounded,
        label: lang.adminAffiliatePlatforms,
        value: '$_platformsCount',
        supportingText: lang.adminPlatformsDesc,
        accentColor: colorScheme.secondary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // 2x2 on mobile (per spec), 4-across once there's room.
        final columns = width >= 760 ? 4 : 2;
        const gap = 16.0;
        final cardWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }

  Widget _buildResponsiveRow(BuildContext context, {required Widget left, required Widget right}) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 900) {
      return Column(children: [left, const SizedBox(height: 24), right]);
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 24),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 760 ? 4 : 2;
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
        ),
      ),
    );
  }
}

class _RecentUsersCard extends StatelessWidget {
  final List<UserModel> users;

  const _RecentUsersCard({required this.users});

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
            lang.adminRecentUsers,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (users.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                lang.adminNoUsersYet,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < users.length; i++) ...[
                  AdminUserListItem(user: users[i]),
                  if (i != users.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
