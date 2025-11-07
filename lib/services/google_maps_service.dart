import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapsService {
  static final GoogleMapsService instance = GoogleMapsService._();
  GoogleMapsService._();

  // Prefer passing at build time: --dart-define=GOOGLE_MAPS_API_KEY=XXXX
  static const String _apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyCmdngbXx6VBraDfM3-NgKbA0q7DAjcl3Q',
  );

  Future<DirectionsResult?> getDirections(
      LatLng origin, LatLng destination) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=walking&alternatives=false&key=$_apiKey',
    );

    final resp = await http.get(url);
    if (resp.statusCode != 200) return null;
    final data = json.decode(resp.body) as Map<String, dynamic>;
    if (data['status'] != 'OK' || (data['routes'] as List).isEmpty) return null;

    final route = (data['routes'] as List).first as Map<String, dynamic>;
    final overview = route['overview_polyline']['points'] as String;
    final leg = (route['legs'] as List).first as Map<String, dynamic>;
    final distanceText = leg['distance']['text'] as String;
    final durationText = leg['duration']['text'] as String;
    final points =
        _decodePolyline(overview).map((e) => LatLng(e.item1, e.item2)).toList();

    // Parse detailed steps
    final rawSteps = (leg['steps'] as List? ?? []);
    final steps = rawSteps.map((raw) {
      final m = raw as Map<String, dynamic>;
      final instrHtml = (m['html_instructions'] as String?) ?? '';
      final instruction = _stripHtml(instrHtml);
      final distance = (m['distance']?['text'] as String?) ?? '';
      final duration = (m['duration']?['text'] as String?) ?? '';
      final maneuver = m['maneuver'] as String?;
      final poly = (m['polyline']?['points'] as String?) ?? '';
      final stepPoints =
          _decodePolyline(poly).map((e) => LatLng(e.item1, e.item2)).toList();

      final startLoc = m['start_location'] as Map<String, dynamic>?;
      final endLoc = m['end_location'] as Map<String, dynamic>?;
      final start = startLoc != null
          ? LatLng((startLoc['lat'] as num).toDouble(),
              (startLoc['lng'] as num).toDouble())
          : (stepPoints.isNotEmpty ? stepPoints.first : points.first);
      final end = endLoc != null
          ? LatLng((endLoc['lat'] as num).toDouble(),
              (endLoc['lng'] as num).toDouble())
          : (stepPoints.isNotEmpty ? stepPoints.last : points.last);

      return DirectionStep(
        instruction: instruction,
        distanceText: distance,
        durationText: duration,
        points: stepPoints,
        startLocation: start,
        endLocation: end,
        maneuver: maneuver,
      );
    }).toList();

    return DirectionsResult(
      points: points,
      steps: steps,
      distanceText: distanceText,
      durationText: durationText,
    );
  }

  Future<List<PlaceResult>> getNearbyParking(LatLng location,
      {int radiusMeters = 800}) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${location.latitude},${location.longitude}'
      '&radius=$radiusMeters&type=parking&key=$_apiKey',
    );
    final resp = await http.get(url);
    if (resp.statusCode != 200) return [];
    final data = json.decode(resp.body) as Map<String, dynamic>;
    final results = (data['results'] as List? ?? []);
    return results.map((raw) {
      final m = raw as Map<String, dynamic>;
      final geom = m['geometry']['location'] as Map<String, dynamic>;
      return PlaceResult(
        name: (m['name'] as String?) ?? 'Parking',
        position: LatLng(
            (geom['lat'] as num).toDouble(), (geom['lng'] as num).toDouble()),
        placeId: (m['place_id'] as String?) ?? '',
        vicinity: m['vicinity'] as String?,
        rating: (m['rating'] as num?)?.toDouble(),
        userRatingsTotal: (m['user_ratings_total'] as num?)?.toInt(),
        openNow: (m['opening_hours'] != null)
            ? (m['opening_hours']['open_now'] as bool?)
            : null,
      );
    }).toList();
  }

  // Polyline decoder returning list of (lat, lng)
  List<_Tuple> _decodePolyline(String encoded) {
    final List<_Tuple> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(_Tuple(lat / 1e5, lng / 1e5));
    }
    return poly;
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&', '&')
        .replaceAll(RegExp(r'\\s+'), ' ')
        .trim();
  }
}

class DirectionsResult {
  final List<LatLng> points;
  final List<DirectionStep> steps;
  final String distanceText;
  final String durationText;
  DirectionsResult({
    required this.points,
    required this.steps,
    required this.distanceText,
    required this.durationText,
  });
}

class DirectionStep {
  final String instruction;
  final String distanceText;
  final String durationText;
  final List<LatLng> points;
  final LatLng startLocation;
  final LatLng endLocation;
  final String? maneuver;
  DirectionStep({
    required this.instruction,
    required this.distanceText,
    required this.durationText,
    required this.points,
    required this.startLocation,
    required this.endLocation,
    this.maneuver,
  });
}

class PlaceResult {
  final String name;
  final LatLng position;
  final String placeId;
  final String? vicinity;
  final double? rating;
  final int? userRatingsTotal;
  final bool? openNow;
  PlaceResult({
    required this.name,
    required this.position,
    required this.placeId,
    this.vicinity,
    this.rating,
    this.userRatingsTotal,
    this.openNow,
  });
}

class _Tuple {
  final double item1;
  final double item2;
  _Tuple(this.item1, this.item2);
}
