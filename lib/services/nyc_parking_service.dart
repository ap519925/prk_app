import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/parking_alert.dart';

/// Service for NYC Open Data Parking Regulations
/// Data source: https://data.cityofnewyork.us/Transportation/Parking-Regulation-Locations-and-Signs/nfid-uabd
class NYCParkingService {
  static final NYCParkingService instance = NYCParkingService._();
  NYCParkingService._();

  // NYC Open Data API endpoint
  static const String _baseUrl =
      'https://data.cityofnewyork.us/resource/nfid-uabd.json';

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
      // Build query with spatial filter using X/Y coordinates
      // Since the dataset doesn't have spatial geometry, we'll use X/Y coordinates
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          '\$where': 'sign_x_coord IS NOT NULL AND sign_y_coord IS NOT NULL',
          '\$limit': '500', // Get more results to filter client-side
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

        // Filter data client-side by distance since we can't use spatial queries
        final filteredData = data.where((item) {
          try {
            final xCoord =
                double.tryParse(item['sign_x_coord']?.toString() ?? '');
            final yCoord =
                double.tryParse(item['sign_y_coord']?.toString() ?? '');

            if (xCoord == null || yCoord == null) return false;

            // Convert NY State Plane coordinates to lat/lng (approximation)
            final lat = (yCoord - 10000) / 100000; // Rough conversion
            final lng = (xCoord - 100000) / 100000; // Rough conversion

            // Calculate distance
            final distance = _calculateDistance(latitude, longitude, lat, lng);
            return distance <= radiusMeters;
          } catch (e) {
            return false;
          }
        }).toList();

        print(
            'Filtered to ${filteredData.length} NYC parking signs within radius');

