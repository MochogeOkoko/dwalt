import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://yzmhhoyesraijaakucci.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl6bWhob3llc3JhaWphYWt1Y2NpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ2NDIxNzEsImV4cCI6MjA3MDIxODE3MX0.tKlg536oXyn4vaaqA1HsAhqZcL75hda6rdOBf6p4NsE',
      debug: true,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
