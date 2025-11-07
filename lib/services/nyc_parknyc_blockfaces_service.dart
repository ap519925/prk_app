import 'dart:convert';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class NYCParkNYCBlockfacesService {
  static final NYCParkNYCBlockfacesService instance =
      NYCParkNYCBlockfacesService._();
  NYCParkNYCBlockfacesService._();

  static const String _url =
      'https://data.cityofnewyork.us/resource/s7zi-dgdx.json';
  static const String? _appToken = null;

  Future<List<ParkNYCBlockface>> getBlockfacesNearby(LatLng center,
      {int radiusMeters = 800}) async {
    print(
        '🔍 Fetching NYC ParkNYC blockfaces near: ${center.latitude}, ${center.longitude} within ${radiusMeters}m radius');
    print('🌐 Using API endpoint: $_url');

    final query = {
      // Get all records first since spatial filtering might not work
      '\$limit': '1000', // Get more results
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

      print('📊 Response status: ${resp.statusCode}');

      if (resp.statusCode != 200) {
        print('❌ HTTP Error: ${resp.statusCode} - ${resp.body}');
        return [];
      }

      final List<dynamic> list = json.decode(resp.body);
      print('📋 Raw JSON list length: ${list.length}');

      if (list.isEmpty) {
        print('⚠️ No ParkNYC blockfaces found at all. This could mean:');
        print('  • The API is not returning data');
        print('  • There might be an issue with the data source');
        print('  • The dataset might be empty or restricted');
        return [];
      }

      // Since spatial filtering isn't working, filter client-side
      final blockfaces = list
          .map((m) {
            try {
              final blockface = ParkNYCBlockface.fromNYCJson(m);
              if (blockface.geometry.isEmpty) return null;

              // Calculate distance to the first point of geometry
              final firstPoint = blockface.geometry.first;
              final distance = _calculateDistance(
                center.latitude,
                center.longitude,
                firstPoint.latitude,
                firstPoint.longitude,
              );

              if (distance <= radiusMeters) {
                return blockface;
              }
              return null;
            } catch (e) {
              print('⚠️ Failed to parse blockface: $e');
              return null;
            }
          })
          .where((e) => e != null)
          .cast<ParkNYCBlockface>()
          .toList();

      print(
          '✅ Successfully parsed $blockfaces.length ParkNYC blockfaces within ${radiusMeters}m radius');
      return blockfaces;
    } catch (e) {
      print('❌ Error fetching ParkNYC blockfaces: $e');
      return [];
    }
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // Earth's radius in meters
    final dLat = (lat2 - lat1) * 3.14159 / 180;
    final dLon = (lon2 - lon1) * 3.14159 / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * 3.14159 / 180) *
            cos(lat2 * 3.14159 / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }
}

class ParkNYCBlockface {
  final String? segmentId;
  final String? blockfaceId;
  final String? street;
  final String? sideOfStreet;
  final int? meters;
  final double? lengthFeet;
  final String? borough;
  final bool isMobileAppEnabled;
  final List<LatLng> geometry;

  ParkNYCBlockface({
    this.segmentId,
    this.blockfaceId,
    this.street,
    this.sideOfStreet,
    this.meters,
    this.lengthFeet,
    this.borough,
    required this.isMobileAppEnabled,
    required this.geometry,
  });

  factory ParkNYCBlockface.fromNYCJson(Map<String, dynamic> json) {
    // Geometry can be LineString or MultiLineString
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
    return ParkNYCBlockface(
      segmentId: json['segment_id'] as String?,
      blockfaceId: json['blockface_id'] as String?,
      street: json['street'] as String?,
      sideOfStreet: json['side_of_street'] as String?,
      meters: (json['meters'] is String)
          ? int.tryParse(json['meters'])
          : (json['meters'] as int?),
      lengthFeet: (json['length_feet'] is String)
          ? double.tryParse(json['length_feet'])
          : (json['length_feet'] as num?)?.toDouble(),
      borough: json['borough'] as String?,
      isMobileAppEnabled:
          (json['mobile_app'] as String?)?.toLowerCase() == 'yes',
      geometry: geom,
    );
  }
}
