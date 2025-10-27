import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/parking_spot.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/navigation_service.dart';
import '../services/parking_alerts_service.dart';
import '../services/notification_service.dart';
import '../screens/map_screen.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreenRedesign extends StatefulWidget {
  const HomeScreenRedesign({super.key});

  @override
  State<HomeScreenRedesign> createState() => _HomeScreenRedesignState();
}

class _HomeScreenRedesignState extends State<HomeScreenRedesign>
    with SingleTickerProviderStateMixin {
  ParkingSpot? _parkingSpot;
  bool _isLoading = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadParkingSpot();
    _initializeNotifications();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    await NotificationService.instance.initialize();
  }

  Future<void> _loadParkingSpot() async {
    final spot = await StorageService.instance.getParkingSpot();
    if (mounted) {
      setState(() => _parkingSpot = spot);
    }
  }

  Future<void> _saveParkingSpot() async {
    setState(() => _isLoading = true);

    try {
      final position = await LocationService.instance.getCurrentLocation();

      if (position == null) {
        if (mounted) {
          _showSnackBar('Unable to get location', isError: true);
        }
        return;
      }

      final address = await LocationService.instance.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final alertsResponse = await ParkingAlertsService.instance.getParkingAlerts(
        position.latitude,
        position.longitude,
      );

      final spot = ParkingSpot(
        latitude: position.latitude,
        longitude: position.longitude,
        savedAt: DateTime.now(),
        address: address,
        alerts: alertsResponse.alerts,
        city: alertsResponse.city,
        state: alertsResponse.state,
      );

      await StorageService.instance.saveParkingSpot(spot);

      if (alertsResponse.alerts.isNotEmpty) {
        await NotificationService.instance.showAlertSummary(alertsResponse.alerts);
      }

      if (mounted) {
        setState(() => _parkingSpot = spot);
        _showSnackBar(
          '✓ Parking spot saved! ${alertsResponse.alerts.length} alerts found',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _findMyCar() async {
    if (_parkingSpot == null) return;

    final success = await NavigationService.instance.openNavigation(
      _parkingSpot!.latitude,
      _parkingSpot!.longitude,
    );

    if (!success && mounted) {
      _showSnackBar('Unable to open navigation', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _clearParking() async {
    await StorageService.instance.deleteParkingSpot();
    await NotificationService.instance.cancelAllNotifications();
    setState(() => _parkingSpot = null);
    _showSnackBar('Parking cleared', isError: false);
  }

  void _openMap() {
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F172A),
              const Color(0xFF1E293B),
              const Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_parking,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Prk',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF1F5F9),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms).slideX(),
                actions: [
                  if (hasSpot)
                    IconButton(
                      onPressed: _clearParking,
                      icon: const Icon(Icons.delete_outline),
                      color: const Color(0xFFEF4444),
                      tooltip: 'Clear parking',
                    ).animate().scale(delay: 300.ms),
                ],
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (!hasSpot) ...[
                      _buildEmptyState(),
                    ] else ...[
                      _buildParkingInfo(),
                      const SizedBox(height: 20),
                      if (_parkingSpot!.alerts != null &&
                          _parkingSpot!.alerts!.isNotEmpty)
                        _buildAlertsCard(),
                    ],
                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildActionButtons(hasSpot),
    );
  }

  Widget _buildEmptyState() {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 600),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.1),
                  child: const Icon(
                    Icons.car_rental,
                    size: 120,
                    color: Color(0xFF3B82F6),
                  ),
                );
              },
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2000.ms, color: const Color(0xFF3B82F6).withOpacity(0.3)),
          const SizedBox(height: 40),
          const Text(
            'No Parking Spot Saved',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF1F5F9),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(),
          const SizedBox(height: 12),
          Text(
            'Save your location to never\nlose your car again',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFFF1F5F9).withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildParkingInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Car Parked',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF1F5F9),
                      ),
                    ),
                    Text(
                      _formatTimeAgo(_parkingSpot!.savedAt),
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFFF1F5F9).withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _parkingSpot!.address ?? _parkingSpot!.coordinates,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFF1F5F9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.map_outlined,
                  label: 'Map',
                  color: const Color(0xFF3B82F6),
                  onTap: _openMap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.camera_alt_outlined,
                  label: 'Photo',
                  color: const Color(0xFF3B82F6),
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.timer_outlined,
                  label: 'Timer',
                  color: const Color(0xFF3B82F6),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsCard() {
    final alerts = _parkingSpot!.alerts!;

    return AnimationLimiter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 400),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Parking Alerts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF1F5F9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...alerts.take(3).map((alert) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF1F5F9),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFFF1F5F9).withOpacity(0.7),
                              ),
                            ),
                            if (alert.timeRange != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                alert.timeRange!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF3B82F6),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool hasSpot) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSpot) ...[
            _buildMainButton(
              label: 'FIND MY CAR',
              icon: Icons.navigation,
              color: const Color(0xFF10B981),
              onPressed: _findMyCar,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
            const SizedBox(height: 12),
          ],
          _buildMainButton(
            label: hasSpot ? 'UPDATE LOCATION' : 'SAVE PARKING SPOT',
            icon: Icons.pin_drop,
            color: const Color(0xFF3B82F6),
            onPressed: _isLoading ? null : _saveParkingSpot,
            isLoading: _isLoading,
          ).animate().fadeIn(delay: hasSpot ? 300.ms : 0.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }

  Widget _buildMainButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
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

