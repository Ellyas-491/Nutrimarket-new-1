import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:clev_ai/features/orders/models/saved_address.dart';
import 'package:clev_ai/features/orders/services/history_service.dart';
import 'package:clev_ai/features/orders/services/location_service.dart';
import 'package:clev_ai/core/theme/app_theme.dart';
import 'package:clev_ai/core/widgets/app_toast.dart';

class AddressPickerSheet extends StatefulWidget {
  final Function(String title, String fullAddress, String detail)? onAddressSelected;

  const AddressPickerSheet({super.key, this.onAddressSelected});

  static void show(
    BuildContext context, {
    Function(String title, String fullAddress, String detail)? onAddressSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddressPickerSheet(onAddressSelected: onAddressSelected),
    );
  }

  @override
  State<AddressPickerSheet> createState() => _AddressPickerSheetState();
}

enum _AddressSheetMode {
  list,
  mapPicker,
  addOrEdit,
}

class _AddressPickerSheetState extends State<AddressPickerSheet> {
  final HistoryService _historyService = HistoryService();
  final LocationService _locationService = LocationService();

  _AddressSheetMode _mode = _AddressSheetMode.list;
  String? _editingAddressId;
  bool _isDetectingGps = false;
  bool _isGeocodingPin = false;
  bool _setAsPrimary = true;

  // Form Controllers
  String _selectedLabel = 'Rumah';
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Search Location Bar
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  Timer? _geocodeDebounce;
  List<PlaceSearchResult> _searchResults = [];
  bool _isSearching = false;

  final List<Map<String, dynamic>> _labelOptions = [
    {'name': 'Rumah', 'icon': Icons.home_rounded},
    {'name': 'Kantor', 'icon': Icons.business_rounded},
    {'name': 'Apartemen', 'icon': Icons.apartment_rounded},
    {'name': 'Kos', 'icon': Icons.holiday_village_rounded},
    {'name': 'Lainnya', 'icon': Icons.location_on_rounded},
  ];

  // Dynamic Live Geolocation & Interactive Map State (For Courier Navigation)
  double _baseLat = -7.9839;
  double _baseLng = 112.6214;
  int _zoomLevel = 17;
  Offset _mapPanOffset = Offset.zero;
  String _liveAddressText = 'Mengambil koordinat presisi...';

  double get _pixelDegrees => 360.0 / (256.0 * math.pow(2.0, _zoomLevel));
  double get _computedLat => _baseLat - (_mapPanOffset.dy * _pixelDegrees);
  double get _computedLng => _baseLng + (_mapPanOffset.dx * _pixelDegrees);

