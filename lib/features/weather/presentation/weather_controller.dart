import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/location_service.dart';
import '../data/weather_model.dart';
import '../data/weather_repository.dart';

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
        Exception('Location permission denied or unavailable'),
        StackTrace.current,
      );
      return;
    }

    try {
      final weather = await _repo.fetch(loc.lat, loc.lon);
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
