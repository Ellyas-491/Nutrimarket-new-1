import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:clev_ai/features/notifications/models/app_notification.dart';
import 'package:clev_ai/features/ai_assistant/models/chat_message.dart';
import 'package:clev_ai/features/ai_assistant/models/chat_session.dart';
import 'package:clev_ai/features/orders/models/saved_address.dart';
import 'package:clev_ai/features/auth/models/user_profile.dart';
import 'package:clev_ai/data/local/local_storage_service.dart';
import 'package:clev_ai/features/orders/services/location_service.dart';
import 'package:clev_ai/features/notifications/services/notification_service.dart';
import 'package:clev_ai/data/local/secure_storage_service.dart';
import 'package:clev_ai/data/remote/supabase_service.dart';

class HistoryService extends ChangeNotifier {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal() {
    _initRealLocation();
  }

  final List<ChatSession> _sessions = [];
  final List<UserProfile> _profiles = [
    const UserProfile(
      name: 'Pengguna NutriMarket',
      email: '',
      age: 25,
      heightCm: 170,
      weightKg: 65,
      activityLevel: 'Moderate',
      dietaryType: 'General Sehat',
      dietaryPreferences: ['Rendah Gula', 'Tinggi Serat'],
      foodAllergies: [],
      healthGoal: 'Gaya Hidup Sehat',
      isPremium: false,
      address: 'Mendeteksi lokasi GPS Anda...',
      addressLabel: 'Lokasi Saya',
      addressDetail: '',
    ),
  ];
  int _activeProfileIndex = 0;

  // Real user saved addresses list (No dummy data!)
  final List<SavedAddress> _savedAddresses = [];

  List<ChatSession> get sessions => List.unmodifiable(_sessions);
  List<UserProfile> get allProfiles => List.unmodifiable(_profiles);
  int get activeProfileIndex => _activeProfileIndex;
  UserProfile get userProfile => _profiles.isNotEmpty && _activeProfileIndex < _profiles.length
      ? _profiles[_activeProfileIndex]
      : const UserProfile(
          name: 'Pengguna',
          age: 25,
          heightCm: 170,
          weightKg: 65,
          activityLevel: 'Moderate',
          dietaryPreferences: [],
          foodAllergies: [],
          healthGoal: 'Gaya Hidup Sehat',
        );
  List<SavedAddress> get savedAddresses => List.unmodifiable(_savedAddresses);

  void initFromLocalStorage() {
    final cachedProfileJson = LocalStorageService().getUserProfile();
    if (cachedProfileJson != null) {
      try {
        final cachedProfile = UserProfile.fromMap(cachedProfileJson);
        _profiles.clear();
        _profiles.add(cachedProfile);
        _activeProfileIndex = 0;
        debugPrint('[HistoryService] Berhasil memuat profil pengguna offline dari Local Storage: ${cachedProfile.name}');
      } catch (e) {
        debugPrint('[HistoryService] Error loading cached profile: $e');
      }
    }

    final cachedAddrsJson = LocalStorageService().getSavedAddresses();
    if (cachedAddrsJson.isNotEmpty) {
      try {
        _savedAddresses.clear();
        for (var a in cachedAddrsJson) {
          _savedAddresses.add(SavedAddress.fromJson(a));
        }
      } catch (e) {
        debugPrint('[HistoryService] Error loading cached addresses: $e');
      }
    }
    _safeNotify();
  }

  void _persistAddresses() {
    try {
      LocalStorageService().saveSavedAddresses(_savedAddresses.map((a) => a.toJson()).toList());
    } catch (_) {}
  }

  void resetForNewUser(UserProfile profile) {
    _profiles.clear();
    _profiles.add(profile);
    _activeProfileIndex = 0;
    _sessions.clear();
    _savedAddresses.clear();
    LocalStorageService().saveUserProfile(profile.toMap());
    _persistAddresses();
    _initRealLocation();
    _safeNotify();
  }

