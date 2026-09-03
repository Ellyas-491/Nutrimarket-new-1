import 'package:flutter/widgets.dart';
import 'package:clev_ai/features/products/models/food_product.dart';
import 'package:clev_ai/data/local/local_storage_service.dart';
import 'package:clev_ai/data/local/offline_sync_service.dart';
import 'package:clev_ai/features/products/services/product_repository.dart';
import 'package:clev_ai/data/remote/supabase_service.dart';

class FavoriteService extends ChangeNotifier {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal();

  final List<FoodProduct> _favorites = [];

  List<FoodProduct> get favorites => List.unmodifiable(_favorites);

  int get count => _favorites.length;

  bool isFavorite(String productId) {
    return _favorites.any((p) => p.id == productId);
  }

  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  void initFromLocalStorage() {
    try {
      final favIds = LocalStorageService().getFavoriteIds();
      if (favIds.isNotEmpty) {
        final allProducts = ProductRepository().products;
        final loadedFavs = allProducts.where((p) => favIds.contains(p.id)).toList();
        _favorites.clear();
        _favorites.addAll(loadedFavs);
        _safeNotify();
      }
    } catch (e) {
      debugPrint('[FavoriteService] Error loading cached favorites: $e');
    }
  }

  void _persistFavorites() {
    try {
      final ids = _favorites.map((p) => p.id).toList();
      LocalStorageService().saveFavoriteIds(ids);
    } catch (_) {}
  }

  Future<void> syncWithSupabase() async {
    final supabaseService = SupabaseService();
    if (!supabaseService.isConfigured || !supabaseService.isLoggedIn) return;

    try {
      final favIds = await supabaseService.fetchUserFavorites();
      final allProducts = ProductRepository().verifiedProducts;
      final loadedFavs = allProducts.where((p) => favIds.contains(p.id)).toList();
      _favorites.clear();
      _favorites.addAll(loadedFavs);
      _persistFavorites();
      _safeNotify();
    } catch (e) {
      debugPrint('[FavoriteService] Error sync with Supabase: $e');
    }
  }

  bool toggleFavorite(FoodProduct product) {
    final index = _favorites.indexWhere((p) => p.id == product.id);
    final bool isFavNow;
    if (index >= 0) {
      _favorites.removeAt(index);
      isFavNow = false;

      LocalStorageService().addToSyncQueue({
        'id': 'task_fav_rem_${product.id}',
        'type': 'favorite_remove',
        'payload': {'product_id': product.id},
      });
    } else {
      _favorites.add(product);
      isFavNow = true;

      LocalStorageService().addToSyncQueue({
        'id': 'task_fav_add_${product.id}',
        'type': 'favorite_add',
        'payload': {'product_id': product.id},
      });
    }

    OfflineSyncService().triggerSync();
    _persistFavorites();
    _safeNotify();
    return isFavNow;
  }

  void removeFavorite(String productId) {
    _favorites.removeWhere((p) => p.id == productId);

    LocalStorageService().addToSyncQueue({
      'id': 'task_fav_rem_$productId',
      'type': 'favorite_remove',
      'payload': {'product_id': productId},
    });

    OfflineSyncService().triggerSync();
    _persistFavorites();
    _safeNotify();
  }

  void clearFavorites() {
    _favorites.clear();
    _persistFavorites();
    _safeNotify();
  }

  void setFavorites(List<FoodProduct> list) {
    _favorites.clear();
    _favorites.addAll(list);
    _persistFavorites();
    _safeNotify();
  }
}
