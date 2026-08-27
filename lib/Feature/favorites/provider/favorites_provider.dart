import 'dart:async';

import 'package:flutter/material.dart';

import 'package:rosivia/Feature/auth/provider/auth_provider.dart';
import 'package:rosivia/Feature/products/data/models/product_model.dart';
import 'package:rosivia/Feature/products/data/repositories/product_repository.dart';
import 'package:rosivia/core/network/api_exception.dart';
import 'package:rosivia/core/network/view_state.dart';

/// Keeps the favorite product ids stored on the user's Firestore
/// document (`AuthProvider`/`UserModel.favorites`) in sync with the
/// full [ProductModel] objects shown on the Favorites screen and the
/// heart icon on every product card.
class FavoritesProvider extends ChangeNotifier {
  final AuthProvider _authProvider;
  final ProductRepository _productRepository;

  StreamSubscription? _sub;
  Set<String> _favoriteIds = {};

  FavoritesProvider({
    required AuthProvider authProvider,
    ProductRepository? productRepository,
  })  : _authProvider = authProvider,
        _productRepository = productRepository ?? ProductRepository() {
    _listen();
  }

  ViewState<List<ProductModel>> _state = const ViewState();
  ViewState<List<ProductModel>> get state => _state;

  Set<String> get favoriteIds => _favoriteIds;

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  void _listen() {
    _sub = _authProvider.watchCurrentUser().listen((user) {
      final ids = (user?.favorites ?? const <String>[]).toSet();
      if (ids.length == _favoriteIds.length &&
          ids.every(_favoriteIds.contains)) {
        return;
      }
      _favoriteIds = ids;
      _resolveProducts();
    });
  }

  Future<void> _resolveProducts() async {
    if (_favoriteIds.isEmpty) {
      _state = const ViewState(status: ViewStatus.empty, data: []);
      notifyListeners();
      return;
    }

    _state = _state.copyWith(status: ViewStatus.loading);
    notifyListeners();

    try {
      final products =
          await _productRepository.getProductsByIds(_favoriteIds.toList());
      _state = ViewState(
        status: products.isEmpty ? ViewStatus.empty : ViewStatus.success,
        data: products,
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

  Future<void> toggle(String productId) async {
    final wasFavorite = _favoriteIds.contains(productId);

    // Optimistic local update; Firestore stream will reconcile.
    if (wasFavorite) {
      _favoriteIds = {..._favoriteIds}..remove(productId);
    } else {
      _favoriteIds = {..._favoriteIds, productId};
    }
    notifyListeners();

    if (wasFavorite) {
      await _authProvider.removeFavorite(productId);
    } else {
      await _authProvider.addFavorite(productId);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
