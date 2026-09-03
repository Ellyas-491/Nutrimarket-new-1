import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  late SharedPreferences _prefs;

  static const String _keyOrdersList = 'pref_orders_list_v1';
  static const String _keySyncQueue = 'pref_sync_queue_v1';
  static const String _keyActivities = 'pref_activity_log_v1';
  static const String _keyLocalCart = 'pref_user_local_cart_v1';
  static const String _keyChatSessions = 'pref_chat_sessions_v1';
  static const String _keyUserProfile = 'pref_user_profile_cache_v1';
  static const String _keyCachedProducts = 'pref_cached_products_v1';
  static const String _keySavedAddresses = 'pref_saved_addresses_v1';
  static const String _keyFavoriteIds = 'pref_user_favorites_v1';
  static const String _keyNotifications = 'pref_notifications_v1';

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      debugPrint('Local Storage Service (SharedPreferences) initialized successfully.');
    } catch (e) {
      debugPrint('LocalStorageService init error: $e');
    }
  }

  // ===========================================================================
  // 0. USER PROFILE STORAGE (Offline-First Cache)
  // ===========================================================================
  Future<void> saveUserProfile(Map<String, dynamic> profileJson) async {
    try {
      final str = jsonEncode(profileJson);
      await _prefs.setString(_keyUserProfile, str);
    } catch (e) {
      debugPrint('saveUserProfile error: $e');
    }
  }

  Map<String, dynamic>? getUserProfile() {
    try {
      final str = _prefs.getString(_keyUserProfile);
      if (str == null || str.isEmpty) return null;
      return Map<String, dynamic>.from(jsonDecode(str) as Map);
    } catch (e) {
      debugPrint('getUserProfile error: $e');
      return null;
    }
  }

  Future<void> clearUserProfile() async {
    try {
      await _prefs.remove(_keyUserProfile);
    } catch (e) {
      debugPrint('clearUserProfile error: $e');
    }
  }

  // ===========================================================================
  // 0.1 PRODUCTS CATALOG OFFLINE CACHE
  // ===========================================================================
  Future<void> saveCachedProducts(List<Map<String, dynamic>> productsJsonList) async {
    try {
      final encoded = productsJsonList.map((p) => jsonEncode(p)).toList();
      await _prefs.setStringList(_keyCachedProducts, encoded);
    } catch (e) {
      debugPrint('saveCachedProducts error: $e');
    }
  }

  List<Map<String, dynamic>> getCachedProducts() {
    try {
      final rawList = _prefs.getStringList(_keyCachedProducts);
      if (rawList == null || rawList.isEmpty) return [];

      final List<Map<String, dynamic>> results = [];
      for (var str in rawList) {
        try {
          results.add(Map<String, dynamic>.from(jsonDecode(str) as Map));
        } catch (_) {}
      }
      return results;
    } catch (e) {
      return [];
    }
  }

  // ===========================================================================
  // 0.2 SAVED ADDRESSES STORAGE
  // ===========================================================================
  Future<void> saveSavedAddresses(List<Map<String, dynamic>> addressesJson) async {
    try {
      final encoded = addressesJson.map((a) => jsonEncode(a)).toList();
      await _prefs.setStringList(_keySavedAddresses, encoded);
    } catch (e) {
      debugPrint('saveSavedAddresses error: $e');
    }
  }

  List<Map<String, dynamic>> getSavedAddresses() {
    try {
      final rawList = _prefs.getStringList(_keySavedAddresses);
      if (rawList == null || rawList.isEmpty) return [];

      final List<Map<String, dynamic>> results = [];
      for (var str in rawList) {
        try {
          results.add(Map<String, dynamic>.from(jsonDecode(str) as Map));
        } catch (_) {}
      }
      return results;
    } catch (e) {
      return [];
    }
  }

  // ===========================================================================
  // 0.3 USER FAVORITES STORAGE
  // ===========================================================================
  Future<void> saveFavoriteIds(List<String> favIds) async {
    try {
      await _prefs.setStringList(_keyFavoriteIds, favIds);
    } catch (e) {
      debugPrint('saveFavoriteIds error: $e');
    }
  }

  List<String> getFavoriteIds() {
    try {
      return _prefs.getStringList(_keyFavoriteIds) ?? [];
    } catch (e) {
      return [];
    }
  }

  // ===========================================================================
  // 1. LOCAL CART STORAGE (Offline-First)
  // ===========================================================================
  Future<void> saveLocalCart(List<Map<String, dynamic>> cartJsonList) async {
    try {
      final encoded = cartJsonList.map((c) => jsonEncode(c)).toList();
      await _prefs.setStringList(_keyLocalCart, encoded);
    } catch (e) {
      debugPrint('saveLocalCart error: $e');
    }
  }

  List<Map<String, dynamic>> getLocalCart() {
    try {
      final rawList = _prefs.getStringList(_keyLocalCart);
      if (rawList == null || rawList.isEmpty) return [];

      final List<Map<String, dynamic>> results = [];
      for (var str in rawList) {
        try {
          results.add(Map<String, dynamic>.from(jsonDecode(str) as Map));
        } catch (_) {}
      }
      return results;
    } catch (e) {
      return [];
    }
  }

  Future<void> clearLocalCart() async {
    try {
      await _prefs.remove(_keyLocalCart);
    } catch (e) {
      debugPrint('clearLocalCart error: $e');
    }
  }

  // ===========================================================================
  // 2. ORDERS OFFLINE STORAGE (Offline-First)
  // ===========================================================================
  Future<void> saveOrder(Map<String, dynamic> orderJson) async {
    try {
      final id = orderJson['id'] as String;
      final existingOrders = getAllOrders();
      final index = existingOrders.indexWhere((o) => o['id'] == id);

      if (index >= 0) {
        existingOrders[index] = orderJson;
      } else {
        existingOrders.insert(0, orderJson);
      }

      final encodedList = existingOrders.map((o) => jsonEncode(o)).toList();
      await _prefs.setStringList(_keyOrdersList, encodedList);
    } catch (e) {
      debugPrint('saveOrder error: $e');
    }
  }

  List<Map<String, dynamic>> getAllOrders() {
    try {
      final rawList = _prefs.getStringList(_keyOrdersList);
      if (rawList == null || rawList.isEmpty) return [];

      final List<Map<String, dynamic>> results = [];
      for (var str in rawList) {
        try {
          results.add(Map<String, dynamic>.from(jsonDecode(str) as Map));
        } catch (_) {}
      }
      return results;
    } catch (e) {
      return [];
    }
  }

  Future<void> clearAllOrders() async {
    try {
      await _prefs.remove(_keyOrdersList);
    } catch (e) {
      debugPrint('clearAllOrders error: $e');
    }
  }

  // ===========================================================================
  // 3. SYNC QUEUE STORAGE (Local Sync Queue for Cloud Dispatch)
  // ===========================================================================
  Future<void> addToSyncQueue(Map<String, dynamic> item) async {
    try {
      final queue = getSyncQueue();
      // Cegah duplikasi berdasarkan id dan type
      final itemId = item['id'] as String? ?? 'task_${DateTime.now().millisecondsSinceEpoch}';
      queue.removeWhere((i) => i['id'] == itemId);
      queue.add(item);

      final encodedQueue = queue.map((i) => jsonEncode(i)).toList();
      await _prefs.setStringList(_keySyncQueue, encodedQueue);
    } catch (e) {
      debugPrint('addToSyncQueue error: $e');
    }
  }

  List<Map<String, dynamic>> getSyncQueue() {
    try {
      final rawList = _prefs.getStringList(_keySyncQueue);
      if (rawList == null || rawList.isEmpty) return [];

      final List<Map<String, dynamic>> queue = [];
      for (var str in rawList) {
        try {
          queue.add(Map<String, dynamic>.from(jsonDecode(str) as Map));
        } catch (_) {}
      }
      return queue;
    } catch (e) {
      return [];
    }
  }

  Future<void> removeFromSyncQueue(String id) async {
    try {
      final queue = getSyncQueue();
      queue.removeWhere((item) => item['id'] == id);
      final encodedQueue = queue.map((i) => jsonEncode(i)).toList();
      await _prefs.setStringList(_keySyncQueue, encodedQueue);
    } catch (e) {
      debugPrint('removeFromSyncQueue error: $e');
    }
  }

  Future<void> clearSyncQueue() async {
    try {
      await _prefs.remove(_keySyncQueue);
    } catch (e) {
      debugPrint('clearSyncQueue error: $e');
    }
  }

  // ===========================================================================
  // 4. USER ACTIVITY LOG STORAGE
  // ===========================================================================
  Future<void> logActivity(String action, Map<String, dynamic> details) async {
    try {
      final rawList = _prefs.getStringList(_keyActivities) ?? [];
      final entry = {
        'id': 'act_${DateTime.now().millisecondsSinceEpoch}',
        'action': action,
        'details': details,
        'timestamp': DateTime.now().toIso8601String(),
      };
      rawList.insert(0, jsonEncode(entry));
      if (rawList.length > 50) rawList.removeLast(); // Keep max 50 recent logs
      await _prefs.setStringList(_keyActivities, rawList);
    } catch (e) {
      debugPrint('logActivity error: $e');
    }
  }

  // ===========================================================================
  // 5. CHAT SESSIONS STORAGE (Local Cache)
  // ===========================================================================
  Future<void> saveChatSessions(List<Map<String, dynamic>> sessionsJson) async {
    try {
      final encoded = sessionsJson.map((s) => jsonEncode(s)).toList();
      await _prefs.setStringList(_keyChatSessions, encoded);
    } catch (e) {
      debugPrint('saveChatSessions error: $e');
    }
  }

  List<Map<String, dynamic>> getChatSessions() {
    try {
      final rawList = _prefs.getStringList(_keyChatSessions);
      if (rawList == null || rawList.isEmpty) return [];

      final List<Map<String, dynamic>> list = [];
      for (var str in rawList) {
        try {
          list.add(Map<String, dynamic>.from(jsonDecode(str) as Map));
        } catch (_) {}
      }
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<void> clearChatSessions() async {
    try {
      await _prefs.remove(_keyChatSessions);
    } catch (e) {
      debugPrint('clearChatSessions error: $e');
    }
  }

  // ===========================================================================
  // 9. NOTIFICATIONS STORAGE
  // ===========================================================================
  Future<void> saveNotifications(List<Map<String, dynamic>> notificationsJson) async {
    try {
      final encoded = notificationsJson.map((n) => jsonEncode(n)).toList();
      await _prefs.setStringList(_keyNotifications, encoded);
    } catch (e) {
      debugPrint('saveNotifications error: $e');
    }
  }

  List<Map<String, dynamic>> getNotifications() {
    try {
      final rawList = _prefs.getStringList(_keyNotifications);
      if (rawList == null || rawList.isEmpty) return [];

      final List<Map<String, dynamic>> list = [];
      for (var str in rawList) {
        try {
          list.add(Map<String, dynamic>.from(jsonDecode(str) as Map));
        } catch (_) {}
      }
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<void> clearNotifications() async {
    try {
      await _prefs.remove(_keyNotifications);
    } catch (e) {
      debugPrint('clearNotifications error: $e');
    }
  }
}
