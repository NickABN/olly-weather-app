import 'dart:convert';
import 'wmo_codes.dart';

class HourlyForecast {
  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    required this.precipitationProbability,
  });

  final DateTime time;
  final double temperature;
  final int weatherCode;
  final int precipitationProbability;

  String get icon => wmoCodes[weatherCode]?.icon ?? '🌡️';
}

class Weather {
  const Weather({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.precipitation,
    required this.weatherCode,
    required this.isDay,
    required this.hourlyForecast,
    required this.uvIndexMax,
    required this.aqi,
    this.cityName,
    this.region,
    this.isApproximateLocation = false,
  });

  final double temperature;
  final double apparentTemperature;
  final double humidity;
  final double windSpeed;
  final int windDirection;
  final double precipitation;
  final int weatherCode;
  final bool isDay;
  final List<HourlyForecast> hourlyForecast;
  final double uvIndexMax;
  final int aqi;
  final String? cityName;
  final String? region;
  final bool isApproximateLocation;

  String get description => wmoCodes[weatherCode]?.description ?? 'Unknown';
  String get icon => wmoCodes[weatherCode]?.icon ?? '🌡️';

  factory Weather.fromJson(
    Map<String, dynamic> json, {
    int aqi = 0,
    String? cityName,
    String? region,
    bool isApproximateLocation = false,
  }) {
    final current = json['current'] as Map<String, dynamic>;
    final hourly = json['hourly'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;

    final times = hourly['time'] as List<dynamic>;
    final hourlyTemps = hourly['temperature_2m'] as List<dynamic>;
    final hourlyCodes = hourly['weather_code'] as List<dynamic>;
    final hourlyPrecip =
        hourly['precipitation_probability'] as List<dynamic>;

    final now = DateTime.now();
    final upcomingHours = <HourlyForecast>[];
    for (var i = 0; i < times.length && upcomingHours.length < 24; i++) {
      final t = DateTime.parse(times[i] as String);
      if (t.isAfter(now)) {
        upcomingHours.add(HourlyForecast(
          time: t,
          temperature: (hourlyTemps[i] as num).toDouble(),
          weatherCode: hourlyCodes[i] as int,
          precipitationProbability: (hourlyPrecip[i] as num?)?.toInt() ?? 0,
        ));
      }
    }

    final uvList = daily['uv_index_max'] as List<dynamic>;

    return Weather(
      temperature: (current['temperature_2m'] as num).toDouble(),
      apparentTemperature:
          (current['apparent_temperature'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toDouble(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      windDirection: (current['wind_direction_10m'] as num).toInt(),
      precipitation: (current['precipitation'] as num).toDouble(),
      weatherCode: current['weather_code'] as int,
      isDay: (current['is_day'] as int) == 1,
      hourlyForecast: upcomingHours,
      uvIndexMax: (uvList[0] as num).toDouble(),
      aqi: aqi,
      cityName: cityName,
      region: region,
      isApproximateLocation: isApproximateLocation,
    );
  }

  Map<String, dynamic> toJson() => {
        'temperature': temperature,
        'apparentTemperature': apparentTemperature,
        'humidity': humidity,
        'windSpeed': windSpeed,
        'windDirection': windDirection,
        'precipitation': precipitation,
        'weatherCode': weatherCode,
        'isDay': isDay,
        'uvIndexMax': uvIndexMax,
        'aqi': aqi,
        if (cityName != null) 'cityName': cityName,
        if (region != null) 'region': region,
        'isApproximateLocation': isApproximateLocation,
      };

  String toJsonString() => jsonEncode(toJson());

  factory Weather.fromJsonString(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return Weather.fromJson(
      map,
      cityName: map['cityName'] as String?,
      region: map['region'] as String?,
      isApproximateLocation: map['isApproximateLocation'] as bool? ?? false,
    );
  }
}
