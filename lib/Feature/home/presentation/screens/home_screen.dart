import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/core/functions/navigations.dart';
import 'package:rosivia/core/responsive/responsive.dart';
import 'package:rosivia/core/widgets/main_button.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../../ai/presentation/screens/ai_screen.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../favorites/provider/favorites_provider.dart';
import '../../../products/data/models/category_model.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/screens/category_products_screen.dart';
import '../../../products/presentation/screens/product_details_screen.dart';
import '../../../products/presentation/widgets/category_card.dart';
import '../../../products/presentation/widgets/product_card.dart';
import '../../../products/provider/home_products_provider.dart';
import 'package:rosivia/Feature/settings/provider/regional_prefs_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_loading.dart';
import '../widgets/home_section_title.dart';
import '../widgets/welcome_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _userData;
  bool _loading = true;

  late final HomeProductsProvider _productsProvider;

  @override
  void initState() {
    super.initState();
    _productsProvider = HomeProductsProvider(
      country: context.read<RegionalPrefsProvider>().countryCode,
    )..load();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUser();
    });
  }

  @override
  void dispose() {
    _productsProvider.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final auth = context.read<AuthProvider>();

    final data = await auth.fetchUserData();

    if (!mounted) return;

    setState(() {
      _userData = data;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    await Future.wait([_loadUser(), _productsProvider.load()]);
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    return ChangeNotifierProvider.value(
      value: _productsProvider,
      child: Scaffold(
        appBar: HomeAppBar(
          title: lang.appName,
          onLogout: () {
            context.read<AuthProvider>().logout();
          },
          onNotificationsTap: () => pushTo(context, const SettingsScreen()),
        ),
        body: SafeArea(
          child: _loading
              ? const HomeLoading()
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: Consumer<HomeProductsProvider>(
                    builder: (context, productsProvider, _) {
                      return PageContainer(
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(20.w),
                          children: [
                            WelcomeCard(userData: _userData),
                            SizedBox(height: 24.h),
                            _Greeting(lang: lang),
                            SizedBox(height: 20.h),
                            _AiSearchEntry(
                              onTap: () => pushTo(context, const AiScreen()),
                            ),
                            SizedBox(height: 28.h),
                            ..._buildProductSections(
                              context,
                              lang,
                              productsProvider,
                            ),
                            _AffiliateDisclosure(
                              text: lang.affiliateDisclosureShort,
                            ),
                            SizedBox(height: 24.h),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  List<Widget> _buildProductSections(
    BuildContext context,
    AppLocalizations lang,
    HomeProductsProvider provider,
  ) {
    final data = provider.state.data;

    if (data == null) {
      if (provider.state.isLoading) {
        return [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            child: const HomeLoading(),
          ),
        ];
      }
      if (provider.state.isError) {
        return [
          _InlineRetry(
            message: provider.state.errorMessage ?? lang.somethingWentWrongDesc,
            retryLabel: lang.retry,
            onRetry: provider.load,
          ),
        ];
      }
      return const [];
    }

    return [
      if (data.categories.isNotEmpty) ...[
        HomeSectionTitle(title: lang.categories),
        SizedBox(height: 12.h),
        _CategoriesRow(categories: data.categories),
        SizedBox(height: 28.h),
      ],
      if (data.curated.isNotEmpty) ...[
        HomeSectionTitle(title: lang.curatedEssentials),
        SizedBox(height: 12.h),
        _ProductsRow(products: data.curated),
        SizedBox(height: 28.h),
      ],
      if (data.trending.isNotEmpty) ...[
        HomeSectionTitle(title: lang.trendingNow),
        SizedBox(height: 12.h),
        _ProductsGrid(products: data.trending),
        SizedBox(height: 28.h),
      ],
    ];
  }
}

class _Greeting extends StatelessWidget {
  final AppLocalizations lang;

  const _Greeting({required this.lang});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.helloBeautiful,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4.h),
        Text(lang.elevateYourRitual, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _AiSearchEntry extends StatelessWidget {
  final VoidCallback onTap;

  const _AiSearchEntry({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = AppLocalizations.of(context)!;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colorScheme.primary,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  lang.askRosivaAnything,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriesRow extends StatelessWidget {
  final List<CategoryModel> categories;

  const _CategoriesRow({required this.categories});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryChip(
            label: category.name,
            selected: false,
            onTap: () => pushTo(
              context,
              CategoryProductsScreen(
                categorySlug: category.slug,
                title: category.name,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductsRow extends StatelessWidget {
  final List<ProductModel> products;

  const _ProductsRow({required this.products});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider?>();

    return SizedBox(
      height: 250.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, _) => SizedBox(width: 14.w),
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            width: 150,
            isFavorite: favorites?.isFavorite(product.id) ?? false,
            onFavoriteTap: favorites == null
                ? null
                : () => favorites.toggle(product.id),
            onTap: () =>
                pushTo(context, ProductDetailsScreen(productId: product.id)),
          );
        },
      ),
    );
  }
}

class _ProductsGrid extends StatelessWidget {
  final List<ProductModel> products;

  const _ProductsGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider?>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = responsiveGridColumns(constraints.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 16.h,
            crossAxisSpacing: 16.w,
            childAspectRatio: columns >= 4 ? 0.72 : 0.62,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              product: product,
              width: double.infinity,
              isFavorite: favorites?.isFavorite(product.id) ?? false,
              onFavoriteTap: favorites == null
                  ? null
                  : () => favorites.toggle(product.id),
              onTap: () =>
                  pushTo(context, ProductDetailsScreen(productId: product.id)),
            );
          },
        );
      },
    );
  }
}

class _InlineRetry extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _InlineRetry({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: 12.h),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}

class _AffiliateDisclosure extends StatelessWidget {
  final String text;

  const _AffiliateDisclosure({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Optional standalone logout button.
///
/// يمكن استخدامه في أي مكان آخر داخل التطبيق إذا احتجنا
/// زر Logout بنفس Theme التطبيق.
class HomeSignOutButton extends StatelessWidget {
  const HomeSignOutButton({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final lang = AppLocalizations.of(context)!;

    return MainButton(text: lang.logOut, onpress: () => auth.logout());
  }
}
