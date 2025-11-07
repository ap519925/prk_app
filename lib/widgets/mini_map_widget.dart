import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/parking_spot.dart';
import '../screens/map_screen.dart';

class MiniMapWidget extends StatefulWidget {
  final ParkingSpot parkingSpot;

  const MiniMapWidget({
    super.key,
    required this.parkingSpot,
  });

  @override
  State<MiniMapWidget> createState() => _MiniMapWidgetState();
}

class _MiniMapWidgetState extends State<MiniMapWidget> {
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _createMarker();
  }

  void _createMarker() {
    _markers.add(
      Marker(
        markerId: const MarkerId('parking'),
        position:
            LatLng(widget.parkingSpot.latitude, widget.parkingSpot.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  void _openFullMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(parkingSpot: widget.parkingSpot),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _openFullMap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Mini Map
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AbsorbPointer(
                child: GoogleMap(
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
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  mapToolbarEnabled: false,
                  myLocationButtonEnabled: false,
                  liteModeEnabled: true, // Faster rendering for mini map
                ),
              ),
            ),

            // Overlay with tap to expand
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
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

            // Tap to expand indicator
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Tap to view full map',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
