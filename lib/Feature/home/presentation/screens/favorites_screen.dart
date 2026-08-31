import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/core/functions/navigations.dart';
import 'package:rosivia/core/responsive/responsive.dart';
import 'package:rosivia/core/widgets/state_views.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../../favorites/provider/favorites_provider.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/screens/product_details_screen.dart';
import '../../../products/presentation/widgets/product_grid.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final favorites = context.watch<FavoritesProvider?>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.favorites, style: theme.textTheme.titleMedium),
      ),
      body: SafeArea(
        // Same horizontal/vertical padding every other product-grid
        // screen (Explore, CategoryProducts, Search) uses, so cards
        // never touch the screen edges and spacing stays consistent
        // across the app. PageContainer centres + caps the width on
        // desktop web; it is a no-op on mobile.
        child: PageContainer(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: favorites == null
                ? AppEmptyView(
                    icon: Icons.favorite_border_rounded,
                    title: lang.noFavoritesYetTitle,
                    description: lang.noFavoritesYetDesc,
                  )
                : RefreshIndicator(
                    onRefresh: favorites.refresh,
                    child: ProductGrid(
                      state: favorites.state,
                      emptyIcon: Icons.favorite_border_rounded,
                      emptyTitle: lang.noFavoritesYetTitle,
                      emptyDescription: lang.noFavoritesYetDesc,
                      onRetry: favorites.refresh,
                      onProductTap: (ProductModel product) {
                        pushTo(
                          context,
                          ProductDetailsScreen(productId: product.id),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
