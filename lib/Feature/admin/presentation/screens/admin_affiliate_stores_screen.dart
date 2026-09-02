import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/core/functions/navigations.dart';
import 'package:rosivia/core/services/snackbar_service.dart';
import 'package:rosivia/core/widgets/state_views.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../data/models/affiliate_store_model.dart';
import '../../data/repositories/affiliate_store_repository.dart';
import '../../provider/admin_config_provider.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_time_format.dart';
import 'admin_affiliate_store_form_screen.dart';
import 'admin_affiliate_sync_history_screen.dart';
import 'admin_platforms_screen.dart';

/// The "Affiliate Stores" tab. Add a store once; the backend imports
/// its products automatically. Reuses the existing admin card / button /
/// confirm-dialog / relative-time styling — no new design language.
class AdminAffiliateStoresScreen extends StatefulWidget {
  const AdminAffiliateStoresScreen({super.key});

  @override
  State<AdminAffiliateStoresScreen> createState() =>
      _AdminAffiliateStoresScreenState();
}

class _AdminAffiliateStoresScreenState
    extends State<AdminAffiliateStoresScreen> {
  final _repo = AffiliateStoreRepository();
  String? _busyStoreId;

  @override
  void dispose() {
    _repo.dispose();
    super.dispose();
  }

  List<String> get _currencies =>
      context.read<AdminConfigProvider>().currencies.map((c) => c.code).toList();
  List<String> get _countries =>
      context.read<AdminConfigProvider>().countries.map((c) => c.code).toList();

  Future<void> _openForm({AffiliateStore? store}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminAffiliateStoreFormScreen(
          repository: _repo,
          existing: store,
          currencies: _currencies,
          countries: _countries,
        ),
      ),
    );
    if (saved == true && mounted) {
      SnackbarService.success(
        context,
        AppLocalizations.of(context)!.affiliateFormSaved,
      );
    }
  }

  Future<void> _syncNow(AffiliateStore store) async {
    final lang = AppLocalizations.of(context)!;
    if (!_repo.backendConfigured) {
      SnackbarService.warning(context, lang.affiliateBackendMissing);
      return;
    }
    setState(() => _busyStoreId = store.id);
    SnackbarService.info(context, lang.affiliateSyncStarted);
    final res = await _repo.syncNow(store.id);
    if (!mounted) return;
    setState(() => _busyStoreId = null);

    if (res.mode == 'queued') {
      // Deliberately NOT a success toast — the sync has NOT run yet.
      _showQueuedDialog(res.message ?? lang.affiliateSyncQueuedMsg);
      return;
    }
    if (res.mode == 'inline' && res.log != null) {
      final l = res.log!;
      final msg = '${lang.affiliateSyncDoneMsg} · '
          '${lang.affiliateSyncResult(l.newProducts, l.updatedProducts, l.deactivatedProducts, l.failedProducts)}';
      if (l.isNeedsReview) {
        SnackbarService.warning(context, l.errorSummary.isNotEmpty ? l.errorSummary : msg);
      } else if (res.ok) {
        SnackbarService.success(context, msg);
      } else {
        SnackbarService.error(context, res.message ?? lang.affiliateSyncFailedMsg);
      }
      return;
    }
    SnackbarService.error(context, res.message ?? lang.affiliateSyncFailedMsg);
  }

  Future<void> _toggleEnabled(AffiliateStore store) async {
    await _repo.setStoreEnabled(store.id, !store.isActive);
  }

  Future<void> _delete(AffiliateStore store) async {
    final lang = AppLocalizations.of(context)!;
    final ok = await showAdminConfirmDialog(
      context,
      title: lang.affiliateDeleteConfirmTitle,
      message: lang.affiliateDeleteConfirmBody,
      confirmLabel: lang.affiliateActionDelete,
      destructive: true,
    );
    if (!ok) return;
    await _repo.deleteStore(store.id);
    if (mounted) {
      SnackbarService.success(context, lang.affiliateActionDelete);
    }
  }

  void _openHistory(AffiliateStore store) {
    pushTo(
      context,
      AdminAffiliateSyncHistoryScreen(repository: _repo, store: store),
    );
  }

  void _showQueuedDialog(String message) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.schedule_rounded, color: theme.colorScheme.tertiary),
        title: Text(AppLocalizations.of(ctx)!.affiliateSyncQueuedShort),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    );
  }

  void _openDetails(AffiliateStore store) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _StoreDetailsSheet(store: store),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return StreamBuilder<List<AffiliateStore>>(
      stream: _repo.watchStores(),
      builder: (context, snapshot) {
        final stores = snapshot.data;
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lang.affiliateStores,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(lang.affiliateAddStore),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang.affiliateStoresSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () =>
                          pushTo(context, const AdminPlatformsScreen()),
                      icon: const Icon(Icons.insights_rounded, size: 18),
                      label: Text(lang.affiliatePlatformStatusLink),
                    ),
                    const SizedBox(height: 12),
                    if (!_repo.backendConfigured)
                      _InfoBanner(text: lang.affiliateBackendMissing),
                    const SizedBox(height: 12),
                    _buildBody(theme, lang, snapshot, stores),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    ThemeData theme,
    AppLocalizations lang,
    AsyncSnapshot<List<AffiliateStore>> snapshot,
    List<AffiliateStore>? stores,
  ) {
    if (snapshot.hasError) {
      return AppErrorView(
        title: lang.somethingWentWrong,
        description: lang.affiliateStoreLoadError,
        retryLabel: lang.retry,
        onRetry: () => setState(() {}),
      );
    }
    if (stores == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (stores.isEmpty) {
      return AppEmptyView(
        icon: Icons.storefront_outlined,
        title: lang.affiliateNoStoresTitle,
        description: lang.affiliateNoStoresDesc,
      );
    }
    return Column(
      children: [
        for (var i = 0; i < stores.length; i++) ...[
          _AffiliateStoreCard(
            store: stores[i],
            busy: _busyStoreId == stores[i].id,
            onView: () => _openDetails(stores[i]),
            onEdit: () => _openForm(store: stores[i]),
            onSyncNow: () => _syncNow(stores[i]),
            onToggleEnabled: () => _toggleEnabled(stores[i]),
            onDelete: () => _delete(stores[i]),
            onHistory: () => _openHistory(stores[i]),
          ),
          if (i != stores.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Card
// ---------------------------------------------------------------------

class _AffiliateStoreCard extends StatelessWidget {
  final AffiliateStore store;
  final bool busy;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onSyncNow;
  final VoidCallback onToggleEnabled;
  final VoidCallback onDelete;
  final VoidCallback onHistory;

  const _AffiliateStoreCard({
    required this.store,
    required this.busy,
    required this.onView,
    required this.onEdit,
    required this.onSyncNow,
    required this.onToggleEnabled,
    required this.onDelete,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Logo(url: store.logoUrl, name: store.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${store.productCount} ${lang.affiliateColProducts.toLowerCase()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(active: store.isActive),
              const SizedBox(width: 4),
              _SyncStatusChip(store: store),
              _ActionsMenu(
                store: store,
                onView: onView,
                onEdit: onEdit,
                onSyncNow: onSyncNow,
                onToggleEnabled: onToggleEnabled,
                onDelete: onDelete,
                onHistory: onHistory,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _Meta(
                label: lang.affiliateColNetwork,
                value: store.affiliateNetwork?.toUpperCase() ?? '—',
              ),
              _Meta(
                label: lang.affiliateColIntegration,
                value: _integrationLabel(lang, store.integrationType),
              ),
              _Meta(
                label: lang.affiliateColCommission,
                value: store.commissionType == AffiliateCommissionType.percentage
                    ? '${store.defaultCommissionRate}%'
                    : '${store.defaultCommissionRate} ${store.currency}',
              ),
              _Meta(
                label: lang.affiliateColLastSync,
                value: store.lastSyncAt != null
                    ? formatRelativeTime(lang, store.lastSyncAt!)
                    : lang.affiliateNeverSynced,
              ),
            ],
          ),
          if ((store.lastSyncStatus == 'error' ||
                  store.lastSyncStatus == 'needs_review') &&
              store.lastSyncError != null) ...[
            const SizedBox(height: 8),
            Text(
              store.lastSyncError!,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: busy || store.isManual ? null : onSyncNow,
                icon: busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded, size: 18),
                label: Text(lang.affiliateActionSyncNow),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onHistory,
                icon: const Icon(Icons.history_rounded, size: 18),
                label: Text(lang.affiliateActionHistory),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _integrationLabel(
    AppLocalizations lang,
    AffiliateIntegrationType t,
  ) {
    switch (t) {
      case AffiliateIntegrationType.productFeed:
        return lang.affiliateIntegrationProductFeed;
      case AffiliateIntegrationType.restApi:
        return lang.affiliateIntegrationRestApi;
      case AffiliateIntegrationType.affiliateNetwork:
        return lang.affiliateIntegrationNetwork;
      case AffiliateIntegrationType.manual:
        return lang.affiliateIntegrationManual;
      case AffiliateIntegrationType.mock:
        return lang.affiliateIntegrationMock;
    }
  }
}

class _ActionsMenu extends StatelessWidget {
  final AffiliateStore store;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onSyncNow;
  final VoidCallback onToggleEnabled;
  final VoidCallback onDelete;
  final VoidCallback onHistory;

  const _ActionsMenu({
    required this.store,
    required this.onView,
    required this.onEdit,
    required this.onSyncNow,
    required this.onToggleEnabled,
    required this.onDelete,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (v) {
        switch (v) {
          case 'view':
            onView();
          case 'edit':
            onEdit();
          case 'sync':
            onSyncNow();
          case 'toggle':
            onToggleEnabled();
          case 'delete':
            onDelete();
          case 'history':
            onHistory();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'view', child: Text(lang.affiliateActionView)),
        PopupMenuItem(value: 'edit', child: Text(lang.affiliateActionEdit)),
        if (!store.isManual)
          PopupMenuItem(value: 'sync', child: Text(lang.affiliateActionSyncNow)),
        PopupMenuItem(
          value: 'toggle',
          child: Text(store.isActive
              ? lang.affiliateActionDisable
              : lang.affiliateActionEnable),
        ),
        PopupMenuItem(
          value: 'history',
          child: Text(lang.affiliateActionHistory),
        ),
        PopupMenuItem(value: 'delete', child: Text(lang.affiliateActionDelete)),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  final String? url;
  final String name;
  const _Logo({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasUrl = url != null && url!.isNotEmpty;
    return Container(
      width: 44,
      height: 44,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: hasUrl
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) => _initial(colorScheme),
            )
          : _initial(colorScheme),
    );
  }

  Widget _initial(ColorScheme colorScheme) => Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  final bool active;
  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final color = active ? colorScheme.primary : colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? lang.affiliateStatusActive : lang.affiliateStatusInactive,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _SyncStatusChip extends StatelessWidget {
  final AffiliateStore store;
  const _SyncStatusChip({required this.store});

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    late final String label;
    late final Color color;
    switch (store.syncStatus) {
      case 'running':
        label = lang.affiliateSyncRunningShort;
        color = colorScheme.tertiary;
      case 'queued':
        label = lang.affiliateSyncQueuedShort;
        color = colorScheme.tertiary;
      case 'success':
        label = lang.affiliateSyncSuccessShort;
        color = colorScheme.primary;
      case 'error':
        label = lang.affiliateSyncFailedShort;
        color = colorScheme.error;
      case 'needs_review':
        label = lang.affiliateSyncNeedsReviewShort;
        color = colorScheme.tertiary;
      default:
        label = lang.affiliateSyncIdle;
        color = colorScheme.onSurfaceVariant;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final String label;
  final String value;
  const _Meta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.tertiary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _StoreDetailsSheet extends StatelessWidget {
  final AffiliateStore store;
  const _StoreDetailsSheet({required this.store});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final rows = <(String, String)>[
      (lang.affiliateFieldStoreName, store.name),
      ('Slug', store.slug),
      (lang.affiliateFieldWebsiteUrl, store.websiteUrl ?? '—'),
      (lang.affiliateFieldCountry, store.country ?? '—'),
      (lang.affiliateFieldCurrency, store.currency),
      (lang.affiliateFieldNetwork, store.affiliateNetwork ?? '—'),
      (lang.affiliateFieldProgramId, store.programId ?? '—'),
      (lang.affiliateFieldAffiliateId, store.affiliateId ?? '—'),
      (lang.affiliateFieldIntegrationType, store.integrationType.value),
      (lang.affiliateColProducts, '${store.productCount}'),
      (
        lang.affiliateColCommission,
        '${store.defaultCommissionRate} (${store.commissionType.value})'
      ),
      (lang.affiliateFieldSyncFrequency, store.syncFrequency.value),
      (
        lang.affiliateColLastSync,
        store.lastSyncAt != null
            ? formatRelativeTime(lang, store.lastSyncAt!)
            : lang.affiliateNeverSynced
      ),
      (
        lang.affiliateNextSync,
        store.nextSyncAt != null
            ? formatRelativeTime(lang, store.nextSyncAt!)
            : '—'
      ),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.affiliateDetailsTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final (k, v) in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 140,
                            child: Text(
                              k,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(v, style: theme.textTheme.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
