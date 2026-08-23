import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/Feature/favorites/provider/favorites_provider.dart';
import 'package:rosivia/core/network/view_state.dart';
import 'package:rosivia/core/widgets/state_views.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../data/models/product_model.dart';
import 'product_card.dart';

/// A two-column product grid driven by a [ViewState], with optional
/// infinite scroll via [onLoadMore]. Handles loading / empty / error
/// rendering itself so every listing screen stays tiny.
class ProductGrid extends StatelessWidget {
  final ViewState<List<ProductModel>> state;
  final void Function(ProductModel product) onProductTap;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRetry;
  final String? emptyTitle;
  final String? emptyDescription;
  final IconData emptyIcon;

  const ProductGrid({
    super.key,
    required this.state,
    required this.onProductTap,
    this.onLoadMore,
    this.onRetry,
    this.emptyTitle,
    this.emptyDescription,
    this.emptyIcon = Icons.spa_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final favorites = context.watch<FavoritesProvider?>();

    if (state.isLoading) {
      return AppLoadingView(message: lang.loadingProducts);
    }

    if (state.isError && (state.data == null || state.data!.isEmpty)) {
      return AppErrorView(
        title: lang.somethingWentWrong,
        description: state.errorMessage ?? lang.somethingWentWrongDesc,
        retryLabel: lang.retry,
        onRetry: onRetry,
      );
    }

    final items = state.data ?? const [];

    if (items.isEmpty) {
      return AppEmptyView(
        icon: emptyIcon,
        title: emptyTitle ?? lang.noProductsYet,
        description: emptyDescription ?? lang.noProductsYetDesc,
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (onLoadMore != null &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          onLoadMore!();
        }
        return false;
      },
      child: GridView.builder(
        padding: EdgeInsets.only(bottom: 24.h),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16.h,
          crossAxisSpacing: 16.w,
          childAspectRatio: 0.62,
        ),
        itemCount: items.length + (state.isLoadingMore ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return AppSkeletonBox(height: double.infinity, width: double.infinity);
          }

          final product = items[index];

          return ProductCard(
            product: product,
            width: double.infinity,
            isFavorite: favorites?.isFavorite(product.id) ?? false,
            onTap: () => onProductTap(product),
            onFavoriteTap: favorites == null
                ? null
                : () => favorites.toggle(product.id),
          );
        },
      ),
    );
  }
}
