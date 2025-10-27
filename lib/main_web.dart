// Web-compatible version of the Prk app
// Run with: flutter run -t lib/main_web.dart -d chrome

import 'package:flutter/material.dart';

void main() {
  runApp(const PrkWebDemo());
}

class PrkWebDemo extends StatelessWidget {
  const PrkWebDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prk - Web Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),        // Bright Blue
          secondary: Color(0xFF10B981),       // Green
          error: Color(0xFFEF4444),           // Red (Accent)
          background: Color(0xFF0F172A),      // Slate 900
          surface: Color(0xFF1E293B),        // Slate 800
          onPrimary: Color(0xFFF1F5F9),      // Slate 100
          onSecondary: Color(0xFFF1F5F9),    // Slate 100
          onError: Color(0xFFF1F5F9),        // Slate 100
          onBackground: Color(0xFFF1F5F9),    // Slate 100
          onSurface: Color(0xFFF1F5F9),      // Slate 100
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        useMaterial3: true,
        cardTheme: CardTheme(
          color: const Color(0xFF1E293B), // Slate 800
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B), // Slate 800
          foregroundColor: Color(0xFFF1F5F9), // Slate 100
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.dark, // Force dark mode
      home: const WebDemoScreen(),
    );
  }
}

class WebDemoScreen extends StatefulWidget {
  const WebDemoScreen({super.key});

  @override
  State<WebDemoScreen> createState() => _WebDemoScreenState();
}

class _WebDemoScreenState extends State<WebDemoScreen> {
  bool _hasSpot = false;
  String? _coordinates;
  String? _address;
  List<Map<String, dynamic>> _alerts = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prk - Find My Car'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      '🌐 Web Demo Mode',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This is a demonstration of the Prk parking app.\n'
                      'Some features require a mobile device:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildFeatureChip('📍 Real GPS', false),
                        _buildFeatureChip('🔔 Push Notifications', false),
                        _buildFeatureChip('📷 Camera', false),
                        _buildFeatureChip('🗺️ Native Navigation', false),
                        _buildFeatureChip('⚡ Parking Alerts', true),
                        _buildFeatureChip('💾 Local Storage', true),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),

              // Status card
              if (_hasSpot) ...[
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
                        if (_address != null)
                          Text(
                            _address!,
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        if (_coordinates != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _coordinates!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Saved just now',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Sample alerts
                if (_alerts.isNotEmpty) ...[
                  Card(
                    elevation: 2,
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, 
                                   color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Parking Alerts',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._alerts.map((alert) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(alert['emoji'], 
                                     style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alert['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        alert['description'],
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      if (alert['timeRange'] != null)
                                        Text(
                                          alert['timeRange'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ] else ...[
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
                  'Click "Save Parking Spot" to see the smart alerts feature in action',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ],

              // Save button
              ElevatedButton.icon(
                onPressed: _saveParkingSpot,
                icon: const Icon(Icons.pin_drop, size: 32),
                label: Text(_hasSpot ? 'UPDATE SPOT' : 'SAVE PARKING SPOT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size.fromHeight(70),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Find button
              ElevatedButton.icon(
                onPressed: _hasSpot ? _findMyCar : null,
                icon: const Icon(Icons.navigation, size: 32),
                label: const Text('FIND MY CAR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(70),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              if (_hasSpot) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _clearSpot,
                  icon: const Icon(Icons.clear),
                  label: const Text('CLEAR PARKING SPOT'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],

              const SizedBox(height: 32),
              
              // Download CTA
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      '📱 Get the Full Experience',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Download the mobile app for:\n'
                      '• Real GPS location tracking\n'
                      '• Push notifications & timers\n'
                      '• Camera photos of your spot\n'
                      '• Offline functionality',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mobile app coming soon to iOS & Android!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Coming Soon'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, bool available) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: available ? Colors.green.shade700 : Colors.grey.shade600,
        ),
      ),
      backgroundColor: available ? Colors.green.shade50 : Colors.grey.shade100,
      side: BorderSide(
        color: available ? Colors.green.shade200 : Colors.grey.shade300,
      ),
    );
  }

  void _saveParkingSpot() {
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
          'timeRange': 'Mon-Sat 9:00 AM - 7:00 PM, Sun 12:00 PM - 6:00 PM',
        },
        {
          'emoji': '⏱️',
          'title': '2-Hour Time Limit',
          'description': 'Maximum 2 hours parking during business hours',
          'timeRange': 'Weekdays 9:00 AM - 6:00 PM',
        },
      ];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Demo parking spot saved! ${_alerts.length} parking alerts found.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _findMyCar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.navigation, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('Opening Google Maps... (Demo mode)\n'
                          'On mobile, this opens your navigation app'),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );

    // On web, you could open Google Maps in a new tab:
    // import 'dart:html' as html;
    // html.window.open(
    //   'https://www.google.com/maps/dir/?api=1&destination=$_coordinates',
    //   '_blank'
    // );
  }

  void _clearSpot() {
    setState(() {
      _hasSpot = false;
      _coordinates = null;
      _address = null;
      _alerts = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Parking spot cleared!'),
      ),
    );
  }
}

