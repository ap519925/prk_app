import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  Future<void> initialize() async {
    // Check permissions on startup
    await checkPermissions();
  }

  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Attempt to prompt the user to enable location services
      await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      if (!await checkPermissions()) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  Stream<Position> getPositionStream({LocationAccuracy accuracy = LocationAccuracy.best}) {
    final locationSettings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: 5, // meters
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  Future<String?> getAddressFromCoordinates(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}'
            .replaceAll(', , ', ', ')
            .replaceAll(RegExp(r'^, |, $'), '');
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return null;
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  bool isNearLocation(Position current, double targetLat, double targetLon, {double radiusMeters = 50}) {
    double distance = calculateDistance(
      current.latitude,
      current.longitude,
      targetLat,
      targetLon,
    );
    return distance <= radiusMeters;
  }
}

