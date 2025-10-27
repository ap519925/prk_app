import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class NavigationService {
  static final NavigationService instance = NavigationService._();
  NavigationService._();

  Future<bool> openNavigation(double lat, double lon) async {
    // Try to open navigation in the best available app
    // For iOS: Apple Maps
    // For Android: Google Maps
    
    Uri uri;
    
    if (Platform.isIOS) {
      // Apple Maps
      uri = Uri.parse('http://maps.apple.com/?daddr=$lat,$lon&dirflg=d');
    } else {
      // Google Maps (works on Android)
      uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving');
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      
      // Fallback to web browser
      final webUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error launching navigation: $e');
      return false;
    }
  }

  Future<bool> openInMaps(double lat, double lon) async {
    // Just open the location in maps (no navigation)
    Uri uri;
    
    if (Platform.isIOS) {
      uri = Uri.parse('http://maps.apple.com/?q=$lat,$lon');
    } else {
      uri = Uri.parse('geo:$lat,$lon?q=$lat,$lon');
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      print('Error opening maps: $e');
      return false;
    }
  }
}