  void clearForLogout() {
    _sessions.clear();
    _savedAddresses.clear();
    _profiles.clear();
    _profiles.add(const UserProfile(
      name: 'Pengguna Baru',
      email: '',
      age: 25,
      heightCm: 170,
      weightKg: 65,
      activityLevel: 'Moderate',
      dietaryType: 'General Sehat',
      dietaryPreferences: ['Rendah Gula', 'Tinggi Serat'],
      foodAllergies: [],
      healthGoal: 'Gaya Hidup Sehat Seimbang',
      isPremium: false,
    ));
    _activeProfileIndex = 0;
    LocalStorageService().clearUserProfile();
    LocalStorageService().saveSavedAddresses([]);
    _safeNotify();
  }

  void switchProfile(int index) {
    if (index >= 0 && index < _profiles.length) {
      _activeProfileIndex = index;
      _safeNotify();
    }
  }

  void addProfile(UserProfile profile) {
    _profiles.add(profile);
    _activeProfileIndex = _profiles.length - 1;
    _safeNotify();
  }

  void deleteProfile(int index) {
    if (_profiles.length > 1 && index >= 0 && index < _profiles.length) {
      _profiles.removeAt(index);
      if (_activeProfileIndex >= _profiles.length) {
        _activeProfileIndex = _profiles.length - 1;
      }
      _safeNotify();
    }
  }

  SavedAddress get primaryAddress => _savedAddresses.firstWhere(
        (a) => a.isPrimary,
        orElse: () => SavedAddress(
          id: 'addr_live_current',
          label: userProfile.addressLabel,
          recipientName: userProfile.name,
          phoneNumber: '',
          fullAddress: userProfile.address,
          notes: userProfile.addressDetail,
          isPrimary: true,
        ),
      );

  Future<void> _initRealLocation() async {
    try {
      final loc = await LocationService().getCurrentUserLocation();
      final liveAddress = SavedAddress(
        id: 'addr_gps_real',
        label: 'Lokasi GPS Saya',
        recipientName: userProfile.name,
        phoneNumber: '',
        fullAddress: loc.formattedAddress,
        notes: '',
        latitude: loc.latitude,
        longitude: loc.longitude,
        isPrimary: true,
      );

      if (_savedAddresses.isEmpty) {
        _savedAddresses.add(liveAddress);
      } else {
        _savedAddresses[0] = liveAddress;
      }

      if (_profiles.isNotEmpty && _activeProfileIndex < _profiles.length) {
        _profiles[_activeProfileIndex] = _profiles[_activeProfileIndex].copyWith(
          address: loc.formattedAddress,
          addressLabel: 'Lokasi GPS Saya',
          addressDetail: '',
        );
      }
      _safeNotify();
    } catch (e) {
      debugPrint('Error init real location: $e');
    }
  }

  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  void syncWithSecureStorage() {
    final secStorage = SecureStorageService();
    if (_profiles.isNotEmpty && _activeProfileIndex < _profiles.length) {
      _profiles[_activeProfileIndex] = _profiles[_activeProfileIndex].copyWith(
        isPremium: secStorage.isPremium,
      );
      _safeNotify();
    }
  }

  void updateUserProfile(UserProfile newProfile, {bool notifyUser = true}) {
    if (_profiles.isNotEmpty && _activeProfileIndex < _profiles.length) {
      _profiles[_activeProfileIndex] = newProfile;
    } else {
      _profiles.add(newProfile);
      _activeProfileIndex = 0;
    }

    // Save profile locally for offline-first support
    LocalStorageService().saveUserProfile(newProfile.toMap());

    // Save monetization / subscription status securely
    SecureStorageService().saveSubscriptionStatus(
      isPremium: newProfile.isPremium,
      subscriptionTier: newProfile.isPremium ? 'Nutri-VIP Premium' : 'Free Trial',
    );

    // Sync to Supabase Cloud
    final supabase = SupabaseService();
    if (supabase.isConfigured && supabase.currentUser != null) {
      supabase.saveUserProfile(newProfile).catchError((e) {
        debugPrint('[HistoryService] Error saveUserProfile to Supabase: $e');
      });
    }

    if (notifyUser && newProfile.name.isNotEmpty && newProfile.age > 0) {
      NotificationService().addNotification(
        title: 'Profil Kesehatan Diperbarui 🩺',
        message: 'Data fisik (${newProfile.weightKg.toInt()} kg / ${newProfile.heightCm.toInt()} cm), target (${newProfile.healthGoal}), dan preferensi diet Anda berhasil disinkronkan.',
        category: NotificationCategory.health,
        isImportant: false,
      );
    }

    _safeNotify();
  }

