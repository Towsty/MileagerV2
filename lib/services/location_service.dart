import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService with ChangeNotifier {
  bool _hasLocation = false;
  bool _isConnecting = false;
  Position? _lastPosition;
  Timer? _locationTimer;
  final int _updateInterval = 10; // seconds
  bool _highPrecisionMode = false;

  bool get hasLocation => _hasLocation;
  bool get isConnecting => _isConnecting;
  Position? get lastPosition => _lastPosition;
  bool get isHighPrecisionMode => _highPrecisionMode;

  // Enhanced getters for status details
  double? get accuracy => _lastPosition?.accuracy;
  DateTime? get lastUpdateTime => _lastPosition != null
      ? DateTime.fromMillisecondsSinceEpoch(
          _lastPosition!.timestamp.millisecondsSinceEpoch)
      : null;

  String get accuracyDescription {
    final acc = accuracy;
    if (acc == null) return 'Unknown';
    if (acc <= 5) return 'Excellent';
    if (acc <= 10) return 'Good';
    if (acc <= 50) return 'Fair';
    return 'Poor';
  }

  Future<void> initialize() async {
    try {
      _isConnecting = true;
      notifyListeners();

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 5));
      if (!serviceEnabled) {
        print('Location services are disabled.');
        _isConnecting = false;
        notifyListeners();
        return;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 5));

      print('Current location permission: $permission');

      // Only request permission if it's denied or not determined
      if (permission == LocationPermission.denied) {
        print('Location permission denied, requesting permission...');
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 10));
        print('Permission request result: $permission');
      }

      // Check if we have sufficient permissions
      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied.');
        _isConnecting = false;
        notifyListeners();
        return;
      }

      if (permission == LocationPermission.denied) {
        print('Location permissions are denied.');
        _isConnecting = false;
        notifyListeners();
        return;
      }

      // If we have whileInUse or always permission, we can proceed
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        print('Location permission granted: $permission');
        // Start periodic location updates
        _startLocationUpdates();
        print('Location service initialized successfully');
      } else {
        print('Insufficient location permissions: $permission');
        _isConnecting = false;
        notifyListeners();
        return;
      }
    } catch (e) {
      _hasLocation = false;
      print('Location service initialization error: $e');
      _isConnecting = false;
      notifyListeners();
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  void _startLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      Duration(seconds: _updateInterval),
      (_) => _updateLocation(),
    );
    // Get initial location
    _updateLocation();
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: _highPrecisionMode
            ? LocationAccuracy.best
            : LocationAccuracy.medium,
      );
      _lastPosition = position;
      _hasLocation = true;
    } catch (e) {
      _hasLocation = false;
      print('Location update error: $e');
    }
    notifyListeners();
  }

  void setHighPrecisionMode(bool enabled) {
    if (_highPrecisionMode != enabled) {
      _highPrecisionMode = enabled;
      print('Location precision mode: ${enabled ? 'HIGH' : 'POWER_SAVING'}');
      notifyListeners();

      // Update location immediately with new precision
      if (_hasLocation) {
        _updateLocation();
      }
    }
  }

  GeoPoint? getCurrentGeoPoint() {
    if (_lastPosition != null) {
      return GeoPoint(_lastPosition!.latitude, _lastPosition!.longitude);
    }
    return null;
  }

  double calculateDistance(GeoPoint start, GeoPoint end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }
}