        return _parseNYCParkingData(filteredData);
      } else {
        print('NYC API error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching NYC parking data: $e');
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
      description =
          signDescription ?? regulationText ?? 'Commercial vehicles only';
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
      description =
          signDescription ?? regulationText ?? 'Check sign for details';
      timeRange = _extractTimeRange(text);
    }

    // Add location context
    if (streetName != null) {
      description += ' on $streetName';
    }
    if (sideOfStreet != null) {
      description += ' ($sideOfStreet side)';
    }

    // Compute schedule info (for notifications)
    final computedDayOfWeek = _extractDayOfWeek(text);
    DateTime? nextStart;
    if (type == ParkingAlertType.streetCleaning) {
      nextStart = _computeNextRestrictionStart(
        text: text,
        dayOfWeek: computedDayOfWeek,
        timeRange: timeRange,
      );
    }

    return ParkingAlert(
      id: 'nyc_${orderNumber ?? DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      description: description,
      timeRange: timeRange,
      dayOfWeek: computedDayOfWeek,
      expiresAt: nextStart,
      source: 'NYC DOT',
      isActive: true,
    );
  }

  /// Extracts time range from parking sign text
  String? _extractTimeRange(String text) {
    // Look for time patterns like "8AM-6PM", "8:00AM - 6:00PM", etc.
    final timePatterns = [
      RegExp(r'\d{1,2}:\d{2}\s*[AP]M\s*-\s*\d{1,2}:\d{2}\s*[AP]M',
          caseSensitive: false),
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
      final exceptMatch =
          RegExp(r'EXCEPT\s+[\w\s-]+', caseSensitive: false).firstMatch(text);
      if (exceptMatch != null) {
        return exceptMatch.group(0)?.trim();
      }
    }

    return null;
  }

  /// Extracts day of week from parking sign text
  String? _extractDayOfWeek(String text) {
    final days = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY'
    ];

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
    final hourMatch =
        RegExp(r'(\d+)\s*HOUR', caseSensitive: false).firstMatch(text);
    if (hourMatch != null) {
      final hours = hourMatch.group(1);
      return '$hours-Hour Limit';
    }
    return 'Time Limited Zone';
  }

  /// Compute next restriction start for a rule text/day/time
  DateTime? _computeNextRestrictionStart({
    required String text,
    String? dayOfWeek,
    String? timeRange,
  }) {
    final hm = _parseTimeRangeToHM(timeRange);
    if (hm == null) return null;

    final now = DateTime.now();
    final fromText = _parseDaysFromText(text);
    final days = fromText.isNotEmpty
        ? fromText
        : _parseDaysFromDayOfWeekString(dayOfWeek);

    if (days.isEmpty) {
      // If no explicit days, assume weekday cleaning (Mon-Fri) as a safe default
      days.addAll({
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday
      });
    }

    // Scan next 7 days to find upcoming window start
    for (int i = 0; i < 7; i++) {
      final candidate = now.add(Duration(days: i));
      if (days.contains(candidate.weekday)) {
        final start = DateTime(
          candidate.year,
          candidate.month,
          candidate.day,
          hm['sh']!,
          hm['sm']!,
        );
        final end = DateTime(
          candidate.year,
          candidate.month,
          candidate.day,
          hm['eh']!,
          hm['em']!,
        );

        if (i > 0 || now.isBefore(start)) {
          // Upcoming window later today or in future days
          return start;
        }

        // If already within today's window, schedule next week's occurrence
        if (now.isBefore(end)) {
          final nextWeek = start.add(const Duration(days: 7));
          return nextWeek;
        } else {
          // Today's window already ended; keep scanning
          continue;
        }
      }
    }
    return null;
  }

  Map<String, int>? _parseTimeRangeToHM(String? timeRange) {
    if (timeRange == null) return null;
    final upper = timeRange.toUpperCase().replaceAll('.', '');

    // Extract start and end tokens around '-' or 'TO'
    final parts = upper.split(RegExp(r'\s*(?:-|TO)\s*'));
    if (parts.length < 2) return null;

    Map<String, int>? parseOne(String token, {String? fallbackMeridiem}) {
      final m = RegExp(r'^\s*(\d{1,2})(?::(\d{2}))?\s*([AP]M)?\s*$')
          .firstMatch(token);
      if (m == null) return null;
      int hour = int.parse(m.group(1)!);
      int minute = int.tryParse(m.group(2) ?? '0') ?? 0;
      String? mer = m.group(3) ?? fallbackMeridiem;

      // Infer missing meridiem using common patterns
      if (mer == null) {
        // Heuristic: street cleaning typically morning; default to AM
        mer = 'AM';
      }

      if (mer == 'PM' && hour != 12) hour += 12;
      if (mer == 'AM' && hour == 12) hour = 0;

      return {'h': hour, 'm': minute};
    }

    final startToken = parts[0];
    final endToken = parts[1];

    final startParsed = parseOne(startToken);
    if (startParsed == null) return null;

    final endParsed = parseOne(
      endToken,
      fallbackMeridiem: RegExp(r'[AP]M').hasMatch(endToken)
          ? null
          : (startToken.contains('PM')
              ? 'PM'
              : (startToken.contains('AM') ? 'AM' : null)),
    );
    if (endParsed == null) return null;

    return {
      'sh': startParsed['h']!,
      'sm': startParsed['m']!,
      'eh': endParsed['h']!,
      'em': endParsed['m']!,
    };
  }

  Set<int> _parseDaysFromText(String text) {
    final t = text.toUpperCase();

    // Quick handles
    if (t.contains('DAILY') ||
        t.contains('ALL DAYS') ||
        t.contains('EVERY DAY')) {
      return {
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
        DateTime.sunday
      };
    }

    final dayMap = <String, int>{
      'MONDAY': DateTime.monday,
      'MON': DateTime.monday,
      'TUESDAY': DateTime.tuesday,
      'TUES': DateTime.tuesday,
      'TUE': DateTime.tuesday,
      'WEDNESDAY': DateTime.wednesday,
      'WED': DateTime.wednesday,
      'THURSDAY': DateTime.thursday,
      'THURS': DateTime.thursday,
      'THU': DateTime.thursday,
      'FRIDAY': DateTime.friday,
      'FRI': DateTime.friday,
      'SATURDAY': DateTime.saturday,
      'SAT': DateTime.saturday,
      'SUNDAY': DateTime.sunday,
      'SUN': DateTime.sunday,
    };

    final result = <int>{};

    // Ranges like MON-FRI, MON-SAT, etc.
    final rangePatterns = <List>[
      ['MON', 'FRI', DateTime.monday, DateTime.friday],
      ['MON', 'SAT', DateTime.monday, DateTime.saturday],
      ['TUE', 'SAT', DateTime.tuesday, DateTime.saturday],
      ['MONDAY', 'FRIDAY', DateTime.monday, DateTime.friday],
      ['MONDAY', 'SATURDAY', DateTime.monday, DateTime.saturday],
    ];
    for (final entry in rangePatterns) {
      if (t.contains('${entry[0]}') &&
          t.contains('${entry[1]}') &&
          t.contains('-')) {
        final start = entry[2] as int;
        final end = entry[3] as int;
        for (int d = start; d <= end; d++) {
          result.add(d);
        }
      }
    }

    // Individual days, including conjunctions with &, AND, or commas
    for (final k in dayMap.keys) {
      if (RegExp(r'(^|[^A-Z])' + k + r'([^A-Z]|$)').hasMatch(t)) {
        result.add(dayMap[k]!);
      }
    }

    // "EXCEPT SUNDAY" => Mon-Sat
    if (t.contains('EXCEPT SUNDAY')) {
      result.addAll({
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday
      });
      result.remove(DateTime.sunday);
    }

    return result;
  }

  Set<int> _parseDaysFromDayOfWeekString(String? dayOfWeek) {
    if (dayOfWeek == null) return <int>{};
    final s = dayOfWeek.toUpperCase();
    if (s == 'MONDAY') return {DateTime.monday};
    if (s == 'TUESDAY') return {DateTime.tuesday};
    if (s == 'WEDNESDAY') return {DateTime.wednesday};
    if (s == 'THURSDAY') return {DateTime.thursday};
    if (s == 'FRIDAY') return {DateTime.friday};
    if (s == 'SATURDAY') return {DateTime.saturday};
    if (s == 'SUNDAY') return {DateTime.sunday};
    if (s.contains('MONDAY-FRIDAY') || s.contains('MONDAY - FRIDAY')) {
      return {
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday
      };
    }
    if (s.contains('MONDAY-SATURDAY') || s.contains('MONDAY - SATURDAY')) {
      return {
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday
      };
    }
    return <int>{};
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
