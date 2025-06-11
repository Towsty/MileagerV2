import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mileager/models/vehicle.dart';

class VehicleProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  String? _error;

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
            'VehicleProvider: Loaded vehicle ${vehicle.make} ${vehicle.model} with photoPath: ${vehicle.photoPath}');
        return vehicle;
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    try {
      print(
          'VehicleProvider: Adding vehicle ${vehicle.make} ${vehicle.model} with photoPath: ${vehicle.photoPath}');
      final docRef =
          await _firestore.collection('vehicles').add(vehicle.toMap());
      final newVehicle = vehicle.copyWith(id: docRef.id);
      _vehicles.add(newVehicle);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    try {
      print(
          'VehicleProvider: Updating vehicle ${vehicle.make} ${vehicle.model} with photoPath: ${vehicle.photoPath}');
      await _firestore
          .collection('vehicles')
          .doc(vehicle.id)
          .update(vehicle.toMap());
      final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
      if (index != -1) {
        _vehicles[index] = vehicle;
        notifyListeners();
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
}
