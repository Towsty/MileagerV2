import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/saved_location.dart';

class SavedLocationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<SavedLocation> _locations = [];

  List<SavedLocation> get locations => [..._locations];

  Future<void> fetchLocations() async {
    try {
      final snapshot = await _firestore.collection('saved_locations').get();
      _locations = snapshot.docs
          .map((doc) => SavedLocation.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching saved locations: $e');
      rethrow;
    }
  }

  Future<void> addLocation(SavedLocation location) async {
    try {
      final docRef =
          await _firestore.collection('saved_locations').add(location.toMap());
      final newLocation = location.copyWith(id: docRef.id);
      _locations.add(newLocation);
      notifyListeners();
    } catch (e) {
      print('Error adding saved location: $e');
      rethrow;
    }
  }

  Future<void> updateLocation(SavedLocation location) async {
    try {
      await _firestore
          .collection('saved_locations')
          .doc(location.id)
          .update(location.toMap());

      final index = _locations.indexWhere((loc) => loc.id == location.id);
      if (index != -1) {
        _locations[index] = location;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating saved location: $e');
      rethrow;
    }
  }

  Future<void> deleteLocation(String id) async {
    try {
      await _firestore.collection('saved_locations').doc(id).delete();
      _locations.removeWhere((location) => location.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting saved location: $e');
      rethrow;
    }
  }

  SavedLocation? getLocationById(String id) {
    try {
      return _locations.firstWhere((location) => location.id == id);
    } catch (e) {
      return null;
    }
  }
}
