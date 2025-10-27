# Smart Parking Alerts - Implementation Guide

## Overview

The Prk app now includes a comprehensive parking alerts system that automatically detects and notifies users about parking restrictions at their saved location.

## How It Works

### 1. When You Save a Parking Spot

```dart
// Automatically fetches parking alerts for your location
final alertsResponse = await ParkingAlertsService.instance.getParkingAlerts(
  latitude,
  longitude,
);
```

The app:
1. Saves your GPS coordinates
2. Queries parking restriction APIs (OpenStreetMap by default)
3. Analyzes local parking rules
4. Displays relevant alerts immediately
5. Sends a notification summary

### 2. Alert Types Detected

| Type | Icon | Description | Severity |
|------|------|-------------|----------|
| Street Cleaning | 🧹 | Street cleaning schedule restrictions | Orange |
| Metered Parking | 💰 | Paid parking zone with time limits | Orange |
| Time-Limited | ⏱️ | Maximum parking duration (e.g., 2 hour limit) | Yellow |
| Permit Only | 🎫 | Requires residential/special permit | Yellow |
| Snow Emergency | ❄️ | Snow emergency route restrictions | Red |
| No Parking | 🚫 | Absolute no parking zone | Red |

### 3. Notification System

The app sends smart notifications:

- **Immediate**: When you save your spot with active restrictions
- **30 minutes before**: Upcoming restriction (e.g., street cleaning)
- **Timer-based**:
  - 15 minutes before expiration
  - 5 minutes before expiration
  - At expiration time

## API Integration

### Current: OpenStreetMap Overpass API

**Advantages:**
- ✅ Free and open-source
- ✅ Global coverage
- ✅ Community-maintained
- ✅ No API key required

**Limitations:**
- ⚠️ Data quality varies by location
- ⚠️ May not include all city-specific rules
- ⚠️ Requires internet connection

**Sample Query:**
```overpass
[out:json];
(
  way["parking:lane"](around:100,40.7589,-73.9851);
  way["parking:condition"](around:100,40.7589,-73.9851);
  node["amenity"="parking_space"](around:100,40.7589,-73.9851);
  way["maxstay"](around:100,40.7589,-73.9851);
);
out body;
```

### Recommended Upgrades

#### For NYC - NYC Open Data API

```dart
Future<List<ParkingAlert>> _getNYCParkingAlerts(double lat, double lon) async {
  final response = await http.get(
    Uri.parse('https://data.cityofnewyork.us/resource/...)
        ?lat=$lat&lon=$lon'),
  );
  
  // Parse NYC-specific parking rules
  // Return ParkingAlert objects
}
```

**Benefits:**
- Official city data
- Updated street cleaning schedules
- Metered parking information
- Permit zone details

#### For SF - SFMTA API

```dart
Future<List<ParkingAlert>> _getSFParkingAlerts(double lat, double lon) async {
  final response = await http.get(
    Uri.parse('https://api.sfmta.com/...'),
  );
  
  // Parse SF-specific rules
}
```

**Benefits:**
- Real-time parking availability
- Dynamic pricing information
- Construction-related restrictions

## Code Structure

### ParkingAlert Model

```dart
class ParkingAlert {
  final String id;
  final ParkingAlertType type;
  final String title;
  final String description;
  final DateTime? expiresAt;
  final String? dayOfWeek;
  final String? timeRange;
  final bool isActive;
  final String? source;
}
```

### Service Architecture

```
ParkingAlertsService
├── getParkingAlerts() - Main entry point
├── _getOSMParkingRestrictions() - OpenStreetMap data
├── _getCitySpecificAlerts() - Custom city APIs
├── _getWeatherBasedAlerts() - Snow emergency detection
└── calculateParkingExpiration() - Timer calculation
```

## Adding Your Own City

### Step 1: Create API Method

In `lib/services/parking_alerts_service.dart`:

```dart
Future<List<ParkingAlert>> _getYourCityAlerts(
  String? city,
  String? state,
  double lat,
  double lon,
) async {
  if (city != 'YourCity') return [];
  
  try {
    final response = await http.get(
      Uri.parse('https://your-city-api.com/parking?lat=$lat&lon=$lon'),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _parseYourCityResponse(data);
    }
  } catch (e) {
    print('Error fetching YourCity data: $e');
  }
  
  return [];
}

List<ParkingAlert> _parseYourCityResponse(dynamic data) {
  final alerts = <ParkingAlert>[];
  
  // Parse your city's data format
  for (final item in data['restrictions']) {
    alerts.add(ParkingAlert(
      id: 'yourcity_${item['id']}',
      type: _mapToAlertType(item['type']),
      title: item['title'],
      description: item['description'],
      timeRange: item['hours'],
      source: 'YourCity Parking',
    ));
  }
  
  return alerts;
}
```

