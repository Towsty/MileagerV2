import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mileager/providers/vehicle_provider.dart';
import 'package:mileager/models/vehicle.dart';
import 'package:mileager/widgets/cached_vehicle_image.dart';

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

  String _convertToDirectUrl(String url) {
    print('Converting URL: $url');

    // Convert Google Drive sharing URLs to direct URLs
    if (url.contains('drive.google.com/file/d/')) {
      final regex = RegExp(r'drive\.google\.com/file/d/([a-zA-Z0-9_-]+)');
      final match = regex.firstMatch(url);
      if (match != null) {
        final fileId = match.group(1);
        // Try the thumbnail format which is more reliable for images
        final directUrl =
            'https://drive.google.com/thumbnail?id=$fileId&sz=w400';
        print('Google Drive conversion: $url -> $directUrl');
        return directUrl;
      }
    }

    // Convert Dropbox sharing URLs to direct URLs
    if (url.contains('dropbox.com') && url.contains('dl=0')) {
      final directUrl = url.replaceAll('dl=0', 'dl=1');
      print('Dropbox conversion: $url -> $directUrl');
      return directUrl;
    }

    // Return original URL if no conversion needed
    print('No conversion needed for: $url');
    return url;
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    final String? oldPhotoPath = widget.vehicle?.photoPath;

    // Convert URL to direct URL if needed
    String? finalPhotoUrl;
    if (!_useLocalPhoto && _photoUrlController.text.isNotEmpty) {
      finalPhotoUrl = _convertToDirectUrl(_photoUrlController.text.trim());
      print('Original URL: ${_photoUrlController.text}');
      print('Converted URL: $finalPhotoUrl');
    }

    final vehicle = widget.vehicle != null
        ? Vehicle.existing(
            id: widget.vehicle!.id,
            make: _makeController.text,
            model: _modelController.text,
            year: int.parse(_yearController.text),
            color: _colorController.text,
            vin: _vinController.text,
            tag: _tagController.text,
            startingOdometer: double.parse(_odometerController.text),
            nickname: _nicknameController.text,
            photoPath: _useLocalPhoto ? _photoPath : null,
            photoUrl: finalPhotoUrl,
          )
        : Vehicle.create(
            make: _makeController.text,
            model: _modelController.text,
            year: int.parse(_yearController.text),
            color: _colorController.text,
            vin: _vinController.text,
            tag: _tagController.text,
            startingOdometer: double.parse(_odometerController.text),
            nickname: _nicknameController.text,
            photoPath: _useLocalPhoto ? _photoPath : null,
            photoUrl: finalPhotoUrl,
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
        // Photo display with caching
        GestureDetector(
          onTap: _useLocalPhoto ? _pickAndCropImage : null,
          child: _useLocalPhoto
              ? CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: _photoPath != null && File(_photoPath!).existsSync()
                      ? null
                      : const Icon(Icons.add_a_photo, size: 40),
                  backgroundImage:
                      _photoPath != null && File(_photoPath!).existsSync()
                          ? FileImage(File(_photoPath!))
                          : null,
                )
              : _photoUrlController.text.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: CachedNetworkImage(
                        imageUrl: _convertToDirectUrl(
                            _photoUrlController.text.trim()),
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        cacheKey:
                            'preview_${_photoUrlController.text.hashCode}',
                        placeholder: (context, url) => CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) {
                          print('Network image loading error: $error');
                          return CircleAvatar(
                            radius: 60,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: const Icon(Icons.error,
                                size: 40, color: Colors.white),
                          );
                        },
                        fadeInDuration: const Duration(milliseconds: 300),
                        fadeOutDuration: const Duration(milliseconds: 100),
                      ),
                    )
                  : CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.add_a_photo, size: 40),
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
        if (!_useLocalPhoto) ...[
          TextFormField(
            controller: _photoUrlController,
            decoration: const InputDecoration(
              labelText: 'Photo URL',
              hintText: 'https://example.com/photo.jpg',
              prefixIcon: Icon(Icons.link),
              helperText:
                  'Supports Google Drive, Dropbox, and direct image URLs',
            ),
            maxLines: 2,
            onChanged: (value) {
              setState(() {
                _hasUnsavedChanges = true;
              });
              // Debug: Test URL conversion in real-time
              if (value.isNotEmpty) {
                final converted = _convertToDirectUrl(value.trim());
                print('Real-time conversion: $value -> $converted');
              }
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
          const SizedBox(height: 8),

          // Debug: Show converted URL
          if (_photoUrlController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Converted URL:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _convertToDirectUrl(_photoUrlController.text.trim()),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Supported URL formats:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Google Drive: Share link (will be auto-converted)\n'
                  '• Dropbox: Share link (will be auto-converted)\n'
                  '• Direct image URLs: .jpg, .png, .gif, etc.\n'
                  '• Images are cached locally for faster loading',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
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
