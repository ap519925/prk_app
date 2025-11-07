import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/parking_spot.dart';
import '../screens/map_screen.dart';

class MiniMapPreview extends StatefulWidget {
  final ParkingSpot parkingSpot;

  const MiniMapPreview({
    super.key,
    required this.parkingSpot,
  });

  @override
  State<MiniMapPreview> createState() => _MiniMapPreviewState();
}

class _MiniMapPreviewState extends State<MiniMapPreview> {
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _createMarker();
  }

  void _createMarker() {
    _markers.add(
      Marker(
        markerId: const MarkerId('parking_spot'),
        position: LatLng(
          widget.parkingSpot.latitude,
          widget.parkingSpot.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  void _openFullMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapScreen(parkingSpot: widget.parkingSpot),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: _openFullMap,
      child: Container(
        height: 200,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: 16,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Google Map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    widget.parkingSpot.latitude,
                    widget.parkingSpot.longitude,
                  ),
                  zoom: 15.0,
                ),
                markers: _markers,
                zoomControlsEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                liteModeEnabled: true, // Use lite mode for better performance
                onMapCreated: (controller) {
                  // Apply custom dark style if needed
                  if (isDark) {
                    controller.setMapStyle(_mapStyleDark);
                  }
                },
              ),

              // Overlay with tap hint
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        theme.colorScheme.onSurface.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              ),

              // Tap to expand button
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map,
                          color: theme.colorScheme.onPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tap to Open Full Map',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(
                      onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(
                    duration: 1500.ms,
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.05, 1.05),
                  ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  static const String _mapStyleDark = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#1E293B"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#94A3B8"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#0F172A"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#334155"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#1E293B"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#0F172A"}]
    }
  ]
  ''';
}
