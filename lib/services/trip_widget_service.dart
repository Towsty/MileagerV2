import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'trip_tracking_service.dart';
import '../providers/vehicle_provider.dart';

class TripWidgetService {
  static const String _androidProviderName = 'TripWidgetProvider';
  static const String _widgetName = 'trip_widget';

  // Widget data keys
  static const String _tripStatusKey = 'trip_status';
  static const String _tripDistanceKey = 'trip_distance';
  static const String _tripDurationKey = 'trip_duration';
  static const String _vehicleNameKey = 'vehicle_name';
  static const String _isPausedKey = 'is_paused';

  // Action keys for button clicks
  static const String _startTripAction = 'start_trip';
  static const String _stopTripAction = 'stop_trip';
  static const String _pauseTripAction = 'pause_trip';
  static const String _resumeTripAction = 'resume_trip';

  late StreamSubscription _tripSubscription;
  late StreamSubscription _vehicleSubscription;
  TripTrackingService? _tripService;
  VehicleProvider? _vehicleProvider;

  Future<void> initialize(BuildContext context) async {
    _tripService = Provider.of<TripTrackingService>(context, listen: false);
    _vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);

    // Initialize the home widget
    await HomeWidget.setAppGroupId('group.com.echoseofnumenor.mileager');

    // Set up listeners for trip and vehicle changes
    _setupListeners();

    // Set up widget action callbacks
    await _setupWidgetCallbacks();

    // Initial widget update
    await updateWidget();
  }

  void _setupListeners() {
    // Listen to trip tracking changes
    _tripSubscription = _tripService!.addListener(() {
      updateWidget();
    }) as StreamSubscription;

    // Listen to vehicle changes
    _vehicleSubscription = _vehicleProvider!.addListener(() {
      updateWidget();
    }) as StreamSubscription;
  }

  Future<void> _setupWidgetCallbacks() async {
    // Register widget update callback
    HomeWidget.widgetClicked.listen((Uri? uri) async {
      if (uri != null) {
        final action = uri.queryParameters['action'];
        await _handleWidgetAction(action);
      }
    });
  }

  Future<void> _handleWidgetAction(String? action) async {
    if (_tripService == null || _vehicleProvider == null) return;

    switch (action) {
      case _startTripAction:
        if (!_tripService!.isTracking) {
          final vehicles = _vehicleProvider!.vehicles;
          if (vehicles.isNotEmpty) {
            await _tripService!.startManualTrip(vehicles.first);
          }
        }
        break;

      case _stopTripAction:
        if (_tripService!.isTracking) {
          await _tripService!.manualStopTrip();
        }
        break;

      case _pauseTripAction:
        if (_tripService!.isTracking && !_tripService!.isPaused) {
          await _tripService!.pauseTrip();
        }
        break;

      case _resumeTripAction:
        if (_tripService!.isTracking && _tripService!.isPaused) {
          await _tripService!.resumeTrip();
        }
        break;
    }

    // Update widget after action
    await updateWidget();
  }

  Future<void> updateWidget() async {
    try {
      if (_tripService == null || _vehicleProvider == null) return;

      String tripStatus;
      String tripDistance = '0.0 mi';
      String tripDuration = '00:00';
      String vehicleName = 'No Vehicle';
      bool isPaused = false;

      final vehicles = _vehicleProvider!.vehicles;
      if (vehicles.isNotEmpty) {
        final firstVehicle = vehicles.first;
        vehicleName = (firstVehicle.nickname?.isNotEmpty ?? false)
            ? firstVehicle.nickname!
            : '${firstVehicle.make} ${firstVehicle.model}';
      }

      if (_tripService!.isTracking) {
        isPaused = _tripService!.isPaused;
        tripStatus = isPaused ? 'Paused' : 'Active';

        // Get current trip data
        final currentTrip = _tripService!.currentTrip;
        if (currentTrip != null) {
          tripDistance = '${_tripService!.totalDistance.toStringAsFixed(2)} mi';

          // Calculate active duration (excluding paused time)
          final totalDuration =
              DateTime.now().difference(currentTrip.startTime);
          final pausedDuration = currentTrip.totalPausedDuration;
          final activeDuration = totalDuration - pausedDuration;

          final hours = activeDuration.inHours;
          final minutes = activeDuration.inMinutes % 60;
          tripDuration =
              '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
        }
      } else {
        tripStatus = 'No Active Trip';
      }

      // Update widget data
      await HomeWidget.saveWidgetData<String>(_tripStatusKey, tripStatus);
      await HomeWidget.saveWidgetData<String>(_tripDistanceKey, tripDistance);
      await HomeWidget.saveWidgetData<String>(_tripDurationKey, tripDuration);
      await HomeWidget.saveWidgetData<String>(_vehicleNameKey, vehicleName);
      await HomeWidget.saveWidgetData<bool>(_isPausedKey, isPaused);

      // Update the widget
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _androidProviderName,
      );
    } catch (e) {
      print('Error updating trip widget: $e');
    }
  }

  void dispose() {
    _tripSubscription.cancel();
    _vehicleSubscription.cancel();
  }
}
