import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService with ChangeNotifier {
  bool _isConnected = false;
  bool _isConnecting = false;
  BluetoothDevice? _connectedDevice;
  Timer? _reconnectTimer;
  int? _rssi; // Signal strength
  String? _deviceAddress;
  final int _reconnectInterval = 60; // seconds
  final int _connectionTimeout = 90; // seconds

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  int? get rssi => _rssi;
  String? get deviceAddress => _deviceAddress;

  // Enhanced getters for status details
  String get signalStrength {
    if (_rssi == null) return 'Unknown';
    if (_rssi! >= -50) return 'Excellent';
    if (_rssi! >= -60) return 'Good';
    if (_rssi! >= -70) return 'Fair';
    return 'Poor';
  }

  String get connectionStatus {
    if (_isConnected) return 'Connected';
    if (_isConnecting) return 'Connecting';
    return 'Disconnected';
  }

  Future<void> initialize() async {
    try {
      _isConnecting = true;
      notifyListeners();

      // Check if Bluetooth is available and enabled with timeout
      final isSupported =
          await FlutterBluePlus.isSupported.timeout(const Duration(seconds: 5));
      if (isSupported == false) {
        print('Bluetooth is not supported on this device.');
        return;
      }

      // Try to turn on Bluetooth with timeout
      try {
        await FlutterBluePlus.turnOn().timeout(const Duration(seconds: 10));
      } catch (e) {
        print('Could not turn on Bluetooth: $e');
        // Continue anyway - user might turn it on manually later
      }

      _startReconnectTimer();
      print('Bluetooth service initialized successfully');
    } catch (e) {
      print('Bluetooth service initialization error: $e');
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(
      Duration(seconds: _reconnectInterval),
      (_) => _attemptReconnect(),
    );
  }

  Future<void> _attemptReconnect() async {
    if (_isConnected || _isConnecting) return;

    try {
      _isConnecting = true;
      notifyListeners();

      // Start scanning for devices
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: _connectionTimeout),
      );

      // Listen for scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          _checkAndConnectDevice(result.device, result.rssi);
        }
      });
    } catch (e) {
      print('Bluetooth reconnection error: $e');
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> _checkAndConnectDevice(BluetoothDevice device, int rssi) async {
    try {
      // Check if this is a known device from our vehicle list
      // This would need to be implemented based on your vehicle storage
      bool isKnownDevice = await _isKnownDevice(device);

      if (isKnownDevice) {
        await device.connect(timeout: Duration(seconds: _connectionTimeout));
        _connectedDevice = device;
        _rssi = rssi;
        _deviceAddress = device.remoteId.toString();
        _isConnected = true;

        // Start monitoring RSSI for connected device
        _startRssiMonitoring();

        notifyListeners();
      }
    } catch (e) {
      print('Device connection error: $e');
    }
  }

  void _startRssiMonitoring() {
    if (_connectedDevice == null) return;

    Timer.periodic(Duration(seconds: 5), (timer) async {
      if (!_isConnected || _connectedDevice == null) {
        timer.cancel();
        return;
      }

      try {
        final rssi = await _connectedDevice!.readRssi();
        _rssi = rssi;
        notifyListeners();
      } catch (e) {
        print('RSSI read error: $e');
      }
    });
  }

  Future<bool> _isKnownDevice(BluetoothDevice device) async {
    // This would need to be implemented to check against your stored vehicle Bluetooth devices
    // For now, returning false
    return false;
  }

  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
    } catch (e) {
      print('Bluetooth disconnect error: $e');
    } finally {
      _isConnected = false;
      _connectedDevice = null;
      _rssi = null;
      _deviceAddress = null;
      notifyListeners();
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    disconnect();
    super.dispose();
  }
}
