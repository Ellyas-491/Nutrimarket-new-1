import 'package:flutter/material.dart';

enum NotificationCategory {
  security,
  order,
  payment,
  delivery,
  promo,
  health,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationCategory category;
  final DateTime timestamp;
  bool isRead;
  final bool isImportant;
  final String? orderId;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.isImportant = false,
    this.orderId,
  });

  IconData get icon {
    switch (category) {
      case NotificationCategory.security:
        return Icons.phone_android_rounded;
      case NotificationCategory.order:
        return Icons.restaurant_menu_rounded;
      case NotificationCategory.payment:
        return Icons.receipt_long_rounded;
      case NotificationCategory.delivery:
        return Icons.two_wheeler_rounded;
      case NotificationCategory.promo:
        return Icons.local_offer_rounded;
      case NotificationCategory.health:
        return Icons.health_and_safety_rounded;
    }
  }

  Color get iconColor {
    switch (category) {
      case NotificationCategory.security:
        return const Color(0xFF6366F1); // Indigo
      case NotificationCategory.order:
        return const Color(0xFFEA580C); // Orange
      case NotificationCategory.payment:
        return const Color(0xFF059669); // Emerald Green
      case NotificationCategory.delivery:
        return const Color(0xFF0284C7); // Sky Blue
      case NotificationCategory.promo:
        return const Color(0xFFD97706); // Amber
      case NotificationCategory.health:
        return const Color(0xFF0D9488); // Teal
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays} hari lalu';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'category': category.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'isImportant': isImportant,
      'orderId': orderId,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Pemberitahuan',
      message: json['message'] as String? ?? '',
      category: NotificationCategory.values.firstWhere(
        (c) => c.name == (json['category'] as String?),
        orElse: () => NotificationCategory.order,
      ),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      isImportant: json['isImportant'] as bool? ?? false,
      orderId: json['orderId'] as String?,
    );
  }
}
