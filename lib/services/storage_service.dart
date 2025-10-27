import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:find_my_car/models/parking_spot.dart';

class StorageService {
  static final StorageService instance = StorageService._();
  StorageService._();

  static const String _parkingSpotKey = 'parking_spot';

  Future<void> saveParkingSpot(ParkingSpot spot) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(spot.toJson());
    await prefs.setString(_parkingSpotKey, json);
  }

  Future<ParkingSpot?> getParkingSpot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_parkingSpotKey);
      if (json == null) return null;
      
      final map = jsonDecode(json) as Map<String, dynamic>;
      return ParkingSpot.fromJson(map);
    } catch (e) {
      print('Error loading parking spot: $e');
      return null;
    }
  }

  Future<void> deleteParkingSpot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_parkingSpotKey);
  }

  Future<bool> hasParkingSpot() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_parkingSpotKey);
  }
}