### Step 2: Integrate in Main Method

```dart
Future<ParkingRulesResponse> getParkingAlerts(
  double latitude,
  double longitude,
) async {
  // ... existing code ...
  
  // Add your city-specific alerts
  final yourCityAlerts = await _getYourCityAlerts(city, state, latitude, longitude);
  alerts.addAll(yourCityAlerts);
  
  // ... rest of code ...
}
```

## UI Customization

### Alert Display

Alerts appear in an orange card on the home screen:

```dart
Widget _buildAlertsSection(ThemeData theme) {
  return Card(
    color: Colors.orange.shade50,
    child: Column(
      children: [
        // Alert header with icon
        // List of up to 3 alerts
        // "View all" button if more than 3
      ],
    ),
  );
}
```

### Customizing Colors

Edit `lib/models/parking_alert.dart`:

```dart
String get severityColor {
  switch (type) {
    case ParkingAlertType.noParking:
      return 'red';    // Critical
    case ParkingAlertType.meteredParking:
      return 'orange'; // Warning
    case ParkingAlertType.timeLimitedZone:
      return 'yellow'; // Info
    default:
      return 'blue';   // General
  }
}
```

## Testing

### Test Alert System

```dart
// In your test file
void main() {
  test('Parking alerts are fetched', () async {
    final service = ParkingAlertsService.instance;
    final response = await service.getParkingAlerts(40.7589, -73.9851);
    
    expect(response.alerts, isNotEmpty);
    expect(response.city, equals('New York'));
  });
}
```

### Test Notifications

```dart
// Trigger a test notification
await NotificationService.instance.showParkingAlert(
  ParkingAlert(
    id: 'test',
    type: ParkingAlertType.streetCleaning,
    title: 'Test Alert',
    description: 'This is a test parking alert',
  ),
);
```

## Performance Considerations

### Caching

Consider caching API responses:

```dart
Map<String, ParkingRulesResponse> _cache = {};

Future<ParkingRulesResponse> getParkingAlerts(double lat, double lon) async {
  final key = '${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';
  
  if (_cache.containsKey(key)) {
    return _cache[key]!;
  }
  
  final response = await _fetchAlerts(lat, lon);
  _cache[key] = response;
  
  return response;
}
```

### Rate Limiting

Add rate limiting for API calls:

```dart
DateTime? _lastRequest;
static const _minInterval = Duration(seconds: 5);

Future<ParkingRulesResponse> getParkingAlerts(double lat, double lon) async {
  if (_lastRequest != null && 
      DateTime.now().difference(_lastRequest!) < _minInterval) {
    // Return cached or wait
  }
  
  _lastRequest = DateTime.now();
  // Make request
}
```

## Troubleshooting

### No Alerts Showing

1. **Check internet connection** - API requires network
2. **Verify location permissions** - GPS must be enabled
3. **Check API response** - Add logging to see API results
4. **Validate coordinates** - Ensure lat/lon are correct

### Notifications Not Appearing

1. **Check notification permissions** - Must be granted by user
2. **Verify initialization** - NotificationService.initialize() called
3. **Test on real device** - Emulator notifications can be unreliable
4. **Check scheduled times** - Times must be in the future

### API Errors

```dart
// Add error handling
try {
  final alerts = await ParkingAlertsService.instance.getParkingAlerts(lat, lon);
} catch (e) {
  print('Error fetching alerts: $e');
  // Show user-friendly message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Unable to fetch parking alerts')),
  );
}
```

## Best Practices

1. **Always provide fallback data** - Even if API fails, show basic alerts
2. **Cache API responses** - Reduce network calls and costs
3. **Handle rate limits** - Respect API usage limits
4. **Localize messages** - Support multiple languages
5. **Test thoroughly** - Verify in different cities/scenarios
6. **Monitor API health** - Log failures for debugging
7. **User privacy** - Never send location data without consent

## Resources

- [OpenStreetMap Overpass API](https://wiki.openstreetmap.org/wiki/Overpass_API)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [NYC Open Data](https://opendata.cityofnewyork.us/)
- [SFMTA API Docs](https://www.sfmta.com/getting-around/drive-park)

## Support

For questions or issues with the parking alerts system:
1. Check this guide first
2. Review the README.md
3. Open an issue on GitHub with:
   - Device/platform details
   - Location where issue occurred
   - Screenshots if applicable
   - Logs from the console

---

**Happy parking! 🚗📍**

