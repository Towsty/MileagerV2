import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../services/trip_tracking_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

enum AutoTrackingTrigger {
  androidAuto,
  bluetooth,
  manual,
  none,
}

class AutoTrackingService {
  static final AutoTrackingService _instance = AutoTrackingService._internal();
  factory AutoTrackingService() => _instance;
  AutoTrackingService._internal();

  // Platform channels for Android Auto
  static const _androidAutoChannel = MethodChannel('com.mileager/android_auto');
  static const _androidAutoEventChannel =
      EventChannel('com.mileager/android_auto_events');

  // Services
  late VehicleProvider _vehicleProvider;
  late TripTrackingService _tripTrackingService;
  late LocationService _locationService;

  // State
  bool _isInitialized = false;
  bool _isAndroidAutoConnected = false;
  String? _currentBluetoothDevice;
  Vehicle? _currentVehicle;
  AutoTrackingTrigger _currentTrigger = AutoTrackingTrigger.none;

  // Streams
  StreamSubscription? _androidAutoSubscription;
  StreamSubscription? _bluetoothSubscription;
  StreamSubscription? _locationSubscription;

  // Vehicle associations
  Map<String, String> _androidAutoToVehicle = {};
  Map<String, String> _bluetoothToVehicle = {};

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isAndroidAutoConnected => _isAndroidAutoConnected;
  AutoTrackingTrigger get currentTrigger => _currentTrigger;
  String? get currentBluetoothDevice => _currentBluetoothDevice;
  Vehicle? get currentVehicle => _currentVehicle;

  /// Get current tracking status for UI display
  String get trackingStatus {
    switch (_currentTrigger) {
      case AutoTrackingTrigger.androidAuto:
        return 'Android Auto';
      case AutoTrackingTrigger.bluetooth:
        return 'Bluetooth (${_currentBluetoothDevice ?? 'Unknown'})';
      case AutoTrackingTrigger.manual:
        return 'Manual';
      case AutoTrackingTrigger.none:
        return 'None';
    }
  }

  /// Get current vehicle name for UI display
  String get currentVehicleName {
    if (_currentVehicle != null) {
      return '${_currentVehicle!.make} ${_currentVehicle!.model}';
    }
    return 'No Vehicle';
  }

  /// Initialize the auto tracking service
  Future<void> initialize({
    required VehicleProvider vehicleProvider,
    required TripTrackingService tripTrackingService,
    required LocationService locationService,
  }) async {
    if (_isInitialized) {
      print('AutoTrackingService: Already initialized, skipping');
      return;
    }

    print('AutoTrackingService: Starting initialization...');

    _vehicleProvider = vehicleProvider;
    _tripTrackingService = tripTrackingService;
    _locationService = locationService;

    print('AutoTrackingService: Loading stored associations...');
    await _loadStoredAssociations();

    print('AutoTrackingService: Initializing Android Auto detection...');
    await _initializeAndroidAuto();

    print('AutoTrackingService: Initializing Bluetooth detection...');
    await _initializeBluetooth();

    _isInitialized = true;
    print(
        'AutoTrackingService: Initialized with hybrid tracking (Auto → Bluetooth → Manual)');
    print(
        'AutoTrackingService: Android Auto associations: ${_androidAutoToVehicle.length}');
    print(
        'AutoTrackingService: Bluetooth associations: ${_bluetoothToVehicle.length}');
  }

  /// Dispose of the service
  void dispose() {
    _androidAutoSubscription?.cancel();
    _bluetoothSubscription?.cancel();
    _locationSubscription?.cancel();
    _isInitialized = false;
  }

  // ==================== ANDROID AUTO DETECTION ====================

