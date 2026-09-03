import 'package:flutter/widgets.dart';
import '../models/cart_item.dart';
import '../models/food_product.dart';
import 'local_storage_service.dart';
import 'offline_sync_service.dart';
import 'product_repository.dart';
import 'supabase_service.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);

  double get deliveryFee => _items.isEmpty ? 0 : 10000;

  double get total => subtotal + deliveryFee;

  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  void _persistLocalCart() {
    final payload = _items.map((it) => {
      'productId': it.product.id,
      'productName': it.product.name,
      'productImage': it.product.imageUrl,
      'productPrice': it.product.price,
      'quantity': it.quantity,
      'sellerNotes': it.sellerNotes,
    }).toList();
    LocalStorageService().saveLocalCart(payload);
  }

  void initFromLocalStorage() {
    try {
      final savedCart = LocalStorageService().getLocalCart();
      if (savedCart.isNotEmpty) {
        final allProducts = ProductRepository().verifiedProducts;
        _items.clear();
        for (var map in savedCart) {
          final prodId = map['productId'] as String? ?? '';
          final qty = (map['quantity'] as num?)?.toInt() ?? 1;
          final notes = map['sellerNotes'] as String? ?? '';

          final product = allProducts.firstWhere(
            (p) => p.id == prodId,
            orElse: () => FoodProduct(
              id: prodId,
              name: map['productName'] as String? ?? 'Menu Sehat',
              category: 'Healthy Meals',
              price: (map['productPrice'] as num?)?.toDouble() ?? 30000,
              rating: 4.8,
              reviewCount: 10,
              imageUrl: map['productImage'] as String? ?? '',
              calories: 350,
              protein: 20,
              carbs: 30,
              fat: 8,
              fiber: 5,
              sugar: 2,
              sodium: 300,
              suitableFor: const [],
              ingredients: const [],
              allergens: const [],
              nutritionistName: 'NutriMarket Expert',
              nutritionistReview: 'Menu Terverifikasi',
            ),
          );

          _items.add(CartItem(
            product: product,
            quantity: qty,
            sellerNotes: notes,
          ));
        }
        _safeNotify();
      }
    } catch (e) {
      debugPrint('[CartService] initFromLocalStorage error: $e');
    }
  }

  Future<void> syncWithSupabase() async {
    final supabaseService = SupabaseService();
    if (!supabaseService.isConfigured || !supabaseService.isLoggedIn) return;

    try {
      final allProducts = ProductRepository().verifiedProducts;
      final serverCart = await supabaseService.fetchUserCart(allProducts);
      if (serverCart.isNotEmpty) {
        _items.clear();
        _items.addAll(serverCart);
        _persistLocalCart();
        _safeNotify();
      }
    } catch (e) {
      debugPrint('[CartService] Gagal sync cart dari Supabase: $e');
    }
  }

  void addToCart(FoodProduct product, {int quantity = 1, String sellerNotes = ''}) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    int newQuantity = quantity;
    String newNotes = sellerNotes;

    if (index >= 0) {
      _items[index].quantity += quantity;
      newQuantity = _items[index].quantity;
      if (sellerNotes.isNotEmpty) {
        _items[index].sellerNotes = sellerNotes;
        newNotes = sellerNotes;
      } else {
        newNotes = _items[index].sellerNotes;
      }
    } else {
      _items.add(CartItem(
        product: product,
        quantity: quantity,
        sellerNotes: sellerNotes,
      ));
    }

    // 1. Simpan ke Local Storage dulu
    _persistLocalCart();

    // 2. Masukkan ke Sync Queue untuk dikirim ke Cloud saat online
    LocalStorageService().addToSyncQueue({
      'id': 'task_cart_${product.id}',
      'type': 'cart_item',
      'payload': {
        'product_id': product.id,
        'quantity': newQuantity,
        'seller_notes': newNotes,
      },
    });

    // 3. Trigger background sync
    OfflineSyncService().triggerSync();

    _safeNotify();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final product = _items[index].product;
      final notes = _items[index].sellerNotes;

      if (quantity <= 0) {
        _items.removeAt(index);
        _persistLocalCart();

        LocalStorageService().addToSyncQueue({
          'id': 'task_cart_remove_$productId',
          'type': 'cart_remove',
          'payload': {'product_id': productId},
        });
      } else {
        _items[index].quantity = quantity;
        _persistLocalCart();

        LocalStorageService().addToSyncQueue({
          'id': 'task_cart_$productId',
          'type': 'cart_item',
          'payload': {
            'product_id': product.id,
            'quantity': quantity,
            'seller_notes': notes,
          },
        });
      }

      OfflineSyncService().triggerSync();
      _safeNotify();
    }
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _persistLocalCart();

    LocalStorageService().addToSyncQueue({
      'id': 'task_cart_remove_$productId',
      'type': 'cart_remove',
      'payload': {'product_id': productId},
    });

    OfflineSyncService().triggerSync();
    _safeNotify();
  }

  void updateSellerNotes(String productId, String notes) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].sellerNotes = notes;
      final product = _items[index].product;
      final qty = _items[index].quantity;

      _persistLocalCart();

      LocalStorageService().addToSyncQueue({
        'id': 'task_cart_$productId',
        'type': 'cart_item',
        'payload': {
          'product_id': product.id,
          'quantity': qty,
          'seller_notes': notes,
        },
      });

      OfflineSyncService().triggerSync();
      _safeNotify();
    }
  }

  void clearCart() {
    _items.clear();
    LocalStorageService().clearLocalCart();

    LocalStorageService().addToSyncQueue({
      'id': 'task_cart_clear_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'cart_clear',
      'payload': {},
    });

    OfflineSyncService().triggerSync();
    _safeNotify();
  }

  String formatCurrency(num amount) {
    final priceInt = amount.toInt();
    final buffer = StringBuffer();
    final str = priceInt.toString();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp$buffer';
  }

  static String formatCurrencyStatic(num amount) {
    return CartService().formatCurrency(amount);
  }
}
