import 'package:clev_ai/features/cart/models/cart_item.dart';

enum OrderStatus {
  pendingPayment, // PENDING_PAYMENT
  paid,           // PAID
  confirmed,      // CONFIRMED (Seller Terima Pesanan)
  preparing,      // PREPARING (Seller Mulai Memasak)
  packed,         // PACKED (Dikemas Higienis)
  readyPickup,    // READY_FOR_PICKUP (Siap Diambil Kurir)
  pickedUp,       // PICKED_UP (Kurir Ambil Makanan)
  delivering,     // DELIVERING (Kurir Menuju Alamat)
  delivered,      // DELIVERED (Pesanan Sampai)
  completed,      // COMPLETED (Konsumen Konfirmasi Selesai)
  cancelled,      // CANCELLED (Dibatalkan)
}

class OrderStatusHistoryItem {
  final OrderStatus status;
  final String title;
  final String actor; // 'Consumer', 'Payment Gateway', 'Seller', 'Courier', 'System'
  final String description;
  final DateTime timestamp;

  OrderStatusHistoryItem({
    required this.status,
    required this.title,
    required this.actor,
    required this.description,
    required this.timestamp,
  });
}

class OrderReview {
  final double foodQualityScore;
  final double packagingScore;
  final double deliveryScore;
  final String comments;
  final DateTime createdAt;

  OrderReview({
    required this.foodQualityScore,
    required this.packagingScore,
    required this.deliveryScore,
    required this.comments,
    required this.createdAt,
  });
}

class OrderModel {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
  final double total;
  OrderStatus status;
  final DateTime orderDate;
  String estimatedDelivery;
  final String deliveryAddress;
  final String deliveryOption;
  final String orderNotes;
  final String paymentMethod;
  final String paymentReference;
  final List<OrderStatusHistoryItem> statusHistory;
  OrderReview? review;
  String? deliveryPhotoUrl;

  OrderModel({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    this.serviceFee = 2000,
    this.discount = 0,
    required this.total,
    required this.status,
    required this.orderDate,
    required this.estimatedDelivery,
    required this.deliveryAddress,
    this.deliveryOption = 'Instant Delivery (20-30 Menit)',
    this.orderNotes = '',
    required this.paymentMethod,
    this.paymentReference = 'QRIS-NM-994821',
    List<OrderStatusHistoryItem>? statusHistory,
    this.review,
    this.deliveryPhotoUrl,
  }) : statusHistory = statusHistory ?? [];

  String get statusDisplay {
    switch (status) {
      case OrderStatus.pendingPayment:
        return 'Menunggu Pembayaran';
      case OrderStatus.paid:
        return 'Pembayaran Diterima';
      case OrderStatus.confirmed:
        return 'Pesanan Dikonfirmasi';
      case OrderStatus.preparing:
        return 'Sedang Dimasak';
      case OrderStatus.packed:
        return 'Selesai Dikemas';
      case OrderStatus.readyPickup:
        return 'Siap Diambil Kurir';
      case OrderStatus.pickedUp:
        return 'Diambil Kurir';
      case OrderStatus.delivering:
        return 'Sedang Diantar';
      case OrderStatus.delivered:
        return 'Pesanan Sampai';
      case OrderStatus.completed:
        return 'Pesanan Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  String get formattedTotal {
    final priceInt = total.toInt();
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
}
