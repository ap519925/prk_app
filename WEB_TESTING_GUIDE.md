# Testing Prk App on the Web

## Quick Start

To test the app on the web, use the web-compatible demo version:

```bash
flutter run -t lib/main_web.dart -d chrome
```

Or to run on any available web browser:

```bash
flutter run -t lib/main_web.dart -d web-server
```

## Web Compatibility Overview

### ✅ Features That Work on Web

- **UI/UX Display** - Full Material Design 3 interface
- **Parking Alerts Display** - Visual display of alerts
- **HTTP Requests** - OpenStreetMap API calls work fine
- **Local Storage** - `shared_preferences` works on web
- **Timer Logic** - All time-based calculations
- **Dark Mode** - System theme detection

### ⚠️ Features with Limitations

| Feature | Web Status | Workaround |
|---------|------------|------------|
| **GPS Location** | ⚠️ Partial | Browser geolocation API (requires HTTPS) |
| **Google Maps** | ⚠️ Limited | Use `google_maps_flutter_web` plugin |
| **Navigation** | ⚠️ Different | Opens Google Maps in new tab |
| **Local Storage** | ✅ Works | Uses browser localStorage |

### ❌ Features That Don't Work on Web

| Feature | Why | Mobile Alternative |
|---------|-----|-------------------|
| **Push Notifications** | `flutter_local_notifications` not supported | Use web push API or Firebase Cloud Messaging |
| **Camera** | `image_picker` camera mode not supported | Use `<input type="file" capture="camera">` |
| **Background Tasks** | No background execution on web | Service workers (advanced) |
| **Bluetooth Detection** | Limited web bluetooth API | Physical device required |

## Testing Methods

### Method 1: Web Demo Mode (Recommended)

This is the easiest way to test the UI and features:

```bash
# Run the web demo
flutter run -t lib/main_web.dart -d chrome
```

**What you can test:**
- ✅ Complete UI/UX flow
- ✅ Parking alerts display
- ✅ Button interactions
- ✅ Theme switching
- ✅ Responsive layout
- ✅ Demo data flow

**Limitations:**
- Uses simulated GPS coordinates (Times Square, NYC)
- Shows sample parking alerts
- No real notifications
- No camera access

### Method 2: Enable Web Support for Full App

To test the actual app on web (with limitations):

1. **Enable web support** (if not already enabled):
```bash
flutter create --platforms=web .
```

2. **Add web support to plugins** in `pubspec.yaml`:
```yaml
dependencies:
  # Add web alternatives
  geolocator_web: ^2.2.0
  google_maps_flutter_web: ^0.5.0
```

3. **Update imports** to use conditional imports:
```dart
import 'location_service_mobile.dart' 
  if (dart.library.html) 'location_service_web.dart';
```

4. **Run on web**:
```bash
flutter run -d chrome
```

### Method 3: Build for Production

Build the web app for deployment:

```bash
# Build for production
flutter build web --release

# Serve locally to test
cd build/web
python -m http.server 8000
# Open http://localhost:8000
```

## Setting Up Web Geolocation

If you want to test with browser geolocation:

### 1. Create `web/index.html` configuration

```html
<script>
  // Request geolocation permission
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(
      function(position) {
        console.log('Location:', position.coords.latitude, position.coords.longitude);
      },
      function(error) {
        console.error('Geolocation error:', error);
      }
    );
  }
</script>
```

### 2. Enable HTTPS for Testing

Geolocation requires HTTPS in production. For local testing:

```bash
# Use Chrome with insecure localhost
chrome --unsafely-treat-insecure-origin-as-secure="http://localhost:PORT" --user-data-dir=/tmp/chrome-dev
```

Or use Flutter's built-in server:
```bash
flutter run -d web-server --web-hostname=localhost --web-port=5000
```

## Testing Parking Alerts API

The OpenStreetMap API works perfectly on web:

```bash
# Test with a specific location
curl "https://overpass-api.de/api/interpreter" \
  -d 'data=[out:json];way["parking:lane"](around:100,40.7589,-73.9851);out body;'
```

## Browser-Specific Testing

### Chrome
```bash
flutter run -d chrome --web-renderer=html
```

### Firefox
```bash
# First time setup
flutter devices  # Find the firefox device id
flutter run -d firefox --web-renderer=html
```

### Edge
```bash
flutter run -d edge --web-renderer=html
```

### Safari (macOS only)
```bash
flutter run -d safari --web-renderer=html
```

## Web Renderer Options

Flutter offers two web renderers:

### HTML Renderer (Default for mobile browsers)
```bash
flutter run -d chrome --web-renderer=html
```
- ✅ Smaller download size
- ✅ Better text rendering
- ⚠️ Some widgets may look different

