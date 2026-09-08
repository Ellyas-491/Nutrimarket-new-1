import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clev_ai/core/config/app_config.dart';
import 'package:clev_ai/features/cart/models/cart_item.dart';
import 'package:clev_ai/features/ai_assistant/models/chat_message.dart';
import 'package:clev_ai/features/ai_assistant/models/chat_session.dart';
import 'package:clev_ai/features/products/models/food_product.dart';
import 'package:clev_ai/features/orders/models/order.dart';
import 'package:clev_ai/features/orders/models/saved_address.dart';
import 'package:clev_ai/features/auth/models/user_profile.dart';
import 'package:clev_ai/core/utils/network_retry_helper.dart';

class SupabaseService extends ChangeNotifier {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isConfigured = false;
  bool _isInitialized = false;

  bool get isConfigured => _isConfigured;
  bool get isInitialized => _isInitialized;

  SupabaseClient? get client {
    if (!_isConfigured || !_isInitialized) return null;
    return Supabase.instance.client;
  }

  User? get currentUser => client?.auth.currentUser;
  Session? get currentSession => client?.auth.currentSession;
  bool get isLoggedIn => currentSession != null;
  Stream<AuthState>? get authStateChanges => client?.auth.onAuthStateChange;

  /// Initialize Supabase using environment variables from .env
  Future<void> init() async {
    final url = AppConfig.supabaseUrl.trim();
    final anonKey = AppConfig.supabaseAnonKey.trim();

    final isValidUrl = url.isNotEmpty &&
        !url.contains('your-project-id') &&
        url.startsWith('https://');
    final isValidKey = anonKey.isNotEmpty && !anonKey.contains('your-anon-public-key');

    if (!isValidUrl || !isValidKey) {
      debugPrint('[SupabaseService] Kredensial SUPABASE_URL atau SUPABASE_ANON_KEY belum diisi.');
      _isConfigured = false;
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _isConfigured = true;
      _isInitialized = true;
      debugPrint('[SupabaseService] Berhasil terhubung ke database Supabase: $url');
    } catch (e) {
      debugPrint('[SupabaseService] Gagal inisialisasi: $e');
      _isConfigured = false;
      _isInitialized = true;
    }
    notifyListeners();
  }

  // ===========================================================================
  // 1. AUTHENTICATION
  // ===========================================================================

  /// Sign Up with Email, Password, and Full Name
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (!_isConfigured || client == null) {
      throw const AuthException(
        'Supabase belum terkonfigurasi. Silakan masukkan SUPABASE_URL dan SUPABASE_ANON_KEY di file .env Anda.',
      );
    }

