import 'package:geolocator/geolocator.dart';

class LocationResult {
  const LocationResult({required this.lat, required this.lon});
  final double lat;
  final double lon;
}

class LocationService {
  Future<LocationResult?> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    final pos = await Geolocator.getCurrentPosition();
    return LocationResult(lat: pos.latitude, lon: pos.longitude);
  }
}
