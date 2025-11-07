import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import '../models/parking_alert.dart';
import 'nyc_parking_service.dart';

class ParkingAlertsService {
  static final ParkingAlertsService instance = ParkingAlertsService._();
  ParkingAlertsService._();

  // You can replace this with actual parking API endpoints
  // Options: OpenStreetMap, city-specific parking APIs, or commercial APIs
  static const String _osmOverpassUrl =
      'https://overpass-api.de/api/interpreter';

  /// Fetches parking alerts for a given location
  Future<ParkingRulesResponse> getParkingAlerts(
    double latitude,
    double longitude,
  ) async {
    try {
      // Get city/state information
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      final city = placemarks.first.locality;
      final state = placemarks.first.administrativeArea;

      // Fetch parking rules from multiple sources
      final alerts = <ParkingAlert>[];

      // 1. NYC Open Data (highest priority for NYC locations)
      if (city?.toLowerCase().contains('new york') == true ||
          NYCParkingService.instance.isInNYC(latitude, longitude)) {
        print('Location is in NYC - fetching official parking data...');
        final nycAlerts =
            await NYCParkingService.instance.getParkingRegulations(
          latitude: latitude,
          longitude: longitude,
          radiusMeters: 200,
        );
        alerts.addAll(nycAlerts);
        print('Found ${nycAlerts.length} NYC parking regulations');
      }

      // 2. Check OpenStreetMap for parking restrictions (fallback/supplement)
      final osmAlerts = await _getOSMParkingRestrictions(latitude, longitude);
      alerts.addAll(osmAlerts);

      // 3. Add city-specific rules (can be expanded with real APIs)
      final cityAlerts =
          await _getCitySpecificAlerts(city, state, latitude, longitude);
      alerts.addAll(cityAlerts);

      // 4. Check for weather-related restrictions
      final weatherAlerts = await _getWeatherBasedAlerts(city, state);
      alerts.addAll(weatherAlerts);

      // De-duplicate alerts by type + title + description
      final unique = <String, ParkingAlert>{};
      for (final a in alerts) {
        final key = '${a.type.name}|${a.title}|${a.description}'.toLowerCase();
        unique.putIfAbsent(key, () => a);
      }
      final deduped = unique.values.toList();

      return ParkingRulesResponse(
        alerts: deduped,
        city: city,
        state: state,
        hasActiveRestrictions: deduped.any((a) => a.isActive),
      );
    } catch (e) {
      print('Error fetching parking alerts: $e');
      return ParkingRulesResponse(alerts: []);
    }
  }

  /// Fetches parking restrictions from OpenStreetMap
  Future<List<ParkingAlert>> _getOSMParkingRestrictions(
    double lat,
    double lon,
  ) async {
    try {
      // Query OpenStreetMap Overpass API for parking restrictions
      final query = '''
        [out:json];
        (
          way["parking:lane"](around:100,$lat,$lon);
          way["parking:condition"](around:100,$lat,$lon);
          node["amenity"="parking_space"](around:100,$lat,$lon);
          way["maxstay"](around:100,$lat,$lon);
        );
        out body;
      ''';

      final response = await http.post(
        Uri.parse(_osmOverpassUrl),
        body: {'data': query},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseOSMResponse(data);
      }
    } catch (e) {
      print('Error fetching OSM data: $e');
    }
    return [];
  }

  List<ParkingAlert> _parseOSMResponse(Map<String, dynamic> data) {
    final alerts = <ParkingAlert>[];

    try {
      final elements = data['elements'] as List?;
      if (elements == null) return alerts;

      for (final element in elements) {
        final tags = element['tags'] as Map<String, dynamic>?;
        if (tags == null) continue;

        // Check for parking restrictions
        if (tags.containsKey('parking:condition:left') ||
            tags.containsKey('parking:condition:right')) {
          final condition =
              tags['parking:condition:left'] ?? tags['parking:condition:right'];

          if (condition.toString().contains('no_parking')) {
            alerts.add(ParkingAlert(
              id: 'osm_${element['id']}',
              type: ParkingAlertType.noParking,
              title: 'No Parking Zone',
              description: 'This area has parking restrictions',
              source: 'OpenStreetMap',
            ));
          }
        }

        // Check for time restrictions
        if (tags.containsKey('maxstay')) {
          alerts.add(ParkingAlert(
            id: 'osm_time_${element['id']}',
            type: ParkingAlertType.timeLimitedZone,
            title: 'Time-Limited Parking',
            description: 'Maximum stay: ${tags['maxstay']}',
            source: 'OpenStreetMap',
          ));
        }

        // Check for payment requirements
        if (tags.containsKey('fee') && tags['fee'] == 'yes') {
          alerts.add(ParkingAlert(
            id: 'osm_fee_${element['id']}',
            type: ParkingAlertType.meteredParking,
            title: 'Paid Parking',
            description: 'This is a metered parking area',
            source: 'OpenStreetMap',
          ));
        }
      }
    } catch (e) {
      print('Error parsing OSM response: $e');
    }

    return alerts;
  }

