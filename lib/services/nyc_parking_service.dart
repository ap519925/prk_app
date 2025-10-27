import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/parking_alert.dart';

/// Service for NYC Open Data Parking Regulations
/// Data source: https://data.cityofnewyork.us/Transportation/Parking-Regulation-Locations-and-Signs/nfid-uabd
class NYCParkingService {
  static final NYCParkingService instance = NYCParkingService._();
  NYCParkingService._();

  // NYC Open Data API endpoint
  static const String _baseUrl = 'https://data.cityofnewyork.us/resource/nfid-uabd.json';
  
  // App token for higher rate limits (optional but recommended)
  // Get your free app token at: https://data.cityofnewyork.us/profile/app_tokens
  static const String? _appToken = null; // Add your token here

  /// Fetches parking regulations near a specific location
  /// 
  /// Parameters:
  /// - latitude: Location latitude
  /// - longitude: Location longitude
  /// - radiusMeters: Search radius in meters (default: 200m)
  /// 
  /// Returns list of ParkingAlert objects with NYC regulations
  Future<List<ParkingAlert>> getParkingRegulations({
    required double latitude,
    required double longitude,
    int radiusMeters = 200,
  }) async {
    try {
      // Build query with spatial filter using Socrata within_circle function
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          '\$where': 'within_circle(geom, $latitude, $longitude, $radiusMeters)',
          '\$limit': '100', // Limit results
          '\$order': 'distance_in_meters',
        },
      );

      print('Fetching NYC parking data: $uri');

      final headers = <String, String>{
        'Accept': 'application/json',
        if (_appToken != null) 'X-App-Token': _appToken!,
      };

      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Received ${data.length} NYC parking signs');
        
