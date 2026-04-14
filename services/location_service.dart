import 'package:geolocator/geolocator.dart';
import 'dart:math';

class LocationService {
  /// Get user's current location
  /// Tries to enable location service if disabled
  /// Returns Position with latitude and longitude
  static Future<Position> getUserLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (!serviceEnabled) {
        // Try to open location settings
        final stagesRequest = await Geolocator.openLocationSettings();
        if (!stagesRequest) {
          throw Exception("Location services are disabled. Please enable them in settings.");
        }
        // Re-check after user opens settings
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception("Location services are still disabled.");
        }
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied");
      }

      if (permission == LocationPermission.deniedForever) {
        // Open app settings
        await Geolocator.openAppSettings();
        throw Exception("Location permission permanently denied. Please enable it in settings.");
      }

      // Get position with high accuracy
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      throw Exception("Error getting location: $e");
    }
  }

  /// Calculate distance between two coordinates in kilometers
  /// Formula: Haversine formula
  static double calculateDistanceInKm(
    double userLat,
    double userLng,
    double doctorLat,
    double doctorLng,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(doctorLat - userLat);
    final dLng = _degreesToRadians(doctorLng - userLng);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(userLat)) *
            cos(_degreesToRadians(doctorLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadiusKm * c;

    return distance;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  /// Check if doctor is within specified radius (in km)
  static bool isWithinRadius(
    double userLat,
    double userLng,
    double doctorLat,
    double doctorLng,
    double radiusKm,
  ) {
    final distance = calculateDistanceInKm(userLat, userLng, doctorLat, doctorLng);
    return distance <= radiusKm;
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  /// Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }
}
