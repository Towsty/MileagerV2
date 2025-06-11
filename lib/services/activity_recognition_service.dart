import 'dart:async';
import 'package:flutter/foundation.dart';

class ActivityRecognitionService with ChangeNotifier {
  bool _isInitialized = false;
  bool _isDriving = false;
  DateTime? _drivingStartTime;
  DateTime? _drivingEndTime;
  String _lastActivity = 'Still';
  bool _debugMode = true;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isDriving => _isDriving;
  DateTime? get drivingStartTime => _drivingStartTime;
  DateTime? get drivingEndTime => _drivingEndTime;
  bool get debugMode => _debugMode;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      print('Activity Recognition Service: Initializing...');

      // Perform any necessary setup here
      await Future.delayed(const Duration(
          milliseconds: 100)); // Small delay to prevent race conditions

      _isInitialized = true;
      _isDriving = false;
      _lastActivity = 'Still';

      print('Activity Recognition Service: Initialized successfully');
      // Only notify after complete initialization
      notifyListeners();
      return true;
    } catch (e) {
      print('Error initializing activity recognition: $e');
      return false;
    }
  }

  void toggleDebugMode() {
    if (!_isInitialized) return;
    _debugMode = !_debugMode;
    print(
        'Activity Recognition: Debug mode ${_debugMode ? "enabled" : "disabled"}');
    notifyListeners();
  }

  // Debug methods for testing
  void debugStartDriving() {
    if (!_isDriving) {
      print('🔧 DEBUG: Simulating driving start');
      _isDriving = true;
      _drivingStartTime = DateTime.now();
      _drivingEndTime = null;
      _lastActivity = 'In Vehicle';
      print('🚗 Driving started at $_drivingStartTime');
      notifyListeners();
    }
  }

  void debugStopDriving() {
    if (_isDriving) {
      print('🔧 DEBUG: Simulating driving stop');
      _isDriving = false;
      _drivingEndTime = DateTime.now();
      _lastActivity = 'Still';
      print('🛑 Driving ended at $_drivingEndTime');
      notifyListeners();
    }
  }

  String get activityDescription {
    return _lastActivity;
  }

  String get statusText {
    if (!_isInitialized) return 'Not initialized';
    if (_isDriving) return 'Driving detected (DEBUG)';
    return 'Not driving';
  }

  // Simulate automatic activity detection (could be enhanced later)
  void _simulateActivityDetection() {
    // This could be enhanced with real sensors, accelerometer data, etc.
    // For now, it's purely manual for testing
  }

  @override
  void dispose() {
    super.dispose();
  }
}
