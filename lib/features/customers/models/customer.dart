class Customer {
  const Customer({
    required this.id,
    required this.companyId,
    this.firstName,
    this.lastName,
    this.companyName,
    this.email,
    this.phone,
    this.city,
    this.state,
    required this.customerType,
    required this.status,
    this.notes,
  });

  final String id;
  final String companyId;
  final String? firstName;
  final String? lastName;
  final String? companyName;
  final String? email;
  final String? phone;
  final String? city;
  final String? state;
  final String customerType;
  final String status;

  String get customerTypeLabel {
    final cleaned = customerType.replaceAll('_', ' ').trim();

    if (cleaned.isEmpty) {
      return 'Unknown';
    }

    return cleaned
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) {
          final lower = word.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  String get statusLabel {
    return status.replaceAll('_', ' ').trim().toUpperCase();
  }
  final String? notes;

  String get displayName {
    final fullName = [
      firstName,
      lastName,
    ].where((value) => value != null && value.trim().isNotEmpty).join(' ');

    if (fullName.isNotEmpty) return fullName;

    if (companyName != null && companyName!.trim().isNotEmpty) {
      return companyName!;
    }

    return 'Unnamed Customer';
  }

  String get location {
    final parts = [
      city,
      state,
    ].where((value) => value != null && value.trim().isNotEmpty).join(', ');

    return parts.isEmpty ? 'No location' : parts;
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      companyName: map['company_name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      customerType: map['customer_type'] as String? ?? 'residential',
      status: map['status'] as String? ?? 'active',
      notes: map['notes'] as String?,
    );
  }
}
