enum CustomerStatus {
  active('Active', 0xFF10B981),
  lead('New Lead', 0xFF3B82F6),
  prospect('Prospect', 0xFFF59E0B),
  inactive('Inactive', 0xFF94A3B8);

  final String label;
  final int colorValue;

  const CustomerStatus(this.label, this.colorValue);

  static CustomerStatus fromString(String? value) {
    if (value == null) return CustomerStatus.lead;
    return CustomerStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => CustomerStatus.lead,
    );
  }
}

class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String company;
  final String? avatarUrl;
  final CustomerStatus status;
  final String notes;
  final DateTime createdAt;
  final String? address;
  final String category;
  final String? website;
  final List<String> ownerNames;
  final List<String> phoneNumbers;
  final String? frontDriveUrl;
  final String? backDriveUrl;
  final String? driveUrl;
  final double? latitude;
  final double? longitude;

  const Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    this.avatarUrl,
    required this.status,
    required this.notes,
    required this.createdAt,
    this.address,
    this.category = 'General Business',
    this.website,
    this.ownerNames = const [],
    this.phoneNumbers = const [],
    this.frontDriveUrl,
    this.backDriveUrl,
    this.driveUrl,
    this.latitude,
    this.longitude,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? company,
    String? avatarUrl,
    CustomerStatus? status,
    String? notes,
    DateTime? createdAt,
    String? address,
    String? category,
    String? website,
    List<String>? ownerNames,
    List<String>? phoneNumbers,
    String? frontDriveUrl,
    String? backDriveUrl,
    String? driveUrl,
    double? latitude,
    double? longitude,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      address: address ?? this.address,
      category: category ?? this.category,
      website: website ?? this.website,
      ownerNames: ownerNames ?? this.ownerNames,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      frontDriveUrl: frontDriveUrl ?? this.frontDriveUrl,
      backDriveUrl: backDriveUrl ?? this.backDriveUrl,
      driveUrl: driveUrl ?? this.driveUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'avatarUrl': avatarUrl,
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'address': address,
      'category': category,
      'website': website,
      'ownerNames': ownerNames,
      'phoneNumbers': phoneNumbers,
      'frontDriveUrl': frontDriveUrl,
      'backDriveUrl': backDriveUrl,
      'driveUrl': driveUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      company: json['company'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      status: CustomerStatus.fromString(json['status'] as String?),
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      address: json['address'] as String?,
      category: json['category'] as String? ?? 'General Business',
      website: json['website'] as String?,
      ownerNames: (json['ownerNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      phoneNumbers: (json['phoneNumbers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      frontDriveUrl: json['frontDriveUrl'] as String?,
      backDriveUrl: json['backDriveUrl'] as String?,
      driveUrl: json['driveUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  String get initials {
    final cleanCompany = company.trim();
    if (cleanCompany.isNotEmpty) {
      final parts = cleanCompany.split(' ');
      if (parts.length == 1 && parts[0].isNotEmpty) {
        return parts[0][0].toUpperCase();
      } else if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
    }
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return 'C';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
