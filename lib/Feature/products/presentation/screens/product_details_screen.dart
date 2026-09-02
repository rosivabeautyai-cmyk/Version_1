import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:rosivia/Feature/favorites/provider/favorites_provider.dart';
import 'package:rosivia/core/network/view_state.dart';
import 'package:rosivia/core/responsive/responsive.dart';
import 'package:rosivia/core/styles/app_dimens.dart';
import 'package:rosivia/core/services/snackbar_service.dart';
import 'package:rosivia/core/widgets/app_network_image.dart';
import 'package:rosivia/core/widgets/motion/favorite_button.dart';
import 'package:rosivia/core/widgets/state_views.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import 'package:rosivia/Feature/settings/provider/regional_prefs_provider.dart';

import '../../data/models/product_model.dart';
import '../../provider/product_details_provider.dart';
import '../widgets/product_price_text.dart';

class ProductDetailsScreen extends StatelessWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductDetailsProvider(productId: productId)..load(),
      child: const _ProductDetailsView(),
    );
  }
}

class _ProductDetailsView extends StatelessWidget {
  const _ProductDetailsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final provider = context.watch<ProductDetailsProvider>();
    final favorites = context.watch<FavoritesProvider?>();
    final state = provider.state;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.productDetails, style: theme.textTheme.titleMedium),
        actions: [
          if (state.data != null) ...[
            IconButton(
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: () => _shareProduct(state.data!),
            ),
            SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: FavoriteButton(
                  isFavorite: favorites?.isFavorite(state.data!.id) ?? false,
                  onTap: favorites == null
                      ? null
                      : () => favorites.toggle(state.data!.id),
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
      body: SafeArea(child: _buildBody(context, state, lang)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ViewState<ProductModel> state,
    AppLocalizations lang,
  ) {
    if (state.isLoading || state.status == ViewStatus.initial) {
      return AppLoadingView(message: lang.loadingProducts);
    }

    if (state.isError || state.data == null) {
      return AppErrorView(
        title: lang.somethingWentWrong,
        description: state.errorMessage ?? lang.somethingWentWrongDesc,
        retryLabel: lang.retry,
        onRetry: () => context.read<ProductDetailsProvider>().load(),
      );
    }

    return _ProductDetailsContent(product: state.data!);
  }

  void _shareProduct(ProductModel product) {
    final parts = [
      if (product.brand != null && product.brand!.isNotEmpty)
        '${product.brand} ${product.name}'
      else
        product.name,
      if (product.storeUrl != null && product.storeUrl!.isNotEmpty)
        product.storeUrl!,
    ];
    SharePlus.instance.share(ShareParams(text: parts.join('\n')));
  }
}

class _ProductDetailsContent extends StatelessWidget {
  final ProductModel product;

  const _ProductDetailsContent({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = AppLocalizations.of(context)!;

    final imageBlock = Stack(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: AppNetworkImage(
            url: product.imageUrl,
            borderRadius: BorderRadius.circular(24.r),
          ),
        ),
        if (product.isEditorsChoice)
          Positioned(
            left: 12.w,
            top: 12.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                lang.editorsChoice,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );

    final infoChildren = <Widget>[
      if (product.brand != null)
        Text(product.brand!, style: theme.textTheme.bodyMedium),
      SizedBox(height: 4.h),
      Text(product.name, style: theme.textTheme.headlineSmall),
      SizedBox(height: 10.h),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ProductPriceText(
              product: product,
              showCaption: true,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
          if (product.rating != null) ...[
            SizedBox(width: 8.w),
            const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
            SizedBox(width: 4.w),
            Text(
              '${product.rating!.toStringAsFixed(1)}'
              '${product.reviewCount != null ? ' (${product.reviewCount})' : ''}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
      if (product.whyRecommended != null) ...[
        SizedBox(height: 18.h),
        _InfoCard(
          icon: Icons.auto_awesome_rounded,
          title: lang.whyRosivaRecommends,
          body: product.whyRecommended!,
        ),
      ],
      if (product.ingredients.isNotEmpty) ...[
        SizedBox(height: 18.h),
        _ExpandableSection(
          title: lang.ingredients,
          initiallyExpanded: true,
          child: Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: product.ingredients
                .map(
                  (tag) => Chip(
                    label: Text(tag),
                    backgroundColor: colorScheme.primary.withValues(
                      alpha: 0.08,
                    ),
                    side: BorderSide.none,
                  ),
                )
                .toList(),
          ),
        ),
      ],
      if (product.benefits != null) ...[
        SizedBox(height: 10.h),
        _ExpandableSection(
          title: lang.benefits,
          child: Text(product.benefits!, style: theme.textTheme.bodyMedium),
        ),
      ],
      if (product.howToUse != null) ...[
        SizedBox(height: 10.h),
        _ExpandableSection(
          title: lang.howToUse,
          child: Text(product.howToUse!, style: theme.textTheme.bodyMedium),
        ),
      ],
      SizedBox(height: 20.h),
      _DisclaimerBanner(text: lang.priceAvailabilityDisclaimer),
      SizedBox(height: 10.h),
      _DisclaimerBanner(text: lang.patchTestDisclaimer, isWarning: true),
      SizedBox(height: 24.h),
      Builder(
        builder: (context) {
          final regional = context.watch<RegionalPrefsProvider?>();
          // Country-specific affiliate URL when configured, else the
          // product's default store link. Never fabricated.
          final buyUrl = product.offerFor(regional?.countryCode).storeUrl;
          final canBuy = buyUrl != null && buyUrl.isNotEmpty;
          return SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton.icon(
              onPressed: canBuy ? () => _openStore(context, buyUrl) : null,
              icon: Icon(Icons.shopping_bag_outlined, size: 18.sp),
              label: Text(
                lang.openStore,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md.r),
                ),
              ).copyWith(
                shadowColor: WidgetStatePropertyAll(
                  colorScheme.primary.withValues(alpha: 0.35),
                ),
                elevation: const WidgetStatePropertyAll(6),
              ),
            ),
          );
        },
      ),
      SizedBox(height: 12.h),
    ];

    // Desktop / wide tablet: image on the left, details on the right —
    // capped and centred. Mobile keeps the single stacked scroll view.
    if (context.screenWidth >= 900) {
      return PageContainer(
        maxWidth: 1100,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 20.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: imageBlock),
              SizedBox(width: 32.w),
              Expanded(
                flex: 6,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: infoChildren,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(20.w),
      children: [
        imageBlock,
        SizedBox(height: 18.h),
        ...infoChildren,
      ],
    );
  }

  Future<void> _openStore(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      SnackbarService.error(
        context,
        AppLocalizations.of(context)!.somethingWentWrong,
      );
    }
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const _ExpandableSection({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.only(bottom: 12.h),
        initiallyExpanded: initiallyExpanded,
        title: Text(title, style: theme.textTheme.titleSmall),
        children: [Align(alignment: Alignment.centerLeft, child: child)],
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  final String text;
  final bool isWarning;

  const _DisclaimerBanner({required this.text, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isWarning
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning
                ? Icons.warning_amber_rounded
                : Icons.info_outline_rounded,
            size: 16.sp,
            color: color,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
