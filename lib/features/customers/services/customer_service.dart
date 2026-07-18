import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer.dart';

class CustomerService {
  CustomerService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<Customer>> getCustomersForCompany(String companyId) async {
    final response = await _supabase
        .from('customers')
        .select('''
          id,
          company_id,
          first_name,
          last_name,
          company_name,
          email,
          phone,
          city,
          state,
          customer_type,
          status,
          notes
        ''')
        .eq('company_id', companyId)
        .neq('status', 'archived')
        .order('created_at', ascending: false);

    return response
        .map<Customer>(
          (item) => Customer.fromMap(item),
        )
        .toList();
  }

  Future<Customer> getCustomerById(String customerId) async {
    final response = await _supabase
        .from('customers')
        .select('''
          id,
          company_id,
          first_name,
          last_name,
          company_name,
          email,
          phone,
          city,
          state,
          customer_type,
          status,
          notes
        ''')
        .eq('id', customerId)
        .single();

    return Customer.fromMap(response);
  }

  Future<Customer> createCustomer({
    required String companyId,
    required String createdBy,
    required String firstName,
    required String lastName,
    required String companyName,
    required String email,
    required String phone,
    required String city,
    required String state,
    required String customerType,
    required String notes,
  }) async {
    final response = await _supabase
        .from('customers')
        .insert({
          'company_id': companyId,
          'created_by': createdBy,
          'first_name': _emptyToNull(firstName),
          'last_name': _emptyToNull(lastName),
          'company_name': _emptyToNull(companyName),
          'email': _emptyToNull(email),
          'phone': _emptyToNull(phone),
          'city': _emptyToNull(city),
          'state': _emptyToNull(state),
          'customer_type': customerType,
          'status': 'active',
          'notes': _emptyToNull(notes),
        })
        .select('''
          id,
          company_id,
          first_name,
          last_name,
          company_name,
          email,
          phone,
          city,
          state,
          customer_type,
          status,
          notes
        ''')
        .single();

    return Customer.fromMap(response);
  }

  Future<void> updateCustomer({
    required String customerId,
    required String firstName,
    required String lastName,
    required String companyName,
    required String email,
    required String phone,
    required String city,
    required String state,
    required String customerType,
    required String status,
    required String notes,
  }) async {
    await _supabase.from('customers').update({
      'first_name': _emptyToNull(firstName),
      'last_name': _emptyToNull(lastName),
      'company_name': _emptyToNull(companyName),
      'email': _emptyToNull(email),
      'phone': _emptyToNull(phone),
      'city': _emptyToNull(city),
      'state': _emptyToNull(state),
      'customer_type': customerType,
      'status': status,
      'notes': _emptyToNull(notes),
    }).eq('id', customerId);
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