  // Real Address Management
  void addSavedAddress(SavedAddress address, {bool setAsPrimary = true}) {
    if (setAsPrimary) {
      for (int i = 0; i < _savedAddresses.length; i++) {
        _savedAddresses[i] = _savedAddresses[i].copyWith(isPrimary: false);
      }
      _savedAddresses.insert(0, address.copyWith(isPrimary: true));
      if (_profiles.isNotEmpty && _activeProfileIndex < _profiles.length) {
        _profiles[_activeProfileIndex] = _profiles[_activeProfileIndex].copyWith(
          address: address.fullAddress,
          addressLabel: address.label,
          addressDetail: address.notes,
        );
        LocalStorageService().saveUserProfile(_profiles[_activeProfileIndex].toMap());

        final supabase = SupabaseService();
        if (supabase.isConfigured && supabase.currentUser != null) {
          supabase.saveUserProfile(_profiles[_activeProfileIndex]);
        }
      }
    } else {
      _savedAddresses.add(address);
    }

    final supabase = SupabaseService();
    if (supabase.isConfigured && supabase.currentUser != null) {
      supabase.saveSavedAddress(address).catchError((e) {
        debugPrint('[HistoryService] Error saveSavedAddress to Supabase: $e');
      });
    }

    _persistAddresses();
    _safeNotify();
  }

  void updateSavedAddress(SavedAddress address) {
    final index = _savedAddresses.indexWhere((a) => a.id == address.id);
    if (index >= 0) {
      _savedAddresses[index] = address;
      if (address.isPrimary && _profiles.isNotEmpty && _activeProfileIndex < _profiles.length) {
        _profiles[_activeProfileIndex] = _profiles[_activeProfileIndex].copyWith(
          address: address.fullAddress,
          addressLabel: address.label,
          addressDetail: address.notes,
        );
        LocalStorageService().saveUserProfile(_profiles[_activeProfileIndex].toMap());

        final supabase = SupabaseService();
        if (supabase.isConfigured && supabase.currentUser != null) {
          supabase.saveUserProfile(_profiles[_activeProfileIndex]);
        }
      }

      final supabase = SupabaseService();
      if (supabase.isConfigured && supabase.currentUser != null) {
        supabase.saveSavedAddress(address).catchError((e) {
          debugPrint('[HistoryService] Error updateSavedAddress to Supabase: $e');
        });
      }

      _persistAddresses();
      _safeNotify();
    }
  }

  void deleteSavedAddress(String id) {
    final wasPrimary = _savedAddresses.any((a) => a.id == id && a.isPrimary);
    _savedAddresses.removeWhere((a) => a.id == id);
    if (wasPrimary && _savedAddresses.isNotEmpty) {
      _savedAddresses[0] = _savedAddresses[0].copyWith(isPrimary: true);
      if (_profiles.isNotEmpty && _activeProfileIndex < _profiles.length) {
        _profiles[_activeProfileIndex] = _profiles[_activeProfileIndex].copyWith(
          address: _savedAddresses[0].fullAddress,
          addressLabel: _savedAddresses[0].label,
          addressDetail: _savedAddresses[0].notes,
        );
        LocalStorageService().saveUserProfile(_profiles[_activeProfileIndex].toMap());

        final supabase = SupabaseService();
        if (supabase.isConfigured && supabase.currentUser != null) {
          supabase.saveUserProfile(_profiles[_activeProfileIndex]);
        }
      }
    }

    final supabase = SupabaseService();
    if (supabase.isConfigured && supabase.currentUser != null) {
      supabase.deleteSavedAddress(id).catchError((e) {
        debugPrint('[HistoryService] Error deleteSavedAddress in Supabase: $e');
      });
    }

    _persistAddresses();
    _safeNotify();
  }

