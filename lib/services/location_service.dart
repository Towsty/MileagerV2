import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math' show cos, sqrt, asin;

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
    await _checkLocationPermission();
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('LocationService: Location services are disabled');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('LocationService: Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint(
          'LocationService: Location permissions are permanently denied');
      return false;
    }

    debugPrint('LocationService: Location permissions granted');
    return true;
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
    try {
      final lastKnownPosition = Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null) {
        debugPrint('LocationService: Using last known position');
        return GeoPoint(
            0, 0); // This will be updated when position is available
      }
      debugPrint('LocationService: No last known position available');
      return null;
    } catch (e) {
      debugPrint('LocationService: Error getting current GeoPoint: $e');
      return null;
    }
  }

  Future<Position?> getCurrentLocation() async {
    try {
      if (!await _checkLocationPermission()) {
        debugPrint('LocationService: Failed to get location - no permission');
        return null;
      }
      final position = await Geolocator.getCurrentPosition();
      debugPrint(
          'LocationService: Got current location - ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('LocationService: Error getting current location: $e');
      return null;
    }
  }

  Future<GeoPoint?> getCoordinatesFromAddress(String address) async {
    try {
      debugPrint(
          'LocationService: Attempting to get coordinates for address: $address');

      if (address.trim().isEmpty) {
        debugPrint('LocationService: Empty address provided');
        return null;
      }

      final locations = await locationFromAddress(address);
      debugPrint('LocationService: Geocoding response - $locations');

      if (locations.isEmpty) {
        debugPrint('LocationService: No locations found for address');
        return null;
      }

      final location = locations.first;
      debugPrint(
          'LocationService: Found coordinates - ${location.latitude}, ${location.longitude}');
      return GeoPoint(location.latitude, location.longitude);
    } catch (e) {
      debugPrint('LocationService: Error getting coordinates from address: $e');
      return null;
    }
  }

  Future<String?> getAddressFromCoordinates(GeoPoint point) async {
    try {
      debugPrint(
          'LocationService: Attempting to get address for coordinates: ${point.latitude}, ${point.longitude}');

      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      debugPrint('LocationService: Reverse geocoding response - $placemarks');

      if (placemarks.isEmpty) {
        debugPrint('LocationService: No address found for coordinates');
        return null;
      }

      final place = placemarks.first;
      final components = <String>[
        place.street ?? '',
        place.locality ?? '',
        place.administrativeArea ?? '',
        place.postalCode ?? '',
        place.country ?? '',
      ];
      final address = components.where((e) => e.isNotEmpty).join(', ');
      debugPrint('LocationService: Found address - $address');
      return address;
    } catch (e) {
      debugPrint('LocationService: Error getting address from coordinates: $e');
      return null;
    }
  }

  double calculateDistance(GeoPoint start, GeoPoint end) {
    // Using the Haversine formula to calculate distance between two points
    const p = 0.017453292519943295; // Math.PI / 180
    const c = cos;
    final a = 0.5 -
        c((end.latitude - start.latitude) * p) / 2 +
        c(start.latitude * p) *
            c(end.latitude * p) *
            (1 - c((end.longitude - start.longitude) * p)) /
            2;

    // Return distance in meters
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R; R = 6371 km
  }

  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }
}
