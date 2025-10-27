# Google Maps Setup Guide for Prk App

## Overview

Your Prk app now includes fully integrated Google Maps with custom styling and features:

✅ **Full-screen map view** with parking location marker
✅ **Mini map widget** on home screen
✅ **Custom map styling** (light and dark modes)
✅ **Distance calculation** from current location
✅ **Interactive markers** with info windows
✅ **Satellite/Normal map toggle**
✅ **Circle radius** around parking spot
✅ **Navigation integration**

## Required: Get Google Maps API Key

### Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a Project" → "New Project"
3. Enter project name: `Prk App` (or your choice)
4. Click "Create"

### Step 2: Enable Required APIs

1. Go to **APIs & Services** → **Library**
2. Enable these APIs:
   - ✅ **Maps SDK for Android**
   - ✅ **Maps SDK for iOS**
   - ✅ **Maps JavaScript API** (for web)
   - ✅ **Geocoding API**
   - ✅ **Geolocation API**

Search for each and click "Enable"

### Step 3: Create API Key

1. Go to **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **API key**
3. Copy the API key (you'll need it in next steps)
4. Click "Restrict Key" (recommended for security)

### Step 4: Restrict API Key (Security Best Practice)

#### Application Restrictions:
- For development: None
- For production: Set specific restrictions

#### API Restrictions:
Select "Restrict key" and choose:
- Maps SDK for Android
- Maps SDK for iOS  
- Maps JavaScript API
- Geocoding API
- Geolocation API

Click "Save"

## Configure Your App

### Android Setup

1. **Open**: `android/app/src/main/AndroidManifest.xml`

2. **Add** inside the `<application>` tag:

```xml
<manifest>
    <application>
        <!-- Add this meta-data tag -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_API_KEY_HERE"/>
        
        <!-- Rest of your application config -->
    </application>
</manifest>
```

3. **Replace** `YOUR_API_KEY_HERE` with your actual API key

### iOS Setup

1. **Open**: `ios/Runner/AppDelegate.swift`

2. **Add** at the top:

```swift
import UIKit
import Flutter
import GoogleMaps  // Add this import

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_API_KEY_HERE")  // Add this line
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

3. **Replace** `YOUR_API_KEY_HERE` with your actual API key

### Web Setup

1. **Open**: `web/index.html`

2. **Add** in the `<head>` section:

```html
<head>
  <!-- Other head content -->
  
  <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY_HERE"></script>
</head>
```

3. **Replace** `YOUR_API_KEY_HERE` with your actual API key

## Security Best Practices

### Option 1: Environment Variables (Recommended)

Instead of hardcoding API keys, use environment variables:

#### For Android:
1. Create `android/local.properties`:
```properties
MAPS_API_KEY=your_actual_api_key_here
```

2. Update `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        // Add this
        manifestPlaceholders = [MAPS_API_KEY: project.properties['MAPS_API_KEY'] ?: ""]
    }
}
```

3. Update `AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${MAPS_API_KEY}"/>
```

#### For iOS:
Use a similar approach with `xcconfig` files.

### Option 2: Separate Keys for Each Platform

Create different API keys for:
- Android (with Android app restrictions)
- iOS (with iOS app restrictions)
- Web (with HTTP referrer restrictions)

This limits damage if one key is compromised.

### Option 3: Key Restrictions

In Google Cloud Console, restrict your keys:

**Android Key:**
- Application restrictions: Android apps
- Add your package name: `com.example.find_my_car`
- Add SHA-1 certificate fingerprint

**iOS Key:**
- Application restrictions: iOS apps
- Add your bundle ID: `com.example.findMyCar`

**Web Key:**
- Application restrictions: HTTP referrers
- Add: `yourdomain.com/*` or `localhost:*` for testing

## Testing Your Setup

### Test on Android
```bash
flutter run -d android
```

### Test on iOS
```bash
flutter run -d ios
```

### Test on Web
```bash
flutter run -t lib/main_web.dart -d chrome
```

## Map Features

### Full Screen Map (`lib/screens/map_screen.dart`)

**Features:**
- 🗺️ Interactive Google Map
- 📍 Custom parking marker (red pin)
- 📱 Current location marker (blue pin)
- 🎯 Circle showing 50m radius around car
- 📏 Distance calculation display
- 🌐 Satellite/Normal view toggle
- 🧭 Center on parking button
- 📍 Center on current location button
- 🚗 Start navigation button
- 🎨 Custom dark/light map styling

### Mini Map Widget (`lib/widgets/mini_map_widget.dart`)

**Features:**
- 📱 Compact map preview on home screen
- 🚗 Parking location marker
- 👆 Tap to open full map
- ⚡ Lite mode for fast rendering
- 🎨 Rounded corners and shadows

### Custom Map Styling

The map includes custom JSON styling for:
- **Light Mode**: Clean, minimal style hiding POI clutter
- **Dark Mode**: Sleek dark theme with custom colors

Edit styles in `lib/screens/map_screen.dart`:
- `_mapStyleLight` - Light theme JSON
- `_mapStyleDark` - Dark theme JSON

You can create custom styles at: [Google Maps Styling Wizard](https://mapstyle.withgoogle.com/)

## Customization Options

### Change Marker Icons

In `lib/screens/map_screen.dart`, update `_getCarMarkerIcon()`:

```dart
Future<BitmapDescriptor> _getCarMarkerIcon() async {
  // Option 1: Use different color
  return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  
  // Option 2: Use custom image
  return BitmapDescriptor.fromAssetImage(
    const ImageConfiguration(size: Size(48, 48)),
    'assets/car_icon.png',
  );
}
```

### Change Circle Radius

In `_createCircles()`, modify:

```dart
radius: 100, // Change from 50 to 100 meters
fillColor: Colors.green.withOpacity(0.1), // Change color
```

### Change Map Type Default

```dart
MapType _currentMapType = MapType.satellite; // Or MapType.hybrid, MapType.terrain
```

### Customize Info Windows

In `_createMarkers()`, modify the `infoWindow`:

```dart
infoWindow: InfoWindow(
  title: '🚙 My Awesome Car',
  snippet: 'Parked ${DateTime.now().hour}:00',
),
```

## Troubleshooting

### Map Not Showing

**Issue**: Gray screen or blank map

**Solutions**:
1. ✅ Verify API key is correct
2. ✅ Check API is enabled in Google Cloud Console
3. ✅ Wait 5-10 minutes after creating API key (propagation time)
4. ✅ Check billing is enabled on Google Cloud project
5. ✅ Verify AndroidManifest.xml / AppDelegate has key

### "This page can't load Google Maps correctly"

**Issue**: Error message on map

**Solution**:
- Enable billing in Google Cloud Console
- Google Maps requires a valid payment method (even for free tier)
- Free tier includes: $200 credit per month = ~28,000 map loads

### Markers Not Appearing

**Issue**: Map loads but no parking marker

**Solutions**:
1. Check coordinates are valid (latitude: -90 to 90, longitude: -180 to 180)
2. Verify marker creation in `_createMarkers()`
3. Check zoom level isn't too far out

### Permission Errors

**Issue**: "Location permission denied"

**Solutions**:
- Grant location permissions in device settings
- Check AndroidManifest.xml has location permissions
- Check Info.plist has location usage descriptions

## API Usage and Costs

### Free Tier (Always Free)
- $200 monthly credit
- ~28,000 map loads
- ~40,000 geocodes
- Plenty for personal/development use

### Pricing (After Free Credit)
- Dynamic Maps: $7 per 1,000 loads
- Geocoding: $5 per 1,000 requests
- Geolocation: $5 per 1,000 requests

### Monitor Usage
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. **APIs & Services** → **Dashboard**
3. View daily/monthly usage
4. Set up billing alerts

### Reduce Costs
- ✅ Use `liteModeEnabled: true` for mini maps (cheaper)
- ✅ Cache geocoding results
- ✅ Set billing alerts at $10, $50, etc.
- ✅ Use API key restrictions

## Additional Resources

- [Google Maps Platform Documentation](https://developers.google.com/maps/documentation)
- [Flutter Google Maps Plugin](https://pub.dev/packages/google_maps_flutter)
- [Map Styling Wizard](https://mapstyle.withgoogle.com/)
- [Pricing Calculator](https://mapsplatformtransition.withgoogle.com/calculator)
- [Support](https://developers.google.com/maps/support)

## Need Help?

Common questions:
- **Q**: Do I need a credit card?
  **A**: Yes, but you won't be charged unless you exceed $200/month (unlikely for personal use)

- **Q**: Is there a completely free alternative?
  **A**: OpenStreetMap with Leaflet, but Google Maps has better features and accuracy

- **Q**: Can I use one API key for all platforms?
  **A**: Yes for development, but use separate restricted keys for production

---

**Your Prk app now has beautiful, fully-functional Google Maps integration!** 🗺️🚗

Once you add your API key, you'll see:
- Interactive map on the map screen
- Mini preview map on home screen
- Real-time distance calculations
- Beautiful custom styling

Enjoy! 📍

