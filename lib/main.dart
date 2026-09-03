import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:clev_ai/features/navigation/screens/splash_screen.dart';
import 'package:clev_ai/features/cart/services/cart_service.dart';
import 'package:clev_ai/features/products/services/favorite_service.dart';
import 'package:clev_ai/features/orders/services/history_service.dart';
import 'package:clev_ai/data/local/local_storage_service.dart';
import 'package:clev_ai/features/notifications/services/notification_service.dart';
import 'package:clev_ai/data/local/offline_sync_service.dart';
import 'package:clev_ai/features/orders/services/order_service.dart';
import 'package:clev_ai/features/products/services/product_repository.dart';
import 'package:clev_ai/data/local/secure_storage_service.dart';
import 'package:clev_ai/data/remote/supabase_service.dart';
import 'package:clev_ai/features/ai_assistant/services/voice_service.dart';
import 'package:clev_ai/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Dotenv load error: $e');
  }

  // Initialize Encrypted Storage & Local Storage
  await SecureStorageService().init();
  await LocalStorageService().init();
  await OfflineSyncService().init();

  // Initialize Real Supabase Client & Database Auth
  await SupabaseService().init();

  // Load persisted offline orders, cart, favorites, AI chat history, user profile & products
  HistoryService().initFromLocalStorage();
  FavoriteService().initFromLocalStorage();
  await ProductRepository().initFromSupabase();
  CartService().initFromLocalStorage();
  OrderService().initFromLocalStorage();
  HistoryService().syncWithSecureStorage();
  HistoryService().initChatHistoryFromStorage();

  await VoiceService().init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const HealthCarePlusApp());
}

class HealthCarePlusApp extends StatelessWidget {
  const HealthCarePlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SupabaseService>.value(value: SupabaseService()),
        ChangeNotifierProvider<SecureStorageService>.value(value: SecureStorageService()),
        ChangeNotifierProvider<OfflineSyncService>.value(value: OfflineSyncService()),
        ChangeNotifierProvider<ProductRepository>.value(value: ProductRepository()),
        ChangeNotifierProvider<HistoryService>.value(value: HistoryService()),
        ChangeNotifierProvider<CartService>.value(value: CartService()),
        ChangeNotifierProvider<OrderService>.value(value: OrderService()),
        ChangeNotifierProvider<FavoriteService>.value(value: FavoriteService()),
        ChangeNotifierProvider<NotificationService>.value(value: NotificationService()),
      ],
      child: MaterialApp(
        title: 'HealthCare+ AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
      ),
    );
  }
}
