import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/core/functions/navigations.dart';
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
        child: favorites == null
            ? AppEmptyView(
                icon: Icons.favorite_border_rounded,
                title: lang.noFavoritesYetTitle,
                description: lang.noFavoritesYetDesc,
              )
            : ProductGrid(
                state: favorites.state,
                emptyIcon: Icons.favorite_border_rounded,
                emptyTitle: lang.noFavoritesYetTitle,
                emptyDescription: lang.noFavoritesYetDesc,
                onRetry: () {},
                onProductTap: (ProductModel product) {
                  pushTo(context, ProductDetailsScreen(productId: product.id));
                },
              ),
      ),
    );
  }
}
