import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService extends ChangeNotifier {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  late SharedPreferences _prefs;

  // Keys
  static const String _keySessionToken = 'user_session_token_enc';
  static const String _keyUserId = 'user_session_id_enc';
  static const String _keyIsPremium = 'user_is_premium_enc';
  static const String _keySubscriptionTier = 'user_subscription_tier_enc';
  static const String _keySubscriptionExpiry = 'user_subscription_expiry_enc';
  static const String _keyEncryptionKey = 'hive_master_encryption_key_enc';

  String? _sessionToken;
  String? _userId;
  bool _isPremium = false;
  String _subscriptionTier = 'Free Trial';
  String? _subscriptionExpiry;

  String? get sessionToken => _sessionToken;
  String? get userId => _userId;
  bool get isPremium => _isPremium;
  String get subscriptionTier => _subscriptionTier;
  String? get subscriptionExpiry => _subscriptionExpiry;

  // Helper XOR obfuscation key
  static const String _xorSalt = 'NutriMarketSecureSalt9948!';

  String _encryptString(String value) {
    final bytes = utf8.encode(value);
    final saltBytes = utf8.encode(_xorSalt);
    final result = List<int>.generate(bytes.length, (i) => bytes[i] ^ saltBytes[i % saltBytes.length]);
    return base64Url.encode(result);
  }

  String? _decryptString(String? encrypted) {
    if (encrypted == null || encrypted.isEmpty) return null;
    try {
      final bytes = base64Url.decode(encrypted);
      final saltBytes = utf8.encode(_xorSalt);
      final result = List<int>.generate(bytes.length, (i) => bytes[i] ^ saltBytes[i % saltBytes.length]);
      return utf8.decode(result);
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      _sessionToken = _decryptString(_prefs.getString(_keySessionToken));
      _userId = _decryptString(_prefs.getString(_keyUserId));
      final isPremStr = _decryptString(_prefs.getString(_keyIsPremium));
      _isPremium = isPremStr == 'true';
      _subscriptionTier = _decryptString(_prefs.getString(_keySubscriptionTier)) ?? 'Free Trial';
      _subscriptionExpiry = _decryptString(_prefs.getString(_keySubscriptionExpiry));

      // Hapus auto-generated dummy session agar saat fresh install/logout user berada di state belum login
      // Session hanya akan tersimpan jika user telah sukses login atau register
      if (isPremStr == null) {
        _isPremium = false;
        _subscriptionTier = 'Free Trial';
      }
    } catch (e) {
      debugPrint('SecureStorageService init error: $e');
    }
  }

  /// Get or create 256-bit Master Encryption Key for Hive encrypted boxes
  Future<List<int>> getOrCreateMasterKey() async {
    String? existingKey = _decryptString(_prefs.getString(_keyEncryptionKey));
    if (existingKey == null) {
      final keyBytes = List<int>.generate(32, (i) => (DateTime.now().microsecondsSinceEpoch + i * 37) % 256);
      existingKey = base64UrlEncode(keyBytes);
      await _prefs.setString(_keyEncryptionKey, _encryptString(existingKey));
    }
    return base64Url.decode(existingKey);
  }

  /// Save User Session Credentials securely
  Future<void> saveSessionCredentials({required String token, required String userId}) async {
    _sessionToken = token;
    _userId = userId;
    await _prefs.setString(_keySessionToken, _encryptString(token));
    await _prefs.setString(_keyUserId, _encryptString(userId));
    notifyListeners();
  }

  /// Save Monetization / Subscription status securely
  Future<void> saveSubscriptionStatus({
    required bool isPremium,
    required String subscriptionTier,
    String? expiryDate,
  }) async {
    _isPremium = isPremium;
    _subscriptionTier = subscriptionTier;
    _subscriptionExpiry = expiryDate;

    await _prefs.setString(_keyIsPremium, _encryptString(isPremium ? 'true' : 'false'));
    await _prefs.setString(_keySubscriptionTier, _encryptString(subscriptionTier));
    if (expiryDate != null) {
      await _prefs.setString(_keySubscriptionExpiry, _encryptString(expiryDate));
    }
    notifyListeners();
  }

  /// Clear session credentials on logout
  Future<void> clearSession() async {
    _sessionToken = null;
    _userId = null;
    await _prefs.remove(_keySessionToken);
    await _prefs.remove(_keyUserId);
    notifyListeners();
  }
}
