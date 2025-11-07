import 'dart:convert';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class NYCParkingMeterService {
  static final NYCParkingMeterService instance = NYCParkingMeterService._();
  NYCParkingMeterService._();

  static const String _url =
      'https://data.cityofnewyork.us/resource/mvib-nh9w.json';
  static const String? _appToken =
      null; // Provide your own Socrata app token for higher QPS if needed.

  /// Fetch all meters within a given [radiusMeters] of [center].
  Future<List<ParkingMeter>> getMetersNearby(LatLng center,
      {int radiusMeters = 500}) async {
    print(
        '🔍 Fetching NYC parking meters near: ${center.latitude}, ${center.longitude} within ${radiusMeters}m radius');
    print('🌐 Using API endpoint: $_url');

    final query = {
      // Get all records first since spatial filtering might not work
      '\$limit': '1000', // Get more results
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
          .timeout(const Duration(seconds: 15));

      print('📊 Response status: ${resp.statusCode}');
      print('📊 Response length: ${resp.body.length} characters');

      if (resp.statusCode != 200) {
        print('❌ HTTP Error: ${resp.statusCode} - ${resp.body}');
        return [];
      }

      final List list = json.decode(resp.body);
      print('📋 Raw JSON list length: ${list.length}');

      if (list.isEmpty) {
        print('⚠️ No parking meters found at all. This could mean:');
        print('  • The API is not returning data');
        print('  • There might be an issue with the data source');
        print('  • The dataset might be empty or restricted');
        return [];
      }

      print('📊 Raw data contains ${list.length} records');

      // Since spatial filtering isn't working, we'll filter client-side
      final meters = list
          .map((m) {
            try {
              final meter = ParkingMeter.fromNYCJson(m);
              // Calculate distance and filter
              final distance = _calculateDistance(
                center.latitude,
                center.longitude,
                meter.latitude,
                meter.longitude,
              );
              if (distance <= radiusMeters) {
                return meter;
              }
              return null;
            } catch (e) {
              print('⚠️ Failed to parse meter: $e');
              return null;
            }
          })
          .where((m) => m != null)
          .cast<ParkingMeter>()
          .toList();

      print(
          '✅ Successfully parsed $meters.length parking meters within ${radiusMeters}m radius');
      return meters;
    } catch (e) {
      print('❌ Error fetching NYC meters: $e');
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

class ParkingMeter {
  final String? meterId;
  final String? status;
  final double latitude;
  final double longitude;
  final String? locationDesc;
  final String? borough;
  final String? type;
  final String? streetName;

  ParkingMeter({
    this.meterId,
    this.status,
    required this.latitude,
    required this.longitude,
    this.locationDesc,
    this.borough,
    this.type,
    this.streetName,
  });

  factory ParkingMeter.fromNYCJson(Map<String, dynamic> json) {
    // Many fields can be missing
    final loc = json['the_geom']?['coordinates'];
    final lat = (loc != null && loc is List && loc.length == 2)
        ? (loc[1] as num).toDouble()
        : null;
    final lng = (loc != null && loc is List && loc.length == 2)
        ? (loc[0] as num).toDouble()
        : null;
    if (lat == null || lng == null)
      throw Exception('Missing lat/lng in NYC meter record');
    return ParkingMeter(
      meterId: json['meter_id'] as String?,
      status: json['status'] as String?,
      latitude: lat,
      longitude: lng,
      locationDesc: json['location'] as String?,
      borough: json['borough'] as String?,
      type: json['type'] as String?,
      streetName: json['street_name'] as String?,
    );
  }
}
