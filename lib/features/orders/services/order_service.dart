import 'package:flutter/widgets.dart';
import 'package:clev_ai/features/notifications/models/app_notification.dart';
import 'package:clev_ai/features/cart/models/cart_item.dart';
import 'package:clev_ai/features/products/models/food_product.dart';
import 'package:clev_ai/features/orders/models/order.dart';
import 'package:clev_ai/features/cart/services/cart_service.dart';
import 'package:clev_ai/data/local/local_storage_service.dart';
import 'package:clev_ai/features/notifications/services/notification_service.dart';
import 'package:clev_ai/data/local/offline_sync_service.dart';
import 'package:clev_ai/features/products/services/product_repository.dart';
import 'package:clev_ai/data/remote/supabase_service.dart';

class OrderService extends ChangeNotifier {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;

  final List<OrderModel> _orders = [];

  OrderService._internal();

  List<OrderModel> get orders => List.unmodifiable(_orders);

  List<OrderModel> get activeOrders =>
      _orders.where((o) => o.status != OrderStatus.completed && o.status != OrderStatus.cancelled).toList();

  List<OrderModel> get completedOrders =>
      _orders.where((o) => o.status == OrderStatus.completed).toList();

  List<OrderModel> get cancelledOrders =>
      _orders.where((o) => o.status == OrderStatus.cancelled).toList();

  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  void clearOrders() {
    _orders.clear();
    _safeNotify();
  }

  void setOrders(List<OrderModel> newOrders) {
    _orders.clear();
    _orders.addAll(newOrders);
    _safeNotify();
  }

  Future<void> syncWithSupabase() async {
    final supabaseService = SupabaseService();
    if (!supabaseService.isConfigured || !supabaseService.isLoggedIn) return;

    try {
      final allProducts = ProductRepository().verifiedProducts;
      final serverOrders = await supabaseService.fetchUserOrders(allProducts);

      _orders.clear();
      _orders.addAll(serverOrders);
      _safeNotify();
    } catch (e) {
      debugPrint('[OrderService] Gagal syncWithSupabase: $e');
    }
  }

  void _handleStatusNotification(OrderModel order, OrderStatus oldStatus, OrderStatus newStatus) {
    if (newStatus == OrderStatus.preparing) {
      NotificationService().addNotification(
        title: 'Pesanan Sedang Dimasak 🍳',
        message: 'Pesanan #${order.id} sedang dimasak dan disiapkan oleh koki ahli gizi.',
        category: NotificationCategory.order,
        isImportant: false,
        orderId: order.id,
      );
    } else if (newStatus == OrderStatus.delivering) {
      NotificationService().addNotification(
        title: 'Pesanan Sedang Diantar 🛵',
        message: 'Kurir sedang dalam perjalanan mengantar pesanan #${order.id} ke alamat Anda.',
        category: NotificationCategory.delivery,
        isImportant: true,
        orderId: order.id,
      );
    } else if (newStatus == OrderStatus.delivered) {
      NotificationService().addNotification(
        title: 'Pesanan Telah Sampai 📍',
        message: 'Kurir telah sampai di alamat Anda dengan pesanan #${order.id}. Silakan konfirmasi pesanan diterima.',
        category: NotificationCategory.delivery,
        isImportant: true,
        orderId: order.id,
      );
    } else if (newStatus == OrderStatus.completed) {
      NotificationService().addNotification(
        title: 'Pesanan Selesai 🍽️',
        message: 'Terima kasih! Pesanan #${order.id} telah selesai. Silakan beri ulasan Anda.',
        category: NotificationCategory.order,
        isImportant: true,
        orderId: order.id,
      );
    }
  }