  /// Get city-specific parking alerts
  Future<List<ParkingAlert>> _getCitySpecificAlerts(
    String? city,
    String? state,
    double lat,
    double lon,
  ) async {
    final alerts = <ParkingAlert>[];

    if (city == null) return alerts;
    // Avoid generic templates in NYC; rely on official NYC Open Data results
    if (NYCParkingService.instance.isInNYC(lat, lon)) {
      return alerts;
    }

    // This is a template - you can integrate with specific city APIs
    // Examples of city parking APIs:
    // - NYC: NYC Open Data API
    // - SF: SFMTA API
    // - LA: LA DOT API
    // - Chicago: Chicago Data Portal

    // For demonstration, we'll create sample rules based on common patterns
    final now = DateTime.now();
    final dayOfWeek = _getDayOfWeek(now.weekday);

    // Example: Street cleaning rules (common in many cities)
    if (now.weekday >= 1 && now.weekday <= 5) {
      // Monday to Friday
      alerts.add(ParkingAlert(
        id: 'street_cleaning_${city}_${lat}_$lon',
        type: ParkingAlertType.streetCleaning,
        title: 'Street Cleaning',
        description: 'Check local signs for street cleaning schedule',
        dayOfWeek: dayOfWeek,
        timeRange: '8:00 AM - 10:00 AM',
        source: city,
      ));
    }

    return alerts;
  }

  /// Get weather-based parking alerts (like snow emergency routes)
  Future<List<ParkingAlert>> _getWeatherBasedAlerts(
    String? city,
    String? state,
  ) async {
    final alerts = <ParkingAlert>[];

    // This would integrate with weather APIs to check for snow emergencies
    // For now, we'll return empty - you can integrate with:
    // - OpenWeatherMap API
    // - Weather.gov API
    // - City-specific emergency alerts

    return alerts;
  }

  String _getDayOfWeek(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  /// Calculate when a parking timer should expire based on alerts
  DateTime? calculateParkingExpiration(List<ParkingAlert> alerts) {
    DateTime? earliestExpiration;

    for (final alert in alerts) {
      if (alert.expiresAt != null) {
        if (earliestExpiration == null ||
            alert.expiresAt!.isBefore(earliestExpiration)) {
          earliestExpiration = alert.expiresAt;
        }
      }
    }

    return earliestExpiration;
  }

  /// Get alerts that are currently active or about to become active
  List<ParkingAlert> getActiveAlerts(List<ParkingAlert> alerts) {
    final now = DateTime.now();

    return alerts.where((alert) {
      // If alert has no expiration, consider it always active
      if (alert.expiresAt == null) return true;

      // Check if alert hasn't expired yet
      return alert.expiresAt!.isAfter(now);
    }).toList();
  }
}

// Extension to add parking API integration for specific cities
// You can extend this with real API integrations:

/*
Examples of APIs you can integrate:

1. NYC Open Data (Free)
   - Street parking rules
   - Metered parking locations
   - https://data.cityofnewyork.us/

2. SFMTA API (San Francisco)
   - Real-time parking availability
   - Parking regulations
   - https://www.sfmta.com/getting-around/drive-park/demand-responsive-pricing/sfpark-evaluation

3. ParkWhiz API (Commercial)
   - Multi-city parking data
   - https://www.parkwhiz.com/developers/

4. SpotHero API (Commercial)
   - Parking reservations and rules
   - https://spothero.com/

5. Google Maps Places API
   - Parking information
   - Street view for sign reading

6. Park Smart API (Various cities)
   - Parking regulations by location
*/
