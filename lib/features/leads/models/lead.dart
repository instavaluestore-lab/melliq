class Lead {
  const Lead({
    required this.id,
    required this.companyId,
    required this.title,
    required this.source,
    required this.status,
    required this.estimatedValue,
    required this.country,
    required this.createdAt,
    required this.updatedAt,
    this.customerId,
    this.contactName,
    this.contactEmail,
    this.contactPhone,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.notes,
    this.assignedTo,
    this.createdBy,
    this.archivedAt,
  });

  final String id;
  final String companyId;
  final String? customerId;
  final String title;
  final String? contactName;
  final String? contactEmail;
  final String? contactPhone;
  final String source;
  final String status;
  final double estimatedValue;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String country;
  final String? notes;
  final String? assignedTo;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  String get statusLabel {
    return switch (status) {
      'new' => 'New',
      'contacted' => 'Contacted',
      'scheduled' => 'Scheduled',
      'proposal_needed' => 'Proposal Needed',
      'proposal_sent' => 'Proposal Sent',
      'won' => 'Won',
      'lost' => 'Lost',
      _ => _titleCase(status),
    };
  }

  String get sourceLabel {
    return switch (source) {
      'website' => 'Website',
      'phone' => 'Phone',
      'email' => 'Email',
      'referral' => 'Referral',
      'repeat_customer' => 'Repeat Customer',
      'social_media' => 'Social Media',
      'walk_in' => 'Walk-in',
      'other' => 'Other',
      _ => _titleCase(source),
    };
  }

  String get priorityLabel {
    if (estimatedValue >= 50000) return 'High Value';
    if (estimatedValue >= 15000) return 'Strong Lead';
    if (estimatedValue > 0) return 'Standard';
    return 'Unpriced';
  }

  String get displayContact {
    final cleanName = contactName?.trim();
    if (cleanName != null && cleanName.isNotEmpty) return cleanName;

    final cleanEmail = contactEmail?.trim();
    if (cleanEmail != null && cleanEmail.isNotEmpty) return cleanEmail;

    final cleanPhone = contactPhone?.trim();
    if (cleanPhone != null && cleanPhone.isNotEmpty) return cleanPhone;

    return 'No contact added';
  }

  String get displayLocation {
    final parts = [
      city,
      state,
      postalCode,
    ].where((part) => part != null && part.trim().isNotEmpty).cast<String>();

    final location = parts.join(', ');
    if (location.isNotEmpty) return location;

    final address = addressLine1?.trim();
    if (address != null && address.isNotEmpty) return address;

    return 'No location added';
  }

  factory Lead.fromMap(Map<String, dynamic> map) {
    return Lead(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      customerId: map['customer_id'] as String?,
      title: map['title'] as String? ?? '',
      contactName: map['contact_name'] as String?,
      contactEmail: map['contact_email'] as String?,
      contactPhone: map['contact_phone'] as String?,
      source: map['source'] as String? ?? 'other',
      status: map['status'] as String? ?? 'new',
      estimatedValue: _toDouble(map['estimated_value']),
      addressLine1: map['address_line_1'] as String?,
      addressLine2: map['address_line_2'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      postalCode: map['postal_code'] as String?,
      country: map['country'] as String? ?? 'US',
      notes: map['notes'] as String?,
      assignedTo: map['assigned_to'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      archivedAt: map['archived_at'] == null
          ? null
          : DateTime.parse(map['archived_at'] as String),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0;
  }

  static String _titleCase(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
