import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:rosivia/core/widgets/app_network_image.dart';

import '../../data/models/product_model.dart';
import 'product_price_text.dart';

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

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: AppNetworkImage(
                    url: product.imageUrl,
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                ),
                if (onFavoriteTap != null)
                  Positioned(
                    top: 6.h,
                    right: 6.w,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16.sp,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                if (product.isEditorsChoice)
                  Positioned(
                    left: 6.w,
                    top: 6.h,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '★',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            if (product.brand != null) ...[
              SizedBox(height: 2.h),
              Text(
                product.brand!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
            SizedBox(height: 4.h),
            Row(
              children: [
                ProductPriceText(
                  product: product,
                  showApprox: false,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: colorScheme.primary),
                ),
                const Spacer(),
                if (product.rating != null) ...[
                  Icon(Icons.star_rounded, size: 14.sp, color: Colors.amber),
                  SizedBox(width: 2.w),
                  Text(
                    product.rating!.toStringAsFixed(1),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
