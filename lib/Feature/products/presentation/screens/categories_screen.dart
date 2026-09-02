import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:rosivia/core/functions/navigations.dart';
import 'package:rosivia/core/responsive/responsive.dart';
import 'package:rosivia/core/styles/app_dimens.dart';
import 'package:rosivia/core/widgets/motion/app_shimmer.dart';
import 'package:rosivia/core/widgets/motion/pressable_scale.dart';
import 'package:rosivia/core/widgets/state_views.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../data/models/category_model.dart';
import '../../data/repositories/product_repository.dart';
import 'category_products_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _repository = ProductRepository();

  bool _loading = true;
  bool _hasError = false;
  List<CategoryModel> _categories = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final categories = await _repository.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.categories, style: theme.textTheme.titleMedium),
      ),
      body: SafeArea(
        child: PageContainer(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(context, lang),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations lang) {
    if (_loading) {
      return const _CategoriesSkeleton();
    }

    if (_hasError) {
      return AppErrorView(
        title: lang.somethingWentWrong,
        description: lang.somethingWentWrongDesc,
        retryLabel: lang.retry,
        onRetry: _load,
      );
    }

    if (_categories.isEmpty) {
      return AppEmptyView(
        icon: Icons.category_outlined,
        title: lang.noProductsYet,
        description: lang.noProductsYetDesc,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = responsiveGridColumns(
          constraints.maxWidth,
          min: 2,
          max: 4,
        );
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 16.h,
            crossAxisSpacing: 16.w,
            childAspectRatio: 1.1,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return _CategoryTile(
              category: category,
              onTap: () => pushTo(
                context,
                CategoryProductsScreen(
                  categorySlug: category.slug,
                  title: category.name,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = AppLocalizations.of(context)!;

    return PressableScale(
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    Icons.spa_rounded,
                    color: colorScheme.primary,
                    size: 22.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                if (category.productCount != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    // This is a product count, not a category count — reuse
                    // the existing bare "Products"/"المنتجات" nav label
                    // rather than the "Categories" string (a real bug: the
                    // tile was showing e.g. "378 Categories" instead of
                    // "378 Products").
                    '${category.productCount} ${lang.navProducts}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shimmering placeholder grid for the categories screen's first load.
class _CategoriesSkeleton extends StatelessWidget {
  const _CategoriesSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = responsiveGridColumns(
            constraints.maxWidth,
            min: 2,
            max: 4,
          );
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 16.h,
              crossAxisSpacing: 16.w,
              childAspectRatio: 1.1,
            ),
            itemCount: columns * 3,
            itemBuilder: (context, index) => AppSkeletonBox(
              height: double.infinity,
              width: double.infinity,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          );
        },
      ),
    );
  }
}
