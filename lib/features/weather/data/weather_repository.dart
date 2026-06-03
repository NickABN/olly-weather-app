import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:weather_app/core/constants/api_constants.dart';
import 'package:weather_app/features/weather/data/weather_model.dart';

class WeatherRepository {
  Future<Weather> fetch(
    double lat,
    double lon, {
    String? cityName,
    String? region,
    bool isApproximateLocation = false,
  }) async {
    final latStr = lat.toString();
    final lonStr = lon.toString();

    final forecastUri = Uri.parse(ApiConstants.openMeteoBase).replace(
      queryParameters: {
        'latitude': latStr,
        'longitude': lonStr,
        'current': ApiConstants.openMeteoCurrentParams,
        'hourly': ApiConstants.openMeteoHourlyParams,
        'daily': ApiConstants.openMeteoDailyParams,
        'timezone': 'auto',
        'forecast_days': '2',
      },
    );

    final aqiUri = Uri.parse(ApiConstants.airQualityBase).replace(
      queryParameters: {
        'latitude': latStr,
        'longitude': lonStr,
        'current': ApiConstants.airQualityCurrentParams,
        'timezone': 'auto',
      },
    );

    final results = await Future.wait([
      http.get(forecastUri),
      http.get(aqiUri),
    ]);

    final forecastRes = results[0];
    final aqiRes = results[1];

    if (forecastRes.statusCode != 200) {
      throw Exception('Weather fetch failed: ${forecastRes.statusCode}');
    }

    int aqi = 0;
    if (aqiRes.statusCode == 200) {
      final aqiJson = jsonDecode(aqiRes.body) as Map<String, dynamic>;
      final aqiCurrent = aqiJson['current'] as Map<String, dynamic>;
      aqi = (aqiCurrent['us_aqi'] as num?)?.toInt() ?? 0;
    }

    return Weather.fromJson(
      jsonDecode(forecastRes.body) as Map<String, dynamic>,
      aqi: aqi,
      cityName: cityName,
      region: region,
      isApproximateLocation: isApproximateLocation,
    );
  }
}