        return _parseNYCParkingData(data);
      } else {
        print('NYC API error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching NYC parking data: $e');
      return [];
    }
  }

  /// Parses NYC Open Data response into ParkingAlert objects
  List<ParkingAlert> _parseNYCParkingData(List<dynamic> data) {
    final alerts = <ParkingAlert>[];
    final processedRules = <String>{};

    for (final item in data) {
      try {
        final signDescription = item['sign_description'] as String?;
        final regulationText = item['regulation_text'] as String?;
        final arrow = item['arrow'] as String?;
        final streetName = item['street_name'] as String?;
        final sideOfStreet = item['side_of_street'] as String?;
        final orderNumber = item['order_number'];
        
        if (signDescription == null && regulationText == null) continue;

        // Create unique key to avoid duplicates
        final ruleKey = '$signDescription|$regulationText|$streetName';
        if (processedRules.contains(ruleKey)) continue;
        processedRules.add(ruleKey);

        // Determine alert type and create alert
        final alert = _createAlertFromNYCData(
          signDescription: signDescription,
          regulationText: regulationText,
          arrow: arrow,
          streetName: streetName,
          sideOfStreet: sideOfStreet,
          orderNumber: orderNumber,
        );

        if (alert != null) {
          alerts.add(alert);
        }
      } catch (e) {
        print('Error parsing NYC sign: $e');
        continue;
      }
    }

    return alerts;
  }

  /// Creates a ParkingAlert from NYC sign data
  ParkingAlert? _createAlertFromNYCData({
    String? signDescription,
    String? regulationText,
    String? arrow,
    String? streetName,
    String? sideOfStreet,
    dynamic orderNumber,
  }) {
    final text = (signDescription ?? regulationText ?? '').toUpperCase();
    
    // Determine parking alert type based on sign content
    ParkingAlertType type;
    String title;
    String description;
    String? timeRange;

    if (text.contains('NO PARKING') || text.contains('NO STOPPING')) {
      type = ParkingAlertType.noParking;
      title = 'No Parking Zone';
      description = signDescription ?? regulationText ?? 'Parking not allowed';
      timeRange = _extractTimeRange(text);
    } else if (text.contains('STREET CLEANING') || text.contains('SWEEPING')) {
      type = ParkingAlertType.streetCleaning;
      title = 'Street Cleaning';
      description = 'No parking during street cleaning';
      timeRange = _extractTimeRange(text);
    } else if (text.contains('METER') || text.contains('MUNI-METER')) {
      type = ParkingAlertType.meteredParking;
      title = 'Metered Parking';
      description = 'Payment required at meter';
      timeRange = _extractTimeRange(text);
    } else if (text.contains('HOUR') && !text.contains('NO PARKING')) {
      type = ParkingAlertType.timeLimitedZone;
      title = _extractHourLimit(text);
      description = 'Time-limited parking zone';
      timeRange = _extractTimeRange(text);
    } else if (text.contains('PERMIT') || text.contains('AUTHORIZED')) {
      type = ParkingAlertType.permitOnly;
      title = 'Permit Required';
      description = 'Permit holders only';
      timeRange = _extractTimeRange(text);
    } else if (text.contains('SNOW') || text.contains('EMERGENCY')) {
      type = ParkingAlertType.snowEmergency;
      title = 'Emergency Route';
      description = 'No parking during snow emergency';
      timeRange = _extractTimeRange(text);
    } else if (text.contains('COMMERCIAL') || text.contains('LOADING')) {
      type = ParkingAlertType.other;
      title = 'Commercial Zone';
      description = signDescription ?? regulationText ?? 'Commercial vehicles only';
      timeRange = _extractTimeRange(text);
    } else if (text.contains('NO STANDING')) {
      type = ParkingAlertType.noParking;
      title = 'No Standing';
      description = 'No standing allowed';
      timeRange = _extractTimeRange(text);
    } else {
      // General restriction
      type = ParkingAlertType.other;
      title = 'Parking Restriction';
      description = signDescription ?? regulationText ?? 'Check sign for details';
      timeRange = _extractTimeRange(text);
    }

    // Add location context
    if (streetName != null) {
      description += ' on $streetName';
    }
    if (sideOfStreet != null) {
      description += ' ($sideOfStreet side)';
    }

    return ParkingAlert(
      id: 'nyc_${orderNumber ?? DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      description: description,
      timeRange: timeRange,
      dayOfWeek: _extractDayOfWeek(text),
      source: 'NYC DOT',
      isActive: true,
    );
  }

  /// Extracts time range from parking sign text
  String? _extractTimeRange(String text) {
    // Look for time patterns like "8AM-6PM", "8:00AM - 6:00PM", etc.
    final timePatterns = [
      RegExp(r'\d{1,2}:\d{2}\s*[AP]M\s*-\s*\d{1,2}:\d{2}\s*[AP]M', caseSensitive: false),
      RegExp(r'\d{1,2}\s*[AP]M\s*-\s*\d{1,2}\s*[AP]M', caseSensitive: false),
      RegExp(r'\d{1,2}[AP]M\s*-\s*\d{1,2}[AP]M', caseSensitive: false),
    ];

    for (final pattern in timePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(0)?.trim();
      }
    }

    // Check for "EXCEPT SUNDAYS" type patterns
    if (text.contains('EXCEPT')) {
      final exceptMatch = RegExp(r'EXCEPT\s+[\w\s-]+', caseSensitive: false).firstMatch(text);
      if (exceptMatch != null) {
        return exceptMatch.group(0)?.trim();
      }
    }

    return null;
  }

  /// Extracts day of week from parking sign text
  String? _extractDayOfWeek(String text) {
    final days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    
    for (final day in days) {
      if (text.contains(day)) {
        return day.toLowerCase().capitalize();
      }
    }

    // Check for day ranges
    if (text.contains('MON') && text.contains('FRI')) {
      return 'Monday-Friday';
    }
    if (text.contains('MON') && text.contains('SAT')) {
      return 'Monday-Saturday';
    }

    // Check for "EXCEPT SUNDAY"
    if (text.contains('EXCEPT SUNDAY')) {
      return 'Monday-Saturday';
    }

    return null;
  }

  /// Extracts hour limit from parking sign text
  String _extractHourLimit(String text) {
    final hourMatch = RegExp(r'(\d+)\s*HOUR', caseSensitive: false).firstMatch(text);
    if (hourMatch != null) {
      final hours = hourMatch.group(1);
      return '$hours-Hour Limit';
    }
    return 'Time Limited Zone';
  }

  /// Checks if location is within NYC boundaries
  bool isInNYC(double latitude, double longitude) {
    // NYC approximate bounding box
    // Latitude: 40.4774 to 40.9176
    // Longitude: -74.2591 to -73.7004
    return latitude >= 40.4774 && 
           latitude <= 40.9176 && 
           longitude >= -74.2591 && 
           longitude <= -73.7004;
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}


