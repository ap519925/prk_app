import 'package:flutter/material.dart';
import 'package:find_my_car/models/parking_spot.dart';
import 'package:find_my_car/services/location_service.dart';
import 'package:find_my_car/services/storage_service.dart';
import 'package:find_my_car/services/navigation_service.dart';
import 'package:find_my_car/screens/map_screen.dart';
import 'package:find_my_car/screens/parking_details_screen.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ParkingSpot? _parkingSpot;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadParkingSpot();
  }

  Future<void> _loadParkingSpot() async {
    final spot = await StorageService.instance.getParkingSpot();
    if (mounted) {
      setState(() {
        _parkingSpot = spot;
      });
    }
  }

  Future<void> _saveParkingSpot() async {
    setState(() => _isLoading = true);

    try {
      final position = await LocationService.instance.getCurrentLocation();
      
      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get your location. Please enable location services.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get address
      final address = await LocationService.instance.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final spot = ParkingSpot(
        latitude: position.latitude,
        longitude: position.longitude,
        savedAt: DateTime.now(),
        address: address,
      );

      await StorageService.instance.saveParkingSpot(spot);

      if (mounted) {
        setState(() {
          _parkingSpot = spot;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Parking spot saved!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'ADD PHOTO',
              textColor: Colors.white,
              onPressed: _addPhoto,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _findMyCar() async {
    if (_parkingSpot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No parking spot saved yet!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await NavigationService.instance.openNavigation(
      _parkingSpot!.latitude,
      _parkingSpot!.longitude,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open navigation app'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addPhoto() async {
    if (_parkingSpot == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (photo != null) {
      final updatedSpot = ParkingSpot(
        latitude: _parkingSpot!.latitude,
        longitude: _parkingSpot!.longitude,
        savedAt: _parkingSpot!.savedAt,
        photoPath: photo.path,
        timerEnd: _parkingSpot!.timerEnd,
        address: _parkingSpot!.address,
      );

      await StorageService.instance.saveParkingSpot(updatedSpot);
      
      if (mounted) {
        setState(() {
          _parkingSpot = updatedSpot;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Photo added!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _viewDetails() {
    if (_parkingSpot == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParkingDetailsScreen(
          parkingSpot: _parkingSpot!,
          onDelete: () async {
            await StorageService.instance.deleteParkingSpot();
            setState(() {
              _parkingSpot = null;
            });
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Parking spot cleared!'),
                  backgroundColor: Colors.blue,
                ),
              );
            }
          },
          onUpdate: (updatedSpot) {
            setState(() {
              _parkingSpot = updatedSpot;
            });
          },
        ),
      ),
    );
  }

  void _viewMap() {
    if (_parkingSpot == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(parkingSpot: _parkingSpot!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSpot = _parkingSpot != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find My Car'),
        centerTitle: true,
        actions: [
          if (hasSpot)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _viewDetails,
              tooltip: 'Details',
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status card
              if (hasSpot) ...[
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Parking spot saved',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_parkingSpot!.address != null)
                          Text(
                            _parkingSpot!.address!,
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          )
                        else
                          Text(
                            _parkingSpot!.coordinates,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Saved ${_getTimeAgo(_parkingSpot!.savedAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                        ),
                        if (_parkingSpot!.photoPath != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_camera, size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                'Photo attached',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _viewMap,
                          icon: const Icon(Icons.map),
                          label: const Text('View on Map'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Big buttons
              if (!hasSpot) ...[
                const Spacer(),
                Icon(
                  Icons.local_parking,
                  size: 120,
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
                const SizedBox(height: 24),
                Text(
                  'No parking spot saved',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Save your location to find your car later',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
              ],

              // Save button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveParkingSpot,
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.pin_drop, size: 32),
                label: Text(hasSpot ? 'UPDATE SPOT' : 'SAVE PARKING SPOT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size.fromHeight(70),
                ),
              ),

              const SizedBox(height: 16),

              // Find button
              ElevatedButton.icon(
                onPressed: (_isLoading || !hasSpot) ? null : _findMyCar,
                icon: const Icon(Icons.navigation, size: 32),
                label: const Text('FIND MY CAR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(70),
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                ),
              ),

              if (hasSpot) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addPhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('ADD PHOTO'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await StorageService.instance.deleteParkingSpot();
                          setState(() {
                            _parkingSpot = null;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Parking spot cleared!'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('CLEAR'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}

