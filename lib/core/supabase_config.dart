class SupabaseConfig {
  // Sisonke live Supabase project
  static const url = 'https://dkpdijlbcrhxhrzlchqw.supabase.co';

  // Supabase publishable key.
  // This key is safe for use in the Flutter client when
  // Row Level Security is correctly configured.
  static const publishableKey =
      'sb_publishable_XW_447uKkXgqgdTjyQkskw_W085F7xK';

  static bool get isConfigured =>
      url.isNotEmpty && publishableKey.isNotEmpty;
}
