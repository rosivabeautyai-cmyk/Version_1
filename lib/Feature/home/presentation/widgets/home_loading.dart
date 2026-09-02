import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:rosivia/core/responsive/responsive.dart';
import 'package:rosivia/core/styles/app_dimens.dart';
import 'package:rosivia/core/widgets/motion/app_shimmer.dart';
import 'package:rosivia/core/widgets/state_views.dart';

/// A shimmering skeleton of the home layout — welcome card, greeting,
/// the AI entry, and a scrolling product row — shown on first paint
/// instead of a bare spinner.
class HomeLoading extends StatelessWidget {
  /// Set when rendered inside another scroll view (e.g. the home
  /// `ListView` while only the product sections are still loading).
  final bool shrinkWrap;

  const HomeLoading({super.key, this.shrinkWrap = false});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: PageContainer(
        child: ListView(
          shrinkWrap: shrinkWrap,
          physics: const NeverScrollableScrollPhysics(),
          padding: shrinkWrap ? EdgeInsets.zero : EdgeInsets.all(20.w),
          children: [
            AppSkeletonBox(
              height: 120.h,
              width: double.infinity,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            SizedBox(height: 24.h),
            AppSkeletonBox(
              height: 22.h,
              width: 180.w,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            SizedBox(height: 8.h),
            AppSkeletonBox(
              height: 14.h,
              width: 240.w,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            SizedBox(height: 20.h),
            AppSkeletonBox(
              height: 56.h,
              width: double.infinity,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            SizedBox(height: 28.h),
            AppSkeletonBox(
              height: 18.h,
              width: 140.w,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            SizedBox(height: 14.h),
            SizedBox(
              height: 220.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                separatorBuilder: (_, _) => SizedBox(width: 14.w),
                itemBuilder: (context, index) => SizedBox(
                  width: 150.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeletonBox(
                        height: 150.w,
                        width: 150.w,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
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
                        width: 70.w,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
