import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Favorites',
          style: theme.textTheme.titleMedium,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(20.w),
          children: [
            Text(
              'Favorites',
              style: theme.textTheme.headlineSmall,
            ),
            SizedBox(height: 8.h),
            Text(
              'Your favorite items will appear here.',
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 24.h),
            _FavoritesEmptyState(),
          ],
        ),
      ),
    );
  }
}

class _FavoritesEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 48.sp,
            color: colorScheme.primary,
          ),
          SizedBox(height: 16.h),
          Text(
            'No favorites yet',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: 8.h),
          Text(
            'Start adding your favorite items and they will appear here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}