  Future<void> _initializeAndroidAuto() async {
    try {
      print('AutoTrackingService: 🚗 Initializing Android Auto detection...');

      // Test platform channel connectivity first
      print('AutoTrackingService: 📞 Testing platform channel connectivity...');

      try {
        // Check current Android Auto status
        _isAndroidAutoConnected =
            await _androidAutoChannel.invokeMethod('isAndroidAutoConnected') ??
                false;
        print(
            'AutoTrackingService: ✅ Platform channel connected - Initial Android Auto status: $_isAndroidAutoConnected');
      } catch (e) {
        print('AutoTrackingService: ❌ Platform channel test failed: $e');
        throw e;
      }

      // Listen for Android Auto connection changes
      print(
          'AutoTrackingService: 📡 Setting up Android Auto event listener...');
      _androidAutoSubscription = _androidAutoEventChannel
          .receiveBroadcastStream()
          .listen((dynamic event) {
        print('AutoTrackingService: 🔄 Received Android Auto event: $event');
        final isConnected = event as bool;
        _handleAndroidAutoConnectionChange(isConnected);
      }, onError: (error) {
        print(
            'AutoTrackingService: ⚠️ Android Auto event stream error: $error');
      });

      // Perform initial check
      await _checkAndroidAutoDevices();

      print(
          'AutoTrackingService: ✅ Android Auto monitoring initialized (current: $_isAndroidAutoConnected, associations: ${_androidAutoToVehicle.length})');
    } catch (e, stackTrace) {
      print('AutoTrackingService: ❌ Android Auto initialization failed - $e');
      print('AutoTrackingService: Stack trace: $stackTrace');
    }
  }

  /// Active polling method for Android Auto detection
  Future<void> _checkAndroidAutoDevices() async {
    try {
      print(
          'AutoTrackingService: 🔍 Checking Android Auto status (active polling)...');

      // Call platform channel to check current status
      bool isCurrentlyConnected = false;

      try {
        isCurrentlyConnected =
            await _androidAutoChannel.invokeMethod('isAndroidAutoConnected') ??
                false;
        print(
            'AutoTrackingService: 📊 Platform channel reports Android Auto: $isCurrentlyConnected');
      } catch (e) {
        print('AutoTrackingService: ⚠️ Platform channel call failed: $e');
        // Platform channel might not be working, but continue
      }

      // Check if state changed
      if (isCurrentlyConnected != _isAndroidAutoConnected) {
        print(
            'AutoTrackingService: 🔄 Android Auto state changed: $_isAndroidAutoConnected → $isCurrentlyConnected');
        _isAndroidAutoConnected = isCurrentlyConnected;
        await _handleAndroidAutoConnectionChange(isCurrentlyConnected);
      } else if (isCurrentlyConnected && _androidAutoToVehicle.isNotEmpty) {
        print(
            'AutoTrackingService: ✅ Android Auto still connected and has ${_androidAutoToVehicle.length} associations');
      } else if (isCurrentlyConnected) {
        print(
            'AutoTrackingService: ⚠️ Android Auto connected but no vehicle associations found');
      } else {
        print('AutoTrackingService: ⭕ Android Auto not connected');
      }
    } catch (e, stackTrace) {
      print('AutoTrackingService: ❌ Error checking Android Auto devices: $e');
      print('AutoTrackingService: Stack trace: $stackTrace');
    }
  }

  Future<void> _handleAndroidAutoConnectionChange(bool isConnected) async {
    print(
        'AutoTrackingService: Android Auto ${isConnected ? 'connected' : 'disconnected'}');

    _isAndroidAutoConnected = isConnected;

    if (isConnected) {
      await _handleConnectionDetected(
          AutoTrackingTrigger.androidAuto, 'android_auto_session');
    } else {
      await _handleDisconnectionDetected(AutoTrackingTrigger.androidAuto);
    }
  }

  // ==================== BLUETOOTH DETECTION ====================

  Future<void> _initializeBluetooth() async {
    try {
      print('AutoTrackingService: Initializing Bluetooth detection...');

      // Check if Bluetooth is supported
      if (await FlutterBluePlus.isSupported == false) {
        print('AutoTrackingService: Bluetooth not supported on this device');
        return;
      }

      print('AutoTrackingService: Setting up Bluetooth monitoring...');

      // Request location permissions first (required for Bluetooth scanning on Android)
      print(
          'AutoTrackingService: Requesting location permissions for Bluetooth...');
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.deniedForever) {
          print(
              'AutoTrackingService: Location permission denied forever - Bluetooth scanning will be limited');
        } else if (permission == LocationPermission.denied) {
          print(
              'AutoTrackingService: Location permission denied - Bluetooth scanning will be limited');
        } else {
          print(
              'AutoTrackingService: Location permission granted: $permission');
        }
      } catch (e) {
        print('AutoTrackingService: Location permission request error: $e');
      }

