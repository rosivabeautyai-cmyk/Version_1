import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import 'package:rosivia/core/widgets/state_views.dart';

import '../../data/models/admin_product_query.dart';
import '../../data/models/affiliate_store_model.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/affiliate_store_repository.dart';
import '../../provider/admin_config_provider.dart';
import '../../../products/data/models/product_model.dart';
import '../widgets/admin_product_tile.dart';
import 'admin_product_create_screen.dart';
import 'admin_product_edit_screen.dart';

/// The "Products" tab. Uses [AdminRepository.fetchProductsAdmin] — the
/// admin read path, which (unlike the shopper catalog) is NOT limited
/// to women-only / `isRosivaProduct` items, so an admin can see and
/// fix ineligible products too. Tapping a row opens the editor.
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _repo = AdminRepository();
  final _searchController = TextEditingController();

  AdminProductQuery _query = const AdminProductQuery();
  String? _cursorId;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasError = false;
  List<ProductModel> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(refresh: true));
    _searchController.addListener(() {
      final value = _searchController.text.trim();
      if (value == _query.search) return;
      setState(() => _query = _query.copyWith(search: value));
      _load(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      _cursorId = null;
      setState(() {
        _loading = true;
        _hasError = false;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final page = await _repo.fetchProductsAdmin(_query, afterId: _cursorId);
      if (!mounted) return;
      setState(() {
        _items = refresh ? page.items : [..._items, ...page.items];
        _hasMore = page.hasMore;
        _cursorId = page.cursorId;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = _items.isEmpty;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _updateQuery(AdminProductQuery next) {
    setState(() => _query = next);
    _load(refresh: true);
  }

  Future<void> _openEditor(ProductModel product) async {
    final cfg = context.read<AdminConfigProvider>();
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminProductEditScreen(
          productId: product.id,
          repository: _repo,
          currencies: cfg.currencies,
          countries: cfg.countries,
        ),
      ),
    );
    if (changed == true) _load(refresh: true);
  }

  Future<void> _openCreate() async {
    final cfg = context.read<AdminConfigProvider>();
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminProductCreateScreen(
          repository: _repo,
          currencies: cfg.currencies,
          countries: cfg.countries,
        ),
      ),
    );
    if (created == true) _load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (_hasMore &&
            !_loadingMore &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          _load();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
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
                          lang.navProducts,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _openCreate,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(lang.adminCreateProduct),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lang.adminProductsScreenSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: lang.adminSearchProductsHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: _searchController.clear,
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _CategoryTab(
                          label: lang.allProducts,
                          selected: _query.category == null,
                          onTap: () => _updateQuery(
                            _query.copyWith(clearCategory: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _CategoryTab(
                          label: lang.categorySkincare,
                          selected: _query.category == 'skincare',
                          onTap: () => _updateQuery(
                            _query.copyWith(category: 'skincare'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _CategoryTab(
                          label: lang.categoryMakeup,
                          selected: _query.category == 'makeup',
                          onTap: () =>
                              _updateQuery(_query.copyWith(category: 'makeup')),
                        ),
                        const SizedBox(width: 8),
                        _CategoryTab(
                          label: lang.categoryPerfume,
                          selected: _query.category == 'perfume',
                          onTap: () => _updateQuery(
                            _query.copyWith(category: 'perfume'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _Toggle(
                        label: lang.adminFilterFeatured,
                        value: _query.onlyFeatured,
                        onChanged: (v) => _updateQuery(
                          _query.copyWith(onlyFeatured: v),
                        ),
                      ),
                      _Toggle(
                        label: lang.adminFilterInactive,
                        value: _query.onlyInactive,
                        onChanged: (v) => _updateQuery(
                          _query.copyWith(onlyInactive: v),
                        ),
                      ),
                      _Toggle(
                        label: lang.adminFilterIneligible,
                        value: _query.onlyIneligible,
                        onChanged: (v) => _updateQuery(
                          _query.copyWith(onlyIneligible: v),
                        ),
                      ),
                      _Toggle(
                        label: lang.adminFilterMissingLink,
                        value: _query.missingAffiliate,
                        onChanged: (v) => _updateQuery(
                          _query.copyWith(missingAffiliate: v),
                        ),
                      ),
                      _Toggle(
                        label: lang.adminFilterMissingPrice,
                        value: _query.missingPrice,
                        onChanged: (v) => _updateQuery(
                          _query.copyWith(missingPrice: v),
                        ),
                      ),
                      _Toggle(
                        label: lang.adminFilterHasOffer,
                        value: _query.hasCountryOffer,
                        onChanged: (v) => _updateQuery(
                          _query.copyWith(hasCountryOffer: v),
                        ),
                      ),
                      _Toggle(
                        label: lang.adminFilterMissingOffer,
                        value: _query.missingCountryOffer,
                        onChanged: (v) => _updateQuery(
                          _query.copyWith(missingCountryOffer: v),
                        ),
                      ),
                      _Toggle(
                        label: lang.adminFilterInStock,
                        value: _query.inStockOnly,
                        onChanged: (v) => _updateQuery(
                          _query.copyWith(inStockOnly: v),
                        ),
                      ),
                      _Toggle(
                        label: lang.adminFilterOutOfStock,
                        value: _query.outOfStockOnly,
                        onChanged: (v) => _updateQuery(
                          _query.copyWith(outOfStockOnly: v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _CountryCurrencyFilters(
                    query: _query,
                    countries: context
                        .watch<AdminConfigProvider>()
                        .countries
                        .map((c) => c.code)
                        .toList(),
                    currencies: context
                        .watch<AdminConfigProvider>()
                        .currencies
                        .map((c) => c.code)
                        .toList(),
                    onChanged: _updateQuery,
                  ),
                  const SizedBox(height: 6),
                  _StoreFilter(query: _query, onChanged: _updateQuery),
                  const SizedBox(height: 16),
                  _buildBody(theme, lang),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations lang) {
    if (_loading) {
      return Column(
        children: [
          for (var i = 0; i < 4; i++) ...[
            const _ProductTileSkeleton(),
            if (i != 3) const SizedBox(height: 10),
          ],
        ],
      );
    }

    if (_hasError) {
      return AppErrorView(
        title: lang.somethingWentWrong,
        description: lang.somethingWentWrongDesc,
        retryLabel: lang.retry,
        onRetry: () => _load(refresh: true),
      );
    }

    if (_items.isEmpty) {
      return AppEmptyView(
        icon: Icons.inventory_2_outlined,
        title: lang.adminNoProductsTitle,
        description: lang.adminNoProductsDesc,
      );
    }

    return Column(
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          AdminProductTile(
            product: _items[i],
            onTap: () => _openEditor(_items[i]),
          ),
          if (i != _items.length - 1) const SizedBox(height: 10),
        ],
        if (_loadingMore) ...[
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ],
      ],
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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

class _CountryCurrencyFilters extends StatelessWidget {
  final AdminProductQuery query;
  final List<String> countries;
  final List<String> currencies;
  final ValueChanged<AdminProductQuery> onChanged;

  const _CountryCurrencyFilters({
    required this.query,
    required this.countries,
    required this.currencies,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    if (countries.isEmpty && currencies.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 10,
      children: [
        if (countries.isNotEmpty)
          DropdownButton<String?>(
            value: query.country,
            hint: Text(lang.adminAnyCountry),
            items: [
              DropdownMenuItem(value: null, child: Text(lang.adminAnyCountry)),
              for (final c in countries)
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => onChanged(v == null
                ? query.copyWith(clearCountry: true)
                : query.copyWith(country: v)),
          ),
        if (currencies.isNotEmpty)
          DropdownButton<String?>(
            value: query.currency,
            hint: Text(lang.adminAnyCurrency),
            items: [
              DropdownMenuItem(value: null, child: Text(lang.adminAnyCurrency)),
              for (final c in currencies)
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => onChanged(v == null
                ? query.copyWith(clearCurrency: true)
                : query.copyWith(currency: v)),
          ),
      ],
    );
  }
}

/// "Filter by Store" dropdown — lists the configured affiliate stores
/// plus an "Admin / legacy" pseudo option. Purely additive to the
/// existing admin product filters.
class _StoreFilter extends StatefulWidget {
  final AdminProductQuery query;
  final ValueChanged<AdminProductQuery> onChanged;

  const _StoreFilter({required this.query, required this.onChanged});

  @override
  State<_StoreFilter> createState() => _StoreFilterState();
}

class _StoreFilterState extends State<_StoreFilter> {
  final _repo = AffiliateStoreRepository();

  @override
  void dispose() {
    _repo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    return StreamBuilder<List<AffiliateStore>>(
      stream: _repo.watchStores(),
      builder: (context, snapshot) {
        final stores = snapshot.data ?? const <AffiliateStore>[];
        if (stores.isEmpty) return const SizedBox.shrink();
        return DropdownButton<String?>(
          value: widget.query.storeId,
          hint: Text(lang.affiliateStores),
          items: [
            DropdownMenuItem(value: null, child: Text(lang.allProducts)),
            for (final s in stores)
              DropdownMenuItem(value: s.id, child: Text(s.name)),
          ],
          onChanged: (v) => widget.onChanged(
            v == null
                ? widget.query.copyWith(clearStoreId: true)
                : widget.query.copyWith(storeId: v),
          ),
        );
      },
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      selectedColor: colorScheme.secondary.withValues(alpha: 0.16),
      showCheckmark: true,
      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
    );
  }
}

class _ProductTileSkeleton extends StatelessWidget {
  const _ProductTileSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const AppSkeletonBox(
            width: 56,
            height: 56,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppSkeletonBox(
                  width: 140,
                  height: 14,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                SizedBox(height: 8),
                AppSkeletonBox(
                  width: 90,
                  height: 12,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
