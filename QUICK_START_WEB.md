# 🚀 Quick Start: Testing Prk on the Web

## TL;DR - Fastest Way to Test

```bash
flutter run -t lib/main_web.dart -d chrome
```

That's it! The app will open in Chrome with a web-compatible demo.

## What You'll See

1. **Demo Mode Banner** - Shows which features work on web vs mobile
2. **Save Parking Spot Button** - Click to simulate saving a parking location
3. **Parking Alerts** - Automatically displays 3 sample parking alerts:
   - 🧹 Street Cleaning schedule
   - 💰 Metered Parking info
   - ⏱️ Time limit restrictions
4. **Find My Car Button** - Shows how navigation would work
5. **Clear Button** - Reset the demo

## Sample Demo Location

The demo uses **Times Square, NYC** as the sample location:
- Coordinates: `40.7589, -73.9851`
- Shows realistic parking alerts for a busy NYC street

## Features You Can Test

### ✅ Fully Functional
- Complete UI/UX design
- Parking alerts display with emojis
- Button interactions
- Dark/light mode
- Responsive layout
- Card designs and animations

### ⚠️ Simulated (Demo Data)
- GPS location (uses Times Square coordinates)
- Parking alerts (shows sample NYC alerts)
- Navigation (shows message instead of opening app)

### ❌ Not Available on Web
- Push notifications (mobile only)
- Camera photos (mobile only)
- Background location tracking (mobile only)

## Step-by-Step Testing

### 1. Run the Web Demo
```bash
cd c:\Users\thean\find_my_car
flutter run -t lib/main_web.dart -d chrome
```

### 2. Interact with the App
1. Click **"SAVE PARKING SPOT"** button
2. See the parking alerts appear
3. Click **"FIND MY CAR"** to test navigation
4. Click **"CLEAR"** to reset

### 3. Test Responsive Design
- Resize the browser window
- Try different zoom levels
- Test on mobile browser (see below)

## Testing on Your Phone

Want to test on your phone's browser?

```bash
# Start web server accessible from your network
flutter run -t lib/main_web.dart -d web-server --web-hostname=0.0.0.0 --web-port=8080
```

Then on your phone:
1. Find your computer's IP address:
   - Windows: `ipconfig` → Look for IPv4 Address
   - Mac/Linux: `ifconfig` → Look for inet address
2. Open browser on phone
3. Navigate to: `http://YOUR_IP:8080`

Example: `http://192.168.1.100:8080`

## Browser Compatibility

Test on different browsers:

```bash
# Chrome (recommended)
flutter run -t lib/main_web.dart -d chrome

# Edge
flutter run -t lib/main_web.dart -d edge

# Firefox (if installed)
flutter run -t lib/main_web.dart -d firefox
```

## Keyboard Shortcuts While Running

- `r` - Hot reload
- `R` - Hot restart
- `h` - Show help
- `q` - Quit
- `w` - Open DevTools in browser

## Common Issues & Solutions

### "No connected devices"
```bash
flutter config --enable-web
flutter devices  # Should now show Chrome, Edge, etc.
```

### App not updating after changes?
Press `R` (capital R) for hot restart

### Port already in use?
```bash
flutter run -t lib/main_web.dart -d chrome --web-port=8081
```

## Next Steps

### Want to test the FULL app on mobile?

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios
```

### Want to build for production?

```bash
# Build optimized web version
flutter build web --release

# Output will be in: build/web/
```

## Need More Info?

- **Full web testing guide**: See `WEB_TESTING_GUIDE.md`
- **Parking alerts details**: See `PARKING_ALERTS_GUIDE.md`
- **General documentation**: See `README.md`

## Quick Demo Script

Try this flow to showcase the app:

1. **Open app** → See clean, minimalist interface
2. **Click "SAVE PARKING SPOT"** → Location saved instantly
3. **View alerts** → 3 parking rules displayed with emojis
4. **Click "FIND MY CAR"** → Navigation preview
5. **Click "CLEAR"** → Reset to initial state

Perfect for:
- Showing to friends/colleagues
- Testing UI changes
- Demos and presentations
- Quick functionality verification

---

**Enjoy testing Prk! 🚗📍**

Questions? Check the other guides or open an issue on GitHub.

