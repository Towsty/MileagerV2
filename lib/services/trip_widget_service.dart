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

  TripTrackingService? _tripService;
  VehicleProvider? _vehicleProvider;

  Future<void> initialize(BuildContext context) async {
    try {
      print('Initializing trip widget service...');

      _tripService = Provider.of<TripTrackingService>(context, listen: false);
      _vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);

      print(
          'Providers initialized: TripService=${_tripService != null}, VehicleProvider=${_vehicleProvider != null}');

      // Initialize the home widget
      await HomeWidget.setAppGroupId('group.com.echoseofnumenor.mileager');
      print('HomeWidget app group ID set');

      // Initial widget update
      await updateWidget();

      print('Trip widget service initialized successfully');
    } catch (e, stackTrace) {
      print('Error initializing trip widget service: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> updateWidget() async {
    try {
      print('Updating trip widget...');

      if (_tripService == null || _vehicleProvider == null) {
        print(
            'Widget update skipped: TripService=${_tripService != null}, VehicleProvider=${_vehicleProvider != null}');
        return;
      }

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
          tripDistance = '${_tripService!.totalDistance.toStringAsFixed(1)} mi';

          // Calculate duration
          final now = DateTime.now();
          final duration = now.difference(currentTrip.startTime);
          final hours = duration.inHours;
          final minutes = duration.inMinutes % 60;

          if (hours > 0) {
            tripDuration = '${hours}h ${minutes}m';
          } else {
            tripDuration = '${minutes}m';
          }
        }
      } else {
        tripStatus = 'Not Active';
      }

      print(
          'Widget data: Status=$tripStatus, Distance=$tripDistance, Duration=$tripDuration, Vehicle=$vehicleName');

      // Update widget data
      await HomeWidget.saveWidgetData<String>(_tripStatusKey, tripStatus);
      await HomeWidget.saveWidgetData<String>(_tripDistanceKey, tripDistance);
      await HomeWidget.saveWidgetData<String>(_tripDurationKey, tripDuration);
      await HomeWidget.saveWidgetData<String>(_vehicleNameKey, vehicleName);
      await HomeWidget.saveWidgetData<bool>(_isPausedKey, isPaused);
      await HomeWidget.saveWidgetData<bool>(
          'is_tracking', _tripService!.isTracking);

      print('Widget data saved, triggering update...');

      // Trigger widget update
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _androidProviderName,
      );

      print('Trip widget updated successfully');
    } catch (e, stackTrace) {
      print('Error updating trip widget: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void dispose() {
    // Clean up resources
  }
}