  @override
  void initState() {
    super.initState();
    _resetForm();
    _fetchLiveDeviceLocation();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _geocodeDebounce?.cancel();
    _searchController.dispose();
    _recipientController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveDeviceLocation() async {
    setState(() => _isDetectingGps = true);
    try {
      final userLoc = await _locationService.getCurrentUserLocation(forceRefresh: true);
      if (mounted) {
        setState(() {
          _baseLat = userLoc.latitude;
          _baseLng = userLoc.longitude;
          _liveAddressText = userLoc.formattedAddress;
          _mapPanOffset = Offset.zero;
          _isDetectingGps = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isDetectingGps = false);
    }
  }

  void _updateAddressFromCoordinates() {
    if (_geocodeDebounce?.isActive ?? false) _geocodeDebounce!.cancel();

    setState(() => _isGeocodingPin = true);

    _geocodeDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final geocoded = await _locationService.reverseGeocodeCoordinates(_computedLat, _computedLng);
        if (mounted) {
          setState(() {
            _liveAddressText = geocoded.formattedAddress;
            _isGeocodingPin = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isGeocodingPin = false);
      }
    });
  }

  void _onSearchQueryChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearching = true);
      final results = await _locationService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectSearchResult(PlaceSearchResult place) {
    setState(() {
      _baseLat = place.latitude;
      _baseLng = place.longitude;
      _mapPanOffset = Offset.zero;
      _zoomLevel = 17;
      _searchResults = [];
      _searchController.clear();
      _liveAddressText = place.displayName;
    });
    FocusScope.of(context).unfocus();
    _updateAddressFromCoordinates();
  }

  void _nudgePin(double dx, double dy) {
    setState(() {
      _mapPanOffset += Offset(dx, dy);
    });
    _updateAddressFromCoordinates();
  }

  void _resetForm([SavedAddress? existing]) {
    final profile = _historyService.userProfile;
    if (existing != null) {
      _editingAddressId = existing.id;
      _selectedLabel = existing.label;
      _recipientController.text = existing.recipientName;
      _phoneController.text = existing.phoneNumber;
      _addressController.text = existing.fullAddress;
      _notesController.text = existing.notes;
      _setAsPrimary = existing.isPrimary;
      _baseLat = existing.latitude;
      _baseLng = existing.longitude;
      _mapPanOffset = Offset.zero;
    } else {
      _editingAddressId = null;
      _selectedLabel = 'Rumah';
      _recipientController.text = profile.name;
      _phoneController.text = '';
      _addressController.text = '';
      _notesController.text = '';
      _setAsPrimary = _historyService.savedAddresses.isEmpty;
    }
  }

  void _saveAddressForm() {
    final addressText = _addressController.text.trim();
    if (addressText.isEmpty) {
      AppToast.show(
        context,
        title: 'Alamat Wajib Diisi',
        subtitle: 'Mohon tulis alamat jalan lengkap atau nomor rumah Anda.',
        type: ToastType.error,
      );
      return;
    }

    final recipient = _recipientController.text.trim().isEmpty
        ? _historyService.userProfile.name
        : _recipientController.text.trim();
    final phone = _phoneController.text.trim();
    final notes = _notesController.text.trim();

    if (_editingAddressId != null) {
      // Update
      final updated = SavedAddress(
        id: _editingAddressId!,
        label: _selectedLabel,
        recipientName: recipient,
        phoneNumber: phone,
        fullAddress: addressText,
        notes: notes,
        latitude: _computedLat,
        longitude: _computedLng,
        isPrimary: _setAsPrimary,
      );
      _historyService.updateSavedAddress(updated);
      if (_setAsPrimary) {
        _historyService.setPrimaryAddress(updated.id);
      }
      if (widget.onAddressSelected != null && _setAsPrimary) {
        widget.onAddressSelected!(updated.label, updated.fullAddress, updated.notes);
      }
      AppToast.show(
        context,
        title: 'Alamat Diperbarui',
        subtitle: '$_selectedLabel: $addressText',
        type: ToastType.success,
      );
    } else {
      // Add New
      final newAddr = SavedAddress(
        id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
        label: _selectedLabel,
        recipientName: recipient,
        phoneNumber: phone,
        fullAddress: addressText,
        notes: notes,
        latitude: _computedLat,
        longitude: _computedLng,
        isPrimary: _setAsPrimary,
      );
      _historyService.addSavedAddress(newAddr, setAsPrimary: _setAsPrimary);
      if (widget.onAddressSelected != null && _setAsPrimary) {
        widget.onAddressSelected!(newAddr.label, newAddr.fullAddress, newAddr.notes);
      }
      AppToast.show(
        context,
        title: 'Alamat Disimpan',
        subtitle: '$_selectedLabel: $addressText',
        type: ToastType.success,
      );
    }

    setState(() => _mode = _AddressSheetMode.list);
  }

  void _selectAddress(SavedAddress addr) {
    _historyService.setPrimaryAddress(addr.id);
    if (widget.onAddressSelected != null) {
      widget.onAddressSelected!(addr.label, addr.fullAddress, addr.notes);
    }
    Navigator.pop(context);
    AppToast.show(
      context,
      title: 'Alamat Pengiriman Dipilih',
      subtitle: '${addr.label}: ${addr.fullAddress}',
      type: ToastType.success,
    );
  }

  void _deleteAddress(SavedAddress addr) {
    _historyService.deleteSavedAddress(addr.id);
    setState(() {});
    AppToast.show(
      context,
      title: 'Alamat Dihapus',
      subtitle: '${addr.label} telah dihapus dari daftar.',
      type: ToastType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
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

          // Sheet Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (_mode != _AddressSheetMode.list) ...[
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(8),
                          minimumSize: Size.zero,
                        ),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        onPressed: () => setState(() => _mode = _AddressSheetMode.list),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      _mode == _AddressSheetMode.mapPicker
                          ? 'Titik Pinpoint Kurir'
                          : _mode == _AddressSheetMode.addOrEdit
                              ? (_editingAddressId != null ? 'Ubah Alamat' : 'Tambah Alamat Baru')
                              : 'Pilih Alamat Pengiriman',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(8),
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 16, color: Color(0xFFF1F5F9)),

          // Body Views
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              physics: const BouncingScrollPhysics(),
              child: _mode == _AddressSheetMode.list
                  ? _buildAddressListView(isDark)
                  : _mode == _AddressSheetMode.mapPicker
                      ? _buildInteractiveMapPickerView(isDark)
                      : _buildAddOrEditFormView(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 1. CLEAN ADDRESS LIST VIEW
  // ==========================================
  Widget _buildAddressListView(bool isDark) {
    final savedAddresses = _historyService.savedAddresses;
    final primaryAddr = _historyService.primaryAddress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action: Tambah Alamat Baru (Prominent Modern Card)
        InkWell(
          onTap: () {
            _resetForm();
            setState(() => _mode = _AddressSheetMode.addOrEdit);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.add_rounded, size: 20, color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tambah Alamat Pengiriman Baru',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tulis alamat jalan & atur titik presisi kurir',
                        style: TextStyle(fontSize: 11, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF16A34A)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Section Title
        Text(
          'Daftar Alamat Tersimpan (${savedAddresses.length})',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        if (savedAddresses.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                Icon(Icons.location_off_outlined, size: 38, color: Color(0xFF94A3B8)),
                SizedBox(height: 10),
                Text(
                  'Belum ada alamat tersimpan',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Klik tombol "Tambah Alamat Pengiriman Baru" di atas.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.secondary),
                ),
              ],
            ),
          )
        else
          ...savedAddresses.map((addr) {
            final isSelected = addr.id == primaryAddr.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.primary.withOpacity(0.1) : const Color(0xFFF0FDF4))
                    : (isDark ? AppColors.darkBackground : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Category Label & Primary Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                addr.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF334155),
                                ),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'UTAMA',
                                  style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Radio circle selection indicator
                        InkWell(
                          onTap: () => _selectAddress(addr),
                          borderRadius: BorderRadius.circular(20),
                          child: Icon(
                            isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            size: 20,
                            color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Recipient & Phone
                    InkWell(
                      onTap: () => _selectAddress(addr),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${addr.recipientName}  •  ${addr.phoneNumber}',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            addr.fullAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                              height: 1.35,
                            ),
                          ),
                          if (addr.notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Patokan: ${addr.notes}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.secondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 8),

                    // Bottom Row: Clean Modern Action Buttons (Ubah & Hapus)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Ubah Alamat Button
                            InkWell(
                              onTap: () {
                                _resetForm(addr);
                                setState(() => _mode = _AddressSheetMode.addOrEdit);
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                  borderRadius: BorderRadius.circular(6),
                                  color: isDark ? Colors.transparent : Colors.white,
                                ),
                                child: Text(
                                  'Ubah Alamat',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Hapus Button
                            InkWell(
                              onTap: () => _deleteAddress(addr),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                child: Text(
                                  'Hapus',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Pilih Alamat Button
                        if (!isSelected)
                          InkWell(
                            onTap: () => _selectAddress(addr),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Pilih',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 16),
      ],
    );
  }

  // ==========================================
  // 2. INTERACTIVE MAP PINPOINT (FOR COURIER NAVIGATION)
  // ==========================================
  Widget _buildInteractiveMapPickerView(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Search Input
        TextField(
          controller: _searchController,
          onChanged: _onSearchQueryChanged,
          style: const TextStyle(fontSize: 12.5),
          decoration: InputDecoration(
            hintText: 'Cari patokan jalan, gang, atau komplek...',
            hintStyle: const TextStyle(fontSize: 12),
            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.primary),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null,
            filled: true,
            fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),

        // Search Results List
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6, bottom: 6),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
              ],
            ),
            child: Column(
              children: _searchResults.map((res) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                  title: Text(res.shortName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    res.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: AppColors.secondary),
                  ),
                  onTap: () => _selectSearchResult(res),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 8),

        // Interactive Map Box
        GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _mapPanOffset += details.delta;
            });
          },
          onPanEnd: (_) => _updateAddressFromCoordinates(),
          child: Container(
            height: 210,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _RealTileMapRenderer(
                      latitude: _computedLat,
                      longitude: _computedLng,
                      zoom: _zoomLevel,
                      isDark: isDark,
                    ),
                  ),

                  // Center Pin Marker
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.location_pin, color: Colors.white, size: 20),
                        ),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Top GPS Status Pill
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.black : Colors.white).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isGeocodingPin || _isDetectingGps ? Icons.sync_rounded : Icons.gps_fixed_rounded,
                            size: 12,
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isGeocodingPin ? 'Mencari Gang...' : 'Titik Kurir: ${_computedLat.toStringAsFixed(4)}, ${_computedLng.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Zoom & Recenter Controls
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Column(
                      children: [
                        InkWell(
                          onTap: _fetchLiveDeviceLocation,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
                              ],
                            ),
                            child: const Icon(Icons.my_location_rounded, size: 16, color: Color(0xFF0284C7)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 3),
                            ],
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  if (_zoomLevel < 18) setState(() => _zoomLevel++);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.add, size: 16, color: Color(0xFF334155)),
                                ),
                              ),
                              const Divider(height: 1, color: Color(0xFFCBD5E1)),
                              InkWell(
                                onTap: () {
                                  if (_zoomLevel > 12) setState(() => _zoomLevel--);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.remove, size: 16, color: Color(0xFF334155)),
                                ),
                              ),
                            ],
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

        const SizedBox(height: 10),

        // Micro-Controls: Geser Manual ke Gang-gang
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.touch_app_rounded, size: 15, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Geser Presisi ke Gang:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildMicroNudgeButton(Icons.arrow_back_rounded, () => _nudgePin(25, 0)),
                  const SizedBox(width: 4),
                  _buildMicroNudgeButton(Icons.arrow_upward_rounded, () => _nudgePin(0, 25)),
                  const SizedBox(width: 4),
                  _buildMicroNudgeButton(Icons.arrow_downward_rounded, () => _nudgePin(0, -25)),
                  const SizedBox(width: 4),
                  _buildMicroNudgeButton(Icons.arrow_forward_rounded, () => _nudgePin(-25, 0)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Live Selected Pinpoint Status Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F2E28) : const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.pin_drop_rounded, size: 15, color: AppColors.primary),
                  const SizedBox(width: 6),
                  const Text(
                    'Patokan Titik Pin Kurir:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  if (_isGeocodingPin) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _liveAddressText,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text('Pasang Titik Kurir Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () {
              setState(() => _mode = _AddressSheetMode.addOrEdit);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMicroNudgeButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 15, color: AppColors.primary),
      ),
    );
  }

  // ==========================================
  // 3. CLEAN ADD / EDIT FORM VIEW (COMMERCIAL DESIGN)
  // ==========================================
  Widget _buildAddOrEditFormView(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CARD 1: KONTAK PENERIMA
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Kontak Penerima',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _recipientController,
                style: const TextStyle(fontSize: 12.5),
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap Penerima',
                  labelStyle: const TextStyle(fontSize: 11.5, color: AppColors.secondary),
                  hintText: 'Contoh: Budi Santoso',
                  filled: true,
                  fillColor: isDark ? AppColors.darkBackground : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 12.5),
                decoration: InputDecoration(
                  labelText: 'Nomor WhatsApp / Telepon',
                  labelStyle: const TextStyle(fontSize: 11.5, color: AppColors.secondary),
                  hintText: '0812-3456-7890',
                  filled: true,
                  fillColor: isDark ? AppColors.darkBackground : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // CARD 2: ALAMAT LENGKAP & PATOKAN
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Alamat Pengiriman',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                maxLines: 3,
                style: const TextStyle(fontSize: 12.5, height: 1.3),
                decoration: InputDecoration(
                  labelText: 'Alamat Jalan, No. Rumah, RT/RW, Kelurahan, Kota',
                  labelStyle: const TextStyle(fontSize: 11.5, color: AppColors.secondary),
                  hintText: 'Contoh: Jl. Danau Ranau Raya No. 45, RT 03/RW 07, Sawojajar, Kota Malang',
                  hintStyle: const TextStyle(fontSize: 11, color: Colors.black38),
                  filled: true,
                  fillColor: isDark ? AppColors.darkBackground : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                style: const TextStyle(fontSize: 12.5),
                decoration: InputDecoration(
                  labelText: 'Detail Patokan / Gang (Opsional)',
                  labelStyle: const TextStyle(fontSize: 11.5, color: AppColors.secondary),
                  hintText: 'Contoh: Masuk gang ke-2 samping pos, rumah cat hijau pagar hitam',
                  hintStyle: const TextStyle(fontSize: 11, color: Colors.black38),
                  filled: true,
                  fillColor: isDark ? AppColors.darkBackground : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // CARD 3: PINPOINT LOKASI KURIR (PETA GPS)
        InkWell(
          onTap: () => setState(() => _mode = _AddressSheetMode.mapPicker),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F2E28) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pin_drop_rounded, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Titik Presisi Kurir (Peta)',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF16A34A)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Koordinat: ${_computedLat.toStringAsFixed(4)}, ${_computedLng.toStringAsFixed(4)} (Bantu kurir langsung ke depan pintu)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Atur Pin',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // CARD 4: KATEGORI & PENGATURAN ALAMAT
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kategori Alamat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _labelOptions.map((opt) {
                  final name = opt['name'] as String;
                  final icon = opt['icon'] as IconData;
                  final isSel = _selectedLabel == name;

                  return InkWell(
                    onTap: () => setState(() => _selectedLabel = name),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.primary
                            : (isDark ? AppColors.darkBackground : Colors.white),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSel ? AppColors.primary : borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 14, color: isSel ? Colors.white : AppColors.secondary),
                          const SizedBox(width: 5),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const Divider(height: 20, color: Color(0xFFE2E8F0)),

              // Primary Address Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jadikan Alamat Utama',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Otomatis terpilih saat checkout pesanan',
                          style: TextStyle(fontSize: 10.5, color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _setAsPrimary,
                    activeTrackColor: AppColors.primary,
                    activeColor: Colors.white,
                    onChanged: (val) => setState(() => _setAsPrimary = val),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // SAVE BUTTON
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _saveAddressForm,
            child: Text(
              _editingAddressId != null ? 'Simpan Perubahan Alamat' : 'Simpan Alamat Pengiriman',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

// REAL GOOGLE MAPS / CARTO VOYAGER TILE RENDERER
class _RealTileMapRenderer extends StatelessWidget {
  final double latitude;
  final double longitude;
  final int zoom;
  final bool isDark;

  const _RealTileMapRenderer({
    required this.latitude,
    required this.longitude,
    required this.zoom,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final n = math.pow(2.0, zoom);
        final centerPx = ((longitude + 180.0) / 360.0 * n) * 256.0;
        final latRad = latitude * math.pi / 180.0;
        final centerPy = ((1.0 - (math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi)) / 2.0 * n) * 256.0;

        final topLeftPx = centerPx - (width / 2.0);
        final topLeftPy = centerPy - (height / 2.0);

        final minTileX = (topLeftPx / 256.0).floor();
        final maxTileX = ((topLeftPx + width) / 256.0).floor();
        final minTileY = (topLeftPy / 256.0).floor();
        final maxTileY = ((topLeftPy + height) / 256.0).floor();

        final List<Widget> tileWidgets = [];

        for (int tx = minTileX; tx <= maxTileX; tx++) {
          for (int ty = minTileY; ty <= maxTileY; ty++) {
            final posX = tx * 256.0 - topLeftPx;
            final posY = ty * 256.0 - topLeftPy;

            final tileUrl = 'https://a.basemaps.cartocdn.com/rastertiles/voyager/$zoom/$tx/$ty@2x.png';

            tileWidgets.add(
              Positioned(
                left: posX,
                top: posY,
                width: 256,
                height: 256,
                child: Image.network(
                  tileUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) {
                    return Image.network(
                      'https://tile.openstreetmap.org/$zoom/$tx/$ty.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        child: const Center(
                          child: Icon(Icons.map_outlined, color: Colors.black26),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }
        }

        return Stack(children: tileWidgets);
      },
    );
  }
}
