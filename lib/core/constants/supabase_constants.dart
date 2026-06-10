import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access to Supabase environment configuration.
///
/// Reads values from the `.env` file loaded via `flutter_dotenv`.
/// Must be accessed only after `dotenv.load()` has been called in `main()`.
class SupabaseConstants {
  SupabaseConstants._();

  /// Supabase project REST API URL.
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';

  /// Supabase anonymous (public) API key.
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}
