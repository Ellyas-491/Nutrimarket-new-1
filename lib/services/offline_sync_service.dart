import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/food_product.dart';
import '../models/order.dart';
import 'local_storage_service.dart';
import 'product_repository.dart';
import 'supabase_service.dart';

class OfflineSyncService extends ChangeNotifier {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingItemsCount = 0;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingItemsCount => _pendingItemsCount;

  Future<void> init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = !results.contains(ConnectivityResult.none);
      _updatePendingCount();

      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
        final onlineNow = !results.contains(ConnectivityResult.none);
        debugPrint('[OfflineSyncService] Status koneksi: online=$onlineNow');

        if (!_isOnline && onlineNow) {
          _isOnline = true;
          notifyListeners();
          triggerSync();
        } else {
          _isOnline = onlineNow;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('[OfflineSyncService] init error: $e');
    }
  }

  void _updatePendingCount() {
    _pendingItemsCount = LocalStorageService().getSyncQueue().length;
    notifyListeners();
  }

  /// Trigger background sync process from Local Storage Queue to Supabase Cloud
  Future<void> triggerSync() async {
    if (_isSyncing || !_isOnline) return;

    final supabaseService = SupabaseService();
    if (!supabaseService.isConfigured || !supabaseService.isLoggedIn) {
      _updatePendingCount();
      return;
    }

    final queue = LocalStorageService().getSyncQueue();
    if (queue.isEmpty) {
      _updatePendingCount();
      return;
    }

    _isSyncing = true;
    notifyListeners();

    debugPrint('[OfflineSyncService] Memulai pengiriman ${queue.length} data antrean offline ke Supabase Cloud...');

    final allProducts = ProductRepository().verifiedProducts;

    for (var item in queue) {
      final taskId = item['id'] as String? ?? '';
      final type = item['type'] as String? ?? 'order';
      final payload = Map<String, dynamic>.from(item['payload'] as Map? ?? item);

      try {
        if (type == 'order') {
          // Rekonstruksi Order Model lengkap dengan alamat dan pembayaran
          final rawItems = payload['items'] as List<dynamic>? ?? [];
          final List<CartItem> cartItems = [];

          for (var it in rawItems) {
            final itMap = Map<String, dynamic>.from(it as Map);
            final prodId = itMap['productId'] as String? ?? itMap['product_id'] as String? ?? '';
            final qty = (itMap['quantity'] as num?)?.toInt() ?? 1;
            final notes = itMap['sellerNotes'] as String? ?? itMap['seller_notes'] as String? ?? '';

            final product = allProducts.firstWhere(
              (p) => p.id == prodId,
              orElse: () => FoodProduct(
                id: prodId,
                name: itMap['productName'] as String? ?? 'Menu Sehat',
                category: 'Healthy Meals',
                price: (itMap['productPrice'] as num?)?.toDouble() ?? 30000,
                rating: 4.8,
                reviewCount: 10,
                imageUrl: itMap['productImage'] as String? ?? '',
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

            cartItems.add(CartItem(
              product: product,
              quantity: qty,
              sellerNotes: notes,
            ));
          }

          final statusIdx = payload['statusIndex'] as int? ?? payload['status'] as int? ?? 0;
          final status = statusIdx < OrderStatus.values.length
              ? OrderStatus.values[statusIdx]
              : OrderStatus.pendingPayment;

          final restoredOrder = OrderModel(
            id: payload['id'] as String,
            items: cartItems,
            subtotal: (payload['subtotal'] as num).toDouble(),
            deliveryFee: (payload['deliveryFee'] as num? ?? payload['delivery_fee'] as num? ?? 10000).toDouble(),
            serviceFee: (payload['serviceFee'] as num? ?? payload['service_fee'] as num? ?? 2000).toDouble(),
            discount: (payload['discount'] as num? ?? 0).toDouble(),
            total: (payload['total'] as num).toDouble(),
            status: status,
            orderDate: DateTime.tryParse(payload['orderDate'] as String? ?? payload['created_at'] as String? ?? '') ?? DateTime.now(),
            estimatedDelivery: payload['estimatedDelivery'] as String? ?? payload['estimated_delivery'] as String? ?? '20-30 Menit',
            deliveryAddress: payload['deliveryAddress'] as String? ?? payload['delivery_address'] as String? ?? '',
            deliveryOption: payload['deliveryOption'] as String? ?? payload['delivery_option'] as String? ?? 'Instant Delivery',
            orderNotes: payload['orderNotes'] as String? ?? payload['order_notes'] as String? ?? '',
            paymentMethod: payload['paymentMethod'] as String? ?? payload['payment_method'] as String? ?? 'QRIS Instant Pay',
            paymentReference: payload['paymentReference'] as String? ?? payload['payment_reference'] as String? ?? '',
          );

          await supabaseService.createOrder(restoredOrder);
          debugPrint('[OfflineSyncService] Order offline ${restoredOrder.id} berhasil dikirim ke Supabase!');
        } else if (type == 'order_status') {
          final orderId = payload['order_id'] as String;
          final statusIdx = payload['status_index'] as int;
          final estimate = payload['estimated_delivery'] as String;
          await supabaseService.updateOrderStatus(orderId, statusIdx, estimate);
        } else if (type == 'cart_item') {
          final prodId = payload['product_id'] as String;
          final qty = payload['quantity'] as int? ?? 1;
          final notes = payload['seller_notes'] as String? ?? '';
          final product = allProducts.firstWhere((p) => p.id == prodId, orElse: () => allProducts.first);
          await supabaseService.saveUserCartItem(product, qty, notes);
        } else if (type == 'cart_remove') {
          final prodId = payload['product_id'] as String;
          await supabaseService.removeUserCartItem(prodId);
        } else if (type == 'cart_clear') {
          await supabaseService.clearUserCart();
        } else if (type == 'chat_session') {
          final session = ChatSession(
            id: payload['id'] as String,
            title: payload['title'] as String? ?? 'Konsultasi Nutrisi',
            category: payload['category'] as String? ?? 'AI',
            messages: [],
            createdAt: DateTime.tryParse(payload['createdAt'] as String? ?? '') ?? DateTime.now(),
          );
          await supabaseService.saveChatSession(session);
        } else if (type == 'chat_message') {
          final sId = payload['session_id'] as String;
          final msg = ChatMessage(
            id: payload['id'] as String,
            content: payload['content'] as String,
            isUser: payload['is_user'] as bool? ?? false,
            timestamp: DateTime.tryParse(payload['timestamp'] as String? ?? '') ?? DateTime.now(),
          );
          await supabaseService.saveChatMessage(sId, msg);
        } else if (type == 'favorite_add') {
          final prodId = payload['product_id'] as String;
          await supabaseService.addFavorite(prodId);
        } else if (type == 'favorite_remove') {
          final prodId = payload['product_id'] as String;
          await supabaseService.removeFavorite(prodId);
        }

        // Hapus dari antrean lokal jika berhasil disinkronkan ke Supabase
        await LocalStorageService().removeFromSyncQueue(taskId.isNotEmpty ? taskId : (payload['id'] as String? ?? ''));
      } catch (e) {
        debugPrint('[OfflineSyncService] Gagal sync antrean $taskId: $e');
      }
    }

    _isSyncing = false;
    _updatePendingCount();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