### CanvasKit Renderer (Default for desktop)
```bash
flutter run -d chrome --web-renderer=canvaskit
```
- ✅ Perfect pixel match to mobile
- ✅ Better performance for complex UI
- ⚠️ Larger download size (~2MB extra)

### Auto Renderer (Recommended)
```bash
flutter run -d chrome --web-renderer=auto
```
- Uses HTML on mobile browsers
- Uses CanvasKit on desktop browsers

## Debugging Web App

### Open DevTools
```bash
flutter run -d chrome --web-renderer=html
# Press 'w' to open DevTools in browser
```

### Console Logging
Add logging to see what's happening:

```dart
import 'dart:developer' as developer;

developer.log('Fetching parking alerts...', name: 'parking.service');
```

### Network Tab
Monitor API calls in browser DevTools:
1. Open Chrome DevTools (F12)
2. Go to Network tab
3. Filter by "XHR" to see API calls
4. Check OpenStreetMap API responses

## Common Web Testing Issues

### Issue: "No connected devices"

**Solution:**
```bash
# Enable web support
flutter config --enable-web

# Verify
flutter devices
# Should show: Chrome, Edge, etc.
```

### Issue: CORS errors with APIs

**Solution:**
OpenStreetMap API supports CORS, but some city APIs might not. Use a proxy:

```dart
// Instead of direct API call
final url = 'https://cors-anywhere.herokuapp.com/https://api.example.com/';
```

Or run a local CORS proxy for development.

### Issue: Hot reload not working

**Solution:**
```bash
# Use hot restart instead
# Press 'R' (capital R) in terminal
```

### Issue: Notifications not showing

**Expected** - Web notifications require:
1. Different API (Web Push API)
2. Service worker setup
3. User permission prompt

For demo purposes, use `ScaffoldMessenger`:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Notification would appear here')),
);
```

## Performance Testing

### Lighthouse Audit
```bash
# Build for web
flutter build web --release

# Serve it
cd build/web && python -m http.server 8000

# Open Chrome DevTools > Lighthouse
# Run audit on http://localhost:8000
```

### Check Bundle Size
```bash
flutter build web --release
cd build/web
du -sh *
```

## Deployment Options

Once tested, deploy to:

### Firebase Hosting
```bash
firebase init hosting
firebase deploy
```

### GitHub Pages
```bash
# Build
flutter build web --release --base-href "/prk_app/"

# Copy to docs/ folder
cp -r build/web docs/

# Push to GitHub
git add docs/
git commit -m "Deploy web app"
git push
```

### Netlify
```bash
# Build
flutter build web --release

# Deploy
netlify deploy --dir=build/web --prod
```

## Testing Checklist

Before deploying, test:

- [ ] App loads on Chrome, Firefox, Safari, Edge
- [ ] Mobile responsive (try different screen sizes)
- [ ] Dark mode works correctly
- [ ] All buttons and interactions work
- [ ] API calls succeed (check Network tab)
- [ ] Error handling works (disable network)
- [ ] Loading states display properly
- [ ] Text is readable on all screen sizes
- [ ] Images/icons load correctly
- [ ] Accessibility (screen reader, keyboard navigation)

## Recommended Testing Flow

1. **Start with Web Demo**
   ```bash
   flutter run -t lib/main_web.dart -d chrome
   ```
   - Test UI/UX
   - Verify alerts display
   - Check responsive design

2. **Test API Integration**
   - Open DevTools Network tab
   - Click "Save Parking Spot"
   - Verify OpenStreetMap API call
   - Check response data

3. **Test on Mobile Browser**
   ```bash
   flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080
   ```
   - Find your IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
   - Open on phone: `http://YOUR_IP:8080`

4. **Build and Test Production**
   ```bash
   flutter build web --release
   cd build/web
   python -m http.server 8000
   ```

## Additional Resources

- [Flutter Web Documentation](https://docs.flutter.dev/platform-integration/web)
- [Web Renderers](https://docs.flutter.dev/platform-integration/web/renderers)
- [Debugging Web Apps](https://docs.flutter.dev/platform-integration/web/debugging)
- [Web FAQ](https://docs.flutter.dev/platform-integration/web/faq)

## Mobile Testing (Recommended)

For the full experience with all features, test on mobile:

### Android
```bash
flutter run -d android
```

### iOS
```bash
flutter run -d ios
```

### Physical Device
```bash
# List devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

---

**Note:** The web demo is perfect for showcasing the UI and parking alerts feature, but for production use, the mobile app provides the best experience with GPS, notifications, and camera features.

