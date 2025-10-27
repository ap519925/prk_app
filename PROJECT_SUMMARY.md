# Prk - Find My Car with Smart Parking Alerts

## ✅ PROJECT SUCCESSFULLY UPDATED!

A super simple, minimalist Flutter app to save your parking location and find your car later - now with smart city-specific parking alerts so you never get a ticket!

## 📁 Project Structure

```
find_my_car/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── models/
│   │   ├── parking_spot.dart              # Parking location data model
│   │   └── parking_alert.dart             # Alert data model (NEW)
│   ├── services/
│   │   ├── location_service.dart          # GPS & location handling
│   │   ├── storage_service.dart           # Local data persistence
│   │   ├── navigation_service.dart        # Open navigation apps
│   │   ├── parking_alerts_service.dart    # Parking rules API (NEW)
│   │   └── notification_service.dart      # Local notifications (NEW)
│   └── screens/
│       ├── home_screen.dart               # Main screen with alerts display
│       ├── map_screen.dart                # Map view with car pin
│       └── parking_details_screen.dart    # Details, photo, timer
├── android/                                # Android configuration
├── ios/                                    # iOS configuration
├── pubspec.yaml                            # Dependencies
└── README.md                               # Full documentation
```

## 🚀 Core Features Implemented

### Original Features
✅ SAVE PARKING SPOT button - Saves GPS location with one tap
✅ FIND MY CAR button - Opens navigation to your car
✅ Map view with distance calculation
✅ Photo capture for parking spot
✅ Parking timer for metered spots
✅ Auto-suggest delete when near car
✅ Beautiful Material Design 3 UI
✅ Dark mode support
✅ No accounts, no cloud, just local storage

### NEW: Smart Parking Alerts 🆕
✅ Automatic parking rule detection at your location
✅ City-specific parking regulations
✅ Real-time alerts for:
  - 🧹 Street cleaning schedules
  - 💰 Metered parking expiration
  - ⏱️ Time-limited zone warnings
  - 🎫 Permit-only area notifications
  - ❄️ Snow emergency routes
  - 🚫 No parking zones
✅ Visual alerts display on home screen
✅ Push notifications for parking restrictions
✅ Customizable parking timers with reminders
✅ Notification 15min, 5min before, and at expiration
✅ OpenStreetMap integration for parking data

## 📦 Dependencies

### Original
- geolocator: GPS location services
- geocoding: Address resolution  
- google_maps_flutter: Interactive maps
- url_launcher: Open navigation apps
- shared_preferences: Local storage
- image_picker: Camera functionality

### NEW
- flutter_local_notifications: Smart parking notifications
- timezone: Timezone support for notifications
- http: API requests for parking data

## 🌐 Parking Alerts API Integration

### Current Implementation
- **OpenStreetMap Overpass API** (Free) - Basic parking restrictions

### Recommended Integrations
See README.md for detailed integration guides for:
- NYC Open Data API (Free)
- San Francisco SFMTA API (Free)
- Los Angeles DOT API (Free)
- Chicago Data Portal (Free)
- ParkWhiz API (Commercial)
- SpotHero API (Commercial)
- Google Maps Places API (Commercial)
- Weather APIs for snow emergency alerts

## ⚙️ Next Steps to Run

1. **Install Flutter**: https://flutter.dev/docs/get-started/install

2. **Get Google Maps API Key**: 
   - https://console.cloud.google.com/
   - Enable Maps SDK for Android/iOS
   - Add key to:
     * android/app/src/main/AndroidManifest.xml
     * ios/Runner/Info.plist

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## 🔔 Notification Setup

### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
```

### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSUserNotificationsUsageDescription</key>
<string>Send you parking reminders and alerts</string>
```

## 🎨 Design Philosophy

- **Minimalist**: Just 2 big buttons on home screen
- **No bloat**: No accounts, social features, or premium tiers
- **Fast**: Open app → tap button → get alerts → done
- **Privacy**: All data stored locally on device
- **Smart**: Automatically checks parking rules for you
- **Proactive**: Alerts you before problems occur

## 📱 Perfect For

- City street parking with complex rules
- Shopping malls and parking garages
- Airports and train stations
- Theme parks and stadiums
- Unfamiliar neighborhoods
- Metered parking zones
- Areas with street cleaning schedules
- Snow emergency routes

## 🔮 Future Enhancements

- [ ] Bluetooth auto-detect parking
- [ ] Parking history tracking
- [ ] Parking cost calculator
- [ ] Integration with more city APIs
- [ ] ML-based parking sign recognition
- [ ] Wearable device support
- [ ] Voice commands

## 🎉 What's New in This Update

1. **Smart Parking Alerts System**
   - Automatic detection of parking restrictions
   - Visual alerts display with emoji indicators
   - OpenStreetMap API integration

2. **Advanced Notification System**
   - Local push notifications for parking rules
   - Timer-based reminders (15min, 5min, expiration)
   - Scheduled notifications for time restrictions

3. **Enhanced UI**
   - Parking alerts section on home screen
   - Timer setting dialog with presets
   - Alert count badges
   - Color-coded severity indicators

4. **New Services**
   - `ParkingAlertsService` for fetching parking rules
   - `NotificationService` for managing alerts
   - Extensible API integration framework

---

**Stop wasting time searching for your car and money on parking tickets. Prk remembers so you don't have to.** 🚗📍

Made with Flutter 💙
