import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:rosivia/core/functions/navigations.dart';
import 'package:rosivia/core/responsive/responsive.dart';
import 'package:rosivia/core/styles/app_dimens.dart';
import 'package:rosivia/core/widgets/motion/app_shimmer.dart';
import 'package:rosivia/core/widgets/state_views.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../../home/presentation/widgets/home_bottom_nav_bar.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/product_repository.dart';
import '../widgets/category_image_card.dart';
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

    // Just three categories — a vertical stack of large editorial image
    // cards (Net-a-Porter style) reads more premium than a cramped grid.
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: AppSpace.xs.h,
        bottom: HomeBottomNavBar.bottomInset(context),
      ),
      itemCount: _categories.length,
      separatorBuilder: (_, _) => SizedBox(height: AppSpace.lg.h),
      itemBuilder: (context, index) {
        final category = _categories[index];
        return CategoryImageCard(
          category: category,
          aspectRatio: 16 / 10,
          countLabel: category.productCount != null && category.productCount! > 0
              ? '${category.productCount} ${lang.navProducts}'
              : null,
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
