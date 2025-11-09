import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';

class NYCParkingRegulationSignsService {
  static final NYCParkingRegulationSignsService instance =
      NYCParkingRegulationSignsService._();
  NYCParkingRegulationSignsService._();

  static const String _url =
      'https://data.cityofnewyork.us/resource/xswq-wnv9.json';
  static const String? _appToken = null;

  Future<List<ParkingRegulationSign>> getSignsNearby(LatLng center,
      {int radiusMeters = 600}) async {
    print(
        '🚸 Fetching NYC parking signs near: ${center.latitude}, ${center.longitude} within ${radiusMeters}m radius');
    print('🌐 Using API endpoint: $_url');

    // Temporarily disable this service due to API access issues
    // The API returns "no row or column access to non-tabular tables"
    print(
        '⚠️ Parking Signs API is currently disabled due to access restrictions');
    print('   This is a known issue with the NYC Open Data API');
    return [];
  }
}

class ParkingRegulationSign {
  final String? mainRule;
  final String? signDescription;
  final String? hours;
  final String? fromStreet;
  final String? toStreet;
  final String? sideOfStreet;
  final String? borough;
  final LatLng? position;

  ParkingRegulationSign({
    this.mainRule,
    this.signDescription,
    this.hours,
    this.fromStreet,
    this.toStreet,
    this.sideOfStreet,
    this.borough,
    this.position,
  });

  factory ParkingRegulationSign.fromNYCJson(Map<String, dynamic> json) {
    final geom = json['geom']?['coordinates'];
    final lat = (geom != null && geom is List && geom.length == 2)
        ? (geom[1] as num).toDouble()
        : null;
    final lon = (geom != null && geom is List && geom.length == 2)
        ? (geom[0] as num).toDouble()
        : null;
    LatLng? pos = (lat != null && lon != null) ? LatLng(lat, lon) : null;
    return ParkingRegulationSign(
      mainRule: json['main_rule'] as String?,
      signDescription: json['sign_description'] as String?,
      hours: json['main_hour'] as String?,
      fromStreet: json['from_street'] as String?,
      toStreet: json['to_street'] as String?,
      sideOfStreet: json['side_of_street'] as String?,
      borough: json['borough'] as String?,
      position: pos,
    );
  }

  Color get markerColor {
    final r = ((mainRule ?? signDescription) ?? '').toUpperCase();
    // Using semantic colors that work with both light and dark themes
    if (r.contains('NO PARKING') ||
        r.contains('NO STANDING') ||
        r.contains('NO STOPPING')) {
      return const Color(0xFFEF4444); // Accent Alert - Red for prohibitions
    } else if (r.contains('METER') || r.contains('PAY')) {
      return const Color(0xFF14B8A6); // Primary - Teal for payment
    } else if (r.contains('LOADING') || r.contains('COMMERCIAL')) {
      return const Color(0xFFFF8C00); // Tertiary - Orange for commercial zones
    } else if (r.contains('PERMIT') || r.contains('AUTHORIZED')) {
      return const Color(0xFF22C55E); // Success - Green for permitted areas
    } else if (r.contains('CLEANING') || r.contains('SWEEP')) {
      return const Color(0xFF8B5CF6); // Secondary - Purple for maintenance
    } else if (r.contains('HANDICAP') || r.contains('DISABLED')) {
      return const Color(
          0xFF94A3B8); // Secondary - Slate gray for accessibility
    } else {
      return const Color(0xFF64748B); // Other: slate gray
    }
  }

  String get ruleEmoji {
    final r = ((mainRule ?? signDescription) ?? '').toUpperCase();
    if (r.contains('NO PARKING') ||
        r.contains('NO STANDING') ||
        r.contains('NO STOPPING')) {
      return '🚫';
    }
    if (r.contains('METER') || r.contains('PAY')) return '💰';
    if (r.contains('LOADING') || r.contains('COMMERCIAL')) return '📦';
    if (r.contains('PERMIT') || r.contains('AUTHORIZED')) return '🎫';
    if (r.contains('CLEANING') || r.contains('SWEEP')) return '🧹';
    if (r.contains('HANDICAP') || r.contains('DISABLED')) return '♿';
    return 'ℹ️';
  }
}
