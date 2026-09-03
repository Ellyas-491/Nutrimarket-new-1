import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../screens/cart_screen.dart';
import '../../screens/notifications_screen.dart';

class DashboardHeader extends StatelessWidget {
  final String userName;
  final VoidCallback? onCartPressed;
  final VoidCallback? onNotificationPressed;

  const DashboardHeader({
    super.key,
    required this.userName,
    this.onCartPressed,
    this.onNotificationPressed,
  });

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) {
      return 'Selamat pagi,';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat siang,';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat sore,';
    } else {
      return 'Selamat malam,';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side: User profile info
        Expanded(
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
                    ),
                  ),
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkBackground : Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getTimeGreeting(),
                      style: AppTextStyles.caption(
                        color: isDark ? Colors.white60 : AppColors.secondary,
                      ),
                    ),
                    Text(
                      '$userName 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading2(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Right side: Cart & Notifications
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cart Button with Live Badge
            Consumer<CartService>(
              builder: (context, cartService, _) {
                final count = cartService.itemCount;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                      padding: const EdgeInsets.all(8),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                        side: BorderSide(
                          color: isDark ? Colors.white10 : AppColors.border,
                        ),
                      ),
                      icon: Icon(
                        Icons.shopping_bag_outlined,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        size: 19,
                      ),
                      onPressed: onCartPressed ??
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CartScreen()),
                            );
                          },
                    ),
                    if (count > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$count',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 6),
            Consumer<NotificationService>(
              builder: (context, notifService, _) {
                final unreadCount = notifService.unreadCount;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                      padding: const EdgeInsets.all(8),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                        side: BorderSide(
                          color: isDark ? Colors.white10 : AppColors.border,
                        ),
                      ),
                      icon: Icon(
                        Icons.notifications_none_rounded,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        size: 18,
                      ),
                      onPressed: onNotificationPressed ??
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                            );
                          },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$unreadCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
