import 'package:flutter/material.dart';

import 'package:rosivia/core/network/api_exception.dart';
import 'package:rosivia/core/network/view_state.dart';

import '../data/models/category_model.dart';
import '../data/models/product_model.dart';
import '../data/models/product_query.dart';
import '../data/repositories/product_repository.dart';

/// Bundled data shown on the Home screen: categories, a curated
/// essentials row, and a trending-now grid.
class HomeProductsData {
  final List<CategoryModel> categories;
  final List<ProductModel> curated;
  final List<ProductModel> trending;

  const HomeProductsData({
    required this.categories,
    required this.curated,
    required this.trending,
  });

  bool get isEmpty => categories.isEmpty && curated.isEmpty && trending.isEmpty;
}

class HomeProductsProvider extends ChangeNotifier {
  final ProductRepository _repository;

  HomeProductsProvider({ProductRepository? repository})
      : _repository = repository ?? ProductRepository();

  ViewState<HomeProductsData> _state = const ViewState();
  ViewState<HomeProductsData> get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(status: ViewStatus.loading);
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getCategories(),
        _repository.getProducts(
          const ProductQuery(sort: 'curated', limit: 10),
        ),
        _repository.getProducts(
          const ProductQuery(sort: 'trending', limit: 10),
        ),
      ]);

      final categories = results[0] as List<CategoryModel>;
      final curated = (results[1] as ProductPage<ProductModel>).items;
      final trending = (results[2] as ProductPage<ProductModel>).items;

      final data = HomeProductsData(
        categories: categories,
        curated: curated,
        trending: trending,
      );

      _state = ViewState(
        status: data.isEmpty ? ViewStatus.empty : ViewStatus.success,
        data: data,
      );
    } on ApiException catch (e) {
      _state = ViewState(status: ViewStatus.error, errorMessage: e.message);
    } catch (_) {
      _state = const ViewState(
        status: ViewStatus.error,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }

    notifyListeners();
  }
}
