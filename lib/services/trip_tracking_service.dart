import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';
import '../models/vehicle.dart';
import '../providers/trip_provider.dart';
import '../providers/vehicle_provider.dart';
import '../services/activity_recognition_service.dart';
import '../services/location_service.dart';
import '../utils/settings_utils.dart';
import 'package:flutter/widgets.dart';

class TripTrackingService with ChangeNotifier {
  final TripProvider _tripProvider;
  final VehicleProvider _vehicleProvider;
  final ActivityRecognitionService _activityService;
  final LocationService _locationService;

  String? _deviceName;

  Trip? _currentTrip;
  Vehicle? _currentVehicle;
  double _totalDistance = 0.0;
  List<GeoPoint> _routePoints = [];
  Timer? _trackingTimer;
  StreamSubscription? _activitySubscription;
  DateTime? _tripStartTime;

  // For trip confirmation dialog
  Trip? _pendingConfirmationTrip;
  Vehicle? _pendingConfirmationVehicle;

  TripTrackingService(
    this._tripProvider,
    this._vehicleProvider,
    this._activityService,
    this._locationService,
  );

  // Getters
  bool get isTracking => _currentTrip != null;
  bool get isPaused => _currentTrip?.isPaused ?? false;
  Trip? get currentTrip => _currentTrip;
  Vehicle? get currentVehicle => _currentVehicle;
  double get totalDistance => _totalDistance;
  List<GeoPoint> get routePoints => _routePoints;
  Trip? get pendingConfirmationTrip => _pendingConfirmationTrip;
  Vehicle? get pendingConfirmationVehicle => _pendingConfirmationVehicle;

  Future<void> initialize() async {
    print('TripTrackingService: Initializing...');

    try {
      // Get device name
      await _getDeviceName();

      // Don't add listener during initialization - wait until after startup
      // This prevents circular dependencies during provider setup

      // Schedule listener addition for after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _activityService.addListener(_onActivityChanged);
        print('TripTrackingService: Activity listener added after startup');
      });

