import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';

class TripProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Trip> _trips = [];
  Trip? _activeTrip;
  bool _isLoading = false;
  String? _error;

  List<Trip> get trips => _trips;
  Trip? get activeTrip => _activeTrip;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTrips({String? vehicleId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      CollectionReference<Map<String, dynamic>> tripsRef =
          _db.collection('trips');
      Query<Map<String, dynamic>> query =
          tripsRef.orderBy('startTime', descending: true);

      if (vehicleId != null) {
        query = query.where('vehicleId', isEqualTo: vehicleId);
      }

      final querySnapshot = await query.get();
      _trips = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Set the document ID
        return Trip.fromMap(data);
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCompletedTrip(Trip trip) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Generate a new document reference to get an auto-generated ID
      final docRef = _db.collection('trips').doc();

      // Create trip with the generated ID
      final tripWithId = trip.copyWith(id: docRef.id);

      // Save to Firestore
      await docRef.set(tripWithId.toMap());

      // Add to local list and sort by start time
      _trips.add(tripWithId);
      _trips.sort((a, b) => b.startTime.compareTo(a.startTime));

      print('TripProvider: Trip added successfully with ID: ${docRef.id}');
    } catch (e) {
      _error = 'Failed to add trip: ${e.toString()}';
      print('TripProvider: Error adding trip: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startTrip(Trip trip) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.collection('trips').doc(trip.id).set(trip.toMap());
      _activeTrip = trip;
      _trips.add(trip);
      _trips.sort((a, b) => b.startTime.compareTo(a.startTime));
    } catch (e) {
      _error = 'Failed to start trip: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> endTrip(Trip trip) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.collection('trips').doc(trip.id).update(trip.toMap());
      final index = _trips.indexWhere((t) => t.id == trip.id);
      if (index != -1) {
        _trips[index] = trip;
      }
      _activeTrip = null;
    } catch (e) {
      _error = 'Failed to end trip: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTrip(Trip trip) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.collection('trips').doc(trip.id).update(trip.toMap());
      final index = _trips.indexWhere((t) => t.id == trip.id);
      if (index != -1) {
        _trips[index] = trip;
      }
    } catch (e) {
      _error = 'Failed to update trip: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTrip(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.collection('trips').doc(id).delete();
      _trips.removeWhere((trip) => trip.id == id);
      if (_activeTrip?.id == id) {
        _activeTrip = null;
      }
    } catch (e) {
      _error = 'Failed to delete trip: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<Trip>> getTripsForVehicle(String vehicleId) {
    return _db
        .collection('trips')
        .where('vehicleId', isEqualTo: vehicleId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) {
      final trips = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Trip.fromMap(data);
      }).toList();
      return trips;
    });
  }

  List<Trip> getTripsForDate(DateTime date) {
    return _trips.where((trip) {
      final tripDate = DateTime(
        trip.startTime.year,
        trip.startTime.month,
        trip.startTime.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);
      return tripDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
