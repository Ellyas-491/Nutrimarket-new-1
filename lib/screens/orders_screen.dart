import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/order.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: Semua, 1: Dalam Proses, 2: Selesai
  Timer? _autoSyncTimer;

  final List<String> _tabLabels = ['Semua', 'Dalam Proses', 'Selesai'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != _selectedFilterIndex) {
        setState(() {
          _selectedFilterIndex = _tabController.index;
        });
      }
    });

    // Auto sync server status instantly on open and periodically every 3 seconds
    _orderService.syncWithSupabase();
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _orderService.syncWithSupabase();
      }
    });
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingPayment:
        return const Color(0xFFD97706); // Amber
      case OrderStatus.paid:
      case OrderStatus.confirmed:
        return const Color(0xFF0D9488); // Teal
      case OrderStatus.preparing:
        return const Color(0xFFEA580C); // Orange
      case OrderStatus.packed:
        return const Color(0xFF6366F1); // Indigo
      case OrderStatus.readyPickup:
        return const Color(0xFF8B5CF6); // Purple
      case OrderStatus.pickedUp:
      case OrderStatus.delivering:
        return const Color(0xFF0284C7); // Sky Blue
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return const Color(0xFF059669); // Emerald Green
      case OrderStatus.cancelled:
        return const Color(0xFFDC2626); // Red
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingPayment:
        return Icons.payment_rounded;
      case OrderStatus.paid:
        return Icons.receipt_long_rounded;
      case OrderStatus.confirmed:
        return Icons.store_rounded;
      case OrderStatus.preparing:
        return Icons.soup_kitchen_rounded;
      case OrderStatus.packed:
        return Icons.inventory_2_rounded;
      case OrderStatus.readyPickup:
        return Icons.shopping_bag_rounded;
      case OrderStatus.pickedUp:
      case OrderStatus.delivering:
        return Icons.two_wheeler_rounded;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return Icons.check_circle_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  int _getStepIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingPayment:
      case OrderStatus.paid:
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.preparing:
      case OrderStatus.packed:
      case OrderStatus.readyPickup:
        return 2;
      case OrderStatus.pickedUp:
      case OrderStatus.delivering:
        return 3;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return 4;
      case OrderStatus.cancelled:
        return 0;
    }
  }

  List<OrderModel> _filterOrders(List<OrderModel> source) {
    var list = source;
    if (_selectedFilterIndex == 1) {
      list = _orderService.activeOrders;
    } else if (_selectedFilterIndex == 2) {
      list = _orderService.completedOrders;
    }

    if (_searchQuery.trim().isEmpty) return list;

    final q = _searchQuery.toLowerCase().trim();
    return list.where((o) {
      final idMatch = o.id.toLowerCase().contains(q);
      final itemMatch = o.items.any((it) => it.product.name.toLowerCase().contains(q));
      final statusMatch = o.statusDisplay.toLowerCase().contains(q);
      return idMatch || itemMatch || statusMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Pesanan Saya',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white70 : const Color(0xFF475569)),
            onPressed: () {
              setState(() {});
              AppToast.show(
                context,
                title: 'Data Diperbarui',
                subtitle: 'Daftar pesanan telah disinkronkan.',
                type: ToastType.success,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Cari no. pesanan atau nama menu...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              // Animated Category Filter Chips Bar (3 Tabs: Semua, Dalam Proses, Selesai)
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListenableBuilder(
                  listenable: _orderService,
                  builder: (context, _) {
                    final allCount = _orderService.orders.length;
                    final activeCount = _orderService.activeOrders.length;
                    final completedCount = _orderService.completedOrders.length;
                    final counts = [allCount, activeCount, completedCount];

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _tabLabels.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedFilterIndex == index;
                        final label = _tabLabels[index];
                        final count = counts[index];

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedFilterIndex = index;
                                _tabController.animateTo(index);
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                    ),
                                  ),
                                  if (count > 0) ...[
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.25)
                                            : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark ? Colors.white : const Color(0xFF334155)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ],
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _orderService,
        builder: (context, _) {
          final filtered = _filterOrders(_orderService.orders);

          if (filtered.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _orderService.syncWithSupabase(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _buildEmptyState(isDark),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _orderService.syncWithSupabase(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final order = filtered[index];
                return _buildAnimatedOrderCard(order, isDark, index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'Pesanan Tidak Ditemukan' : 'Belum Ada Pesanan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Tidak ada pesanan yang sesuai dengan kata kunci "$_searchQuery".'
                  : 'Pesanan makanan sehat Anda akan otomatis tercatat dan dapat dilacak langsung di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : AppColors.secondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedOrderCard(OrderModel order, bool isDark, int index) {
    final statusColor = _getStatusColor(order.status);
    final isDelivering = order.status == OrderStatus.delivering || order.status == OrderStatus.preparing;
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final totalItemsCount = order.items.fold(0, (sum, it) => sum + it.quantity);
    final dateStr = '${order.orderDate.day} Ags ${order.orderDate.year}, ${order.orderDate.hour.toString().padLeft(2, '0')}:${order.orderDate.minute.toString().padLeft(2, '0')} WIB';

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 240 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Transform.translate(
          offset: Offset(0, 16 * (1 - val)),
          child: Opacity(
            opacity: val.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDelivering
                ? statusColor.withOpacity(0.45)
                : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            width: isDelivering ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDelivering
                  ? statusColor.withOpacity(0.12)
                  : Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: isDelivering ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showOrderDetailSheet(order),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Store & Status Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.restaurant_rounded, size: 14, color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'NutriMarket Official',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.verified_rounded, color: AppColors.primary, size: 12),
                                    ],
                                  ),
                                  Text(
                                    dateStr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10, color: AppColors.secondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Badge with Pulse effect if active
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: statusColor.withOpacity(0.3), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isDelivering) ...[
                              _buildPulsingDot(statusColor),
                              const SizedBox(width: 5),
                            ] else ...[
                              Icon(_getStatusIcon(order.status), size: 12, color: statusColor),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              order.statusDisplay,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Active Live Delivery Banner (If in progress)
                  if (isDelivering) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.two_wheeler_rounded, size: 16, color: statusColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.estimatedDelivery,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),

                  // Order Item Snapshot Row
                  if (firstItem != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            firstItem.product.imageUrl,
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 54,
                              height: 54,
                              color: AppColors.primaryLight,
                              child: const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                firstItem.product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${firstItem.quantity}x @ Rp ${firstItem.product.price.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                              ),
                              if (order.items.length > 1) ...[
                                const SizedBox(height: 3),
                                Text(
                                  '+${order.items.length - 1} menu lainnya',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          'Rp ${firstItem.totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                  const SizedBox(height: 12),
                  Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),

                  // Bottom Total & Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Belanja ($totalItemsCount item)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, color: AppColors.secondary),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Rp ${order.total.toStringAsFixed(0)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Detail Button
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _showOrderDetailSheet(order),
                            child: Text(
                              'Detail',
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.textPrimary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(width: 6),

                          // Primary Action depending on status
                          if (order.status == OrderStatus.delivering || order.status == OrderStatus.preparing) ...[
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: statusColor,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              onPressed: () => _showOrderDetailSheet(order),
                              icon: const Icon(Icons.location_searching_rounded, size: 13, color: Colors.white),
                              label: const Text(
                                'Lacak',
                                style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ] else if (order.status == OrderStatus.completed) ...[
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              onPressed: () => _showReviewModal(order),
                              child: Text(
                                order.review != null ? 'Ulasan' : 'Beri Ulasan',
                                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ] else if (order.status == OrderStatus.pendingPayment) ...[
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                _orderService.confirmPayment(order.id);
                                AppToast.show(
                                  context,
                                  title: 'Pembayaran Diterima',
                                  subtitle: 'Status pesanan #${order.id} telah dikonfirmasi.',
                                  type: ToastType.success,
                                );
                              },
                              child: const Text(
                                'Bayar',
                                style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingDot(Color color) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  // ============================================================
  // ORDER DETAIL BOTTOM SHEET WITH LIVE STEPPER & COURIER CARD
  // ============================================================
  void _showOrderDetailSheet(OrderModel initialOrder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final order = _orderService.orders.firstWhere(
            (o) => o.id == initialOrder.id,
            orElse: () => initialOrder,
          );
          final liveStatusColor = _getStatusColor(order.status);
          final liveStep = _getStepIndex(order.status);

          return Container(
            height: MediaQuery.of(context).size.height * 0.90,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle Bar
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Rincian Pesanan',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: liveStatusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  order.statusDisplay,
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: liveStatusColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '#${order.id}',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.secondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 16, color: Color(0xFFF1F5F9)),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. LIVE ANIMATED STEPPER PROGRESS
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Status Pengantaran',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      order.estimatedDelivery,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: liveStatusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildStepperRow(liveStep, isDark),

                              if (order.status != OrderStatus.completed && order.status != OrderStatus.cancelled) ...[
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF059669),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                    onPressed: () async {
                                      await _orderService.completeOrder(order.id);
                                      setSheetState(() {});
                                      setState(() {});
                                      if (mounted) {
                                        AppToast.show(
                                          context,
                                          title: 'Pesanan Selesai 🎉',
                                          subtitle: 'Terima kasih, pesanan Anda telah diterima!',
                                          type: ToastType.success,
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
                                    label: const Text(
                                      'Konfirmasi Pesanan Diterima',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                    const SizedBox(height: 16),

                    // 2. COURIER DRIVER CARD (Hanya muncul jika pesanan sudah dalam proses antar / selesai)
                    if (order.status == OrderStatus.delivering ||
                        order.status == OrderStatus.delivered ||
                        order.status == OrderStatus.pickedUp ||
                        order.status == OrderStatus.completed) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primaryLight,
                              child: Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Bambang Wijaya',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
                                      Text(' 4.9', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Kurir NutriExpress • 0812-3456-7890 (N 4821 AA)',
                                    style: TextStyle(fontSize: 10.5, color: AppColors.secondary),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Hubungi Driver',
                              style: IconButton.styleFrom(
                                backgroundColor: isDark ? Colors.white12 : Colors.white,
                                side: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                              ),
                              icon: const Icon(Icons.phone_rounded, color: AppColors.primary, size: 18),
                              onPressed: () {
                                AppToast.show(
                                  context,
                                  title: 'Panggilan Kurir',
                                  subtitle: 'Menghubungi Bambang Wijaya (0812-3456-7890)...',
                                  type: ToastType.info,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (order.deliveryPhotoUrl != null && order.deliveryPhotoUrl!.trim().isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.camera_alt_rounded, size: 16, color: Color(0xFF059669)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Foto Bukti Pengantaran / Makanan',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  order.deliveryPhotoUrl!,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 80,
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    alignment: Alignment.center,
                                    child: const Text('Gagal memuat foto bukti pengantaran', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],

                    // 3. DELIVERY ADDRESS CARD
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'Alamat Pengantaran',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            order.deliveryAddress.isNotEmpty ? order.deliveryAddress : 'Alamat Pengiriman Utama',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                              height: 1.35,
                            ),
                          ),
                          if (order.orderNotes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Catatan: ${order.orderNotes}',
                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.secondary),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 4. ORDER ITEMS BREAKDOWN
                    Text(
                      'Daftar Menu (${order.items.length})',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: order.items.map((it) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    it.product.imageUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        it.product.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${it.quantity}x @ Rp ${it.product.price.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 10.5, color: AppColors.secondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Rp ${it.totalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 5. PAYMENT BREAKDOWN
                    const Text(
                      'Rincian Pembayaran',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildPriceRow('Subtotal Menu', 'Rp ${order.subtotal.toStringAsFixed(0)}', isDark),
                          const SizedBox(height: 6),
                          _buildPriceRow('Ongkos Kirim', 'Rp ${order.deliveryFee.toStringAsFixed(0)}', isDark),
                          const SizedBox(height: 6),
                          _buildPriceRow('Biaya Layanan', 'Rp ${order.serviceFee.toStringAsFixed(0)}', isDark),
                          if (order.discount > 0) ...[
                            const SizedBox(height: 6),
                            _buildPriceRow('Diskon NutriSehat', '-Rp ${order.discount.toStringAsFixed(0)}', isDark, isGreen: true),
                          ],
                          const SizedBox(height: 8),
                          Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Pembayaran',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Rp ${order.total.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Metode: ${order.paymentMethod}',
                                style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                              ),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: order.id));
                                  AppToast.show(
                                    context,
                                    title: 'Disalin!',
                                    subtitle: 'Nomor pesanan #${order.id} telah disalin.',
                                    type: ToastType.info,
                                  );
                                },
                                child: const Row(
                                  children: [
                                    Text('Salin ID', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                    SizedBox(width: 2),
                                    Icon(Icons.copy_rounded, size: 12, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // BOTTOM BUTTON: Reorder 1-tap
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final cart = CartService();
                          for (final it in order.items) {
                            cart.addToCart(it.product);
                          }
                          Navigator.pop(context);
                          AppToast.show(
                            context,
                            title: 'Masuk Keranjang!',
                            subtitle: '${order.items.length} menu berhasil dimasukkan ke keranjang.',
                            type: ToastType.success,
                          );
                        },
                        icon: const Icon(Icons.replay_rounded, color: Colors.white, size: 18),
                        label: const Text(
                          'Pesan Lagi Menu Ini',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  ),
);
  }

  Widget _buildStepperRow(int currentStep, bool isDark) {
    final steps = ['Diterima', 'Dimasak', 'Diantar', 'Selesai'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (i) {
        final stepNum = i + 1;
        final isPassed = stepNum <= currentStep;
        final isCurrent = stepNum == currentStep;

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isPassed ? AppColors.primary : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      shape: BoxShape.circle,
                      border: isCurrent ? Border.all(color: AppColors.primaryLight, width: 2) : null,
                    ),
                    child: Center(
                      child: isPassed
                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                          : Text(
                              '$stepNum',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[i],
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: isPassed ? FontWeight.bold : FontWeight.normal,
                      color: isPassed
                          ? (isDark ? Colors.white : AppColors.textPrimary)
                          : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2.5,
                    margin: const EdgeInsets.only(bottom: 14),
                    color: stepNum < currentStep
                        ? AppColors.primary
                        : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPriceRow(String label, String value, bool isDark, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isGreen
                ? const Color(0xFF059669)
                : (isDark ? Colors.white : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // AUTHENTIC E-COMMERCE REVIEW MODAL (TOKOPEDIA / SHOPEE STYLE)
  // ============================================================
  void _showReviewModal(OrderModel order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double foodScore = order.review?.foodQualityScore ?? 5.0;
    double deliveryScore = order.review?.deliveryScore ?? 5.0;
    final commentController = TextEditingController(text: order.review?.comments ?? '');
    bool isAnonymous = false;
    final selectedTags = <String>{'Rasa Enak', 'Bahan Segar'};

    final availableTags = [
      'Rasa Enak',
      'Bahan Segar',
      'Porsi Pas',
      'Kemasan Rapi',
      'Pengiriman Cepat',
      'Sesuai Deskripsi',
    ];

    String getMoodEmoji(double score) {
      if (score >= 5.0) return '🤩';
      if (score >= 4.0) return '😊';
      if (score >= 3.0) return '😐';
      if (score >= 2.0) return '🙁';
      return '😞';
    }

    String getStarLabel(double score) {
      if (score >= 5.0) return 'Luar Biasa Memuaskan!';
      if (score >= 4.0) return 'Sangat Enak & Puas';
      if (score >= 3.0) return 'Cukup Baik & Lumayan';
      if (score >= 2.0) return 'Kurang Sesuai Ekspektasi';
      return 'Sangat Kecewa';
    }

    Color getMoodColor(double score) {
      if (score >= 5.0) return const Color(0xFF059669);
      if (score >= 4.0) return const Color(0xFF0D9488);
      if (score >= 3.0) return const Color(0xFFF59E0B);
      if (score >= 2.0) return const Color(0xFFF97316);
      return const Color(0xFFEF4444);
    }

    final firstItem = order.items.isNotEmpty ? order.items.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nilai & Ulas Produk',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Pesanan #${order.id}',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.secondary),
                            ),
                          ],
                        ),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                            shape: const CircleBorder(),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 16, color: Color(0xFFF1F5F9)),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Snapshot Tile
                          if (firstItem != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      firstItem.product.imageUrl,
                                      width: 46,
                                      height: 46,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          firstItem.product.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'NutriMarket Official Store',
                                          style: TextStyle(fontSize: 11, color: AppColors.secondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Dynamic Reactive Cute Mood Emoji & Stars
                          Center(
                            child: Column(
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                  child: Text(
                                    getMoodEmoji(foodScore),
                                    key: ValueKey<double>(foodScore),
                                    style: const TextStyle(fontSize: 44),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  getStarLabel(foodScore),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: getMoodColor(foodScore),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(5, (index) {
                                    final star = (index + 1).toDouble();
                                    return GestureDetector(
                                      onTap: () => setModalState(() => foodScore = star),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Icon(
                                          star <= foodScore ? Icons.star_rounded : Icons.star_outline_rounded,
                                          color: const Color(0xFFF59E0B),
                                          size: 36,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Quick Tag Chips (Clean E-Commerce Style)
                          const Text(
                            'Pilih deskripsi yang sesuai:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: availableTags.map((tag) {
                              final isSel = selectedTags.contains(tag);
                              return InkWell(
                                onTap: () {
                                  setModalState(() {
                                    if (isSel) {
                                      selectedTags.remove(tag);
                                    } else {
                                      selectedTags.add(tag);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? AppColors.primaryLight
                                        : (isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSel ? AppColors.primary : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                      color: isSel ? AppColors.primary : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 16),

                          // Review Text Area
                          TextField(
                            controller: commentController,
                            maxLines: 3,
                            style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Tulis ulasan Anda mengenai rasa, porsi, dan kualitas...',
                              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.primary),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Courier Service Rating Row
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Layanan Pengiriman',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(5, (index) {
                                    final star = (index + 1).toDouble();
                                    return GestureDetector(
                                      onTap: () => setModalState(() => deliveryScore = star),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2),
                                        child: Icon(
                                          star <= deliveryScore ? Icons.star_rounded : Icons.star_outline_rounded,
                                          color: const Color(0xFFF59E0B),
                                          size: 22,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Anonymous Switch Row
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: isAnonymous,
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (val) => setModalState(() => isAnonymous = val ?? false),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setModalState(() => isAnonymous = !isAnonymous),
                                child: Text(
                                  'Sembunyikan nama saya (Ulas sebagai Anonim)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                final tagsString = selectedTags.isNotEmpty ? '[${selectedTags.join(', ')}] ' : '';
                                final text = commentController.text.trim();
                                final fullComment = '$tagsString$text'.trim();

                                _orderService.submitReview(
                                  order.id,
                                  OrderReview(
                                    foodQualityScore: foodScore,
                                    packagingScore: foodScore,
                                    deliveryScore: deliveryScore,
                                    comments: fullComment.isNotEmpty ? fullComment : 'Pesanan sangat memuaskan.',
                                    createdAt: DateTime.now(),
                                  ),
                                );
                                Navigator.pop(context);
                                AppToast.show(
                                  context,
                                  title: 'Ulasan Dikirim',
                                  subtitle: 'Terima kasih atas penilaian Anda!',
                                  type: ToastType.success,
                                );
                              },
                              child: const Text(
                                'Kirim Ulasan',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