    try {
      final response = await client!.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
        },
      );

      final user = response.user;
      if (user != null) {
        try {
          await client!.from('profiles').upsert({
            'id': user.id,
            'email': email.trim(),
            'full_name': fullName.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (dbError) {
          debugPrint('[SupabaseService] Profile sync error: $dbError');
        }
      }

      notifyListeners();
      return response;
    } on AuthException catch (e) {
      throw _parseAuthError(e);
    } catch (e) {
      throw AuthException('Gagal mendaftar: ${e.toString()}');
    }
  }

  /// Sign In with Email and Password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    if (!_isConfigured || client == null) {
      throw const AuthException(
        'Supabase belum terkonfigurasi. Silakan masukkan SUPABASE_URL dan SUPABASE_ANON_KEY di file .env Anda.',
      );
    }

    try {
      final response = await client!.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      notifyListeners();
      return response;
    } on AuthException catch (e) {
      throw _parseAuthError(e);
    } catch (e) {
      throw AuthException('Gagal masuk: ${e.toString()}');
    }
  }

  /// Reset Password via Email
  Future<void> resetPassword(String email) async {
    if (!_isConfigured || client == null) {
      throw const AuthException('Supabase belum terkonfigurasi di file .env.');
    }

    try {
      await client!.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw _parseAuthError(e);
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    if (client != null) {
      try {
        await client!.auth.signOut();
      } catch (e) {
        debugPrint('[SupabaseService] SignOut error: $e');
      }
    }
    notifyListeners();
  }

  /// Sign In with Google via Supabase OAuth
  Future<bool> signInWithGoogle() async {
    if (!_isConfigured || client == null) {
      throw const AuthException(
        'Supabase belum terkonfigurasi. Silakan masukkan SUPABASE_URL dan SUPABASE_ANON_KEY di file .env Anda.',
      );
    }

    try {
      final success = await client!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.nutrimarket://login-callback/',
      );
      notifyListeners();
      return success;
    } on AuthException catch (e) {
      throw _parseAuthError(e);
    } catch (e) {
      throw AuthException('Gagal masuk dengan Google: ${e.toString()}');
    }
  }

  // ===========================================================================
  // 2. PRODUCTS DATABASE (Public Catalogue)
  // ===========================================================================

  Future<List<FoodProduct>> fetchProducts() async {
    if (!_isConfigured || client == null) return [];

    return NetworkRetryHelper.execute<List<FoodProduct>>(
      () async {
        final List<dynamic> data = await client!.from('products').select().order('name');
        return data.map((json) => FoodProduct.fromMap(Map<String, dynamic>.from(json as Map))).toList();
      },
      maxAttempts: 3,
      timeoutDuration: const Duration(seconds: 8),
      actionName: 'FetchProducts',
      fallbackValue: [],
    );
  }

  Future<void> addProduct(FoodProduct product) async {
    if (!_isConfigured || client == null) return;

    return NetworkRetryHelper.execute<void>(
      () async {
        await client!.from('products').upsert(product.toMap());
        debugPrint('[SupabaseService] Berhasil menyimpan produk makanan ke database: ${product.name}');
      },
      maxAttempts: 2,
      timeoutDuration: const Duration(seconds: 8),
      actionName: 'AddProduct',
    );
  }

  Future<void> deleteProduct(String id) async {
    if (!_isConfigured || client == null) return;

    return NetworkRetryHelper.execute<void>(
      () async {
        await client!.from('products').delete().eq('id', id);
        debugPrint('[SupabaseService] Berhasil menghapus produk makanan dari database: $id');
      },
      maxAttempts: 2,
      timeoutDuration: const Duration(seconds: 8),
      actionName: 'DeleteProduct',
    );
  }

  // ===========================================================================
  // 3. PROFILES DATABASE (User Specific)
  // ===========================================================================

  Future<UserProfile?> fetchUserProfile() async {
    final user = currentUser;
    if (user == null || client == null) return null;

    return NetworkRetryHelper.execute<UserProfile?>(
      () async {
        final data = await client!
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (data != null) {
          return UserProfile.fromMap(
            Map<String, dynamic>.from(data),
            defaultEmail: user.email,
          );
        }

        final fullName = user.userMetadata?['full_name'] as String? ?? user.email?.split('@').first ?? 'Pengguna NutriMarket';
        return UserProfile(
          name: fullName,
          email: user.email ?? 'user@nutrimarket.id',
        );
      },
      maxAttempts: 3,
      timeoutDuration: const Duration(seconds: 8),
      actionName: 'FetchUserProfile',
      fallbackValue: null,
    );
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final user = currentUser;
    if (user == null || client == null) return;

    return NetworkRetryHelper.execute<void>(
      () async {
        final mapData = profile.toMap();
        mapData['id'] = user.id;
        await client!.from('profiles').upsert(mapData);
      },
      maxAttempts: 3,
      timeoutDuration: const Duration(seconds: 8),
      actionName: 'SaveUserProfile',
      fallbackValue: null,
    );
  }

  // ===========================================================================
  // 4. FAVORITES DATABASE (User Specific)
  // ===========================================================================

  Future<List<String>> fetchUserFavorites() async {
    final user = currentUser;
    if (user == null || client == null) return [];

    try {
      final List<dynamic> data = await client!
          .from('favorites')
          .select('product_id')
          .eq('user_id', user.id);

      return data.map((item) => item['product_id'] as String).toList();
    } catch (e) {
      debugPrint('[SupabaseService] Gagal fetch favorites: $e');
      return [];
    }
  }

  Future<void> addFavorite(String productId) async {
    final user = currentUser;
    if (user == null || client == null) return;

    try {
      await client!.from('favorites').upsert({
        'user_id': user.id,
        'product_id': productId,
      });
    } catch (e) {
      debugPrint('[SupabaseService] Gagal tambah favorit: $e');
    }
  }

  Future<void> removeFavorite(String productId) async {
    final user = currentUser;
    if (user == null || client == null) return;

    try {
      await client!
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('product_id', productId);
    } catch (e) {
      debugPrint('[SupabaseService] Gagal hapus favorit: $e');
    }
  }

  // ===========================================================================
  // 5. SAVED ADDRESSES DATABASE (User Specific)
  // ===========================================================================

  Future<List<SavedAddress>> fetchUserAddresses() async {
    final user = currentUser;
    if (user == null || client == null) return [];

    return NetworkRetryHelper.execute<List<SavedAddress>>(
      () async {
        final List<dynamic> data = await client!
            .from('saved_addresses')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        return data.map((item) => SavedAddress.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      },
      maxAttempts: 3,
      timeoutDuration: const Duration(seconds: 8),
      actionName: 'FetchUserAddresses',
      fallbackValue: [],
    );
  }

  Future<void> saveAddress(SavedAddress address) async {
    final user = currentUser;
    if (user == null || client == null) return;

    return NetworkRetryHelper.execute<void>(
      () async {
        final json = address.toJson();
        json['user_id'] = user.id;
        await client!.from('saved_addresses').upsert(json);
      },
      maxAttempts: 3,
      timeoutDuration: const Duration(seconds: 8),
      actionName: 'SaveAddress',
      fallbackValue: null,
    );
  }

  Future<void> saveSavedAddress(SavedAddress address) => saveAddress(address);

  Future<void> deleteAddress(String addressId) async {
    final user = currentUser;
    if (user == null || client == null) return;

    return NetworkRetryHelper.execute<void>(
      () async {
        await client!.from('saved_addresses').delete().eq('id', addressId).eq('user_id', user.id);
      },
      maxAttempts: 3,
      timeoutDuration: const Duration(seconds: 8),
      actionName: 'DeleteAddress',
      fallbackValue: null,
    );
  }

  Future<void> deleteSavedAddress(String addressId) => deleteAddress(addressId);

  // ===========================================================================
  // 6. ORDERS & ORDER ITEMS DATABASE (User Specific)
  // ===========================================================================

  Future<List<OrderModel>> fetchUserOrders(List<FoodProduct> availableProducts) async {
    final user = currentUser;
    if (user == null || client == null) return [];

    return NetworkRetryHelper.execute<List<OrderModel>>(
      () async {
        final List<dynamic> ordersData = await client!
            .from('orders')
            .select('*, order_items(*)')
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        final List<OrderModel> result = [];

        for (var o in ordersData) {
          final orderMap = Map<String, dynamic>.from(o as Map);
          final itemsRaw = orderMap['order_items'] as List<dynamic>? ?? [];

          final List<CartItem> cartItems = [];
          for (var it in itemsRaw) {
            final itemMap = Map<String, dynamic>.from(it as Map);
            final prodId = itemMap['product_id'] as String;

            FoodProduct product = availableProducts.firstWhere(
              (p) => p.id == prodId,
              orElse: () => FoodProduct(
                id: prodId,
                name: itemMap['product_name'] as String? ?? 'Menu Sehat',
                category: 'Healthy Meals',
                price: (itemMap['product_price'] as num?)?.toDouble() ?? 30000,
                rating: 4.8,
                reviewCount: 10,
                imageUrl: itemMap['product_image'] as String? ?? '',
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
                nutritionistName: 'Ahli Gizi NutriMarket',
                nutritionistReview: 'Menu terverifikasi',
              ),
            );

            cartItems.add(CartItem(
              product: product,
              quantity: (itemMap['quantity'] as num?)?.toInt() ?? 1,
              sellerNotes: itemMap['seller_notes'] as String? ?? '',
            ));
          }

          final statusIndex = (orderMap['status'] as num?)?.toInt() ?? 0;
          final status = statusIndex < OrderStatus.values.length
              ? OrderStatus.values[statusIndex]
              : OrderStatus.pendingPayment;

          OrderReview? orderReview;
          if (orderMap['review_json'] != null) {
            try {
              final revMap = Map<String, dynamic>.from(orderMap['review_json'] as Map);
              orderReview = OrderReview(
                foodQualityScore: (revMap['food_quality_score'] as num?)?.toDouble() ?? 5.0,
                packagingScore: (revMap['packaging_score'] as num?)?.toDouble() ?? 5.0,
                deliveryScore: (revMap['delivery_score'] as num?)?.toDouble() ?? 5.0,
                comments: revMap['comments'] as String? ?? '',
                createdAt: DateTime.tryParse(revMap['created_at'] as String? ?? '') ?? DateTime.now(),
              );
            } catch (e) {
              debugPrint('Error parsing order review_json: $e');
            }
          }

          result.add(OrderModel(
            id: orderMap['id'] as String,
            items: cartItems,
            subtotal: (orderMap['subtotal'] as num?)?.toDouble() ?? 0,
            deliveryFee: (orderMap['delivery_fee'] as num?)?.toDouble() ?? 0,
            serviceFee: (orderMap['service_fee'] as num?)?.toDouble() ?? 2000,
            discount: (orderMap['discount'] as num?)?.toDouble() ?? 0,
            total: (orderMap['total'] as num?)?.toDouble() ?? 0,
            status: status,
            orderDate: DateTime.tryParse(orderMap['created_at'] as String? ?? '') ?? DateTime.now(),
            estimatedDelivery: orderMap['estimated_delivery'] as String? ?? '20-30 Menit',
            deliveryAddress: orderMap['delivery_address'] as String? ?? '',
            deliveryOption: orderMap['delivery_option'] as String? ?? 'Instant Delivery',
            orderNotes: orderMap['order_notes'] as String? ?? '',
            paymentMethod: orderMap['payment_method'] as String? ?? 'QRIS Instant Pay',
            paymentReference: orderMap['payment_reference'] as String? ?? 'QRIS-NM-994821',
            deliveryPhotoUrl: orderMap['delivery_photo_url'] as String?,
            review: orderReview,
          ));
        }

        return result;
      },
      maxAttempts: 3,
      timeoutDuration: const Duration(seconds: 8),
      actionName: 'FetchUserOrders',
      fallbackValue: [],
    );
  }

  Future<void> createOrder(OrderModel order) async {
    final user = currentUser;
    if (user == null || client == null) return;

    return NetworkRetryHelper.execute<void>(
      () async {
        // 1. Insert order header
        await client!.from('orders').insert({
          'id': order.id,
          'user_id': user.id,
          'subtotal': order.subtotal,
          'delivery_fee': order.deliveryFee,
          'service_fee': order.serviceFee,
          'discount': order.discount,
          'total': order.total,
          'status': order.status.index,
          'estimated_delivery': order.estimatedDelivery,
          'delivery_address': order.deliveryAddress,
          'delivery_option': order.deliveryOption,
          'order_notes': order.orderNotes,
          'payment_method': order.paymentMethod,
          'payment_reference': order.paymentReference,
          'delivery_photo_url': order.deliveryPhotoUrl ?? '',
          'created_at': order.orderDate.toIso8601String(),
        });

        // 2. Insert order items
        final List<Map<String, dynamic>> itemsPayload = order.items.map((it) {
          return {
            'order_id': order.id,
            'product_id': it.product.id,
            'product_name': it.product.name,
            'product_image': it.product.imageUrl,
            'product_price': it.product.price,
            'quantity': it.quantity,
            'seller_notes': it.sellerNotes,
          };
        }).toList();

        if (itemsPayload.isNotEmpty) {
          await client!.from('order_items').insert(itemsPayload);
        }
      },
      maxAttempts: 3,
      timeoutDuration: const Duration(seconds: 10),
      actionName: 'CreateOrder',
      fallbackValue: null,
    );
  }

  Future<void> updateOrderStatus(String orderId, int statusIndex, String estimatedDelivery, {String? deliveryPhotoUrl}) async {
    final user = currentUser;
    if (user == null || client == null) return;

    return NetworkRetryHelper.execute<void>(
      () async {
        final payload = <String, dynamic>{
          'status': statusIndex,
          'estimated_delivery': estimatedDelivery,
        };
        if (deliveryPhotoUrl != null && deliveryPhotoUrl.isNotEmpty) {
          payload['delivery_photo_url'] = deliveryPhotoUrl;
        }
        await client!.from('orders').update(payload).eq('id', orderId).eq('user_id', user.id);
      },
      maxAttempts: 3,
      timeoutDuration: const Duration(seconds: 8),
      actionName: 'UpdateOrderStatus',
      fallbackValue: null,
    );
  }

  Future<void> saveOrderReview(String orderId, Map<String, dynamic> reviewJson) async {
    final user = currentUser;
    if (user == null || client == null) return;

    return NetworkRetryHelper.execute<void>(
      () async {
        await client!.from('orders').update({
          'review_json': reviewJson,
        }).eq('id', orderId).eq('user_id', user.id);
      },
      maxAttempts: 3,
      timeoutDuration: const Duration(seconds: 8),
      actionName: 'SaveOrderReview',
      fallbackValue: null,
    );
  }

  // ===========================================================================
  // 7. USER CART DATABASE (Cloud Synchronized Cart)
  // ===========================================================================

  Future<List<CartItem>> fetchUserCart(List<FoodProduct> availableProducts) async {
    final user = currentUser;
    if (user == null || client == null) return [];

    try {
      final List<dynamic> data = await client!
          .from('user_cart')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      final List<CartItem> result = [];
      for (var item in data) {
        final map = Map<String, dynamic>.from(item as Map);
        final prodId = map['product_id'] as String;
        final qty = (map['quantity'] as num?)?.toInt() ?? 1;
        final notes = map['seller_notes'] as String? ?? '';

        final product = availableProducts.firstWhere(
          (p) => p.id == prodId,
          orElse: () => FoodProduct(
            id: prodId,
            name: map['product_name'] as String? ?? 'Menu Sehat',
            category: 'Healthy Meals',
            price: (map['product_price'] as num?)?.toDouble() ?? 30000,
            rating: 4.8,
            reviewCount: 10,
            imageUrl: map['product_image'] as String? ?? '',
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

        result.add(CartItem(
          product: product,
          quantity: qty,
          sellerNotes: notes,
        ));
      }
      return result;
    } catch (e) {
      debugPrint('[SupabaseService] Gagal fetch user_cart: $e');
      return [];
    }
  }

  Future<void> saveUserCartItem(FoodProduct product, int quantity, String sellerNotes) async {
    final user = currentUser;
    if (user == null || client == null) return;

    try {
      await client!.from('user_cart').upsert({
        'user_id': user.id,
        'product_id': product.id,
        'product_name': product.name,
        'product_image': product.imageUrl,
        'product_price': product.price,
        'quantity': quantity,
        'seller_notes': sellerNotes,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SupabaseService] Gagal simpan cart item: $e');
    }
  }

  Future<void> removeUserCartItem(String productId) async {
    final user = currentUser;
    if (user == null || client == null) return;

    try {
      await client!
          .from('user_cart')
          .delete()
          .eq('user_id', user.id)
          .eq('product_id', productId);
    } catch (e) {
      debugPrint('[SupabaseService] Gagal hapus cart item: $e');
    }
  }

  Future<void> clearUserCart() async {
    final user = currentUser;
    if (user == null || client == null) return;

    try {
      await client!.from('user_cart').delete().eq('user_id', user.id);
    } catch (e) {
      debugPrint('[SupabaseService] Gagal clear cart: $e');
    }
  }

  // ===========================================================================
  // 8. AI CHAT SESSIONS DATABASE (Cloud Synchronized Chat History)
  // ===========================================================================

  Future<List<ChatSession>> fetchUserChatSessions() async {
    final user = currentUser;
    if (user == null || client == null) return [];

    try {
      final List<dynamic> sessionsData = await client!
          .from('chat_sessions')
          .select('*, chat_messages(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<ChatSession> result = [];
      for (var s in sessionsData) {
        final sMap = Map<String, dynamic>.from(s as Map);
        final rawMessages = sMap['chat_messages'] as List<dynamic>? ?? [];

        final List<ChatMessage> messages = [];
        for (var m in rawMessages) {
          final mMap = Map<String, dynamic>.from(m as Map);
          messages.add(ChatMessage(
            id: mMap['id'] as String? ?? UniqueKey().toString(),
            content: mMap['text'] as String? ?? '',
            isUser: mMap['is_user'] as bool? ?? false,
            timestamp: DateTime.tryParse(mMap['created_at'] as String? ?? '') ?? DateTime.now(),
          ));
        }

        // Sort messages chronologically
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        result.add(ChatSession(
          id: sMap['id'] as String,
          title: sMap['title'] as String? ?? 'Konsultasi Nutrisi',
          category: sMap['preview'] as String? ?? 'AI Health Assistant',
          messages: messages,
          createdAt: DateTime.tryParse(sMap['created_at'] as String? ?? '') ?? DateTime.now(),
        ));
      }
      return result;
    } catch (e) {
      debugPrint('[SupabaseService] Gagal fetch chat sessions: $e');
      return [];
    }
  }

  Future<void> saveChatSession(ChatSession session) async {
    final user = currentUser;
    if (user == null || client == null) return;

    try {
      await client!.from('chat_sessions').upsert({
        'id': session.id,
        'user_id': user.id,
        'title': session.title,
        'preview': session.category,
        'created_at': session.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SupabaseService] Gagal simpan chat session: $e');
    }
  }

  Future<void> saveChatMessage(String sessionId, ChatMessage message) async {
    final user = currentUser;
    if (user == null || client == null) return;

    try {
      await client!.from('chat_messages').insert({
        'session_id': sessionId,
        'user_id': user.id,
        'text': message.content,
        'is_user': message.isUser,
        'created_at': message.timestamp.toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SupabaseService] Gagal simpan chat message: $e');
    }
  }

  Future<void> deleteChatSession(String sessionId) async {
    final user = currentUser;
    if (user == null || client == null) return;

    try {
      await client!.from('chat_sessions').delete().eq('id', sessionId).eq('user_id', user.id);
    } catch (e) {
      debugPrint('[SupabaseService] Gagal hapus chat session: $e');
    }
  }

  Future<void> clearAllChatSessions() async {
    final user = currentUser;
    if (user == null || client == null) return;

    try {
      await client!.from('chat_sessions').delete().eq('user_id', user.id);
    } catch (e) {
      debugPrint('[SupabaseService] Gagal clear all chat sessions: $e');
    }
  }

  // ===========================================================================
  // 9. HELPER: ERROR PARSER
  // ===========================================================================

  AuthException _parseAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid credential')) {
      return const AuthException('Email atau kata sandi yang Anda masukkan salah.');
    }
    if (msg.contains('user already registered') || msg.contains('user already exists')) {
      return const AuthException('Alamat email ini sudah terdaftar. Silakan langsung masuk.');
    }
    if (msg.contains('email not confirmed')) {
      return const AuthException('Email belum dikonfirmasi. Silakan periksa inbox/spam email Anda.');
    }
    if (msg.contains('password should be at least')) {
      return const AuthException('Kata sandi harus minimal 6 karakter.');
    }
    if (msg.contains('rate limit')) {
      return const AuthException('Terlalu banyak percobaan. Harap tunggu beberapa saat.');
    }
    return e;
  }
}
