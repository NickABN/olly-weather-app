import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/core/constants/api_constants.dart';

class LocationResult {
  const LocationResult({
    required this.lat,
    required this.lon,
    this.cityName,
    this.region,
    this.isApproximate = false,
  });

  final double lat;
  final double lon;
  final String? cityName;
  final String? region;
  final bool isApproximate;
}

class LocationService {
  Future<LocationResult?> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return _resolveByIp();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return _resolveByIp();
    }

    final pos = await Geolocator.getCurrentPosition();
    return _resolvePlaceName(pos.latitude, pos.longitude);
  }

  Future<LocationResult?> _resolvePlaceName(double lat, double lon) async {
    try {
      final uri = Uri.parse(ApiConstants.bigDataCloudBase).replace(
        queryParameters: {
          'latitude': lat.toString(),
          'longitude': lon.toString(),
          'localityLanguage': 'en',
        },
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        return LocationResult(lat: lat, lon: lon);
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return LocationResult(
        lat: lat,
        lon: lon,
        cityName: _nonEmpty(data['city'] as String?),
        region: _buildRegion(
          data['principalSubdivision'] as String?,
          data['countryCode'] as String?,
        ),
      );
    } catch (_) {
      return LocationResult(lat: lat, lon: lon);
    }
  }

  Future<LocationResult?> _resolveByIp() async {
    try {
      final uri = Uri.parse(ApiConstants.bigDataCloudBase).replace(
        queryParameters: {'localityLanguage': 'en'},
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final lat = (data['latitude'] as num?)?.toDouble();
      final lon = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lon == null) return null;
      return LocationResult(
        lat: lat,
        lon: lon,
        cityName: _nonEmpty(data['city'] as String?),
        region: _buildRegion(
          data['principalSubdivision'] as String?,
          data['countryCode'] as String?,
        ),
        isApproximate: true,
      );
    } catch (_) {
      return null;
    }
  }

  String? _nonEmpty(String? s) =>
      (s != null && s.isNotEmpty) ? s : null;

  String? _buildRegion(String? sub, String? cc) {
    final parts = [sub, cc].where((s) => s != null && s.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : null;
  }
}
