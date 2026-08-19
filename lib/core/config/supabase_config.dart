class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://iegwgncvanxbzeunzgpa.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_QfKWO6PrdqhBUzWt7le9qw_sWiU2xCP',
  );
}