  /// Initialize Offline-First order data from Local Storage
  void initFromLocalStorage() {
    try {
      final savedOrdersJson = LocalStorageService().getAllOrders();
      if (savedOrdersJson.isNotEmpty) {
        _orders.clear();
        for (var item in savedOrdersJson) {
          try {
            // Restore basic fields
            final orderId = item['id'] as String;
            final subtotal = (item['subtotal'] as num).toDouble();
            final deliveryFee = (item['deliveryFee'] as num).toDouble();
            final serviceFee = (item['serviceFee'] as num).toDouble();
            final discount = (item['discount'] as num).toDouble();
            final total = (item['total'] as num).toDouble();
            final statusIdx = item['statusIndex'] as int? ?? 1;
            final status = OrderStatus.values[statusIdx];
            final address = item['deliveryAddress'] as String? ?? 'Alamat Utama Pengiriman';
            final deliveryOption = item['deliveryOption'] as String? ?? 'Instant Delivery';
            final orderNotes = item['orderNotes'] as String? ?? '';
            final paymentMethod = item['paymentMethod'] as String? ?? 'QRIS';

            final restoredOrder = OrderModel(
              id: orderId,
              items: [],
              subtotal: subtotal,
              deliveryFee: deliveryFee,
              serviceFee: serviceFee,
              discount: discount,
              total: total,
              status: status,
              orderDate: DateTime.tryParse(item['orderDate'] as String? ?? '') ?? DateTime.now(),
              estimatedDelivery: item['estimatedDelivery'] as String? ?? 'Pesanan Offline',
              deliveryAddress: address,
              deliveryOption: deliveryOption,
              orderNotes: orderNotes,
              paymentMethod: paymentMethod,
            );
            _orders.add(restoredOrder);
          } catch (e) {
            debugPrint('Failed to restore individual order item: $e');
          }
        }
        _safeNotify();
      }
    } catch (e) {
      debugPrint('OrderService initFromHive error: $e');
    }
  }

  OrderModel placeOrder({
    required List<CartItem> cartItems,
    required double subtotal,
    required double deliveryFee,
    double serviceFee = 2000,
    double discount = 0,
    required double total,
    required String address,
    String deliveryOption = 'Instant Delivery (20-30 Menit)',
    String orderNotes = '',
    required String paymentMethod,
    bool isPaidImmediately = false,
  }) {
    final now = DateTime.now();
    final orderId = 'NM-${now.millisecondsSinceEpoch.toString().substring(5)}';

    final newOrder = OrderModel(
      id: orderId,
      items: List.from(cartItems),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      discount: discount,
      total: total,
      status: isPaidImmediately ? OrderStatus.paid : OrderStatus.pendingPayment,
      orderDate: now,
      estimatedDelivery: isPaidImmediately
          ? 'Pembayaran Diterima • Makanan sedang disiapkan'
          : 'Menunggu Pembayaran',
      deliveryAddress: address,
      deliveryOption: deliveryOption,
      orderNotes: orderNotes,
      paymentMethod: paymentMethod,
      paymentReference: 'PAY-${now.millisecondsSinceEpoch}',
      statusHistory: [
        OrderStatusHistoryItem(
          status: OrderStatus.pendingPayment,
          title: 'Pesanan Dibuat',
          actor: 'Konsumen',
          description: 'Pesanan berhasil dibuat.',
          timestamp: now,
        ),
        if (isPaidImmediately)
          OrderStatusHistoryItem(
            status: OrderStatus.paid,
            title: 'Pembayaran Diterima',
            actor: 'Payment Gateway',
            description: 'Pembayaran berhasil dikonfirmasi.',
            timestamp: now.add(const Duration(seconds: 1)),
          ),
      ],
    );

    _orders.insert(0, newOrder);

    // 1. Simpan ke Local Storage Dulu (Offline-First dengan data pengiriman & pembayaran komplit)
    final orderData = {
      'id': newOrder.id,
      'items': newOrder.items.map((it) => {
        'productId': it.product.id,
        'productName': it.product.name,
        'productImage': it.product.imageUrl,
        'productPrice': it.product.price,
        'quantity': it.quantity,
        'sellerNotes': it.sellerNotes,
      }).toList(),
      'subtotal': newOrder.subtotal,
      'deliveryFee': newOrder.deliveryFee,
      'serviceFee': newOrder.serviceFee,
      'discount': newOrder.discount,
      'total': newOrder.total,
      'statusIndex': newOrder.status.index,
      'orderDate': newOrder.orderDate.toIso8601String(),
      'estimatedDelivery': newOrder.estimatedDelivery,
      'deliveryAddress': newOrder.deliveryAddress,
      'deliveryOption': newOrder.deliveryOption,
      'orderNotes': newOrder.orderNotes,
      'paymentMethod': newOrder.paymentMethod,
      'paymentReference': newOrder.paymentReference,
    };

    // Simpan lokal secara instan
    LocalStorageService().saveOrder(orderData);

    // 2. Masukkan ke Sync Queue untuk dikirim ke Supabase Cloud (baik online sekarang maupun nanti saat online lagi)
    LocalStorageService().addToSyncQueue({
      'id': 'task_order_${newOrder.id}',
      'type': 'order',
      'payload': orderData,
      'createdAt': DateTime.now().toIso8601String(),
    });

    LocalStorageService().logActivity('place_order', {'order_id': newOrder.id, 'total': newOrder.total});

    // 3. Langsung kirim ke Supabase jika online & logged in
    final supabase = SupabaseService();
    if (supabase.isConfigured && supabase.currentUser != null) {
      supabase.createOrder(newOrder).catchError((e) {
        debugPrint('[OrderService] direct createOrder error: $e');
      });
    }

    // 4. Trigger background sync & Notification
    OfflineSyncService().triggerSync();

    NotificationService().addNotification(
      title: 'Pesanan Berhasil Dibuat (#${newOrder.id}) 🛍️',
      message: 'Pesanan ${newOrder.items.length} menu senilai ${CartService().formatCurrency(newOrder.total)} berhasil dibuat dan menunggu pembayaran.',
      category: NotificationCategory.order,
      isImportant: true,
      orderId: newOrder.id,
    );

    _safeNotify();
    return newOrder;
  }

