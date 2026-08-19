import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Explore',
          style: theme.textTheme.titleMedium,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(20.w),
          children: [
            Text(
              'Explore',
              style: theme.textTheme.headlineSmall,
            ),
            SizedBox(height: 8.h),
            Text(
              'Discover everything ROSIVA has to offer.',
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 24.h),
            _ExplorePlaceholder(),
          ],
        ),
      ),
    );
  }
}

class _ExplorePlaceholder extends StatelessWidget {
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
            Icons.explore_rounded,
            size: 48.sp,
            color: colorScheme.primary,
          ),
          SizedBox(height: 16.h),
          Text(
            'Explore coming soon',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: 8.h),
          Text(
            'The explore section will be added here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}