class ApiConstants {
  ApiConstants._();

  static const String openMeteoBase = 'https://api.open-meteo.com/v1/forecast';
  static const String openMeteoCurrentParams =
      'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m';

  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