  OrderModel directOrder({
    required FoodProduct product,
    int quantity = 1,
    String sellerNotes = '',
    String address = 'Alamat Pengantaran Utama',
  }) {
    final subtotal = product.price * quantity;
    const deliveryFee = 10000.0;
    const serviceFee = 2000.0;
    final total = subtotal + deliveryFee + serviceFee;

    final cartItem = CartItem(product: product, quantity: quantity, sellerNotes: sellerNotes);

    return placeOrder(
      cartItems: [cartItem],
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      total: total,
      address: address,
      paymentMethod: 'GoPay / QRIS Dinamis',
      isPaidImmediately: false,
    );
  }

  void confirmPayment(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index < 0) return;

    final order = _orders[index];
    if (order.status == OrderStatus.pendingPayment) {
      final now = DateTime.now();
      order.status = OrderStatus.paid;
      order.estimatedDelivery = 'Pembayaran Diterima • Makanan sedang disiapkan';
      order.statusHistory.add(
        OrderStatusHistoryItem(
          status: OrderStatus.paid,
          title: 'Pembayaran Diterima',
          actor: 'Payment Gateway',
          description: 'Pembayaran berhasil dikonfirmasi.',
          timestamp: now,
        ),
      );

      // Update di local storage
      final existing = LocalStorageService().getAllOrders();
      final targetIdx = existing.indexWhere((o) => o['id'] == order.id);
      if (targetIdx >= 0) {
        existing[targetIdx]['statusIndex'] = order.status.index;
        existing[targetIdx]['estimatedDelivery'] = order.estimatedDelivery;
        LocalStorageService().saveOrder(existing[targetIdx]);
      }

      // Langsung update di Supabase
      final supabase = SupabaseService();
      if (supabase.isConfigured && supabase.currentUser != null) {
        supabase.updateOrderStatus(order.id, order.status.index, order.estimatedDelivery).catchError((e) {
          debugPrint('[OrderService] direct updateOrderStatus error: $e');
        });
      }

      // Masukkan task update status ke sync queue
      LocalStorageService().addToSyncQueue({
        'id': 'task_status_${order.id}_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'order_status',
        'payload': {
          'order_id': order.id,
          'status_index': order.status.index,
          'estimated_delivery': order.estimatedDelivery,
        },
      });

      OfflineSyncService().triggerSync();

      NotificationService().addNotification(
        title: 'Pembayaran Berhasil Diterima (#${order.id}) 💳',
        message: 'Pembayaran pesanan #${order.id} sebesar ${CartService().formatCurrency(order.total)} telah diverifikasi. Dapur segera memasak pesanan Anda.',
        category: NotificationCategory.payment,
        isImportant: true,
        orderId: order.id,
      );

      _safeNotify();
    }
  }

  void advanceOrderStatus(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index < 0) return;

    final order = _orders[index];
    final now = DateTime.now();

    OrderStatus nextStatus;
    String title = '';
    String desc = '';
    String newEstimate = order.estimatedDelivery;

    switch (order.status) {
      case OrderStatus.pendingPayment:
        nextStatus = OrderStatus.paid;
        title = 'Pembayaran Diterima';
        desc = 'Pembayaran berhasil dikonfirmasi.';
        newEstimate = 'Pembayaran Diterima • Makanan sedang disiapkan';
        break;
      case OrderStatus.paid:
      case OrderStatus.confirmed:
        nextStatus = OrderStatus.preparing;
        title = 'Sedang Dimasak';
        desc = 'Dapur sedang memasak dan menyiapkan hidangan Anda.';
        newEstimate = 'Sedang dimasak oleh Chef ahli 🍳';
        break;
      case OrderStatus.preparing:
      case OrderStatus.packed:
      case OrderStatus.readyPickup:
      case OrderStatus.pickedUp:
        nextStatus = OrderStatus.delivering;
        title = 'Pesanan Diantarkan';
        desc = 'Kurir sedang mengantarkan pesanan ke alamat tujuan.';
        newEstimate = 'Kurir sedang dalam perjalanan mengantar 🛵';
        break;
      case OrderStatus.delivering:
        nextStatus = OrderStatus.delivered;
        title = 'Pesanan Telah Sampai';
        desc = 'Kurir telah sampai di lokasi tujuan. Silakan konfirmasi pesanan diterima.';
        newEstimate = 'Pesanan telah sampai di lokasi 📍';
        break;
      case OrderStatus.delivered:
        nextStatus = OrderStatus.completed;
        title = 'Pesanan Diterima';
        desc = 'Pesanan telah selesai dan diterima dengan baik.';
        newEstimate = 'Pesanan telah diterima';
        break;
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        return;
    }

    _handleStatusNotification(order, order.status, nextStatus);
    order.status = nextStatus;
    order.estimatedDelivery = newEstimate;
    order.statusHistory.add(
      OrderStatusHistoryItem(
        status: nextStatus,
        title: title,
        actor: 'Sistem',
        description: desc,
        timestamp: now,
      ),
    );

    // Update di local storage
    final existing = LocalStorageService().getAllOrders();
    final targetIdx = existing.indexWhere((o) => o['id'] == order.id);
    if (targetIdx >= 0) {
      existing[targetIdx]['statusIndex'] = order.status.index;
      existing[targetIdx]['estimatedDelivery'] = order.estimatedDelivery;
      LocalStorageService().saveOrder(existing[targetIdx]);
    }

    // Masukkan task update status ke sync queue
    LocalStorageService().addToSyncQueue({
      'id': 'task_status_${order.id}_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'order_status',
      'payload': {
        'order_id': order.id,
        'status_index': order.status.index,
        'estimated_delivery': order.estimatedDelivery,
      },
    });

    OfflineSyncService().triggerSync();
    _safeNotify();
  }

  Future<void> completeOrder(String orderId) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index].status = OrderStatus.completed;
      _orders[index].estimatedDelivery = 'Pesanan telah diterima';
      _orders[index].statusHistory.add(
        OrderStatusHistoryItem(
          status: OrderStatus.completed,
          title: 'Pesanan Diterima',
          actor: 'Konsumen',
          description: 'Pesanan telah diterima.',
          timestamp: DateTime.now(),
        ),
      );

      final orderData = {
        'id': _orders[index].id,
        'subtotal': _orders[index].subtotal,
        'deliveryFee': _orders[index].deliveryFee,
        'serviceFee': _orders[index].serviceFee,
        'discount': _orders[index].discount,
        'total': _orders[index].total,
        'statusIndex': _orders[index].status.index,
        'orderDate': _orders[index].orderDate.toIso8601String(),
        'estimatedDelivery': _orders[index].estimatedDelivery,
        'deliveryAddress': _orders[index].deliveryAddress,
        'deliveryOption': _orders[index].deliveryOption,
        'orderNotes': _orders[index].orderNotes,
        'paymentMethod': _orders[index].paymentMethod,
      };

      LocalStorageService().saveOrder(orderData);

      // Simpan dan update langsung ke Supabase Cloud
      final supabaseService = SupabaseService();
      if (supabaseService.isConfigured && supabaseService.isLoggedIn) {
        try {
          await supabaseService.updateOrderStatus(orderId, OrderStatus.completed.index, 'Pesanan telah diterima');
        } catch (e) {
          debugPrint('[OrderService] Error completeOrder to Supabase: $e');
        }
      } else {
        LocalStorageService().addToSyncQueue({
          'id': 'task_status_${orderId}_completed',
          'type': 'order_status',
          'payload': {
            'order_id': orderId,
            'status_index': OrderStatus.completed.index,
            'estimated_delivery': 'Pesanan telah diterima',
          },
        });
      }
      
      _handleStatusNotification(_orders[index], OrderStatus.delivered, OrderStatus.completed);

      _safeNotify();
    }
  }

  Future<void> submitReview(String orderId, OrderReview review) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index].review = review;

      final reviewData = {
        'food_quality_score': review.foodQualityScore,
        'packaging_score': review.packagingScore,
        'delivery_score': review.deliveryScore,
        'comments': review.comments,
        'created_at': review.createdAt.toIso8601String(),
      };

      // Save locally
      final existing = LocalStorageService().getAllOrders();
      final targetIdx = existing.indexWhere((o) => o['id'] == orderId);
      if (targetIdx >= 0) {
        existing[targetIdx]['review'] = reviewData;
        LocalStorageService().saveOrder(existing[targetIdx]);
      }

      // Sync to Supabase Cloud
      final supabaseService = SupabaseService();
      if (supabaseService.isConfigured && supabaseService.isLoggedIn) {
        try {
          await supabaseService.saveOrderReview(orderId, reviewData);
        } catch (e) {
          debugPrint('[OrderService] Error saveOrderReview to Supabase: $e');
        }
      }

      _safeNotify();
    }
  }

  List<Map<String, dynamic>> getReviewsForProduct(String productId, {String? productName}) {
    final List<Map<String, dynamic>> reviews = [];
    for (var order in _orders) {
      if (order.review != null) {
        final hasProduct = order.items.any((it) =>
            it.product.id == productId ||
            (productName != null && it.product.name.toLowerCase() == productName.toLowerCase()));
        if (hasProduct) {
          reviews.add({
            'orderId': order.id,
            'rating': order.review!.foodQualityScore.round(),
            'score': order.review!.foodQualityScore,
            'comments': order.review!.comments,
            'createdAt': order.review!.createdAt,
          });
        }
      }
    }
    return reviews;
  }
}
