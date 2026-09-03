class SavedAddress {
  final String id;
  final String label; // Rumah, Kantor, Apartemen, Kos, Villa / Liburan, Lainnya
  final String recipientName;
  final String phoneNumber;
  final String fullAddress;
  final String notes;
  final double latitude;
  final double longitude;
  final bool isPrimary;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phoneNumber,
    required this.fullAddress,
    this.notes = '',
    this.latitude = -6.2255,
    this.longitude = 106.8090,
    this.isPrimary = false,
  });

  SavedAddress copyWith({
    String? id,
    String? label,
    String? recipientName,
    String? phoneNumber,
    String? fullAddress,
    String? notes,
    double? latitude,
    double? longitude,
    bool? isPrimary,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullAddress: fullAddress ?? this.fullAddress,
      notes: notes ?? this.notes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'recipient_name': recipientName,
      'phone_number': phoneNumber,
      'full_address': fullAddress,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'is_primary': isPrimary,
    };
  }

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id']?.toString() ?? '',
      label: json['label'] as String? ?? 'Rumah',
      recipientName: (json['recipient_name'] ?? json['recipientName']) as String? ?? 'Penerima',
      phoneNumber: (json['phone_number'] ?? json['phoneNumber']) as String? ?? '',
      fullAddress: (json['full_address'] ?? json['fullAddress']) as String? ?? '',
      notes: json['notes'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? -6.2255,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 106.8090,
      isPrimary: (json['is_primary'] ?? json['isPrimary']) as bool? ?? false,
    );
  }
}
