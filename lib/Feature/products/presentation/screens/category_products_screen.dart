import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/core/functions/navigations.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../data/models/product_model.dart';
import '../../provider/product_list_provider.dart';
import 'package:rosivia/Feature/settings/provider/regional_prefs_provider.dart';
import '../widgets/product_grid.dart';
import 'product_details_screen.dart';

class CategoryProductsScreen extends StatelessWidget {
  final String? categorySlug;
  final String title;

  const CategoryProductsScreen({
    super.key,
    required this.categorySlug,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProductListProvider(
        category: categorySlug,
        country: context.read<RegionalPrefsProvider>().countryCode,
      )..load(refresh: true),
      child: _CategoryProductsView(title: title),
    );
  }
}

class _CategoryProductsView extends StatelessWidget {
  final String title;

  const _CategoryProductsView({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final provider = context.watch<ProductListProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: theme.textTheme.titleMedium),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune_rounded),
            tooltip: lang.sortBy,
            onSelected: provider.updateSort,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'popular', child: Text(lang.trendingNow)),
              PopupMenuItem(value: 'price_asc', child: Text('${lang.sortBy}: \$ ↑')),
              PopupMenuItem(value: 'price_desc', child: Text('${lang.sortBy}: \$ ↓')),
              PopupMenuItem(value: 'newest', child: Text(lang.newDiscoveries)),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: RefreshIndicator(
            onRefresh: () => provider.load(refresh: true),
            child: ProductGrid(
              state: provider.state,
              onLoadMore: provider.loadMore,
              onRetry: () => provider.load(refresh: true),
              onProductTap: (ProductModel product) {
                pushTo(context, ProductDetailsScreen(productId: product.id));
              },
            ),
          ),
        ),
      ),
    );
  }
}
