import 'package:flutter/material.dart';

import 'package:rosivia/core/network/api_exception.dart';
import 'package:rosivia/core/network/view_state.dart';

import '../data/models/product_model.dart';
import '../data/models/product_query.dart';
import '../data/repositories/product_repository.dart';

/// Drives a single paginated product grid — used for both "browse a
/// category" and "all products" screens. Pass `category: null` to
/// list every product.
class ProductListProvider extends ChangeNotifier {
  final ProductRepository _repository;
  final String? category;

  ProductListProvider({
    this.category,
    ProductRepository? repository,
  }) : _repository = repository ?? ProductRepository();

  ViewState<List<ProductModel>> _state = const ViewState();
  ViewState<List<ProductModel>> get state => _state;

  String? _sort;
  String? get sort => _sort;

  int _page = 1;
  final List<ProductModel> _items = [];

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _items.clear();
    }

    _state = _state.copyWith(
      status: refresh || _items.isEmpty ? ViewStatus.loading : ViewStatus.loadingMore,
    );
    notifyListeners();

    try {
      final result = await _repository.getProducts(
        ProductQuery(category: category, sort: _sort, page: _page),
      );

      _items.addAll(result.items);
      _page++;

      _state = ViewState(
        status: _items.isEmpty ? ViewStatus.empty : ViewStatus.success,
        data: List.unmodifiable(_items),
        hasMore: result.hasMore,
      );
    } on ApiException catch (e) {
      _state = ViewState(
        status: ViewStatus.error,
        errorMessage: e.message,
        data: _items.isEmpty ? null : List.unmodifiable(_items),
      );
    } catch (_) {
      _state = ViewState(
        status: ViewStatus.error,
        errorMessage: 'Something went wrong. Please try again.',
        data: _items.isEmpty ? null : List.unmodifiable(_items),
      );
    }

    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_state.isLoadingMore || !_state.hasMore) return;
    await load();
  }

  void updateSort(String? sort) {
    _sort = sort;
    load(refresh: true);
  }
}
