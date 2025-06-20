import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/saved_location.dart';
import '../providers/saved_location_provider.dart';
import '../services/location_service.dart';
import '../services/permission_service.dart';
import '../screens/search_address_screen.dart';
import 'edit_location_screen.dart';

class ManageLocationsScreen extends StatefulWidget {
  const ManageLocationsScreen({super.key});

  @override
  State<ManageLocationsScreen> createState() => _ManageLocationsScreenState();
}

class _ManageLocationsScreenState extends State<ManageLocationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  // Address controllers
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  bool _isLoading = false;
  bool _isManualAddress = false;
  final LocationService _locationService = LocationService();

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  String _getFormattedAddress() {
    final components = [
      _streetController.text.trim(),
      _cityController.text.trim(),
      _stateController.text.trim(),
      _zipController.text.trim(),
    ];
    return components.where((e) => e.isNotEmpty).join(', ');
  }

  Future<void> _addLocation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Location'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Location Name',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Home, Work, Gym',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a location name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Location Type Toggle
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        icon: Icon(Icons.my_location),
                        label: Text('Current Location'),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        icon: Icon(Icons.edit_location),
                        label: Text('Enter Address'),
                      ),
                    ],
                    selected: {_isManualAddress},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _isManualAddress = newSelection.first;
                      });
                    },
                  ),
                  if (_isManualAddress) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Enter Address Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _streetController,
                      decoration: const InputDecoration(
                        labelText: 'Street Address',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 123 Main St',
                      ),
                      validator: (value) {
                        if (_isManualAddress &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Please enter the street address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., San Francisco',
                      ),
                      validator: (value) {
                        if (_isManualAddress &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Please enter the city';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            decoration: const InputDecoration(
                              labelText: 'State',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., CA',
                            ),
                            validator: (value) {
                              if (_isManualAddress &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Please enter the state';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _zipController,
                            decoration: const InputDecoration(
                              labelText: 'ZIP Code',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., 94105',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_isManualAddress &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Please enter the ZIP code';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Park in back lot',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() => _isLoading = true);

      try {
        GeoPoint? coordinates;

        if (_isManualAddress) {
          // Get coordinates from address
          final formattedAddress = _getFormattedAddress();
          coordinates = await _locationService
              .getCoordinatesFromAddress(formattedAddress);

          if (!mounted) return;

          if (coordinates == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Could not find coordinates for this address. Please check the address and try again.',
                ),
                duration: Duration(seconds: 4),
              ),
            );
            setState(() => _isLoading = false);
            return;
          }
        } else {
          // Get current location
          final currentLocation = await _locationService.getCurrentLocation();

          if (!mounted) return;

          if (currentLocation == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Could not get current location. Please check your GPS is enabled and try again.',
                ),
                duration: Duration(seconds: 4),
              ),
            );
            setState(() => _isLoading = false);
            return;
          }

          coordinates =
              GeoPoint(currentLocation.latitude, currentLocation.longitude);
        }

        final location = SavedLocation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: DateTime.now(),
        );

        await context.read<SavedLocationProvider>().addLocation(location);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location added successfully')),
        );

        // Clear the form
        _nameController.clear();
        _streetController.clear();
        _cityController.clear();
        _stateController.clear();
        _zipController.clear();
        _notesController.clear();
        _isManualAddress = false;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding location: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _deleteLocation(SavedLocation location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Are you sure you want to delete ${location.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<SavedLocationProvider>().deleteLocation(location.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting location: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Locations'),
      ),
      body: Consumer<SavedLocationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.locations.isEmpty) {
            return Center(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No saved locations yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add locations to quickly select them when adding trips',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _addLocation,
                        icon: const Icon(Icons.add_location),
                        label: const Text('Add Your First Location'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Stack(
            children: [
              ListView.builder(
                itemCount: provider.locations.length,
                itemBuilder: (context, index) {
                  final location = provider.locations[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(location.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<String?>(
                            future: _locationService.getAddressFromCoordinates(
                              GeoPoint(location.latitude, location.longitude),
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text('Loading address...');
                              }
                              return Text(
                                snapshot.data ??
                                    'Lat: ${location.latitude.toStringAsFixed(6)}\n'
                                        'Long: ${location.longitude.toStringAsFixed(6)}',
                              );
                            },
                          ),
                          if (location.notes != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                location.notes!,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteLocation(location),
                      ),
                    ),
                  );
                },
              ),
              if (_isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _addLocation,
        child: const Icon(Icons.add_location),
      ),
    );
  }
}
