import 'package:flutter/material.dart';

import 'package:rosivia/core/network/api_exception.dart';
import 'package:rosivia/core/network/view_state.dart';

import '../data/models/product_model.dart';
import '../data/repositories/product_repository.dart';

class ProductDetailsProvider extends ChangeNotifier {
  final ProductRepository _repository;
  final String productId;

  ProductDetailsProvider({
    required this.productId,
    ProductRepository? repository,
  }) : _repository = repository ?? ProductRepository();

  ViewState<ProductModel> _state = const ViewState();
  ViewState<ProductModel> get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(status: ViewStatus.loading);
    notifyListeners();

    try {
      final product = await _repository.getProductDetails(productId);
      _state = ViewState(status: ViewStatus.success, data: product);
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
}
