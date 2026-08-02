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
            name,
              brand_name,
              workspace_name,
              logo_url,
              login_subtitle,
              primary_brand_color,
              accent_brand_color,
              powered_by_lupinusbuild
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
    final profile = response['profiles'] as Map<String, dynamic>?;

    return CompanyContext.fromMap({
      'company_id': response['company_id'],
      'company_name': company?['name'] ?? 'Unknown Company',
      'brand_name': company?['brand_name'],
      'workspace_name': company?['workspace_name'],
      'logo_url': company?['logo_url'],
      'login_subtitle': company?['login_subtitle'],
      'primary_brand_color': company?['primary_brand_color'],
      'accent_brand_color': company?['accent_brand_color'],
      'powered_by_lupinusbuild': company?['powered_by_lupinusbuild'] ?? true,
      'user_id': response['user_id'],
      'user_email': profile?['email'] ?? currentUser.email ?? 'Unknown User',
      'role': response['role'],
      'status': response['status'],
    });
  }
}
