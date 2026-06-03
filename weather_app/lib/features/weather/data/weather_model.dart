import 'dart:convert';
import 'wmo_codes.dart';

class Weather {
  const Weather({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
  });

  final double temperature;
  final double humidity;
  final double windSpeed;
  final int weatherCode;

  String get description => wmoCodes[weatherCode]?.description ?? 'Unknown';
  String get icon => wmoCodes[weatherCode]?.icon ?? '🌡️';

  factory Weather.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    return Weather(
      temperature: (current['temperature_2m'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toDouble(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      weatherCode: current['weather_code'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'temperature': temperature,
        'humidity': humidity,
        'windSpeed': windSpeed,
        'weatherCode': weatherCode,
      };

  String toJsonString() => jsonEncode(toJson());

  factory Weather.fromJsonString(String raw) =>
      Weather.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
