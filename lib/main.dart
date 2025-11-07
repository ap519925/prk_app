import 'package:flutter/material.dart';
import 'package:find_my_car/screens/home_screen_redesign.dart';
import 'package:find_my_car/services/location_service.dart';
import 'package:find_my_car/services/notification_service.dart';
import 'package:find_my_car/services/settings_service.dart';
import 'package:find_my_car/constants/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocationService.instance.initialize();
  await NotificationService.instance.initialize();
  await SettingsService().initialize();
  runApp(const FindMyCarApp());
}

class FindMyCarApp extends StatelessWidget {
  const FindMyCarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();
    return MaterialApp(
      title: 'Find My Car',
      debugShowCheckedModeBanner: false,
      theme: getLightTheme(),
      darkTheme: getDarkTheme(),
      themeMode: settingsService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreenRedesign(),
    );
  }
}