  void setPrimaryAddress(String id) {
    for (int i = 0; i < _savedAddresses.length; i++) {
      final isTarget = _savedAddresses[i].id == id;
      _savedAddresses[i] = _savedAddresses[i].copyWith(isPrimary: isTarget);
      if (isTarget && _profiles.isNotEmpty && _activeProfileIndex < _profiles.length) {
        _profiles[_activeProfileIndex] = _profiles[_activeProfileIndex].copyWith(
          address: _savedAddresses[i].fullAddress,
          addressLabel: _savedAddresses[i].label,
          addressDetail: _savedAddresses[i].notes,
        );
        LocalStorageService().saveUserProfile(_profiles[_activeProfileIndex].toMap());

        final supabase = SupabaseService();
        if (supabase.isConfigured && supabase.currentUser != null) {
          supabase.saveUserProfile(_profiles[_activeProfileIndex]);
        }
      }
    }
    _persistAddresses();
    _safeNotify();
  }

  bool executeAgentAction(String responseText) {
    final RegExp regExp = RegExp(r'\[AGENT_ACTION:\s*(\{.*?\})\]', dotAll: true);
    final match = regExp.firstMatch(responseText);
    if (match != null) {
      try {
        final jsonStr = match.group(1)!;
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          jsonDecode(jsonStr) as Map,
        );

        bool changed = false;

        String newName = userProfile.name;
        if (data['name'] != null) {
          final val = data['name'].toString().trim();
          if (val.isNotEmpty && val != '...' && val != 'nama_baru' && val != userProfile.name) {
            newName = val;
            changed = true;
          }
        }

        int newAge = userProfile.age;
        if (data['age'] != null) {
          final parsed = int.tryParse(data['age'].toString());
          if (parsed != null && parsed > 0 && parsed != userProfile.age) {
            newAge = parsed;
            changed = true;
          }
        }

        double newHeight = userProfile.heightCm;
        if (data['height'] != null) {
          final parsed = double.tryParse(data['height'].toString());
          if (parsed != null && parsed > 0 && parsed != userProfile.heightCm) {
            newHeight = parsed;
            changed = true;
          }
        }

        double newWeight = userProfile.weightKg;
        if (data['weight'] != null) {
          final parsed = double.tryParse(data['weight'].toString());
          if (parsed != null && parsed > 0 && parsed != userProfile.weightKg) {
            newWeight = parsed;
            changed = true;
          }
        }

        String newDiet = userProfile.dietaryType;
        if (data['diet'] != null || data['dietaryType'] != null) {
          final val = (data['diet'] ?? data['dietaryType']).toString().trim();
          if (val.isNotEmpty && val != '...' && val != userProfile.dietaryType) {
            newDiet = val;
            changed = true;
          }
        }

        String newGoal = userProfile.healthGoal;
        if (data['goal'] != null || data['healthGoal'] != null) {
          final val = (data['goal'] ?? data['healthGoal']).toString().trim();
          if (val.isNotEmpty && val != '...' && val != userProfile.healthGoal) {
            newGoal = val;
            changed = true;
          }
        }

        if (changed) {
          final updatedProfile = userProfile.copyWith(
            name: newName,
            age: newAge,
            heightCm: newHeight,
            weightKg: newWeight,
            dietaryType: newDiet,
            healthGoal: newGoal,
          );
          updateUserProfile(updatedProfile);
          return true;
        }
      } catch (e) {
        debugPrint('Error parsing AGENT_ACTION: $e');
      }
    }
    return false;
  }

  void _persistSessions() {
    try {
      final List<Map<String, dynamic>> sessionsJson = _sessions.map((s) {
        return {
          'id': s.id,
          'title': s.title,
          'category': s.category,
          'createdAt': s.createdAt.toIso8601String(),
          'messages': s.messages.map((m) {
            return {
              'id': m.id,
              'content': m.content,
              'isUser': m.isUser,
              'timestamp': m.timestamp.toIso8601String(),
            };
          }).toList(),
        };
      }).toList();

      LocalStorageService().saveChatSessions(sessionsJson);
    } catch (e) {
      debugPrint('HistoryService _persistSessions error: $e');
    }
  }

  Future<void> syncChatWithSupabase() async {
    final supabaseService = SupabaseService();
    if (!supabaseService.isConfigured || !supabaseService.isLoggedIn) return;

    try {
      final cloudSessions = await supabaseService.fetchUserChatSessions();
      if (cloudSessions.isNotEmpty) {
        _sessions.clear();
        _sessions.addAll(cloudSessions);
        _persistSessions();
        _safeNotify();
      }
    } catch (e) {
      debugPrint('[HistoryService] Gagal sync chat dari Supabase: $e');
    }
  }

  void initChatHistoryFromStorage() {
    try {
      final savedSessions = LocalStorageService().getChatSessions();
      if (savedSessions.isNotEmpty) {
        _sessions.clear();
        for (var item in savedSessions) {
          try {
            final rawMessages = item['messages'] as List? ?? [];
            final List<ChatMessage> messages = [];
            for (var m in rawMessages) {
              if (m is Map) {
                messages.add(ChatMessage(
                  id: m['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  content: m['content'] as String? ?? '',
                  isUser: m['isUser'] as bool? ?? false,
                  timestamp: DateTime.tryParse(m['timestamp'] as String? ?? '') ?? DateTime.now(),
                ));
              }
            }

            _sessions.add(ChatSession(
              id: item['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
              title: item['title'] as String? ?? 'Konsultasi',
              category: item['category'] as String? ?? 'AI',
              messages: messages,
              createdAt: DateTime.tryParse(item['createdAt'] as String? ?? '') ?? DateTime.now(),
            ));
          } catch (e) {
            debugPrint('Error restoring session: $e');
          }
        }
        _safeNotify();
      }
    } catch (e) {
      debugPrint('initChatHistoryFromStorage error: $e');
    }
  }

  ChatSession createSession({
    required String title,
    required String category,
  }) {
    final newSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: category,
      messages: [],
      createdAt: DateTime.now(),
    );
    _sessions.insert(0, newSession);
    _persistSessions();

    final supabaseService = SupabaseService();
    if (supabaseService.isConfigured && supabaseService.isLoggedIn) {
      supabaseService.saveChatSession(newSession);
    }

    _safeNotify();
    return newSession;
  }

  void addMessageToSession(String sessionId, ChatMessage message) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index >= 0) {
      _sessions[index].messages.add(message);
      _persistSessions();

      final supabaseService = SupabaseService();
      if (supabaseService.isConfigured && supabaseService.isLoggedIn) {
        supabaseService.saveChatMessage(sessionId, message);
      }

      _safeNotify();
    }
  }

  void deleteSession(String sessionId) {
    _sessions.removeWhere((s) => s.id == sessionId);
    _persistSessions();

    final supabaseService = SupabaseService();
    if (supabaseService.isConfigured && supabaseService.isLoggedIn) {
      supabaseService.deleteChatSession(sessionId);
    }

    _safeNotify();
  }

  void clearAllHistory() {
    _sessions.clear();
    _persistSessions();

    final supabaseService = SupabaseService();
    if (supabaseService.isConfigured && supabaseService.isLoggedIn) {
      supabaseService.clearAllChatSessions();
    }

    _safeNotify();
  }
}
