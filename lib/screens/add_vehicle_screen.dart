import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:mileager/providers/vehicle_provider.dart';
import 'package:mileager/models/vehicle.dart';

class AddVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const AddVehicleScreen({super.key, this.vehicle});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _odometerController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  String? _photoPath;
  bool _hasUnsavedChanges = false;
  BluetoothDevice? _selectedDevice;
  List<BluetoothDevice> _availableDevices = [];
  bool _isScanning = false;
  bool _bluetoothPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _makeController.text = widget.vehicle?.make ?? '';
    _modelController.text = widget.vehicle?.model ?? '';
    _yearController.text = widget.vehicle?.year.toString() ?? '';
    _colorController.text = widget.vehicle?.color ?? '';
    _vinController.text = widget.vehicle?.vin ?? '';
    _tagController.text = widget.vehicle?.tag ?? '';
    _odometerController.text =
        widget.vehicle?.startingOdometer.toString() ?? '';
    _nicknameController.text = widget.vehicle?.nickname ?? '';
    _photoPath = widget.vehicle?.photoPath;
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    await _checkBluetoothPermissions();
    if (_bluetoothPermissionGranted) {
      await _loadBluetoothDevices();
    }
  }

  Future<void> _checkBluetoothPermissions() async {
    // Check and request Bluetooth permissions
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    bool allGranted = statuses.values.every((status) =>
        status == PermissionStatus.granted ||
        status == PermissionStatus.limited);

    setState(() {
      _bluetoothPermissionGranted = allGranted;
    });

    if (!allGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Bluetooth permissions are required to detect paired devices'),
          ),
        );
      }
    }
  }

  Future<void> _loadBluetoothDevices() async {
    if (!_bluetoothPermissionGranted) return;

    setState(() => _isScanning = true);

    try {
      // Check if Bluetooth is supported and enabled
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception('Bluetooth not supported by this device');
      }

      // Check if Bluetooth is turned on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        throw Exception('Please enable Bluetooth');
      }

      List<BluetoothDevice> allDevices = [];

      // Get connected devices
      final connectedDevices = await FlutterBluePlus.connectedDevices;
      allDevices.addAll(connectedDevices);

      // Get bonded devices (paired devices)
      final bondedDevices = await FlutterBluePlus.bondedDevices;
      allDevices.addAll(bondedDevices);

      // Start scanning for nearby devices
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

      // Listen to scan results
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        final scannedDevices = results.map((r) => r.device).toList();
        allDevices.addAll(scannedDevices);

        // Remove duplicates and filter out devices without names
        final uniqueDevices = <String, BluetoothDevice>{};
        for (final device in allDevices) {
          if (device.name.isNotEmpty) {
            uniqueDevices[device.id.id] = device;
          }
        }

        if (mounted) {
          setState(() {
            _availableDevices = uniqueDevices.values.toList();
          });
        }
      });

      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 4));
      subscription.cancel();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bluetooth error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _startBluetoothScan() async {
    await _checkBluetoothPermissions();
    if (_bluetoothPermissionGranted) {
      await _loadBluetoothDevices();
    }
  }

  Future<void> _pickAndCropImage() async {
    try {
      print('Starting image picker...');

      final picker = ImagePicker();

      print('Attempting to pick image from gallery...');
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile == null) {
        print('User cancelled image selection');
        return;
      }

      print('Image picked successfully: ${pickedFile.path}');

      // Check if the file exists
      final file = File(pickedFile.path);
      if (!await file.exists()) {
        throw Exception('Selected image file does not exist');
      }

      // Skip cropping for now and directly save the image
      print('Saving image permanently...');
      final permanentPath = await _saveImagePermanently(pickedFile.path);

      setState(() {
        _photoPath = permanentPath;
        _hasUnsavedChanges = true;
      });

      print('Image saved successfully to: $permanentPath');
    } catch (e, stackTrace) {
      print('Error in _pickAndCropImage: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process image: $e')),
        );
      }
    }
  }

  Future<String> _saveImagePermanently(String tempPath) async {
    // Get the app's documents directory
    final documentsDir = await getApplicationDocumentsDirectory();
    final vehicleImagesDir =
        Directory(path.join(documentsDir.path, 'vehicle_images'));

    // Create the directory if it doesn't exist
    if (!await vehicleImagesDir.exists()) {
      await vehicleImagesDir.create(recursive: true);
    }

    // Generate a unique filename
    final vehicleId =
        widget.vehicle?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final extension = path.extension(tempPath);
    final fileName =
        'vehicle_${vehicleId}_${DateTime.now().millisecondsSinceEpoch}$extension';
    final permanentPath = path.join(vehicleImagesDir.path, fileName);

    // Copy the temporary file to the permanent location
    final tempFile = File(tempPath);
    await tempFile.copy(permanentPath);

    print('Image saved permanently to: $permanentPath');
    return permanentPath;
  }

  Future<void> _cleanupOldImage(String? oldImagePath) async {
    if (oldImagePath != null && oldImagePath.isNotEmpty) {
      try {
        final oldFile = File(oldImagePath);
        if (await oldFile.exists()) {
          await oldFile.delete();
          print('Cleaned up old image: $oldImagePath');
        }
      } catch (e) {
        print('Failed to cleanup old image: $e');
        // Don't throw error for cleanup failures
      }
    }
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    // Store old photo path for cleanup if we're updating
    final String? oldPhotoPath = widget.vehicle?.photoPath;

    final vehicle = Vehicle(
      id: widget.vehicle?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      make: _makeController.text,
      model: _modelController.text,
      year: int.parse(_yearController.text),
      color: _colorController.text,
      vin: _vinController.text,
      tag: _tagController.text,
      startingOdometer: double.parse(_odometerController.text),
      nickname: _nicknameController.text,
      bluetoothDeviceName: _selectedDevice?.name,
      bluetoothMacId: _selectedDevice?.id.id,
      photoPath: _photoPath,
    );

    try {
      if (widget.vehicle != null) {
        await context.read<VehicleProvider>().updateVehicle(vehicle);
        // Clean up old image if we have a new one and it's different
        if (_photoPath != oldPhotoPath && oldPhotoPath != null) {
          await _cleanupOldImage(oldPhotoPath);
        }
      } else {
        await context.read<VehicleProvider>().addVehicle(vehicle);
      }

      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save vehicle: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle != null ? 'Edit Vehicle' : 'Add Vehicle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickAndCropImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage:
                      _photoPath != null ? FileImage(File(_photoPath!)) : null,
                  child: _photoPath == null
                      ? const Icon(Icons.add_a_photo, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _makeController,
                decoration: const InputDecoration(labelText: 'Make'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter make' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Model'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter model' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Year'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter year';
                  final year = int.tryParse(value!);
                  if (year == null) return 'Invalid year';
                  if (year < 1900 || year > DateTime.now().year + 1) {
                    return 'Invalid year range';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter color' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _vinController,
                decoration: const InputDecoration(labelText: 'VIN'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter VIN' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tagController,
                decoration: const InputDecoration(labelText: 'Tag'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter tag' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _odometerController,
                decoration: const InputDecoration(
                  labelText: 'Start Odometer',
                  suffixText: 'miles',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter odometer reading';
                  }
                  if (double.tryParse(value!) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: 'Nickname'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter nickname' : null,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bluetooth),
                          const SizedBox(width: 8),
                          const Text('Bluetooth Device',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          if (_isScanning)
                            const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (!_bluetoothPermissionGranted)
                        Column(
                          children: [
                            const Text('Bluetooth permissions required'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _checkBluetoothPermissions,
                              child: const Text('Grant Permissions'),
                            ),
                          ],
                        )
                      else if (_availableDevices.isEmpty && !_isScanning)
                        Column(
                          children: [
                            const Text('No devices found'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _startBluetoothScan,
                              child: const Text('Scan for Devices'),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            DropdownButtonFormField<BluetoothDevice>(
                              value: _selectedDevice,
                              decoration: const InputDecoration(
                                labelText: 'Select Bluetooth Device',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<BluetoothDevice>(
                                  value: null,
                                  child: Text('No device selected'),
                                ),
                                ..._availableDevices.map((device) {
                                  return DropdownMenuItem(
                                    value: device,
                                    child: Text(device.name.isNotEmpty
                                        ? device.name
                                        : 'Unknown Device'),
                                  );
                                }),
                              ],
                              onChanged: (device) {
                                setState(() => _selectedDevice = device);
                              },
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _startBluetoothScan,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh Devices'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_hasUnsavedChanges)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'You have unsaved changes. Click "Save Vehicle" to save.',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _saveVehicle,
                icon: Icon(_hasUnsavedChanges ? Icons.save : Icons.check),
                label: Text(
                    widget.vehicle != null ? 'Update Vehicle' : 'Save Vehicle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasUnsavedChanges
                      ? Colors.orange
                      : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _vinController.dispose();
    _tagController.dispose();
    _odometerController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }
}
