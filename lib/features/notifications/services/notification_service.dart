import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:clev_ai/features/notifications/models/app_notification.dart';
import 'package:clev_ai/data/local/local_storage_service.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  NotificationService._internal() {
    _loadNotifications();
  }

  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Inisialisasi Native Device Notification (Android / iOS System Notification)
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[NotificationService] Notification tapped: ${response.payload}');
        },
      );

      // Buat Notification Channel Prioritas Tinggi untuk Android
      const orderChannel = AndroidNotificationChannel(
        'order_updates_channel',
        'Status Pesanan & Pengantaran',
        description: 'Notifikasi real-time proses memasak, pengantaran kurir, dan pesanan sampai.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.createNotificationChannel(orderChannel);
      }

      _isInitialized = true;
      debugPrint('[NotificationService] Native Local Notifications initialized successfully');
    } catch (e) {
      debugPrint('[NotificationService] Error initializing local notifications: $e');
    }
  }

  /// Menampilkan Notifikasi Asli di Status Bar / Layar HP Pengguna
  Future<void> showSystemNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      final notifId = id ?? (DateTime.now().millisecondsSinceEpoch % 100000);

      final androidDetails = AndroidNotificationDetails(
        'order_updates_channel',
        'Status Pesanan & Pengantaran',
        channelDescription: 'Notifikasi real-time status memasak, pengantaran, dan pesanan selesai.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'NutriMarket Update',
        ),
        icon: '@mipmap/ic_launcher',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _localNotifications.show(
        notifId,
        title,
        body,
        details,
        payload: payload,
      );
      debugPrint('[NotificationService] Native Phone Notification Shown: $title');
    } catch (e) {
      debugPrint('[NotificationService] Failed to show system notification: $e');
    }
  }

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

    // Otomatis Munculkan Notifikasi di HP / Device Status Bar
    showSystemNotification(
      title: title,
      body: message,
      payload: orderId,
    );
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
