import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/core/functions/navigations.dart';
import 'package:rosivia/core/responsive/responsive.dart';
import 'package:rosivia/core/widgets/motion/app_fade_in.dart';
import 'package:rosivia/core/widgets/motion/pressable_scale.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../../products/data/models/category_model.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../../products/presentation/screens/category_products_screen.dart';
import '../../../products/presentation/screens/product_details_screen.dart';
import '../../../products/presentation/screens/search_screen.dart';
import '../../../products/presentation/widgets/category_card.dart';
import '../../../products/presentation/widgets/product_grid.dart';
import '../../../products/provider/product_list_provider.dart';
import 'package:rosivia/Feature/settings/provider/regional_prefs_provider.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<CategoryModel> _categories = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    final categories = await ProductRepository().getCategories();

    if (!mounted) return;

    setState(() {
      _categories = categories;
      _loadingCategories = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return ChangeNotifierProvider(
      create: (context) => ProductListProvider(
        country: context.read<RegionalPrefsProvider>().countryCode,
      )..load(refresh: true),
      child: Scaffold(
        appBar: AppBar(
          title: Text(lang.explore, style: theme.textTheme.titleMedium),
        ),
        body: SafeArea(
          child: PageContainer(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Column(
                children: [
                  AppFadeIn(
                    child: _SearchBar(
                      onTap: () => pushTo(context, const SearchScreen()),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  if (!_loadingCategories && _categories.isNotEmpty) ...[
                    _CategoryRow(categories: _categories),
                    SizedBox(height: 16.h),
                  ],
                  _SortRow(),
                  SizedBox(height: 8.h),
                  Expanded(child: _ProductsSection()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = AppLocalizations.of(context)!;

    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: colorScheme.primary, size: 22.sp),
            SizedBox(width: 10.w),
            Text(lang.searchHint, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatefulWidget {
  final List<CategoryModel> categories;

  const _CategoryRow({required this.categories});

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  String? _selectedSlug;

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    return SizedBox(
      height: 40.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          CategoryChip(
            label: lang.allProducts,
            selected: _selectedSlug == null,
            onTap: () => setState(() => _selectedSlug = null),
          ),
          ...widget.categories.map(
            (category) => CategoryChip(
              label: category.name,
              selected: _selectedSlug == category.slug,
              onTap: () {
                setState(() => _selectedSlug = category.slug);
                pushTo(
                  context,
                  CategoryProductsScreen(
                    categorySlug: category.slug,
                    title: category.name,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SortRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final provider = context.watch<ProductListProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(lang.categories, style: Theme.of(context).textTheme.titleSmall),
        PopupMenuButton<String>(
          icon: const Icon(Icons.tune_rounded),
          tooltip: lang.sortBy,
          onSelected: provider.updateSort,
          itemBuilder: (context) => [
            PopupMenuItem(value: 'popular', child: Text(lang.trendingNow)),
            PopupMenuItem(
              value: 'price_asc',
              child: Text('${lang.sortBy}: \$ ↑'),
            ),
            PopupMenuItem(
              value: 'price_desc',
              child: Text('${lang.sortBy}: \$ ↓'),
            ),
            PopupMenuItem(value: 'newest', child: Text(lang.newDiscoveries)),
          ],
        ),
      ],
    );
  }
}

class _ProductsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductListProvider>();

    return RefreshIndicator(
      onRefresh: () => provider.load(refresh: true),
      child: ProductGrid(
        state: provider.state,
        onLoadMore: provider.loadMore,
        onRetry: () => provider.load(refresh: true),
        onProductTap: (ProductModel product) {
          pushTo(context, ProductDetailsScreen(productId: product.id));
        },
      ),
    );
  }
}
