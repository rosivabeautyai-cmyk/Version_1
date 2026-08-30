import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/core/functions/navigations.dart';
import 'package:rosivia/core/network/view_state.dart';
import 'package:rosivia/core/widgets/state_views.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../data/models/product_model.dart';
import '../../provider/search_provider.dart';
import 'package:rosivia/Feature/settings/provider/regional_prefs_provider.dart';
import '../widgets/product_grid.dart';
import 'product_details_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SearchProvider(
        country: context.read<RegionalPrefsProvider>().countryCode,
      ),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatelessWidget {
  const _SearchView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final provider = context.watch<SearchProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.search, style: theme.textTheme.titleMedium),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Column(
            children: [
              TextField(
                controller: provider.controller,
                onChanged: provider.onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: lang.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: provider.query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: provider.clear,
                        ),
                ),
              ),
              SizedBox(height: 16.h),
              Expanded(child: _buildBody(context, provider, lang)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SearchProvider provider,
    AppLocalizations lang,
  ) {
    if (provider.query.isEmpty && provider.state.status == ViewStatus.initial) {
      return AppEmptyView(
        icon: Icons.search_rounded,
        title: lang.startSearching,
        description: lang.startSearchingDesc,
      );
    }

    return ProductGrid(
      state: provider.state,
      onRetry: () => provider.onChanged(provider.query),
      emptyIcon: Icons.search_off_rounded,
      emptyTitle: lang.noResultsFound,
      emptyDescription: lang.noResultsFoundDesc,
      onProductTap: (ProductModel product) {
        pushTo(context, ProductDetailsScreen(productId: product.id));
      },
    );
  }
}
