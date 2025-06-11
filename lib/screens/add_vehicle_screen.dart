import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
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
  final TextEditingController _photoUrlController = TextEditingController();

  String? _photoPath;
  bool _hasUnsavedChanges = false;
  bool _useLocalPhoto = true; // Toggle between local photo and URL

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
    _photoUrlController.text = widget.vehicle?.photoUrl ?? '';
    _photoPath = widget.vehicle?.photoPath;

    // Determine which photo method to use
    if (widget.vehicle?.photoUrl?.isNotEmpty ?? false) {
      _useLocalPhoto = false;
    }
  }

  Future<void> _pickAndCropImage() async {
    try {
      print('Starting image picker...');

      final picker = ImagePicker();
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

      final file = File(pickedFile.path);
      if (!await file.exists()) {
        throw Exception('Selected image file does not exist');
      }

      final permanentPath = await _saveImagePermanently(pickedFile.path);

      setState(() {
        _photoPath = permanentPath;
        _hasUnsavedChanges = true;
      });

      print('Image saved to: $permanentPath');
    } catch (e) {
      print('Error picking/cropping image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  Future<String> _saveImagePermanently(String tempPath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final vehicleImagesDir = Directory('${appDir.path}/vehicle_images');

    if (!await vehicleImagesDir.exists()) {
      await vehicleImagesDir.create(recursive: true);
    }

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}${path.extension(tempPath)}';
    final permanentPath = '${vehicleImagesDir.path}/$fileName';

    await File(tempPath).copy(permanentPath);
    return permanentPath;
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

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
      photoPath: _useLocalPhoto ? _photoPath : null,
      photoUrl: !_useLocalPhoto && _photoUrlController.text.isNotEmpty
          ? _photoUrlController.text
          : null,
    );

    try {
      if (widget.vehicle != null) {
        await context.read<VehicleProvider>().updateVehicle(vehicle);
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
      }
    }
  }

  Widget _buildPhotoSection() {
    return Column(
      children: [
        // Photo display
        GestureDetector(
          onTap: _useLocalPhoto ? _pickAndCropImage : null,
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Theme.of(context).colorScheme.primary,
            backgroundImage: _getPhotoImageProvider(),
            child: _getPhotoImageProvider() == null
                ? const Icon(Icons.add_a_photo, size: 40)
                : null,
          ),
        ),
        const SizedBox(height: 16),

        // Toggle between local photo and URL
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Local Photo'),
              selected: _useLocalPhoto,
              onSelected: (selected) {
                setState(() {
                  _useLocalPhoto = true;
                  _hasUnsavedChanges = true;
                });
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Photo URL'),
              selected: !_useLocalPhoto,
              onSelected: (selected) {
                setState(() {
                  _useLocalPhoto = false;
                  _hasUnsavedChanges = true;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // URL input field (only shown when URL mode is selected)
        if (!_useLocalPhoto)
          TextFormField(
            controller: _photoUrlController,
            decoration: const InputDecoration(
              labelText: 'Photo URL',
              hintText: 'https://example.com/photo.jpg',
              prefixIcon: Icon(Icons.link),
            ),
            onChanged: (value) {
              setState(() {
                _hasUnsavedChanges = true;
              });
            },
            validator: (value) {
              if (!_useLocalPhoto && (value?.isNotEmpty ?? false)) {
                final uri = Uri.tryParse(value!);
                if (uri == null || !uri.hasAbsolutePath) {
                  return 'Please enter a valid URL';
                }
              }
              return null;
            },
          ),
      ],
    );
  }

  ImageProvider? _getPhotoImageProvider() {
    if (_useLocalPhoto && _photoPath != null) {
      return FileImage(File(_photoPath!));
    } else if (!_useLocalPhoto && _photoUrlController.text.isNotEmpty) {
      return NetworkImage(_photoUrlController.text);
    }
    return null;
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
              _buildPhotoSection(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _makeController,
                decoration: const InputDecoration(labelText: 'Make'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter make' : null,
                onChanged: (_) => setState(() => _hasUnsavedChanges = true),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Model'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter model' : null,
                onChanged: (_) => setState(() => _hasUnsavedChanges = true),
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
                onChanged: (_) => setState(() => _hasUnsavedChanges = true),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter color' : null,
                onChanged: (_) => setState(() => _hasUnsavedChanges = true),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _vinController,
                decoration: const InputDecoration(labelText: 'VIN'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter VIN' : null,
                onChanged: (_) => setState(() => _hasUnsavedChanges = true),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tagController,
                decoration: const InputDecoration(labelText: 'Tag'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter tag' : null,
                onChanged: (_) => setState(() => _hasUnsavedChanges = true),
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
                onChanged: (_) => setState(() => _hasUnsavedChanges = true),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: 'Nickname'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter nickname' : null,
                onChanged: (_) => setState(() => _hasUnsavedChanges = true),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveVehicle,
                child: Text(
                    widget.vehicle != null ? 'Update Vehicle' : 'Add Vehicle'),
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
    _photoUrlController.dispose();
    super.dispose();
  }
}
