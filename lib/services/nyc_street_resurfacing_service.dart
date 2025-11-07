import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class NYCDOTStreetResurfacingService {
  static final NYCDOTStreetResurfacingService instance =
      NYCDOTStreetResurfacingService._();
  NYCDOTStreetResurfacingService._();

  static const String _url =
      'https://data.cityofnewyork.us/resource/xnfm-u3k5.json';
  static const String? _appToken = null;

  Future<List<StreetResurfacing>> getResurfacingNearby(LatLng center,
      {int radiusMeters = 1400}) async {
    final query = {
      '\$where':
          'within_circle(geometry, ${center.latitude}, ${center.longitude}, $radiusMeters)',
      '\$limit': '200',
    };
    try {
      final uri = Uri.parse(_url).replace(queryParameters: query);
      final headers = <String, String>{
        'Accept': 'application/json',
        if (_appToken != null) 'X-App-Token': _appToken!,
      };
      final resp = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return [];
      final List<dynamic> list = json.decode(resp.body);
      return list
          .map((m) => StreetResurfacing.fromNYCJson(m))
          .where((e) => e != null)
          .cast<StreetResurfacing>()
          .toList();
    } catch (e) {
      print('Error fetching resurfacing: $e');
      return [];
    }
  }
}

class StreetResurfacing {
  final String? status; // e.g. In Progress, Scheduled, Completed
  final String? operation; // Resurfacing, Milling
  final String? startDate;
  final String? endDate;
  final String? street;
  final String? crossStreets;
  final String? borough;
  final List<LatLng> geometry;

  StreetResurfacing({
    this.status,
    this.operation,
    this.startDate,
    this.endDate,
    this.street,
    this.crossStreets,
    this.borough,
    required this.geometry,
  });

  factory StreetResurfacing.fromNYCJson(Map<String, dynamic> json) {
    List<LatLng> geom = [];
    final g = json['geometry'];
    if (g != null) {
      String? t = g['type'] as String?;
      var coords = g['coordinates'];
      if (t == 'LineString' && coords is List) {
        geom = coords
            .map<LatLng>((v) =>
                LatLng((v[1] as num).toDouble(), (v[0] as num).toDouble()))
            .toList();
      } else if (t == 'MultiLineString' && coords is List) {
        geom = coords
            .expand((lst) => (lst as List).map<LatLng>((v) =>
                LatLng((v[1] as num).toDouble(), (v[0] as num).toDouble())))
            .toList();
      }
    }
    return StreetResurfacing(
      status: json['status'] as String?,
      operation: json['operation_type'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      street: json['on_street'] as String?,
      crossStreets: json['cross_streets'] as String?,
      borough: json['borough'] as String?,
      geometry: geom,
    );
  }
}
