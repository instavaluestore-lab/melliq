import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lead.dart';

class LeadService {
  LeadService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<Lead>> getLeadsForCompany({
    required String companyId,
    bool includeArchived = false,
  }) async {
    var query = _supabase
        .from('leads')
        .select()
        .eq('company_id', companyId);

    if (!includeArchived) {
      query = query.isFilter('archived_at', null);
    }

    final rows = await query
        .order('created_at', ascending: false)
        .order('updated_at', ascending: false);

    return rows.map<Lead>(Lead.fromMap).toList();
  }

  Future<Lead> createLead({
    required String companyId,
    required String title,
    required String source,
    required String status,
    required double estimatedValue,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String country = 'US',
    String? notes,
    String? assignedTo,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    final row = await _supabase
        .from('leads')
        .insert({
          'company_id': companyId,
          'title': title.trim(),
          'source': source,
          'status': status,
          'estimated_value': estimatedValue,
          'contact_name': _emptyToNull(contactName),
          'contact_email': _emptyToNull(contactEmail),
          'contact_phone': _emptyToNull(contactPhone),
          'address_line_1': _emptyToNull(addressLine1),
          'address_line_2': _emptyToNull(addressLine2),
          'city': _emptyToNull(city),
          'state': _emptyToNull(state),
          'postal_code': _emptyToNull(postalCode),
          'country': country.trim().isEmpty ? 'US' : country.trim(),
          'notes': _emptyToNull(notes),
          'assigned_to': assignedTo,
          'created_by': userId,
        })
        .select()
        .single();

    return Lead.fromMap(row);
  }

  Future<Lead> updateLead({
    required String id,
    required String title,
    required String source,
    required String status,
    required double estimatedValue,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String country = 'US',
    String? notes,
    String? assignedTo,
  }) async {
    final row = await _supabase
        .from('leads')
        .update({
          'title': title.trim(),
          'source': source,
          'status': status,
          'estimated_value': estimatedValue,
          'contact_name': _emptyToNull(contactName),
          'contact_email': _emptyToNull(contactEmail),
          'contact_phone': _emptyToNull(contactPhone),
          'address_line_1': _emptyToNull(addressLine1),
          'address_line_2': _emptyToNull(addressLine2),
          'city': _emptyToNull(city),
          'state': _emptyToNull(state),
          'postal_code': _emptyToNull(postalCode),
          'country': country.trim().isEmpty ? 'US' : country.trim(),
          'notes': _emptyToNull(notes),
          'assigned_to': assignedTo,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();

    return Lead.fromMap(row);
  }

  Future<void> archiveLead(String id) async {
    await _supabase
        .from('leads')
        .update({
          'archived_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    return trimmed;
  }
}