      // Request Bluetooth permissions
      print('AutoTrackingService: Requesting Bluetooth permissions...');
      try {
        await FlutterBluePlus.turnOn();
        print('AutoTrackingService: Bluetooth permissions granted');
      } catch (e) {
        print('AutoTrackingService: Bluetooth permission error: $e');
        // Continue anyway, might still work
      }

      // Listen to adapter state changes
      FlutterBluePlus.adapterState.listen((state) {
        print('AutoTrackingService: Bluetooth adapter state changed: $state');
        if (state == BluetoothAdapterState.on) {
          _checkBluetoothDevices();
        }
      });

      // Check current state
      final currentState = await FlutterBluePlus.adapterState.first;
      print(
          'AutoTrackingService: Current Bluetooth adapter state: $currentState');

      if (currentState == BluetoothAdapterState.on) {
        _checkBluetoothDevices();
      }

      // Set up periodic checking since FlutterBluePlus doesn't have global connection events
      Timer.periodic(const Duration(seconds: 10), (timer) {
        if (_isInitialized) {
          _checkBluetoothDevices();
          _checkAndroidAutoDevices(); // Add active Android Auto polling
        } else {
          timer.cancel();
        }
      });

      print('AutoTrackingService: Bluetooth monitoring initialized');
    } catch (e, stackTrace) {
      print('AutoTrackingService: Bluetooth initialization error: $e');
      print('AutoTrackingService: Stack trace: $stackTrace');
    }
  }

  Future<void> _checkBluetoothDevices() async {
    try {
      print('AutoTrackingService: Checking Bluetooth connected devices...');

      // Check adapter state first
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        print(
            'AutoTrackingService: Bluetooth adapter is not on: $adapterState');
        return;
      }

      // If we have no associations, skip the intensive checking
      if (_bluetoothToVehicle.isEmpty) {
        print(
            'AutoTrackingService: No Bluetooth associations configured, skipping scan');
        return;
      }

      print(
          'AutoTrackingService: Checking for ${_bluetoothToVehicle.length} associated devices: ${_bluetoothToVehicle.keys.join(', ')}');

      // Remember previous state
      final previousTrigger = _currentTrigger;
      final previousDevice = _currentBluetoothDevice;
      final previousVehicle = _currentVehicle;

      // Start a quick scan to get fresh device data
      bool foundAssociatedDevice = false;
      String? detectedDeviceName;
      Vehicle? detectedVehicle;

      try {
        print(
            'AutoTrackingService: Starting targeted scan for associated devices...');

        // Start scan with shorter timeout since we're looking for specific devices
        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 3),
          androidUsesFineLocation: true,
        );

        // Wait for scan results
        await Future.delayed(const Duration(seconds: 2));

        // Check all scan results for our associated devices
        final scanResults = FlutterBluePlus.lastScanResults;
        print(
            'AutoTrackingService: Checking ${scanResults.length} scan results for associated devices');

        for (final result in scanResults) {
          // Get device name from multiple sources
          String deviceName = result.device.platformName;
          if (deviceName.isEmpty &&
              result.advertisementData.advName.isNotEmpty) {
            deviceName = result.advertisementData.advName;
          }
          if (deviceName.isEmpty &&
              result.advertisementData.localName.isNotEmpty) {
            deviceName = result.advertisementData.localName;
          }

          // Check if this device matches any of our associations
          for (final entry in _bluetoothToVehicle.entries) {
            final associatedDeviceName = entry.key;
            final vehicleId = entry.value;

            if (deviceName == associatedDeviceName) {
              print(
                  'AutoTrackingService: Found associated device in scan: $deviceName');

              // Check if device is connectable/connected by checking RSSI and other indicators
              final rssi = result.rssi;
              final isNearby = rssi > -80; // Device is nearby (strong signal)

              // For headphones and audio devices, if they're advertising and nearby, they're likely connected
              final isLikelyConnected = isNearby &&
                  (deviceName.toLowerCase().contains('airpods') ||
                      deviceName.toLowerCase().contains('buds') ||
                      deviceName.toLowerCase().contains('headphone') ||
                      deviceName.toLowerCase().contains('shokz') ||
                      deviceName.toLowerCase().contains('beats') ||
                      deviceName.toLowerCase().contains('sony') ||
                      deviceName.toLowerCase().contains('bose'));

              print(
                  'AutoTrackingService: Device $deviceName - RSSI: $rssi, Nearby: $isNearby, Likely Connected: $isLikelyConnected');

              if (isLikelyConnected) {
                print(
                    'AutoTrackingService: Detected connected associated device: $deviceName for vehicle $vehicleId');
                foundAssociatedDevice = true;
                detectedDeviceName = deviceName;

                try {
                  detectedVehicle = _vehicleProvider.vehicles.firstWhere(
                    (v) => v.id == vehicleId,
                  );
                  print(
                      'AutoTrackingService: Found vehicle ${detectedVehicle.make} ${detectedVehicle.model}');
                } catch (e) {
                  print(
                      'AutoTrackingService: Could not find vehicle with ID $vehicleId');
                }
                break;
              }
            }
          }

          if (foundAssociatedDevice) break;
        }

        await FlutterBluePlus.stopScan();
      } catch (e) {
        print('AutoTrackingService: Error during targeted scan: $e');
        await FlutterBluePlus.stopScan();
      }

      // Also check FlutterBluePlus connected devices as backup
      try {
        final flutterConnectedDevices = FlutterBluePlus.connectedDevices;
        if (flutterConnectedDevices.isNotEmpty && !foundAssociatedDevice) {
          print(
              'AutoTrackingService: FlutterBluePlus found ${flutterConnectedDevices.length} connected devices');

          for (final device in flutterConnectedDevices) {
            final name = device.platformName.isNotEmpty
                ? device.platformName
                : device.remoteId.str;
            print('AutoTrackingService: Flutter-connected device: $name');

            // Check if this matches any association
            if (_bluetoothToVehicle.containsKey(name)) {
              print(
                  'AutoTrackingService: Found Flutter-connected associated device: $name');
              foundAssociatedDevice = true;
              detectedDeviceName = name;

              try {
                detectedVehicle = _vehicleProvider.vehicles.firstWhere(
                  (v) => v.id == _bluetoothToVehicle[name]!,
                );
              } catch (e) {
                print(
                    'AutoTrackingService: Could not find vehicle for device $name');
              }
              break;
            }
          }
        }
      } catch (e) {
        print(
            'AutoTrackingService: Error checking Flutter connected devices: $e');
      }

      // Handle state changes and trigger trip management
      if (foundAssociatedDevice && detectedVehicle != null) {
        // Device is connected
        if (previousTrigger != AutoTrackingTrigger.bluetooth ||
            previousDevice != detectedDeviceName) {
          // New connection detected
          print(
              'AutoTrackingService: NEW CONNECTION - Device: $detectedDeviceName, Vehicle: ${detectedVehicle.make} ${detectedVehicle.model}');

          _currentTrigger = AutoTrackingTrigger.bluetooth;
          _currentBluetoothDevice = detectedDeviceName;
          _currentVehicle = detectedVehicle;

          // Start automatic trip
          await _startAutomaticTrip(
              detectedVehicle, AutoTrackingTrigger.bluetooth);
        } else {
          // Same device still connected - just update status
          _currentTrigger = AutoTrackingTrigger.bluetooth;
          _currentBluetoothDevice = detectedDeviceName;
          _currentVehicle = detectedVehicle;
          print(
              'AutoTrackingService: Device still connected - Device: $detectedDeviceName, Vehicle: ${detectedVehicle.make} ${detectedVehicle.model}');
        }
      } else {
        // No associated device found
        if (previousTrigger == AutoTrackingTrigger.bluetooth) {
          // Device was connected but now disconnected
          print(
              'AutoTrackingService: DISCONNECTION DETECTED - Previous device: $previousDevice');
          print('AutoTrackingService: Ending automatic trip immediately...');

          // End automatic trip BEFORE clearing the state (so _endAutomaticTrip can access current vehicle)
          if (_tripTrackingService.isTracking && _currentVehicle != null) {
            await _tripTrackingService.endCurrentTrip();
            print(
                'AutoTrackingService: Ended automatic trip for ${_currentVehicle!.make} ${_currentVehicle!.model}');
          }

          // Clear state after ending trip
          _currentTrigger = AutoTrackingTrigger.none;
          _currentBluetoothDevice = null;
          _currentVehicle = null;

          print('AutoTrackingService: Trip ended and state cleared');
        } else {
          // No change - still no device
          print('AutoTrackingService: No associated devices detected');
        }
      }
    } catch (e, stackTrace) {
      print('AutoTrackingService: Error checking Bluetooth devices: $e');
      print('AutoTrackingService: Stack trace: $stackTrace');
    }
  }

  // ==================== CONNECTION HANDLING ====================

  Future<void> _handleConnectionDetected(
      AutoTrackingTrigger trigger, String deviceId) async {
    print(
        'AutoTrackingService: Connection detected via ${trigger.name} - $deviceId');

    // Find associated vehicle
    Vehicle? vehicle = await _findVehicleForDevice(trigger, deviceId);

    if (vehicle != null) {
      // Start automatic tracking
      await _startAutomaticTrip(vehicle, trigger);
    } else {
      // No vehicle association found - prompt user
      await _promptForVehicleAssociation(trigger, deviceId);
    }
  }

  Future<void> _handleDisconnectionDetected(AutoTrackingTrigger trigger) async {
    print('AutoTrackingService: Disconnection detected via ${trigger.name}');

    // Only handle disconnection if this trigger started the current trip
    if (_currentTrigger == trigger && _currentVehicle != null) {
      await _endAutomaticTrip();
    }
  }

  Future<Vehicle?> _findVehicleForDevice(
      AutoTrackingTrigger trigger, String deviceId) async {
    String? vehicleId;

    switch (trigger) {
      case AutoTrackingTrigger.androidAuto:
        vehicleId = _androidAutoToVehicle[deviceId];
        break;
      case AutoTrackingTrigger.bluetooth:
        vehicleId = _bluetoothToVehicle[deviceId];
        break;
      case AutoTrackingTrigger.manual:
      case AutoTrackingTrigger.none:
        return null;
    }

    if (vehicleId != null) {
      try {
        return _vehicleProvider.vehicles.firstWhere(
          (v) => v.id == vehicleId,
        );
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  // ==================== TRIP MANAGEMENT ====================

  Future<void> _startAutomaticTrip(
      Vehicle vehicle, AutoTrackingTrigger trigger) async {
    try {
      // Check if a trip is already active
      if (_tripTrackingService.isTracking) {
        print(
            'AutoTrackingService: Trip already active, not starting new trip');
        return;
      }

      _currentVehicle = vehicle;
      _currentTrigger = trigger;

      // Start the trip
      await _tripTrackingService.manualStartTrip(vehicle);

      print(
          'AutoTrackingService: Started automatic trip for ${vehicle.make} ${vehicle.model} via ${trigger.name}');

      // Store this successful association for future use
      await _storeSuccessfulAssociation(trigger, vehicle);
    } catch (e) {
      print('AutoTrackingService: Failed to start automatic trip - $e');
      _currentVehicle = null;
      _currentTrigger = AutoTrackingTrigger.none;
    }
  }

  Future<void> _endAutomaticTrip() async {
    try {
      if (_tripTrackingService.isTracking && _currentVehicle != null) {
        await _tripTrackingService.endCurrentTrip();
        print(
            'AutoTrackingService: Ended automatic trip for ${_currentVehicle!.make} ${_currentVehicle!.model}');
      }
    } catch (e) {
      print('AutoTrackingService: Failed to end automatic trip - $e');
    } finally {
      _currentVehicle = null;
      _currentTrigger = AutoTrackingTrigger.none;
    }
  }

  // ==================== VEHICLE ASSOCIATION ====================

  Future<void> _promptForVehicleAssociation(
      AutoTrackingTrigger trigger, String deviceId) async {
    // This will be called from the UI layer to show a dialog
    print(
        'AutoTrackingService: Need vehicle association for ${trigger.name} device: $deviceId');

    // For now, we'll use the first available vehicle as a fallback
    // In the UI implementation, this should show a selection dialog
    if (_vehicleProvider.vehicles.isNotEmpty) {
      final firstVehicle = _vehicleProvider.vehicles.first;
      await associateDeviceWithVehicle(trigger, deviceId, firstVehicle.id);
      await _startAutomaticTrip(firstVehicle, trigger);
    }
  }

  Future<void> associateDeviceWithVehicle(
      AutoTrackingTrigger trigger, String deviceId, String vehicleId) async {
    switch (trigger) {
      case AutoTrackingTrigger.androidAuto:
        _androidAutoToVehicle[deviceId] = vehicleId;
        break;
      case AutoTrackingTrigger.bluetooth:
        _bluetoothToVehicle[deviceId] = vehicleId;
        break;
      case AutoTrackingTrigger.manual:
      case AutoTrackingTrigger.none:
        break;
    }

    await _saveAssociations();
    print(
        'AutoTrackingService: Associated ${trigger.name} device $deviceId with vehicle $vehicleId');
  }

  Future<void> _storeSuccessfulAssociation(
      AutoTrackingTrigger trigger, Vehicle vehicle) async {
    // Store the association for future automatic detection
    switch (trigger) {
      case AutoTrackingTrigger.androidAuto:
        _androidAutoToVehicle['android_auto_session'] = vehicle.id;
        break;
      case AutoTrackingTrigger.bluetooth:
        if (_currentBluetoothDevice != null) {
          _bluetoothToVehicle[_currentBluetoothDevice!] = vehicle.id;
        }
        break;
      case AutoTrackingTrigger.manual:
      case AutoTrackingTrigger.none:
        break;
    }

    await _saveAssociations();
  }

  // ==================== PERSISTENCE ====================

  Future<void> _loadStoredAssociations() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Android Auto associations
      final autoAssociations =
          prefs.getStringList('android_auto_associations') ?? [];
      for (final association in autoAssociations) {
        final parts = association.split('|');
        if (parts.length == 2) {
          _androidAutoToVehicle[parts[0]] = parts[1];
        }
      }

      // Load Bluetooth associations
      final bluetoothAssociations =
          prefs.getStringList('bluetooth_associations') ?? [];
      for (final association in bluetoothAssociations) {
        final parts = association.split('|');
        if (parts.length == 2) {
          _bluetoothToVehicle[parts[0]] = parts[1];
        }
      }

      print(
          'AutoTrackingService: Loaded ${_androidAutoToVehicle.length} Android Auto and ${_bluetoothToVehicle.length} Bluetooth associations');
    } catch (e) {
      print('AutoTrackingService: Failed to load associations - $e');
    }
  }

  Future<void> _saveAssociations() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save Android Auto associations
      final autoAssociations = _androidAutoToVehicle.entries
          .map((e) => '${e.key}|${e.value}')
          .toList();
      await prefs.setStringList('android_auto_associations', autoAssociations);

      // Save Bluetooth associations
      final bluetoothAssociations = _bluetoothToVehicle.entries
          .map((e) => '${e.key}|${e.value}')
          .toList();
      await prefs.setStringList(
          'bluetooth_associations', bluetoothAssociations);

      print('AutoTrackingService: Saved associations to storage');
    } catch (e) {
      print('AutoTrackingService: Failed to save associations - $e');
    }
  }

  // ==================== PUBLIC API ====================

  /// Manually start a trip (fallback option)
  Future<void> startManualTrip(Vehicle vehicle) async {
    await _startAutomaticTrip(vehicle, AutoTrackingTrigger.manual);
  }

  /// Get all device associations for management UI
  Map<String, Map<String, String>> getAllAssociations() {
    return {
      'androidAuto': Map.from(_androidAutoToVehicle),
      'bluetooth': Map.from(_bluetoothToVehicle),
    };
  }

  /// Remove a device association
  Future<void> removeAssociation(
      AutoTrackingTrigger trigger, String deviceId) async {
    switch (trigger) {
      case AutoTrackingTrigger.androidAuto:
        _androidAutoToVehicle.remove(deviceId);
        break;
      case AutoTrackingTrigger.bluetooth:
        _bluetoothToVehicle.remove(deviceId);
        break;
      case AutoTrackingTrigger.manual:
      case AutoTrackingTrigger.none:
        break;
    }

    await _saveAssociations();
    print(
        'AutoTrackingService: Removed ${trigger.name} association for $deviceId');
  }

  /// Force refresh of all connections
  Future<void> refreshConnections() async {
    print('AutoTrackingService: Manual refresh requested');
    if (_isInitialized) {
      print(
          'AutoTrackingService: Service is initialized, checking Bluetooth devices...');
      await _checkBluetoothDevices();
      print('AutoTrackingService: Manual refresh complete');
    } else {
      print('AutoTrackingService: Service not initialized, skipping refresh');
    }
  }
}
