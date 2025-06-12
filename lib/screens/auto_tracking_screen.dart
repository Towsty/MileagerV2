import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/auto_tracking_service.dart';
import '../providers/vehicle_provider.dart';
import '../models/vehicle.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class AutoTrackingScreen extends StatefulWidget {
  const AutoTrackingScreen({super.key});

  @override
  State<AutoTrackingScreen> createState() => _AutoTrackingScreenState();
}

class _AutoTrackingScreenState extends State<AutoTrackingScreen> {
  late AutoTrackingService _autoTrackingService;
  late VehicleProvider _vehicleProvider;

  @override
  void initState() {
    super.initState();
    _autoTrackingService = AutoTrackingService();
    _vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Tracking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _autoTrackingService.refreshConnections();
              setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildHowItWorksCard(),
            const SizedBox(height: 16),
            _buildAndroidAutoSection(),
            const SizedBox(height: 16),
            _buildBluetoothSection(),
            const SizedBox(height: 16),
            _buildManualFallbackSection(),
            const SizedBox(height: 16),
            _buildDebugSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.track_changes,
                  color: _autoTrackingService.isInitialized
                      ? Colors.green
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Auto Tracking Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              'Service Status',
              _autoTrackingService.isInitialized ? 'Active' : 'Inactive',
              _autoTrackingService.isInitialized ? Colors.green : Colors.red,
            ),
            _buildStatusRow(
              'Android Auto',
              _autoTrackingService.isAndroidAutoConnected
                  ? 'Connected'
                  : 'Disconnected',
              _autoTrackingService.isAndroidAutoConnected
                  ? Colors.green
                  : Colors.grey,
            ),
            _buildStatusRow(
              'Bluetooth Device',
              _autoTrackingService.currentBluetoothDevice ?? 'None',
              _autoTrackingService.currentBluetoothDevice != null
                  ? Colors.green
                  : Colors.grey,
            ),
            if (_autoTrackingService.currentVehicle != null) ...[
              const Divider(),
              _buildStatusRow(
                'Active Vehicle',
                '${_autoTrackingService.currentVehicle!.make} ${_autoTrackingService.currentVehicle!.model}',
                Colors.blue,
              ),
              _buildStatusRow(
                'Trigger Method',
                _autoTrackingService.trackingStatus,
                _autoTrackingService.currentTrigger != AutoTrackingTrigger.none
                    ? Colors.green
                    : Colors.grey,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'How Hybrid Tracking Works',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Mileager uses a smart 3-tier system to automatically detect when you start driving:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildPriorityStep(
              1,
              'Android Auto',
              'Highest priority - detects when you connect to Android Auto',
              Icons.android,
              Colors.green,
            ),
            _buildPriorityStep(
              2,
              'Bluetooth',
              'Fallback - detects connection to your vehicle\'s Bluetooth',
              Icons.bluetooth,
              Colors.blue,
            ),
            _buildPriorityStep(
              3,
              'Manual',
              'Last resort - you can manually start trips',
              Icons.touch_app,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityStep(
      int step, String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color),
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidAutoSection() {
    final associations =
        _autoTrackingService.getAllAssociations()['androidAuto'] ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.android, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Android Auto Detection',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Android Auto provides the most reliable automatic detection. When you connect your phone to Android Auto, trips will start automatically.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (associations.isEmpty) ...[
              const Text(
                'No vehicle associations yet. Connect to Android Auto and start a trip to create an association.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ] else ...[
              const Text(
                'Vehicle Associations:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...associations.entries.map((entry) => _buildAssociationTile(
                    AutoTrackingTrigger.androidAuto,
                    entry.key,
                    entry.value,
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothSection() {
    final associations =
        _autoTrackingService.getAllAssociations()['bluetooth'] ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bluetooth, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Bluetooth Detection',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Bluetooth detection works when Android Auto isn\'t available. Connect to your vehicle\'s Bluetooth and associate it with a vehicle.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showBluetoothAssociationDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Bluetooth Device'),
            ),
            const SizedBox(height: 16),
            if (associations.isEmpty) ...[
              const Text(
                'No Bluetooth devices associated yet.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ] else ...[
              const Text(
                'Associated Devices:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...associations.entries.map((entry) => _buildAssociationTile(
                    AutoTrackingTrigger.bluetooth,
                    entry.key,
                    entry.value,
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManualFallbackSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.touch_app, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Manual Fallback',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'When automatic detection isn\'t available, you can always start trips manually from the home screen.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to home screen where manual trip start is available
              },
              icon: const Icon(Icons.home),
              label: const Text('Go to Home Screen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Debug',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _runDebugTest,
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Debug Test'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _scanBluetoothDevices,
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('Scan Bluetooth'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _forceRefreshTracking,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Force Refresh'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssociationTile(
      AutoTrackingTrigger trigger, String deviceId, String vehicleId) {
    final vehicle = _vehicleProvider.vehicles.firstWhere(
      (v) => v.id == vehicleId,
      orElse: () => Vehicle(
        id: vehicleId,
        make: 'Unknown',
        model: 'Vehicle',
        year: 0,
        color: 'Unknown',
        startingOdometer: 0.0,
        photoPath: '',
        photoUrl: '',
      ),
    );

    return ListTile(
      leading: Icon(
        trigger == AutoTrackingTrigger.androidAuto
            ? Icons.android
            : Icons.bluetooth,
        color: trigger == AutoTrackingTrigger.androidAuto
            ? Colors.green
            : Colors.blue,
      ),
      title: Text(deviceId),
      subtitle: Text('${vehicle.make} ${vehicle.model}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _confirmRemoveAssociation(trigger, deviceId),
      ),
    );
  }

  void _showBluetoothAssociationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Associate Bluetooth Device'),
        content: const Text(
          'We\'ll scan for available Bluetooth devices. Make sure your vehicle\'s Bluetooth is discoverable and try connecting to it first from your phone\'s Bluetooth settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showBluetoothDeviceSelection();
            },
            child: const Text('Scan for Devices'),
          ),
        ],
      ),
    );
  }

  void _showBluetoothDeviceSelection() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Scanning for Bluetooth devices...'),
          ],
        ),
      ),
    );

    try {
      // Get available devices
      final availableDevices = await _scanForBluetoothDevices();

      // Hide loading dialog
      Navigator.of(context).pop();

      if (availableDevices.isEmpty) {
        _showNoDevicesFoundDialog();
        return;
      }

      // Show device selection dialog
      _showDeviceSelectionDialog(availableDevices);
    } catch (e) {
      // Hide loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bluetooth scan failed: $e')),
      );
    }
  }

  Future<List<BluetoothDevice>> _scanForBluetoothDevices() async {
    final devices = <BluetoothDevice>[];

    try {
      // Check if Bluetooth is on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        throw Exception('Bluetooth is not enabled');
      }

      // Check location permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permission is required for Bluetooth scanning');
      }

      // Get connected devices first
      final connectedDevices = FlutterBluePlus.connectedDevices;
      devices.addAll(connectedDevices);
      print('Found ${connectedDevices.length} connected devices');

      // Start scanning for nearby devices with longer timeout
      print('Starting Bluetooth scan...');
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation:
            true, // Use fine location for better device discovery
      );

      // Collect scan results over time
      final scanCompleter = Completer<void>();
      final scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          if (!devices.any((d) => d.remoteId == result.device.remoteId)) {
            devices.add(result.device);
            print(
                'Found device: ${result.device.platformName.isNotEmpty ? result.device.platformName : result.device.remoteId.str}');
          }
        }
      });

      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 12));
      await scanSubscription.cancel();
      await FlutterBluePlus.stopScan();

      print('Scan complete, found ${devices.length} total devices');

      // Try to get better names for devices by connecting briefly
      for (int i = 0; i < devices.length; i++) {
        final device = devices[i];
        if (device.platformName.isEmpty) {
          try {
            // Try to read device name from advertisement data or services
            print('Attempting to get name for device ${device.remoteId.str}');

            // Check if we can get the name from recent scan results
            final recentResults = FlutterBluePlus.lastScanResults;
            final matchingResult = recentResults
                .where((r) => r.device.remoteId == device.remoteId)
                .firstOrNull;

            if (matchingResult != null &&
                matchingResult.advertisementData.advName.isNotEmpty) {
              // Create a new device object with the advertisement name
              print(
                  'Found advertisement name: ${matchingResult.advertisementData.advName}');
            }
          } catch (e) {
            print('Could not get name for device ${device.remoteId.str}: $e');
          }
        }
      }
    } catch (e) {
      print('Bluetooth scan error: $e');
      await FlutterBluePlus.stopScan();
      rethrow;
    }

    return devices;
  }

  void _showNoDevicesFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Devices Found'),
        content: const Text(
          'No Bluetooth devices were found. Please:\n\n'
          '1. Make sure Bluetooth is enabled\n'
          '2. Connect to your vehicle\'s Bluetooth first\n'
          '3. Ensure your vehicle is in pairing mode\n'
          '4. Try the manual entry option below',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showManualEntryDialog();
            },
            child: const Text('Manual Entry'),
          ),
        ],
      ),
    );
  }

  void _showDeviceSelectionDialog(List<BluetoothDevice> devices) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Bluetooth Device'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];

              // Try multiple ways to get a meaningful device name
              String deviceName = 'Unknown Device';
              String subtitle = device.remoteId.str;

              if (device.platformName.isNotEmpty) {
                deviceName = device.platformName;
              } else {
                // Try to get name from recent scan results
                final recentResults = FlutterBluePlus.lastScanResults;
                final matchingResult = recentResults
                    .where((r) => r.device.remoteId == device.remoteId)
                    .firstOrNull;

                if (matchingResult != null) {
                  if (matchingResult.advertisementData.advName.isNotEmpty) {
                    deviceName = matchingResult.advertisementData.advName;
                  } else if (matchingResult
                      .advertisementData.localName.isNotEmpty) {
                    deviceName = matchingResult.advertisementData.localName;
                  }
                }

                // If still no name, use a more user-friendly format
                if (deviceName == 'Unknown Device') {
                  deviceName = 'Bluetooth Device';
                  subtitle = 'MAC: ${device.remoteId.str}';
                }
              }

              final isConnected =
                  FlutterBluePlus.connectedDevices.contains(device);

              return ListTile(
                leading: Icon(
                  isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                  color: isConnected ? Colors.green : Colors.grey,
                ),
                title: Text(deviceName),
                subtitle: Text(
                  '${subtitle}${isConnected ? ' (Connected)' : ''}',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  await _autoTrackingService.associateDeviceWithVehicle(
                    AutoTrackingTrigger.bluetooth,
                    deviceName,
                    _vehicleProvider
                        .vehicles.first.id, // For now, use first vehicle
                  );
                  Navigator.of(context).pop();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Associated "$deviceName" with vehicle'),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showManualEntryDialog();
            },
            child: const Text('Manual Entry'),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog() {
    final deviceNameController = TextEditingController();
    Vehicle? selectedVehicle;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Manual Device Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the exact Bluetooth device name as it appears in your phone\'s Bluetooth settings.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: deviceNameController,
                decoration: const InputDecoration(
                  labelText: 'Bluetooth Device Name',
                  hintText: 'e.g., "My Car Audio"',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Vehicle>(
                value: selectedVehicle,
                decoration: const InputDecoration(
                  labelText: 'Vehicle',
                  border: OutlineInputBorder(),
                ),
                items: _vehicleProvider.vehicles.map((vehicle) {
                  return DropdownMenuItem(
                    value: vehicle,
                    child: Text('${vehicle.make} ${vehicle.model}'),
                  );
                }).toList(),
                onChanged: (vehicle) {
                  setState(() {
                    selectedVehicle = vehicle;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: deviceNameController.text.isNotEmpty &&
                      selectedVehicle != null
                  ? () async {
                      await _autoTrackingService.associateDeviceWithVehicle(
                        AutoTrackingTrigger.bluetooth,
                        deviceNameController.text.trim(),
                        selectedVehicle!.id,
                      );
                      Navigator.of(context).pop();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Associated "${deviceNameController.text}" with ${selectedVehicle!.make} ${selectedVehicle!.model}',
                          ),
                        ),
                      );
                    }
                  : null,
              child: const Text('Associate'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveAssociation(AutoTrackingTrigger trigger, String deviceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Association'),
        content: Text('Remove association for "$deviceId"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _autoTrackingService.removeAssociation(trigger, deviceId);
              Navigator.of(context).pop();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Removed association for "$deviceId"')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _runDebugTest() async {
    print('=== DEBUG TEST START ===');

    try {
      // Test 1: Check Bluetooth support
      print('1. Checking Bluetooth support...');
      final isSupported = await FlutterBluePlus.isSupported;
      print('   Bluetooth supported: $isSupported');

      if (!isSupported) {
        print('   ERROR: Bluetooth not supported on this device');
        return;
      }

      // Test 2: Check Bluetooth adapter state
      print('2. Checking Bluetooth adapter state...');
      final adapterState = await FlutterBluePlus.adapterState.first;
      print('   Adapter state: $adapterState');

      if (adapterState != BluetoothAdapterState.on) {
        print('   Attempting to turn on Bluetooth...');
        try {
          await FlutterBluePlus.turnOn();
          print('   Bluetooth turn-on requested');
        } catch (e) {
          print('   Failed to turn on Bluetooth: $e');
        }

        // Wait and check again
        await Future.delayed(const Duration(seconds: 2));
        final newState = await FlutterBluePlus.adapterState.first;
        print('   New adapter state: $newState');
      }

      // Test 3: Check connected devices (Method 1)
      print(
          '3. Checking connected devices (FlutterBluePlus.connectedDevices)...');
      final connectedDevices = FlutterBluePlus.connectedDevices;
      print('   Found ${connectedDevices.length} connected devices');
      for (final device in connectedDevices) {
        final name =
            device.platformName.isNotEmpty ? device.platformName : 'Unknown';
        print('   - $name (${device.remoteId.str})');
      }

      // Test 4: Check via scan (Method 2)
      print('4. Performing Bluetooth scan...');
      final scannedDevices = <BluetoothDevice>[];

      try {
        print('   Starting scan...');
        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 5),
          androidUsesFineLocation: false,
        );

        // Wait for scan results
        await Future.delayed(const Duration(seconds: 2));

        final scanResults = FlutterBluePlus.lastScanResults;
        print('   Scan found ${scanResults.length} devices');

        for (final result in scanResults) {
          try {
            final connectionState =
                await result.device.connectionState.first.timeout(
              const Duration(seconds: 1),
            );
            final name = result.device.platformName.isNotEmpty
                ? result.device.platformName
                : 'Unknown';

            print(
                '   - $name (${result.device.remoteId.str}) - State: $connectionState');

            if (connectionState == BluetoothConnectionState.connected) {
              scannedDevices.add(result.device);
            }
          } catch (e) {
            print(
                '   - Error checking device ${result.device.remoteId.str}: $e');
          }
        }

        await FlutterBluePlus.stopScan();
        print('   Found ${scannedDevices.length} connected devices via scan');
      } catch (e) {
        print('   Scan error: $e');
        await FlutterBluePlus.stopScan();
      }

      // Test 5: Check Android Auto
      print('5. Testing Android Auto platform channel...');
      try {
        final isConnected = _autoTrackingService.isAndroidAutoConnected;
        print('   Android Auto connected: $isConnected');
      } catch (e) {
        print('   Android Auto error: $e');
      }

      // Test 6: Check service status
      print('6. Checking AutoTrackingService status...');
      print('   Service initialized: ${_autoTrackingService.isInitialized}');
      print('   Current trigger: ${_autoTrackingService.currentTrigger}');
      final associations = _autoTrackingService.getAllAssociations();
      print(
          '   Android Auto associations: ${associations['androidAuto']?.length ?? 0}');
      print(
          '   Bluetooth associations: ${associations['bluetooth']?.length ?? 0}');

      // Test 7: Permission check
      print('7. Checking permissions...');
      try {
        // Check current location permission
        final hasLocationPermission = await Geolocator.checkPermission();
        print('   Current location permission: $hasLocationPermission');

        // Request permission if needed
        if (hasLocationPermission == LocationPermission.denied) {
          print('   Requesting location permission...');
          final newPermission = await Geolocator.requestPermission();
          print('   New location permission: $newPermission');
        }

        // Check if we can scan with current permissions
        if (hasLocationPermission == LocationPermission.denied ||
            hasLocationPermission == LocationPermission.deniedForever) {
          print(
              '   WARNING: Location permission required for Bluetooth scanning');
        } else {
          print('   Location permission OK for Bluetooth scanning');
        }
      } catch (e) {
        print('   Location permission check error: $e');
      }
    } catch (e, stackTrace) {
      print('DEBUG TEST ERROR: $e');
      print('Stack trace: $stackTrace');
    }

    print('=== DEBUG TEST COMPLETE ===');
  }

  void _scanBluetoothDevices() async {
    print('=== BLUETOOTH SCAN TEST ===');

    try {
      // Use the same comprehensive scanning method as device selection
      final devices = await _scanForBluetoothDevices();

      print(
          'Bluetooth adapter state: ${await FlutterBluePlus.adapterState.first}');
      print('Total devices found: ${devices.length}');

      if (devices.isEmpty) {
        print('No Bluetooth devices found');
        print('This could mean:');
        print('1. No devices are discoverable nearby');
        print('2. All devices are in non-discoverable mode');
        print('3. Bluetooth scanning permissions issue');
      } else {
        print('Found devices:');
        for (final device in devices) {
          String deviceName = 'Unknown Device';

          if (device.platformName.isNotEmpty) {
            deviceName = device.platformName;
          } else {
            // Try to get name from recent scan results
            final recentResults = FlutterBluePlus.lastScanResults;
            final matchingResult = recentResults
                .where((r) => r.device.remoteId == device.remoteId)
                .firstOrNull;

            if (matchingResult != null) {
              if (matchingResult.advertisementData.advName.isNotEmpty) {
                deviceName = matchingResult.advertisementData.advName;
              } else if (matchingResult
                  .advertisementData.localName.isNotEmpty) {
                deviceName = matchingResult.advertisementData.localName;
              }
            }
          }

          final isConnected = FlutterBluePlus.connectedDevices.contains(device);
          final connectionStatus =
              isConnected ? ' (Connected)' : ' (Discoverable)';

          print('- $deviceName (${device.remoteId.str})$connectionStatus');
        }

        // Show connected vs discoverable breakdown
        final connectedCount = devices
            .where((d) => FlutterBluePlus.connectedDevices.contains(d))
            .length;
        final discoverableCount = devices.length - connectedCount;

        print(
            'Summary: $connectedCount connected, $discoverableCount discoverable');
      }
    } catch (e) {
      print('Bluetooth scan error: $e');
    }

    print('=== BLUETOOTH SCAN COMPLETE ===');
  }

  void _forceRefreshTracking() async {
    await _autoTrackingService.refreshConnections();
    setState(() {});
  }

  String _getTriggerDisplayName(AutoTrackingTrigger trigger) {
    switch (trigger) {
      case AutoTrackingTrigger.androidAuto:
        return 'Android Auto';
      case AutoTrackingTrigger.bluetooth:
        return 'Bluetooth';
      case AutoTrackingTrigger.manual:
        return 'Manual';
      case AutoTrackingTrigger.none:
        return 'None';
    }
  }
}
