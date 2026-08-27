import 'package:flutter/material.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import 'package:rosivia/core/network/api_exception.dart';
import 'package:rosivia/core/widgets/state_views.dart';

import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_query.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../widgets/admin_product_tile.dart';

/// The "Products" tab — reuses the existing [ProductRepository] /
/// [ProductQuery] / [ProductModel] exactly as-is (no API changes),
/// with its own lightweight local pagination state (the same pattern
/// already used elsewhere in this app, e.g. the Categories screen).
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _repository = ProductRepository();
  final _searchController = TextEditingController();

  String? _category;
  String _searchTerm = '';
  int _page = 1;
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
      if (value == _searchTerm) return;
      _searchTerm = value;
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
      _page = 1;
      setState(() {
        _loading = true;
        _hasError = false;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final page = await _repository.getProducts(
        ProductQuery(
          category: _category,
          searchTerm: _searchTerm.isEmpty ? null : _searchTerm,
          page: _page,
          limit: 20,
        ),
      );

      if (!mounted) return;
      setState(() {
        _items = refresh ? page.items : [..._items, ...page.items];
        _hasMore = page.hasMore;
        _page++;
        _loading = false;
        _loadingMore = false;
      });
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = _items.isEmpty;
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

  void _selectCategory(String? category) {
    if (category == _category) return;
    setState(() => _category = category);
    _load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (_hasMore &&
            !_loadingMore &&
            notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
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
                  Text(
                    lang.navProducts,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
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
                          selected: _category == null,
                          onTap: () => _selectCategory(null),
                        ),
                        const SizedBox(width: 8),
                        _CategoryTab(
                          label: lang.categorySkincare,
                          selected: _category == 'skincare',
                          onTap: () => _selectCategory('skincare'),
                        ),
                        const SizedBox(width: 8),
                        _CategoryTab(
                          label: lang.categoryMakeup,
                          selected: _category == 'makeup',
                          onTap: () => _selectCategory('makeup'),
                        ),
                        const SizedBox(width: 8),
                        _CategoryTab(
                          label: lang.categoryPerfume,
                          selected: _category == 'perfume',
                          onTap: () => _selectCategory('perfume'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
          AdminProductTile(product: _items[i]),
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

  const _CategoryTab({required this.label, required this.selected, required this.onTap});

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

class _ProductTileSkeleton extends StatelessWidget {
  const _ProductTileSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const AppSkeletonBox(width: 56, height: 56, borderRadius: BorderRadius.all(Radius.circular(10))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSkeletonBox(width: 140, height: 14, borderRadius: BorderRadius.all(Radius.circular(4))),
                const SizedBox(height: 8),
                const AppSkeletonBox(width: 90, height: 12, borderRadius: BorderRadius.all(Radius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
