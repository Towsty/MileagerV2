import 'package:flutter/services.dart';

class BackgroundLocationService {
  static const MethodChannel _channel =
      MethodChannel('background_location_plugin');
  static const EventChannel _eventChannel =
      EventChannel('background_location_events');

  static Stream<Map<String, dynamic>> get locationStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event as Map);
    });
  }

  static Future<void> startLocationService() async {
    try {
      await _channel.invokeMethod('startLocationService');
    } on PlatformException catch (e) {
      print('Error starting location service: ${e.message}');
      rethrow;
    }
  }

  static Future<void> stopLocationService() async {
    try {
      await _channel.invokeMethod('stopLocationService');
    } on PlatformException catch (e) {
      print('Error stopping location service: ${e.message}');
      rethrow;
    }
  }

  static Future<bool> checkLocationPermission() async {
    try {
      final result = await _channel.invokeMethod('checkLocationPermission');
      return result as bool;
    } on PlatformException catch (e) {
      print('Error checking location permission: ${e.message}');
      return false;
    }
  }

  static Future<bool> requestLocationPermission() async {
    try {
      final result = await _channel.invokeMethod('requestLocationPermission');
      return result as bool;
    } on PlatformException catch (e) {
      print('Error requesting location permission: ${e.message}');
      return false;
    }
  }
}
