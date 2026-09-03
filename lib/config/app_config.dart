import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Compile-time environment injection via --dart-define
  static const String _dartDefineSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _dartDefineSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _dartDefineGroqApiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String _dartDefineAppEnv = String.fromEnvironment('APP_ENV', defaultValue: 'production');

  /// Supabase Project URL (Priority: --dart-define -> .env)
  static String get supabaseUrl {
    if (_dartDefineSupabaseUrl.isNotEmpty) return _dartDefineSupabaseUrl;
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  /// Supabase Anon Key (Priority: --dart-define -> .env)
  static String get supabaseAnonKey {
    if (_dartDefineSupabaseAnonKey.isNotEmpty) return _dartDefineSupabaseAnonKey;
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  /// Groq Cloud API Key (Priority: --dart-define -> .env)
  static String get groqApiKey {
    if (_dartDefineGroqApiKey.isNotEmpty) return _dartDefineGroqApiKey;
    return dotenv.env['GROQ_API_KEY'] ?? '';
  }

  /// Environment Name (development / staging / production)
  static String get appEnv => _dartDefineAppEnv;

  /// Check if running in production mode
  static bool get isProduction => _dartDefineAppEnv == 'production';
}
