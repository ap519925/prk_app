import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class DirectionsStep {
  final String instruction;
  final String distance;
  final String duration;
  final LatLng startLocation;
  final LatLng endLocation;
  final String maneuver;
  final double distanceValue; // in meters
  final int durationValue; // in seconds

  DirectionsStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    required this.maneuver,
    required this.distanceValue,
    required this.durationValue,
  });

  factory DirectionsStep.fromJson(Map<String, dynamic> json) {
    return DirectionsStep(
      instruction: json['html_instructions'] ?? '',
      distance: json['distance']['text'] ?? '',
      duration: json['duration']['text'] ?? '',
      distanceValue: (json['distance']['value'] ?? 0).toDouble(),
      durationValue: json['duration']['value'] ?? 0,
      startLocation: LatLng(
        json['start_location']['lat'],
        json['start_location']['lng'],
      ),
      endLocation: LatLng(
        json['end_location']['lat'],
        json['end_location']['lng'],
      ),
      maneuver: json['maneuver'] ?? 'straight',
    );
  }

  // Clean HTML tags from instruction
  String get cleanInstruction {
    return instruction
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ');
  }
}

class DirectionsRoute {
  final List<LatLng> polylinePoints;
  final List<DirectionsStep> steps;
  final String totalDistance;
  final String totalDuration;
  final double totalDistanceValue; // in meters
  final int totalDurationValue; // in seconds
  final LatLng startLocation;
  final LatLng endLocation;

  DirectionsRoute({
    required this.polylinePoints,
    required this.steps,
    required this.totalDistance,
    required this.totalDuration,
    required this.totalDistanceValue,
    required this.totalDurationValue,
    required this.startLocation,
    required this.endLocation,
  });
}

class DirectionsService {
  static final DirectionsService instance = DirectionsService._();
  DirectionsService._();

  // NOTE: Make sure Google Directions API is enabled in your Google Cloud Console
  // Same API key used for Google Maps
  static const String _apiKey = 'AIzaSyCmdngbXx6VBraDfM3-NgKbA0q7DAjcl3Q';

  Future<DirectionsRoute?> getDirections({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'driving',
  }) async {
    try {
      final String url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=$travelMode'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          return _parseDirections(data['routes'][0]);
        } else {
          print('Directions API error: ${data['status']}');
          if (data['error_message'] != null) {
            print('Error message: ${data['error_message']}');
          }
          // Return a fallback route with direct line
          return _createFallbackRoute(origin, destination);
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        return _createFallbackRoute(origin, destination);
      }
    } catch (e) {
      print('Error fetching directions: $e');
      return _createFallbackRoute(origin, destination);
    }
  }

  DirectionsRoute _parseDirections(Map<String, dynamic> route) {
    final leg = route['legs'][0];
    final List<DirectionsStep> steps = [];

    // Parse steps
    for (var step in leg['steps']) {
      steps.add(DirectionsStep.fromJson(step));
    }

    // Decode polyline
    final polylinePoints = PolylinePoints()
        .decodePolyline(route['overview_polyline']['points']);

    final latLngPoints = polylinePoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    return DirectionsRoute(
      polylinePoints: latLngPoints,
      steps: steps,
      totalDistance: leg['distance']['text'] ?? '',
      totalDuration: leg['duration']['text'] ?? '',
      totalDistanceValue: (leg['distance']['value'] ?? 0).toDouble(),
      totalDurationValue: leg['duration']['value'] ?? 0,
      startLocation: LatLng(
        leg['start_location']['lat'],
        leg['start_location']['lng'],
      ),
      endLocation: LatLng(
        leg['end_location']['lat'],
        leg['end_location']['lng'],
      ),
    );
  }

  // Fallback route with direct line (when API fails or key is not set)
  DirectionsRoute _createFallbackRoute(LatLng origin, LatLng destination) {
    // Calculate approximate distance
    final distance = _calculateDistance(origin, destination);
    final distanceKm = distance / 1000;
    final durationMinutes = (distanceKm / 40 * 60).round(); // Assume 40 km/h average

    return DirectionsRoute(
      polylinePoints: [origin, destination],
      steps: [
        DirectionsStep(
          instruction: 'Head toward destination',
          distance: '${distance.toStringAsFixed(0)} m',
          duration: '$durationMinutes min',
          distanceValue: distance,
          durationValue: durationMinutes * 60,
          startLocation: origin,
          endLocation: destination,
          maneuver: 'straight',
        ),
      ],
      totalDistance: distanceKm >= 1
          ? '${distanceKm.toStringAsFixed(1)} km'
          : '${distance.toStringAsFixed(0)} m',
      totalDuration: '$durationMinutes min',
      totalDistanceValue: distance,
      totalDurationValue: durationMinutes * 60,
      startLocation: origin,
      endLocation: destination,
    );
  }

  double _calculateDistance(LatLng from, LatLng to) {
    const double earthRadius = 6371000; // meters
    final dLat = _degreesToRadians(to.latitude - from.latitude);
    final dLon = _degreesToRadians(to.longitude - from.longitude);

    final a = (dLat / 2).sin() * (dLat / 2).sin() +
        from.latitude.toRadians().cos() *
            to.latitude.toRadians().cos() *
            (dLon / 2).sin() *
            (dLon / 2).sin();

    final c = 2 * a.sqrt().asin();
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * 3.141592653589793 / 180;
  }

  // Get the current navigation step based on user's position
  DirectionsStep? getCurrentStep(
    List<DirectionsStep> steps,
    LatLng currentPosition,
  ) {
    for (var step in steps) {
      final distanceToEnd = _calculateDistance(currentPosition, step.endLocation);
      if (distanceToEnd > 10) {
        // Still heading toward this step (10 meter threshold)
        return step;
      }
    }
    return steps.isNotEmpty ? steps.last : null;
  }

  // Calculate remaining distance from current position
  double calculateRemainingDistance(
    LatLng currentPosition,
    DirectionsRoute route,
  ) {
    double totalRemaining = 0;
    bool foundCurrent = false;

    for (int i = 0; i < route.polylinePoints.length - 1; i++) {
      if (!foundCurrent) {
        final distanceToPoint = _calculateDistance(
          currentPosition,
          route.polylinePoints[i],
        );
        if (distanceToPoint < 50) {
          // Within 50 meters
          foundCurrent = true;
          totalRemaining += _calculateDistance(
            currentPosition,
            route.polylinePoints[i + 1],
          );
        }
      } else {
        totalRemaining += _calculateDistance(
          route.polylinePoints[i],
          route.polylinePoints[i + 1],
        );
      }
    }

    return foundCurrent ? totalRemaining : route.totalDistanceValue;
  }
}

extension DoubleExtensions on double {
  double toRadians() => this * 3.141592653589793 / 180;
  double sin() => this < 0 ? -(-this).sin() : this % (2 * 3.141592653589793);
  double cos() => (this + 3.141592653589793 / 2).sin();
  double sqrt() {
    if (this < 0) return double.nan;
    if (this == 0) return 0;
    double x = this;
    double last;
    do {
      last = x;
      x = (x + this / x) / 2;
    } while ((x - last).abs() > 0.000001);
    return x;
  }
  double asin() {
    if (this < -1 || this > 1) return double.nan;
    return this / (1 + (1 - this * this).sqrt());
  }
}