      print('TripTrackingService: Initialized successfully');
    } catch (e) {
      print('TripTrackingService: Error during initialization: $e');
      // Don't rethrow - let the app continue without automatic trip detection
    }
  }

  Future<void> _getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        _deviceName = 'Android Device';
      } else if (Platform.isIOS) {
        _deviceName = 'iOS Device';
      } else {
        _deviceName = 'Unknown Device';
      }
      print('TripTrackingService: Device name: $_deviceName');
    } catch (e) {
      print('TripTrackingService: Error getting device name: $e');
      _deviceName = 'Unknown Device';
    }
  }

  void _onActivityChanged() {
    final wasTracking = isTracking;
    final isDriving = _activityService.isDriving;

    print(
        'TripTrackingService: Activity changed - isDriving: $isDriving, wasTracking: $wasTracking');
    print('TripTrackingService: Current trip memo: "${_currentTrip?.memo}"');

    // Skip all activity-based logic for manual trips
    if (_currentTrip?.memo == 'Manual trip') {
      print(
          'TripTrackingService: Ignoring all activity changes for manual trip');
      return;
    }

    if (!wasTracking && isDriving) {
      // Started driving - begin automatic trip
      _startAutomaticTrip();
    } else if (wasTracking && !isDriving) {
      // Stopped driving - end automatic trip (but not manual trips)
      print(
          'TripTrackingService: Auto-ending automatic trip due to activity change');
      _endAutomaticTrip();
    }
  }

  Future<void> _startAutomaticTrip() async {
    try {
      print('TripTrackingService: Starting automatic trip...');

      // For now, use the first vehicle or create a default one
      final vehicles = _vehicleProvider.vehicles;
      _currentVehicle = vehicles.isNotEmpty ? vehicles.first : null;

      if (_currentVehicle == null) {
        print('TripTrackingService: No vehicle available for automatic trip');
        return;
      }

      // Enable high precision GPS for trip tracking
      _locationService.setHighPrecisionMode(true);

      final currentLocation = _locationService.getCurrentGeoPoint();

      _currentTrip = Trip(
        id: '', // Will be set when saving to Firestore
        vehicleId: _currentVehicle!.id,
        startTime: DateTime.now(),
        endTime: null,
        distance: 0.0,
        purpose: TripPurpose.business, // Default to business
        memo: '',
        startLocation: currentLocation ?? GeoPoint(0, 0),
        endLocation: null,
        isManualEntry: false,
        deviceName: _deviceName,
      );

      _totalDistance = 0.0;
      _routePoints.clear();
      _tripStartTime = DateTime.now();

      if (currentLocation != null) {
        _routePoints.add(currentLocation);
      }

      // Start GPS tracking with variable timing
      _startVariableGPSTracking();

      notifyListeners();
      print(
          'TripTrackingService: Automatic trip started for vehicle: ${_currentVehicle!.make} ${_currentVehicle!.model}');
    } catch (e) {
      print('TripTrackingService: Error starting automatic trip: $e');
    }
  }

  Future<void> _endAutomaticTrip() async {
    if (_currentTrip == null) return;

    try {
      print('TripTrackingService: Ending automatic trip...');

      _stopGPSTracking();

      final currentLocation = _locationService.getCurrentGeoPoint();

      _currentTrip = _currentTrip!.copyWith(
        endTime: DateTime.now(),
        distance: _totalDistance,
        endLocation: currentLocation,
      );

      // Set up for confirmation dialog
      _pendingConfirmationTrip = _currentTrip;
      _pendingConfirmationVehicle = _currentVehicle;

      // Clear current trip
      _currentTrip = null;
      _currentVehicle = null;
      _tripStartTime = null;

      // Revert to power saving GPS mode
      _locationService.setHighPrecisionMode(false);

      notifyListeners();
      print('TripTrackingService: Automatic trip ended, pending confirmation');
    } catch (e) {
      print('TripTrackingService: Error ending automatic trip: $e');
    }
  }

  // New method matching the home screen expectation
  Future<void> startManualTrip(Vehicle vehicle) async {
    if (isTracking) {
      print('TripTrackingService: Cannot start manual trip - already tracking');
      return;
    }

    try {
      print(
          'TripTrackingService: Starting manual trip for vehicle: ${vehicle.make} ${vehicle.model}');

      _currentVehicle = vehicle;

      // Enable high precision GPS for trip tracking
      _locationService.setHighPrecisionMode(true);

      final currentLocation = _locationService.getCurrentGeoPoint();

      _currentTrip = Trip(
        id: '', // Will be set when saving to Firestore
        vehicleId: vehicle.id,
        startTime: DateTime.now(),
        endTime: null,
        distance: 0.0,
        purpose: TripPurpose.business, // Default to business
        memo: '',
        startLocation: currentLocation ?? GeoPoint(0, 0),
        endLocation: null,
        isManualEntry: false,
        deviceName: _deviceName,
      );

      _totalDistance = 0.0;
      _routePoints.clear();
      _tripStartTime = DateTime.now();

      if (currentLocation != null) {
        _routePoints.add(currentLocation);
      }

      // Start GPS tracking with variable timing
      _startVariableGPSTracking();

      notifyListeners();
      print('TripTrackingService: Manual trip started');
    } catch (e) {
      print('TripTrackingService: Error starting manual trip: $e');
    }
  }

  // New method matching the home screen expectation
  Future<void> endCurrentTrip() async {
    if (!isTracking) {
      print('TripTrackingService: Cannot stop trip - not currently tracking');
      return;
    }

    try {
      print('TripTrackingService: Stopping current trip...');

      _stopGPSTracking();

      final currentLocation = _locationService.getCurrentGeoPoint();

      _currentTrip = _currentTrip!.copyWith(
        endTime: DateTime.now(),
        distance: _totalDistance,
        endLocation: currentLocation,
      );

      // Set up for confirmation dialog
      _pendingConfirmationTrip = _currentTrip;
      _pendingConfirmationVehicle = _currentVehicle;

      // Clear current trip
      _currentTrip = null;
      _currentVehicle = null;
      _tripStartTime = null;

      // Revert to power saving GPS mode
      _locationService.setHighPrecisionMode(false);

      notifyListeners();
      print('TripTrackingService: Current trip ended, pending confirmation');
    } catch (e) {
      print('TripTrackingService: Error stopping current trip: $e');
    }
  }

  // New method matching the home screen expectation
  void discardPendingTrip() {
    print('TripTrackingService: Discarding pending trip');
    _pendingConfirmationTrip = null;
    _pendingConfirmationVehicle = null;

    // Revert to power saving GPS mode
    _locationService.setHighPrecisionMode(false);

    notifyListeners();
  }

  Future<void> manualStartTrip(Vehicle vehicle) async {
    if (isTracking) {
      print('TripTrackingService: Cannot start manual trip - already tracking');
      return;
    }

    try {
      print(
          'TripTrackingService: Starting manual trip for vehicle: ${vehicle.make} ${vehicle.model}');

      _currentVehicle = vehicle;

      // Enable high precision GPS for trip tracking
      _locationService.setHighPrecisionMode(true);

      final currentLocation = _locationService.getCurrentGeoPoint();

      _currentTrip = Trip(
        id: '', // Will be set by Firestore
        vehicleId: vehicle.id,
        startTime: DateTime.now(),
        endTime: null,
        distance: 0.0,
        purpose: TripPurpose.business, // Default to business
        memo: '',
        startLocation: currentLocation ?? GeoPoint(0, 0),
        endLocation: null,
        isManualEntry: false,
      );

      _totalDistance = 0.0;
      _routePoints.clear();
      _tripStartTime = DateTime.now();

      if (currentLocation != null) {
        _routePoints.add(currentLocation);
      }

      // Start GPS tracking with variable timing
      _startVariableGPSTracking();

      notifyListeners();
      print('TripTrackingService: Manual trip started');
    } catch (e) {
      print('TripTrackingService: Error starting manual trip: $e');
    }
  }

  Future<void> manualStopTrip() async {
    if (!isTracking) {
      print('TripTrackingService: Cannot stop trip - not currently tracking');
      return;
    }

    try {
      print('TripTrackingService: Stopping manual trip...');

      _stopGPSTracking();

      final currentLocation = _locationService.getCurrentGeoPoint();

      _currentTrip = _currentTrip!.copyWith(
        endTime: DateTime.now(),
        distance: _totalDistance,
        endLocation: currentLocation,
      );

      // Set up for confirmation dialog
      _pendingConfirmationTrip = _currentTrip;
      _pendingConfirmationVehicle = _currentVehicle;

      // Clear current trip
      _currentTrip = null;
      _currentVehicle = null;
      _tripStartTime = null;

      // Revert to power saving GPS mode
      _locationService.setHighPrecisionMode(false);

      notifyListeners();
      print('TripTrackingService: Manual trip stopped, pending confirmation');
    } catch (e) {
      print('TripTrackingService: Error stopping manual trip: $e');
    }
  }

  Future<void> pauseTrip() async {
    if (!isTracking || isPaused) {
      print(
          'TripTrackingService: Cannot pause - not tracking or already paused');
      return;
    }

    try {
      print('TripTrackingService: Pausing trip...');

      // Stop GPS tracking
      _stopGPSTracking();

      // Add pause period
      final pausePeriods = List<PausePeriod>.from(_currentTrip!.pausePeriods);
      pausePeriods.add(PausePeriod(pauseTime: DateTime.now()));

      _currentTrip = _currentTrip!.copyWith(pausePeriods: pausePeriods);

      notifyListeners();
      print('TripTrackingService: Trip paused');
    } catch (e) {
      print('TripTrackingService: Error pausing trip: $e');
    }
  }

  Future<void> resumeTrip() async {
    if (!isTracking || !isPaused) {
      print('TripTrackingService: Cannot resume - not tracking or not paused');
      return;
    }

    try {
      print('TripTrackingService: Resuming trip...');

      // Update the last pause period with resume time
      final pausePeriods = List<PausePeriod>.from(_currentTrip!.pausePeriods);
      final lastPause = pausePeriods.last;
      pausePeriods[pausePeriods.length - 1] = PausePeriod(
        pauseTime: lastPause.pauseTime,
        resumeTime: DateTime.now(),
      );

      _currentTrip = _currentTrip!.copyWith(pausePeriods: pausePeriods);

      // Restart GPS tracking
      _startVariableGPSTracking();

      notifyListeners();
      print('TripTrackingService: Trip resumed');
    } catch (e) {
      print('TripTrackingService: Error resuming trip: $e');
    }
  }

  void _startVariableGPSTracking() async {
    _trackingTimer?.cancel();

    // Check if debug mode is enabled
    final isDebugMode = await SettingsUtils.getDebugTrackingEnabled();

    if (isDebugMode) {
      // Debug mode: update every 2 seconds
      _trackingTimer = Timer.periodic(
          const Duration(seconds: 2), (_) => _updateGPSTracking());
      print(
          'TripTrackingService: Debug GPS tracking started (2-second intervals)');
    } else {
      // Normal mode: start with initial 5-second interval
      _scheduleNextUpdate(const Duration(seconds: 5));
      print('TripTrackingService: Variable GPS tracking started');
    }
  }

  void _scheduleNextUpdate(Duration interval) {
    _trackingTimer?.cancel();
    _trackingTimer = Timer(interval, () async {
      _updateGPSTracking();

      // Check if debug mode was enabled during the trip
      final isDebugMode = await SettingsUtils.getDebugTrackingEnabled();

      if (isDebugMode) {
        // Switch to debug mode
        _trackingTimer?.cancel();
        _trackingTimer = Timer.periodic(
            const Duration(seconds: 2), (_) => _updateGPSTracking());
        print('TripTrackingService: Switched to debug mode during trip');
        return;
      }

      // Calculate next interval based on elapsed time (normal mode)
      if (_tripStartTime != null) {
        final elapsed = DateTime.now().difference(_tripStartTime!);
        Duration nextInterval;

        if (elapsed < const Duration(minutes: 2)) {
          // First 2 minutes: every 5 seconds
          nextInterval = const Duration(seconds: 5);
        } else if (elapsed < const Duration(minutes: 10)) {
          // Next 8 minutes: every 30 seconds
          nextInterval = const Duration(seconds: 30);
        } else {
          // After 10 minutes: every 2 minutes
          nextInterval = const Duration(minutes: 2);
        }

        _scheduleNextUpdate(nextInterval);
      }
    });
  }

  void _startGPSTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(
        const Duration(seconds: 10), (_) => _updateGPSTracking());
    print('TripTrackingService: GPS tracking started');
  }

  void _stopGPSTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    print('TripTrackingService: GPS tracking stopped');
  }

  Future<void> _updateGPSTracking() async {
    if (!isTracking || isPaused) return;

    try {
      final currentLocation = _locationService.getCurrentGeoPoint();
      if (currentLocation == null) return;

      if (_routePoints.isNotEmpty) {
        final lastPoint = _routePoints.last;
        final distance =
            _locationService.calculateDistance(lastPoint, currentLocation);

        // Only add point if we've moved more than 25 feet (7.6 meters)
        if (distance > 7.6) {
          _routePoints.add(currentLocation);

          // Convert meters to miles and add to total distance
          _totalDistance += distance * 0.000621371;

          notifyListeners();
          print(
              'TripTrackingService: GPS update - Distance: ${_totalDistance.toStringAsFixed(2)} miles, Points: ${_routePoints.length}');
        }
      } else {
        _routePoints.add(currentLocation);
      }
    } catch (e) {
      print('TripTrackingService: Error updating GPS tracking: $e');
    }
  }

  Future<void> confirmTrip({
    required double distance,
    required TripPurpose purpose,
    String? memo,
  }) async {
    if (_pendingConfirmationTrip == null) return;

    try {
      print('TripTrackingService: Confirming trip...');

      final confirmedTrip = _pendingConfirmationTrip!.copyWith(
        distance: distance,
        purpose: purpose,
        memo: memo ?? _pendingConfirmationTrip!.memo,
      );

      await _tripProvider.startTrip(confirmedTrip);

      // Clear pending confirmation
      _pendingConfirmationTrip = null;
      _pendingConfirmationVehicle = null;

      notifyListeners();
      print('TripTrackingService: Trip confirmed and saved');
    } catch (e) {
      print('TripTrackingService: Error confirming trip: $e');
    }
  }

  void cancelPendingTrip() {
    print('TripTrackingService: Canceling pending trip');
    _pendingConfirmationTrip = null;
    _pendingConfirmationVehicle = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _activitySubscription?.cancel();
    super.dispose();
  }
}
