class ApiConstants {
  ApiConstants._();

  static const String openMeteoBase = 'https://api.open-meteo.com/v1/forecast';
  static const String openMeteoCurrentParams =
      'temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,'
      'wind_speed_10m,wind_direction_10m,is_day,precipitation';
  static const String openMeteoHourlyParams =
      'temperature_2m,weather_code,precipitation_probability,apparent_temperature';
  static const String openMeteoDailyParams = 'uv_index_max';

  static const String bigDataCloudBase =
      'https://api.bigdatacloud.net/data/reverse-geocode-client';

  static const String airQualityBase =
      'https://air-quality-api.open-meteo.com/v1/air-quality';
  static const String airQualityCurrentParams = 'us_aqi';
}
