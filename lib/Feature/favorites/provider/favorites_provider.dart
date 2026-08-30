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

  /// Re-resolves the current favorite ids into products — used by the
  /// Favorites screen's pull-to-refresh and error-state retry.
  Future<void> refresh() => _resolveProducts();

  Future<void> toggle(String productId) async {
    final wasFavorite = _favoriteIds.contains(productId);

    // Optimistic local update.
    if (wasFavorite) {
      _favoriteIds = {..._favoriteIds}..remove(productId);
    } else {
      _favoriteIds = {..._favoriteIds, productId};
    }

    if (wasFavorite && _state.data != null) {
      // Un-favoriting must drop the product from the resolved list
      // (what the Favorites screen actually renders) immediately —
      // otherwise it lingers on screen until the Firestore stream
      // round-trips.
      final updated =
          _state.data!.where((p) => p.id != productId).toList();
      _state = ViewState(
        status: updated.isEmpty ? ViewStatus.empty : ViewStatus.success,
        data: updated,
      );
      notifyListeners();
    } else if (!wasFavorite) {
      // Reflect the heart-icon flip immediately everywhere...
      notifyListeners();
      // ...then actually fetch the newly-favorited product's data.
      // This can NOT be left to the `_listen()` stream callback: by
      // the time Firestore confirms the write, `_favoriteIds` here
      // already matches (we just optimistically set it above), so
      // that callback's own "did the id set actually change" check
      // sees no difference and skips `_resolveProducts()` — meaning
      // the new favorite's ProductModel would never get fetched and
      // it would never appear on the Favorites screen. This was the
      // root cause of "heart fills in but the product never shows up
      // in Favorites".
      unawaited(_resolveProducts());
    } else {
      notifyListeners();
    }

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
