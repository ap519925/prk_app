import 'package:flutter/material.dart';
import 'package:find_my_car/screens/home_screen.dart';
import 'package:find_my_car/services/location_service.dart';
import 'package:find_my_car/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocationService.instance.initialize();
  await NotificationService.instance.initialize();
  runApp(const FindMyCarApp());
}

class FindMyCarApp extends StatelessWidget {
  const FindMyCarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Find My Car',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
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
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B), // Slate 800
          foregroundColor: Color(0xFFF1F5F9), // Slate 100
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.dark, // Force dark mode to show new color scheme
      home: const HomeScreen(),
    );
  }
}

