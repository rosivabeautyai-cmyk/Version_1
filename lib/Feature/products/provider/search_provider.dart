import 'dart:async';

import 'package:flutter/material.dart';

import 'package:rosivia/core/network/api_exception.dart';
import 'package:rosivia/core/network/view_state.dart';

import '../data/models/product_model.dart';
import '../data/models/product_query.dart';
import '../data/models/search_term_normalizer.dart';
import '../data/repositories/product_repository.dart';

class SearchProvider extends ChangeNotifier {
  final ProductRepository _repository;

  /// Shopper's selected country — applies country-availability
  /// visibility to search results.
  final String? country;

  SearchProvider({this.country, ProductRepository? repository})
      : _repository = repository ?? ProductRepository();

  final TextEditingController controller = TextEditingController();

  Timer? _debounce;

  ViewState<List<ProductModel>> _state = const ViewState();
  ViewState<List<ProductModel>> get state => _state;

  String get query => controller.text.trim();

  void onChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      _state = const ViewState();
      notifyListeners();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 450), () => _search(value.trim()));
  }

  void clear() {
    controller.clear();
    _debounce?.cancel();
    _state = const ViewState();
    notifyListeners();
  }

  Future<void> _search(String term) async {
    _state = _state.copyWith(status: ViewStatus.loading);
    notifyListeners();

    try {
      final result = await _repository.getProducts(
        ProductQuery(
          searchTerm: normalizeSearchTerm(term),
          limit: 30,
          country: country,
        ),
      );

      _state = ViewState(
        status: result.items.isEmpty ? ViewStatus.empty : ViewStatus.success,
        data: result.items,
      );
    } on ApiException catch (_) {
      _state = const ViewState(status: ViewStatus.error);
    } catch (_) {
      _state = const ViewState(
        status: ViewStatus.error,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    controller.dispose();
    super.dispose();
  }
}
