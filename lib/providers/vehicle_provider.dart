import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mileager/models/vehicle.dart';
import 'package:mileager/services/image_cache_service.dart';

class VehicleProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageCacheService _imageCacheService = ImageCacheService();
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  String? _error;
  String? _deviceId;

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadVehicles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('vehicles').get();
      _vehicles = snapshot.docs.map((doc) {
        final vehicle = Vehicle.fromFirestore(doc);
        // Debug logging to track photo paths
        print(
            'VehicleProvider: Loaded vehicle ${vehicle.make} ${vehicle.model} with photoPath: ${vehicle.photoPath}, photoUrl: ${vehicle.photoUrl}');
        return vehicle;
      }).toList();

      _isLoading = false;
      notifyListeners();

      // Preload vehicle images in the background
      _preloadVehicleImages().catchError((e) {
        print('VehicleProvider: Error preloading images: $e');
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    try {
      print(
          'VehicleProvider: Adding vehicle ${vehicle.make} ${vehicle.model} with photoPath: ${vehicle.photoPath}, photoUrl: ${vehicle.photoUrl}');
      final docRef =
          await _firestore.collection('vehicles').add(vehicle.toMap());
      final newVehicle = vehicle.copyWith(id: docRef.id);
      _vehicles.add(newVehicle);
      notifyListeners();

      // Preload image if it's a URL
      if (newVehicle.photoUrl != null &&
          newVehicle.photoUrl!.startsWith('http')) {
        final cacheKey = _imageCacheService.generateVehicleCacheKey(
            newVehicle.id, newVehicle.photoUrl!);
        _imageCacheService
            .preloadImage(newVehicle.photoUrl!, cacheKey: cacheKey)
            .catchError((e) {
          print('VehicleProvider: Error preloading image for new vehicle: $e');
        });
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    try {
      print(
          'VehicleProvider: Updating vehicle ${vehicle.make} ${vehicle.model} with photoPath: ${vehicle.photoPath}, photoUrl: ${vehicle.photoUrl}');
      await _firestore
          .collection('vehicles')
          .doc(vehicle.id)
          .update(vehicle.toMap());
      final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
      if (index != -1) {
        _vehicles[index] = vehicle;
        notifyListeners();

        // Preload image if it's a URL
        if (vehicle.photoUrl != null && vehicle.photoUrl!.startsWith('http')) {
          final cacheKey = _imageCacheService.generateVehicleCacheKey(
              vehicle.id, vehicle.photoUrl!);
          _imageCacheService
              .preloadImage(vehicle.photoUrl!, cacheKey: cacheKey)
              .catchError((e) {
            print(
                'VehicleProvider: Error preloading image for updated vehicle: $e');
          });
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _firestore.collection('vehicles').doc(vehicleId).delete();
      _vehicles.removeWhere((vehicle) => vehicle.id == vehicleId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> testFirestoreConnection() async {
    print(
        'VehicleProvider: Firestore connection test skipped (Firebase disabled)');
  }

  // Preload vehicle images for caching
  Future<void> _preloadVehicleImages() async {
    for (final vehicle in _vehicles) {
      final photoUrl = vehicle.photoUrl;
      if (photoUrl != null &&
          photoUrl.isNotEmpty &&
          photoUrl.startsWith('http')) {
        final cacheKey =
            _imageCacheService.generateVehicleCacheKey(vehicle.id, photoUrl);
        await _imageCacheService.preloadImage(photoUrl, cacheKey: cacheKey);
      }
    }
  }

  // Clear cache for a specific vehicle's image
  Future<void> clearVehicleImageCache(String vehicleId) async {
    final vehicle = _vehicles.firstWhere((v) => v.id == vehicleId);
    final photoUrl = vehicle.photoUrl;
    if (photoUrl != null &&
        photoUrl.isNotEmpty &&
        photoUrl.startsWith('http')) {
      await _imageCacheService.clearCacheForUrl(photoUrl);
    }
  }

  // Clear all vehicle image caches
  Future<void> clearAllImageCache() async {
    await _imageCacheService.clearAllCache();
  }
}
