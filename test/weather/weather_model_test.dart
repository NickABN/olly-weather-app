import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/weather/data/weather_model.dart';

/// Minimal Open-Meteo-shaped payload for parsing tests.
Map<String, dynamic> _apiJson() => {
      'current': {
        'temperature_2m': 21.4,
        'apparent_temperature': 20.1,
        'relative_humidity_2m': 55,
        'wind_speed_10m': 12.0,
        'wind_direction_10m': 270,
        'precipitation': 0.0,
        'weather_code': 3,
        'is_day': 1,
      },
      'hourly': {
        'time': [
          '2999-01-01T00:00',
          '2999-01-01T01:00',
        ],
        'temperature_2m': [22.0, 23.0],
        'weather_code': [3, 1],
        'precipitation_probability': [10, 20],
      },
      'daily': {
        'uv_index_max': [6.5],
      },
    };

void main() {
  group('Weather.fromJson (API payload)', () {
    test('parses current fields', () {
      final w = Weather.fromJson(_apiJson(), aqi: 42, cityName: 'Morelia');

      expect(w.temperature, 21.4);
      expect(w.apparentTemperature, 20.1);
      expect(w.humidity, 55);
      expect(w.windDirection, 270);
      expect(w.weatherCode, 3);
      expect(w.isDay, isTrue);
      expect(w.uvIndexMax, 6.5);
      expect(w.aqi, 42);
      expect(w.cityName, 'Morelia');
      expect(w.description, 'Overcast');
    });

    test('keeps only future hourly entries', () {
      final w = Weather.fromJson(_apiJson());
      // Both sample times are in year 2999 → future → both kept.
      expect(w.hourlyForecast.length, 2);
      expect(w.hourlyForecast.first.temperature, 22.0);
    });
  });

  group('cache round-trip (toJsonString -> fromJsonString)', () {
    test('survives serialize/deserialize without throwing', () {
      final original = Weather.fromJson(
        _apiJson(),
        aqi: 42,
        cityName: 'Morelia',
        region: 'MIC, MX',
        isApproximateLocation: true,
      );

      final restored = Weather.fromJsonString(original.toJsonString());

      expect(restored.temperature, original.temperature);
      expect(restored.humidity, original.humidity);
      expect(restored.weatherCode, original.weatherCode);
      expect(restored.uvIndexMax, original.uvIndexMax);
      expect(restored.aqi, original.aqi);
      expect(restored.cityName, 'Morelia');
      expect(restored.region, 'MIC, MX');
      expect(restored.isApproximateLocation, isTrue);
      expect(restored.description, original.description);
    });
  });
}
