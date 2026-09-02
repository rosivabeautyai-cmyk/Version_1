import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:rosivia/core/styles/app_dimens.dart';
import 'package:rosivia/core/widgets/app_network_image.dart';
import 'package:rosivia/core/widgets/motion/favorite_button.dart';
import 'package:rosivia/core/widgets/motion/pressable_scale.dart';

import '../../data/models/product_model.dart';
import 'product_price_text.dart';

/// Editorial product card: image on a soft shadow, then BRAND (small
/// caps) → product name (up to two lines, reserved height so cards in a
/// row align) → price + rating. Consistent radii and typography with
/// the rest of the catalog.
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final double width;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.lg.r);

    return PressableScale(
      onTap: onTap,
      child: SizedBox(
        width: width.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: AppShadow.low(colorScheme.primary),
              ),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: AppNetworkImage(
                      url: product.imageUrl,
                      borderRadius: radius,
                    ),
                  ),
                  if (onFavoriteTap != null)
                    PositionedDirectional(
                      top: AppSpace.sm.h,
                      end: AppSpace.sm.w,
                      child: Container(
                        padding: EdgeInsets.all(AppSpace.xs.w),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          shape: BoxShape.circle,
                          boxShadow: AppShadow.low(colorScheme.shadow),
                        ),
                        child: FavoriteButton(
                          isFavorite: isFavorite,
                          onTap: onFavoriteTap,
                          size: 16.sp,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  if (product.isEditorsChoice)
                    PositionedDirectional(
                      start: AppSpace.sm.w,
                      top: AppSpace.sm.h,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpace.sm.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '★',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: AppSpace.md.h),
            if (product.brand != null && product.brand!.isNotEmpty) ...[
              Text(
                product.brand!.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpace.xxs.h),
            ],
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                height: 1.32,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpace.xs.h),
            // Exact price + rating on one line; the "≈ N XXX" estimate
            // (when a different currency is in effect) sits below it,
            // small and muted, so it's never mistaken for the checkout
            // amount.
            ProductPriceText(
              product: product,
              showApprox: true,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
              trailing: product.rating != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded,
                            size: 13.sp, color: Colors.amber),
                        SizedBox(width: 2.w),
                        Text(
                          product.rating!.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
