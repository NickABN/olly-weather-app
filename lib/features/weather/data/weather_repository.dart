import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:weather_app/core/constants/api_constants.dart';
import 'package:weather_app/features/weather/data/weather_model.dart';

class WeatherRepository {
  Future<Weather> fetch(double lat, double lon) async {
    final uri = Uri.parse(ApiConstants.openMeteoBase).replace(
      queryParameters: {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'current': ApiConstants.openMeteoCurrentParams,
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Weather fetch failed: ${response.statusCode}');
    }

    return Weather.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
