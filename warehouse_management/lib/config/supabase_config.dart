import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://ozadmtmkrkwbolzbqtif.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im96YWRtdG1rcmt3Ym9semJxdGlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4MDMyODUsImV4cCI6MjA4MzM3OTI4NX0.dMRtIAEkg6C7IlHqxWUWR9TQxJY7RYmTQ5UoXnKBR4U';

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    _isInitialized = true;
  }

  static bool get isInitialized => _isInitialized;

  static SupabaseClient get client => Supabase.instance.client;
}
