import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/features/weather/data/location_service.dart';
import 'package:weather_app/features/weather/data/weather_model.dart';
import 'package:weather_app/features/weather/data/weather_repository.dart';

const _cacheKey = 'weather_cache';

class WeatherController extends AsyncNotifier<Weather?> {
  final _repo = WeatherRepository();
  final _location = LocationService();

  @override
  Future<Weather?> build() async {
    return _loadCached();
  }

  Future<Weather?> _loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw != null) return Weather.fromJsonString(raw);
    return null;
  }

  Future<void> _saveCache(Weather w) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, w.toJsonString());
  }

  Future<void> requestPermissionAndRefresh() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      await refresh();
    } else if (kIsWeb) {
      // Web: no hay openAppSettings. Refrescar → IP fallback.
      await refresh();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  Future<void> refresh() async {
    final cached = state.valueOrNull;

    // Show cached immediately while fetching in background (stale-while-revalidate)
    if (cached != null) {
      _fetchAndUpdate();
    } else {
      state = const AsyncLoading();
      await _fetchAndUpdate();
    }
  }

  Future<void> _fetchAndUpdate() async {
    final loc = await _location.getLocation();
    if (loc == null) {
      state = AsyncError(
        Exception('Location unavailable'),
        StackTrace.current,
      );
      return;
    }

    try {
      final weather = await _repo.fetch(
        loc.lat,
        loc.lon,
        cityName: loc.cityName,
        region: loc.region,
        isApproximateLocation: loc.isApproximate,
      );
      await _saveCache(weather);
      state = AsyncData(weather);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final weatherControllerProvider =
    AsyncNotifierProvider<WeatherController, Weather?>(
  WeatherController.new,
);
