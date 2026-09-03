import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clev_ai/features/notifications/models/app_notification.dart';
import 'package:clev_ai/features/notifications/services/notification_service.dart';
import 'package:clev_ai/core/theme/app_theme.dart';
import 'package:clev_ai/core/widgets/app_toast.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Belum Dibaca', 'Penting'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<NotificationService>(
      builder: (context, notifService, _) {
        final allNotifs = notifService.notifications;
        final filteredNotifs = allNotifs.where((n) {
          if (_selectedFilter == 'Belum Dibaca') return !n.isRead;
          if (_selectedFilter == 'Penting') return n.isImportant;
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Notifikasi',
              style: AppTextStyles.body1(
                color: isDark ? Colors.white : AppColors.dark,
                weight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              if (allNotifs.isNotEmpty)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white70 : AppColors.dark),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  onSelected: (val) {
                    if (val == 'mark_all') {
                      notifService.markAllAsRead();
                      AppToast.show(
                        context,
                        title: 'Semua Dibaca',
                        subtitle: 'Semua notifikasi telah ditandai sebagai sudah dibaca.',
                        type: ToastType.info,
                      );
                    } else if (val == 'clear_all') {
                      notifService.clearAll();
                      AppToast.show(
                        context,
                        title: 'Notifikasi Dibersihkan',
                        subtitle: 'Riwayat notifikasi telah dihapus.',
                        type: ToastType.warning,
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'mark_all',
                      child: Row(
                        children: [
                          Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
                          SizedBox(width: 10),
                          Text('Tandai Semua Dibaca', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_rounded, size: 18, color: Color(0xFFDC2626)),
                          SizedBox(width: 10),
                          Text('Hapus Semua', style: TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Filter Pills (Semua | Belum Dibaca | Penting)
                Container(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      int badgeCount = 0;
                      if (filter == 'Belum Dibaca') {
                        badgeCount = notifService.unreadCount;
                      } else if (filter == 'Penting') {
                        badgeCount = allNotifs.where((n) => n.isImportant).length;
                      } else {
                        badgeCount = allNotifs.length;
                      }

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => setState(() => _selectedFilter = filter),
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    filter,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? Colors.white70 : AppColors.dark),
                                    ),
                                  ),
                                  if (badgeCount > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.white24 : AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        badgeCount.toString(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Notification Items List / Empty State
                Expanded(
                  child: filteredNotifs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.notifications_off_outlined,
                                  size: 48,
                                  color: isDark ? Colors.white38 : AppColors.secondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedFilter == 'Belum Dibaca'
                                    ? 'Tidak ada notifikasi belum dibaca'
                                    : _selectedFilter == 'Penting'
                                        ? 'Tidak ada notifikasi penting'
                                        : 'Belum ada notifikasi',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.dark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Aktivitas akun dan status pesanan akan tampil di sini.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredNotifs.length,
                          itemBuilder: (context, index) {
                            final notif = filteredNotifs[index];
                            return _buildNotificationCard(
                              notif: notif,
                              isDark: isDark,
                              onTap: () {
                                if (!notif.isRead) {
                                  notifService.markAsRead(notif.id);
                                }
                              },
                              onDelete: () {
                                notifService.deleteNotification(notif.id);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard({
    required AppNotification notif,
    required bool isDark,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: notif.isRead
              ? (isDark ? AppColors.darkSurface : Colors.white)
              : (isDark ? const Color(0xFF1E2D2B) : const Color(0xFFF0FDF4)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead
                ? (isDark ? Colors.white10 : const Color(0xFFE2E8F0))
                : AppColors.primary.withValues(alpha: 0.35),
            width: notif.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: notif.iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        notif.icon,
                        color: notif.iconColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  notif.timeAgo,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark ? Colors.white38 : AppColors.secondary,
                                  ),
                                ),
                                if (!notif.isRead) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif.message,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
