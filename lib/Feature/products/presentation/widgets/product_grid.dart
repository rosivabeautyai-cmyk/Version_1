import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/Feature/favorites/provider/favorites_provider.dart';
import 'package:rosivia/core/network/view_state.dart';
import 'package:rosivia/core/responsive/responsive.dart';
import 'package:rosivia/core/styles/app_dimens.dart';
import 'package:rosivia/core/widgets/motion/app_shimmer.dart';
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

  /// Extra trailing space inside the scroll view. Tab-hosted screens
  /// pass `HomeBottomNavBar.bottomInset(context)` so the last row of
  /// cards clears the floating glass nav.
  final double? bottomPadding;

  const ProductGrid({
    super.key,
    required this.state,
    required this.onProductTap,
    this.onLoadMore,
    this.onRetry,
    this.emptyTitle,
    this.emptyDescription,
    this.emptyIcon = Icons.spa_outlined,
    this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final favorites = context.watch<FavoritesProvider?>();

    if (state.isLoading) {
      return const _ProductGridSkeleton();
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
      // The single shimmer controller only runs while more pages are
      // streaming in.
      child: AppShimmer(
        enabled: state.isLoadingMore,
        child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = responsiveGridColumns(constraints.maxWidth);
          return GridView.builder(
            padding: EdgeInsets.only(bottom: bottomPadding ?? 24.h),
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 16.h,
              crossAxisSpacing: 16.w,
              // Wider cards (fewer columns / larger screens) need a
              // slightly taller ratio; on desktop the narrower 4–5 col
              // cards would otherwise leave dead space under each tile.
              childAspectRatio: columns >= 4 ? 0.68 : 0.56,
            ),
            itemCount: items.length + (state.isLoadingMore ? columns : 0),
            itemBuilder: (context, index) {
              if (index >= items.length) {
                return AppSkeletonBox(
                  height: double.infinity,
                  width: double.infinity,
                );
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
          );
        },
      ),
      ),
    );
  }
}

/// A shimmering skeleton that mirrors the real grid's layout while the
/// first page loads — a premium replacement for a bare spinner.
class _ProductGridSkeleton extends StatelessWidget {
  const _ProductGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = responsiveGridColumns(constraints.maxWidth);
          return GridView.builder(
            padding: EdgeInsets.only(bottom: 24.h),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 16.h,
              crossAxisSpacing: 16.w,
              childAspectRatio: columns >= 4 ? 0.68 : 0.56,
            ),
            itemCount: columns * 3,
            itemBuilder: (context, index) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: AppSkeletonBox(height: double.infinity),
                ),
                SizedBox(height: 8.h),
                AppSkeletonBox(
                  height: 12.h,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                SizedBox(height: 6.h),
                AppSkeletonBox(
                  height: 12.h,
                  width: 80.w,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
