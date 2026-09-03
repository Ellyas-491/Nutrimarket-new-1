import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import 'local_storage_service.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    _loadNotifications();
  }

  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _loadNotifications() {
    try {
      final list = LocalStorageService().getNotifications();
      _notifications.clear();
      if (list.isNotEmpty) {
        for (var item in list) {
          if (item['id'] != 'notif_init_sec') {
            _notifications.add(AppNotification.fromJson(item));
          }
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Error loading notifications: $e');
    }
  }

  void _persist() {
    try {
      LocalStorageService().saveNotifications(_notifications.map((n) => n.toJson()).toList());
    } catch (e) {
      debugPrint('[NotificationService] Error persisting notifications: $e');
    }
  }

  void addNotification({
    required String title,
    required String message,
    required NotificationCategory category,
    bool isImportant = false,
    String? orderId,
  }) {
    final newNotif = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      category: category,
      timestamp: DateTime.now(),
      isRead: false,
      isImportant: isImportant,
      orderId: orderId,
    );

    _notifications.insert(0, newNotif);
    _persist();
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _notifications[index].isRead = true;
      _persist();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    _persist();
    notifyListeners();
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _persist();
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _persist();
    notifyListeners();
  }
}
