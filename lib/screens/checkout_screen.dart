import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../services/history_service.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../widgets/address_picker_sheet.dart';
import '../widgets/app_toast.dart';
import 'main_navigation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Address Selection
  late String _selectedAddressTitle;
  late String _deliveryAddress;
  final String _addressDistance = '2.4 km dari Merchant';

  // Delivery Option
  String _deliveryOption = 'Instant Delivery (20-30 Menit)';
  double _deliveryFee = 10000;

  // Order Notes
  final TextEditingController _notesController = TextEditingController();
  final List<String> _quickNotes = [
    'Titip di pos satpam',
    'Jangan pencet bel',
    'Hubungi saat sampai',
    'Saus & sendok terpisah',
  ];

  // Payment Method
  String _paymentMethod = 'QRIS Instant Pay';

  @override
  void initState() {
    super.initState();
    final profile = context.read<HistoryService>().userProfile;
    _selectedAddressTitle = profile.addressLabel;
    _deliveryAddress = profile.address;

    if (profile.defaultPaymentMethod.contains('Mobile Banking')) {
      _paymentMethod = 'QRIS Mobile Banking';
    } else {
      _paymentMethod = 'QRIS Instant Pay';
    }
  }

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'QRIS Instant Pay',
      'subtitle': 'GoPay, ShopeePay, OVO, Dana, LinkAja',
      'icon': Icons.qr_code_scanner_rounded,
      'badge': 'Otomatis',
      'badgeColor': const Color(0xFF059669),
    },
    {
      'name': 'QRIS Mobile Banking',
      'subtitle': 'm-BCA, Livin by Mandiri, BRImo, BNI Mobile',
      'icon': Icons.account_balance_rounded,
      'badge': 'Semua Bank',
      'badgeColor': const Color(0xFF0284C7),
    },
  ];

  final double _serviceFee = 2000;
  final double _discount = 0;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double _getFinalTotal(CartService cartService) => cartService.subtotal + _deliveryFee + _serviceFee - _discount;

  void _openAddressPicker() {
    AddressPickerSheet.show(
      context,
      onAddressSelected: (title, fullAddress, detail) {
        setState(() {
          _selectedAddressTitle = title;
          _deliveryAddress = fullAddress;
        });
      },
    );
  }

  void _showPaymentModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalFormatted = 'Rp ${_getFinalTotal(context.read<CartService>()).toStringAsFixed(0)}';

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
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
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, size: 20, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Metode Pembayaran',
                            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
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
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Total Tagihan Pembayaran',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.secondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalFormatted,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer_outlined, size: 14, color: Color(0xFFD97706)),
                              SizedBox(width: 5),
                              Text(
                                'Batas Bayar: 14:59 Menit',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Standard QRIS Box
                        if (_paymentMethod.contains('QRIS') || _paymentMethod.contains('GoPay')) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('QRIS STANDAR NASIONAL', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 11)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('NMID: ID1029384756', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  width: 190,
                                  height: 190,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.qr_code_2_rounded, size: 150, color: Colors.grey.shade900),
                                        const Text('NUTRI-MARKET-PAY', style: TextStyle(fontSize: 8, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Scan menggunakan GoPay, OVO, Dana, BCA, atau ShopeePay',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black54, fontSize: 10.5),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Virtual Account Card
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
                                  children: [
                                    const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      _paymentMethod,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text('Nomor Rekening Virtual Account:', style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('8801 2938 4192 001', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.primary)),
                                    IconButton(
                                      icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 18),
                                      onPressed: () {
                                        AppToast.show(context, title: 'Disalin', subtitle: 'Nomor VA berhasil disalin ke clipboard.', type: ToastType.info);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Action: Simulate Webhook Payment Success
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                            label: const Text(
                              'Konfirmasi Pembayaran Selesai',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            onPressed: () {
                              Navigator.pop(context); // close payment modal
                              _executeOrderSuccess();
                            },
                          ),
                        ),
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

  void _executeOrderSuccess() {
    final cartService = context.read<CartService>();
    final orderService = context.read<OrderService>();
    final cartItems = cartService.items;
    if (cartItems.isEmpty) return;

    final newOrder = orderService.placeOrder(
      cartItems: cartItems,
      subtotal: cartService.subtotal,
      deliveryFee: _deliveryFee,
      serviceFee: _serviceFee,
      discount: _discount,
      total: _getFinalTotal(cartService),
      address: _deliveryAddress,
      deliveryOption: _deliveryOption,
      orderNotes: _notesController.text,
      paymentMethod: _paymentMethod,
      isPaidImmediately: true,
    );

    cartService.clearCart();

    AppToast.show(
      context,
      title: 'Pembayaran Dikonfirmasi!',
      subtitle: 'Pesanan #${newOrder.id} status: PAID & diteruskan ke Dapur.',
      type: ToastType.success,
    );

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F4F1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 36),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pesanan Berhasil Dibuat!',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Order ID: #${newOrder.id} • Status: PAID',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pesanan telah diterima dan merchant sedang menyiapkan makanan Anda dengan rapi & higienis.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.secondary, height: 1.4),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Lacak Pesanan Sekarang',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  onPressed: () {
                    MainNavigationScreen.switchToTab(3); // Switch to Orders tab
                    Navigator.pop(context); // Close sheet
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    MainNavigationScreen.switchToTab(0); // Switch to Home tab
                    Navigator.pop(context); // Close sheet
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Kembali ke Beranda', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pengiriman & Pembayaran',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Delivery Destination Card
              _buildModernDeliveryAddressCard(isDark),
              const SizedBox(height: 14),

              // 2. Delivery Courier Tier Card
              _buildModernCourierTierCard(isDark),
              const SizedBox(height: 14),

              // 3. Ordered Food Items Summary Card
              _buildOrderedItemsPreviewCard(isDark),
              const SizedBox(height: 14),

              // 4. Special Notes & Presets Card
              _buildModernNotesCard(isDark),
              const SizedBox(height: 14),

              // 5. Payment Method Selector Card
              _buildModernPaymentMethodCard(isDark),
              const SizedBox(height: 14),

              // 6. Transparent Price Breakdown Card
              _buildModernPriceBreakdown(isDark),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildStickyBottomCheckout(isDark),
    );
  }

  Widget _buildModernDeliveryAddressCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Alamat Pengiriman',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              InkWell(
                onTap: _openAddressPicker,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Text('Ganti', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_right_rounded, size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _selectedAddressTitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  HistoryService().userProfile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _deliveryAddress,
            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : AppColors.secondary, height: 1.3),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.near_me_rounded, size: 12, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                _addressDistance,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernCourierTierCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Pilihan Pengiriman',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCourierOptionRow(
            title: 'Instant Delivery (20-30 Menit)',
            badge: 'Diantar langsung oleh kurir mitra',
            fee: 10000,
            isSelected: _deliveryFee == 10000,
            isDark: isDark,
            onTap: () {
              setState(() {
                _deliveryOption = 'Instant Delivery (20-30 Menit)';
                _deliveryFee = 10000;
              });
            },
          ),
          const SizedBox(height: 8),
          _buildCourierOptionRow(
            title: 'Express Priority (15-20 Menit)',
            badge: 'Prioritas persiapan merchant & kurir cepat',
            fee: 15000,
            isSelected: _deliveryFee == 15000,
            isDark: isDark,
            onTap: () {
              setState(() {
                _deliveryOption = 'Express Priority (15-20 Menit)';
                _deliveryFee = 15000;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCourierOptionRow({
    required String title,
    required String badge,
    required double fee,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary.withOpacity(0.12) : AppColors.primaryLight)
              : (isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.secondary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    badge,
                    style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : AppColors.secondary),
                  ),
                ],
              ),
            ),
            Text(
              'Rp ${fee.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : (isDark ? Colors.white : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderedItemsPreviewCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.storefront_rounded, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text('NutriMarket Official Store', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  SizedBox(width: 4),
                  Icon(Icons.verified_rounded, color: AppColors.primary, size: 14),
                ],
              ),
              Text(
                '${context.watch<CartService>().items.length} Menu',
                style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...context.watch<CartService>().items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.product.imageUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 44, height: 44, color: AppColors.primaryLight),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        Text('${item.quantity}x @ Rp ${item.product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
                        if (item.sellerNotes.isNotEmpty)
                          Text('Catatan: "${item.sellerNotes}"', style: const TextStyle(fontSize: 10, color: AppColors.primary, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  Text(
                    'Rp ${(item.product.price * item.quantity).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildModernNotesCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text('Catatan untuk Penjual / Kurir', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            style: const TextStyle(fontSize: 12.5),
            decoration: InputDecoration(
              hintText: 'Tulis pesan khusus (opsional)...',
              hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : AppColors.textHint),
              filled: true,
              fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickNotes.map((preset) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      if (_notesController.text.isEmpty) {
                        _notesController.text = preset;
                      } else {
                        _notesController.text += ', $preset';
                      }
                      setState(() {});
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        '+ $preset',
                        style: const TextStyle(fontSize: 10.5, color: AppColors.secondary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPaymentMethodCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text('Metode Pembayaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ..._paymentMethods.map((m) {
            final isSelected = _paymentMethod == m['name'];
            return InkWell(
              onTap: () => setState(() => _paymentMethod = m['name']),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.primary.withOpacity(0.12) : AppColors.primaryLight)
                      : (isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                    width: isSelected ? 1.2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: isSelected ? AppColors.primary : AppColors.secondary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                m['name'],
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (m['badgeColor'] as Color).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  m['badge'],
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: m['badgeColor'] as Color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m['subtitle'],
                            style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildModernPriceBreakdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rincian Pembayaran', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildRowItem('Subtotal Menu', context.watch<CartService>().formatCurrency(context.watch<CartService>().subtotal), isDark),
          const SizedBox(height: 8),
          _buildRowItem('Biaya Pengiriman Kurir', 'Rp ${_deliveryFee.toStringAsFixed(0)}', isDark),
          const SizedBox(height: 8),
          _buildRowItem('Biaya Layanan Aplikasi', 'Rp ${_serviceFee.toStringAsFixed(0)}', isDark),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pembayaran', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
              Text(
                'Rp ${_getFinalTotal(context.watch<CartService>()).toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRowItem(String label, String val, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.secondary)),
        Text(
          val,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStickyBottomCheckout(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total Tagihan',
                    style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rp ${_getFinalTotal(context.watch<CartService>()).toStringAsFixed(0)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 6,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _showPaymentModal();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Bayar Sekarang',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
