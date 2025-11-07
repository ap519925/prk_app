// Web-compatible version of the Prk app
// Run with: flutter run -t lib/main_web.dart -d chrome

import 'package:flutter/material.dart';
import 'screens/home_screen_web_demo.dart';
import 'constants/colors.dart';

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
      theme: getLightTheme(),
      darkTheme: getDarkTheme(),
      themeMode: ThemeMode.dark, // Force dark mode
      home: const HomeScreenWebDemo(),
    );
  }
}
