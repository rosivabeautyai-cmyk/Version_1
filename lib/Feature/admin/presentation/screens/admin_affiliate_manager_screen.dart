import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import 'package:rosivia/core/widgets/state_views.dart';

import '../../data/models/admin_product_query.dart';
import '../../data/repositories/admin_repository.dart';
import '../../provider/admin_config_provider.dart';
import '../../../products/data/models/product_model.dart';
import '../widgets/admin_product_tile.dart';
import 'admin_product_edit_screen.dart';

/// Affiliate / merchant health, per country. Reuses the existing admin
/// product read path + [AdminProductQuery]; tapping a product opens the
/// same editor (which has the Country Offers section) — no second
/// affiliate architecture.
class AdminAffiliateManagerScreen extends StatelessWidget {
  const AdminAffiliateManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminConfigProvider(),
      child: const _AffiliateView(),
    );
  }
}

class _AffiliateView extends StatefulWidget {
  const _AffiliateView();

  @override
  State<_AffiliateView> createState() => _AffiliateViewState();
}

class _AffiliateViewState extends State<_AffiliateView> {
  final _repo = AdminRepository();
  AdminProductQuery _query = const AdminProductQuery(missingAffiliate: true);
  List<ProductModel> _items = const [];
  String? _cursorId;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      if (refresh) {
        _loading = true;
        _cursorId = null;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final page = await _repo.fetchProductsAdmin(_query, afterId: _cursorId);
      setState(() {
        _items = refresh ? page.items : [..._items, ...page.items];
        _cursorId = page.cursorId;
        _hasMore = page.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _set(AdminProductQuery q) {
    setState(() => _query = q);
    _load(refresh: true);
  }

  Future<void> _open(ProductModel p) async {
    final cfg = context.read<AdminConfigProvider>();
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminProductEditScreen(
          productId: p.id,
          repository: _repo,
          currencies: cfg.currencies,
          countries: cfg.countries,
        ),
      ),
    );
    if (changed == true) _load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final countries =
        context.watch<AdminConfigProvider>().countries.map((c) => c.code).toList();

    return Scaffold(
      appBar: AppBar(title: Text(lang.adminAffiliateManager)),
      body: SafeArea(
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (_hasMore &&
                !_loadingMore &&
                n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
              _load();
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () => _load(refresh: true),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(lang.adminAffiliateManagerDesc,
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilterChip(
                      label: Text(lang.adminFilterMissingLink),
                      selected: _query.missingAffiliate,
                      onSelected: (v) =>
                          _set(_query.copyWith(missingAffiliate: v)),
                    ),
                    FilterChip(
                      label: Text(lang.adminFilterHasOffer),
                      selected: _query.hasCountryOffer,
                      onSelected: (v) =>
                          _set(_query.copyWith(hasCountryOffer: v)),
                    ),
                    if (countries.isNotEmpty)
                      DropdownButton<String?>(
                        value: _query.country,
                        hint: Text(lang.adminAnyCountry),
                        items: [
                          DropdownMenuItem(
                              value: null, child: Text(lang.adminAnyCountry)),
                          for (final c in countries)
                            DropdownMenuItem(value: c, child: Text(c)),
                        ],
                        onChanged: (v) => _set(v == null
                            ? _query.copyWith(clearCountry: true)
                            : _query.copyWith(country: v)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_items.isEmpty)
                  AppEmptyView(
                    icon: Icons.link_rounded,
                    title: lang.adminNothingToShow,
                    description: lang.adminAffiliateManagerDesc,
                  )
                else
                  for (var i = 0; i < _items.length; i++) ...[
                    AdminProductTile(
                      product: _items[i],
                      onTap: () => _open(_items[i]),
                    ),
                    if (i != _items.length - 1) const SizedBox(height: 10),
                  ],
                if (_loadingMore)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
