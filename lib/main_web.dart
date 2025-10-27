// Web-compatible version of the Prk app
// Run with: flutter run -t lib/main_web.dart -d chrome

import 'package:flutter/material.dart';
import 'screens/home_screen_web_demo.dart';

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
          primary: Color(0xFF3B82F6), // Bright Blue
          secondary: Color(0xFF10B981), // Green
          error: Color(0xFFEF4444), // Red (Accent)
          background: Color(0xFF0F172A), // Slate 900
          surface: Color(0xFF1E293B), // Slate 800
          onPrimary: Color(0xFFF1F5F9), // Slate 100
          onSecondary: Color(0xFFF1F5F9), // Slate 100
          onError: Color(0xFFF1F5F9), // Slate 100
          onBackground: Color(0xFFF1F5F9), // Slate 100
          onSurface: Color(0xFFF1F5F9), // Slate 100
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        useMaterial3: true,
        cardTheme: const CardThemeData(
          color: Color(0xFF1E293B), // Slate 800
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B), // Slate 800
          foregroundColor: Color(0xFFF1F5F9), // Slate 100
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.dark, // Force dark mode
      home: const HomeScreenWebDemo(),
    );
  }
}
