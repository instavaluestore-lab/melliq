import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/company_context.dart';

class CompanyService {
  CompanyService(this._supabase);

  final SupabaseClient _supabase;

  Future<CompanyContext?> getCurrentCompanyContext() async {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      return null;
    }

    final response = await _supabase
        .from('company_members')
        .select('''
          company_id,
          user_id,
          role,
          status,
          companies (
            name
          ),
          profiles!company_members_user_id_fkey (
            email
          )
        ''')
        .eq('user_id', currentUser.id)
        .eq('status', 'active')
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    final company = response['companies'] as Map<String, dynamic>?;
    final profile =
        response['profiles'] as Map<String, dynamic>?;

    return CompanyContext.fromMap({
      'company_id': response['company_id'],
      'company_name': company?['name'] ?? 'Unknown Company',
      'user_id': response['user_id'],
      'user_email': profile?['email'] ?? currentUser.email ?? 'Unknown User',
      'role': response['role'],
      'status': response['status'],
    });
  }
}
