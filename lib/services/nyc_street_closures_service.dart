import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class NYCDOTStreetClosuresService {
  static final NYCDOTStreetClosuresService instance =
      NYCDOTStreetClosuresService._();
  NYCDOTStreetClosuresService._();

  static const String _url =
      'https://data.cityofnewyork.us/resource/i6b5-j7bu.json';
  static const String? _appToken = null;

  /// Fetch closures within [radiusMeters] of [center].
  Future<List<StreetClosure>> getClosuresNearby(LatLng center,
      {int radiusMeters = 800}) async {
    print(
        '🚧 Fetching NYC street closures near: ${center.latitude}, ${center.longitude} within ${radiusMeters}m radius');
    print('🌐 Using API endpoint: $_url');

    final query = {
      // Use within_circle on the_geom for spatial filter
      // The geometry may be Point or LineString!
      // Socrata does not index LineStrings the same as Points. We'll use a wider radius for more inclusion.
      '\$where':
          'within_circle(the_geom, ${center.latitude}, ${center.longitude}, $radiusMeters)',
      '\$limit': '200',
    };
    try {
      final uri = Uri.parse(_url).replace(queryParameters: query);
      print('📡 Request URL: $uri');

      final headers = <String, String>{
        'Accept': 'application/json',
        if (_appToken != null) 'X-App-Token': _appToken!,
      };
      final resp = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 12));

      print('📊 Response status: ${resp.statusCode}');
      print('📊 Response length: ${resp.body.length} characters');

      if (resp.statusCode != 200) {
        print('❌ HTTP Error: ${resp.statusCode} - ${resp.body}');
        return [];
      }

      final List list = json.decode(resp.body);
      print('📋 Raw JSON list length: ${list.length}');

      if (list.isEmpty) {
        print('⚠️ No street closures found in this area. This could mean:');
        print('  • The area has no active street closures');
        print('  • The API query is too restrictive');
        print('  • There might be an issue with the data source');
      }

      final closures = list
          .map((m) {
            try {
              return StreetClosure.fromNYCJson(m);
            } catch (e) {
              print('⚠️ Failed to parse closure: $m. Error: $e');
              return null;
            }
          })
          .where((e) => e != null)
          .cast<StreetClosure>()
          .toList();

      print('✅ Successfully parsed $closures.length street closures');
      return closures;
    } catch (e) {
      print('❌ Error fetching NYC street closures: $e');
      return [];
    }
  }
}

class StreetClosure {
  final String? closureType;
  final String? reason;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? borough;
  final String? streetA;
  final String? streetB;
  final List<LatLng> geometry; // Could be empty if failed

  StreetClosure({
    this.closureType,
    this.reason,
    this.startDate,
    this.endDate,
    this.borough,
    this.streetA,
    this.streetB,
    required this.geometry,
  });

  factory StreetClosure.fromNYCJson(Map<String, dynamic> json) {
    // Geometry is GeoJSON-style: type: LineString/Point, coordinates: List
    List<LatLng> geom = [];
    final g = json['the_geom'];
    if (g != null) {
      final type = g['type'] as String?;
      final coords = g['coordinates'];
      if (type == 'LineString' && coords is List) {
        geom = coords
            .map<LatLng>((v) =>
                LatLng((v[1] as num).toDouble(), (v[0] as num).toDouble()))
            .toList();
      } else if (type == 'Point' && coords is List && coords.length == 2) {
        geom = [
          LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble())
        ];
      }
    }
    return StreetClosure(
      closureType: json['closure_type'] as String?,
      reason: json['reason'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      endDate:
          json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
      borough: json['borough'] as String?,
      streetA: json['on_street'] as String?,
      streetB: json['cross_street'] as String?,
      geometry: geom,
    );
  }
}
