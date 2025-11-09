// Web demo version with new redesigned UI
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class HomeScreenWebDemo extends StatefulWidget {
  const HomeScreenWebDemo({super.key});

  @override
  State<HomeScreenWebDemo> createState() => _HomeScreenWebDemoState();
}

class _HomeScreenWebDemoState extends State<HomeScreenWebDemo>
    with SingleTickerProviderStateMixin {
  bool _hasSpot = false;
  String? _coordinates;
  String? _address;
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
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

  void _saveParkingSpot() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _hasSpot = true;
        _address = 'Times Square, New York, NY';
        _coordinates = '40.7589, -73.9851';
        _alerts = [
          {
            'emoji': '🧹',
            'title': 'Street Cleaning',
            'description': 'No parking on this side of street',
            'timeRange': 'Monday & Thursday, 8:00 AM - 10:00 AM',
          },
          {
            'emoji': '💰',
            'title': 'Metered Parking',
            'description': 'Payment required at all times',
            'timeRange': 'Mon-Sat 9:00 AM - 7:00 PM',
          },
          {
            'emoji': '⏱️',
            'title': '2-Hour Time Limit',
            'description': 'Maximum 2 hours parking',
            'timeRange': 'Weekdays 9:00 AM - 6:00 PM',
          },
        ];
        _isLoading = false;
      });

      _showSnackBar('✓ Demo parking spot saved! 3 alerts found',
          isError: false);
    });
  }

  void _findMyCar() {
    _showSnackBar('Opening navigation... (Demo mode)', isError: false);
  }

  void _clearParking() {
    setState(() {
      _hasSpot = false;
      _coordinates = null;
      _address = null;
      _alerts = [];
    });
    _showSnackBar('Parking cleared', isError: false);
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface,
              theme.colorScheme.surface,
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
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.local_parking,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Prk',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms).slideX(),
                actions: [
                  if (_hasSpot)
                    IconButton(
                      onPressed: _clearParking,
                      icon: const Icon(Icons.delete_outline),
                      color: theme.colorScheme.error,
                      tooltip: 'Clear parking',
                    ).animate().scale(delay: 300.ms),
                ],
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Web Demo Banner
                    _buildDemoBanner(),
                    const SizedBox(height: 20),

                    if (!_hasSpot) ...[
                      _buildEmptyState(),
                    ] else ...[
                      _buildParkingInfo(),
                      const SizedBox(height: 20),
                      if (_alerts.isNotEmpty) _buildAlertsCard(),
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
      floatingActionButton: _buildActionButtons(),
    );
  }

  Widget _buildDemoBanner() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                '🌐 Web Demo Mode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This demo shows NYC parking alerts for Times Square.\n'
            'Real app includes GPS, camera, and push notifications.',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2);
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
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
                  theme.colorScheme.primary.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.1),
                  child: Icon(
                    Icons.car_rental,
                    size: 120,
                    color: theme.colorScheme.primary,
                  ),
                );
              },
            ),
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(
              duration: 2000.ms,
              color: theme.colorScheme.primary.withOpacity(0.3)),
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
            'Click Save to demo NYC parking alerts',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildParkingInfo() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
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
                  color: theme.colorScheme.tertiary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.tertiary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Car Parked',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF1F5F9),
                      ),
                    ),
                    Text(
                      'just now',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
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
              color: theme.colorScheme.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _address ?? _coordinates ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildAlertsCard() {
    final theme = Theme.of(context);
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
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Parking Alerts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._alerts.map((alert) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert['emoji'],
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF1F5F9),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                            if (alert['timeRange'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                alert['timeRange'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.primary,
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

  Widget _buildActionButtons() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasSpot) ...[
            _buildMainButton(
              label: 'FIND MY CAR',
              icon: Icons.navigation,
              color: theme.colorScheme.tertiary,
              onPressed: _findMyCar,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
            const SizedBox(height: 12),
          ],
          _buildMainButton(
            label: _hasSpot ? 'UPDATE LOCATION' : 'SAVE PARKING SPOT',
            icon: Icons.pin_drop,
            color: theme.colorScheme.primary,
            onPressed: _isLoading ? null : _saveParkingSpot,
            isLoading: _isLoading,
          )
              .animate()
              .fadeIn(delay: _hasSpot ? 300.ms : 0.ms)
              .slideY(begin: 0.3),
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
}
