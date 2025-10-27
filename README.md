# Prk - Find My Car with Smart Parking Alerts

Never forget where you parked again, and never get a parking ticket.

**Prk** is the simplest parking app you'll ever use. No complicated menus. No account required. Just two buttons that do exactly what you need - plus smart alerts so you never get a ticket.

## Features

### Core Features
- **One-tap save and find** - Save your parking location with a single tap
- **Turn-by-turn navigation** - Get directions straight back to your car
- **Works offline** - Saves GPS coordinates even without internet
- **Optional photo** - Take a picture of your parking spot or surrounding area
- **No ads, no tracking, no nonsense**

### Smart Parking Alerts 🆕
Prk automatically checks local parking rules at your location and alerts you about:

- 🧹 **Street cleaning schedules**
- 💰 **Metered parking expiration**
- ⏱️ **Time-limited zone warnings**
- 🎫 **Permit-only area notifications**
- ❄️ **Snow emergency routes**
- 🚫 **No parking zones**

No need to decipher confusing signs. Prk reads them for you.

### Additional Features
- ⏰ **Customizable parking timers** with notifications
- 🔔 **Smart notifications** - Get alerts before your time expires
- 📍 **Precise GPS location** saving
- 🗺️ **Map view** of your parking spot
- 🔄 **Auto-detects** when you park (via Bluetooth - coming soon)

## Perfect For

- City street parking with complex rules
- Shopping malls and parking garages
- Airports and train stations
- Theme parks and stadiums
- Unfamiliar neighborhoods
- Metered parking zones

## Getting Started

### Prerequisites

- Flutter SDK 3.0.0 or higher
- Android Studio / Xcode for mobile development
- iOS 12.0+ / Android 5.0+

### Installation

1. Clone the repository:
```bash
git clone https://github.com/ap519925/prk_app.git
cd prk_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Parking Alerts API Integration

The app currently uses **OpenStreetMap Overpass API** (free) for basic parking restrictions. You can enhance the alerts by integrating with additional APIs:

### Current Implementation

**OpenStreetMap Overpass API** (Free)
- Parking lane restrictions
- Time limits
- Fee requirements
- No parking zones

### Recommended API Integrations

#### 1. City-Specific APIs (Free)

**NYC Open Data**
- Street parking rules
- Metered parking locations
- Website: https://data.cityofnewyork.us/

**San Francisco SFMTA**
- Real-time parking availability
- Parking regulations
- Website: https://www.sfmta.com/

**Los Angeles DOT**
- Parking restrictions
- Street cleaning schedules

**Chicago Data Portal**
- Parking meters and restrictions
- Website: https://data.cityofchicago.org/

#### 2. Commercial APIs

**ParkWhiz API**
- Multi-city parking data
- Website: https://www.parkwhiz.com/developers/

**SpotHero API**
- Parking reservations and rules
- Website: https://spothero.com/

**Google Maps Places API**
- Parking information
- Street view for sign reading
- Website: https://developers.google.com/maps/documentation/places/web-service

#### 3. Weather APIs for Snow Emergency Alerts

**OpenWeatherMap**
- Weather conditions for snow emergency detection
- Website: https://openweathermap.org/api

**Weather.gov API** (Free, US only)
- Official weather alerts
- Website: https://www.weather.gov/documentation/services-web-api

### How to Add Your Own API

1. Open `lib/services/parking_alerts_service.dart`
2. Find the `_getCitySpecificAlerts` method
3. Add your API integration:

```dart
Future<List<ParkingAlert>> _getCitySpecificAlerts(
  String? city,
  String? state,
  double lat,
  double lon,
) async {
  final alerts = <ParkingAlert>[];
  
  // Example: Add your city API here
  if (city == 'New York') {
    final response = await http.get(
      Uri.parse('https://your-api-endpoint.com/parking?lat=$lat&lon=$lon'),
    );
    // Parse response and create ParkingAlert objects
  }
  
  return alerts;
}
```

## Configuration

### Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
```

### iOS Permissions

Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to save your parking spot</string>
<key>NSCameraUsageDescription</key>
<string>Take a photo of your parking spot</string>
<key>NSUserNotificationsUsageDescription</key>
<string>Send you parking reminders and alerts</string>
```

## Architecture

```
lib/
├── main.dart                          # App entry point
├── models/
│   ├── parking_spot.dart             # Parking location data model
│   └── parking_alert.dart            # Alert data model
├── screens/
│   ├── home_screen.dart              # Main screen with save/find buttons
│   ├── map_screen.dart               # Map view of parking location
│   └── parking_details_screen.dart   # Detailed parking info
└── services/
    ├── location_service.dart          # GPS location handling
    ├── storage_service.dart           # Local data persistence
    ├── navigation_service.dart        # Turn-by-turn navigation
    ├── parking_alerts_service.dart    # Parking rules API integration
    └── notification_service.dart      # Local notifications
```

## Technologies Used

- **Flutter** - Cross-platform mobile framework
- **geolocator** - GPS location services
- **geocoding** - Address lookup
- **google_maps_flutter** - Map display
- **flutter_local_notifications** - Push notifications
- **shared_preferences** - Local storage
- **http** - API requests
- **OpenStreetMap Overpass API** - Parking restrictions data

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

Areas where contributions would be especially valuable:
- Integration with more city-specific parking APIs
- Bluetooth auto-detection when parking
- Apple Watch / Wear OS support
- Parking history tracking
- Multi-language support

## Roadmap

- [ ] Bluetooth auto-detect parking
- [ ] Parking history
- [ ] Parking cost calculator
- [ ] Wearable device support
- [ ] Voice commands
- [ ] Parking spot sharing
- [ ] Integration with more city parking APIs
- [ ] ML-based sign recognition using camera

## Privacy

Prk respects your privacy:
- ✅ No user accounts required
- ✅ No tracking or analytics
- ✅ All data stored locally on your device
- ✅ Location only used when you actively save a spot
- ✅ No data sold or shared with third parties

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, questions, or feature requests, please open an issue on GitHub.

## Acknowledgments

- OpenStreetMap contributors for parking restriction data
- Flutter team for the amazing framework
- All contributors who help make parking easier!

---

**Stop wasting time searching for your car and money on parking tickets. Prk remembers so you don't have to.** 🚗📍

