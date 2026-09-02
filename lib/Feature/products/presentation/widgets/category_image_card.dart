import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:rosivia/core/constants/app_images.dart';
import 'package:rosivia/core/styles/app_dimens.dart';
import 'package:rosivia/core/widgets/app_asset_image.dart';
import 'package:rosivia/core/widgets/motion/pressable_scale.dart';

import '../../data/models/category_model.dart';

/// A full image category card: the model photo IS the card. The name
/// sits over a bottom gradient scrim so it stays readable, on the
/// calmer lower part of the portrait; `Alignment.topCenter` keeps faces
/// from being cropped. RTL-safe (label uses directional alignment, the
/// scrim is vertical).
class CategoryImageCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  /// Optional line under the name (e.g. "378 Products"). Home passes
  /// null for a cleaner row; the Categories screen passes a count.
  final String? countLabel;

  /// null → fill the parent (stacked layout on the Categories screen).
  final double? width;
  final double? height;
  final double aspectRatio;

  const CategoryImageCard({
    super.key,
    required this.category,
    required this.onTap,
    this.countLabel,
    this.width,
    this.height,
    this.aspectRatio = 3 / 4,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.xl.r);

    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppShadow.medium(theme.colorScheme.primary),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppAssetImage(
              assetPath: AppImages.categoryImage(category.slug),
              alignment: Alignment.topCenter,
            ),
            // Bottom-anchored scrim so the label is always legible over
            // whatever the photo does down there.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0x11000000),
                    Color(0x8A000000),
                  ],
                  stops: [0.45, 0.68, 1],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpace.lg.w),
              child: Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        height: 1.1,
                      ),
                    ),
                    if (countLabel != null && countLabel!.isNotEmpty) ...[
                      SizedBox(height: AppSpace.xxs.h),
                      Text(
                        countLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (width != null || height != null) {
      card = SizedBox(width: width, height: height, child: card);
    } else {
      card = AspectRatio(aspectRatio: aspectRatio, child: card);
    }

    return PressableScale(onTap: onTap, child: card);
  }
}
