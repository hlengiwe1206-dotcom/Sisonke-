class SupabaseConfig {
  // Sisonke live Supabase project
  static const url = 'https://dkpdijlbcrhxhrzlchqw.supabase.co';
  static const anonKey = 'sb_publishable_XW_447uKkXgqgdTjyQkskw_W085F7xK';

  static bool get isConfigured =>
      url.isNotEmpty && anonKey.isNotEmpty;
}
