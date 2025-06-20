import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/saved_location.dart';
import '../providers/saved_location_provider.dart';

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<SavedLocationProvider>(context, listen: false)
          .fetchLocations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading locations: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addLocation() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Location Name'),
            ),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop({
              'name': nameController.text,
              'notes': notesController.text,
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result['name']!.isNotEmpty) {
      final location = SavedLocation(
        id: '', // Will be set by Firestore
        name: result['name']!,
        latitude: 0, // Replace with actual location
        longitude: 0, // Replace with actual location
        notes: result['notes'],
        createdAt: DateTime.now(),
      );

      try {
        await Provider.of<SavedLocationProvider>(context, listen: false)
            .addLocation(location);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location saved successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving location: $e')),
          );
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

    if (confirmed == true) {
      try {
        await Provider.of<SavedLocationProvider>(context, listen: false)
            .deleteLocation(location.id);
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
        title: const Text('Saved Locations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLocations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<SavedLocationProvider>(
              builder: (context, provider, child) {
                final locations = provider.locations;
                if (locations.isEmpty) {
                  return const Center(
                    child: Text('No saved locations'),
                  );
                }
                return ListView.builder(
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final location = locations[index];
                    return ListTile(
                      title: Text(location.name),
                      subtitle: Text(
                        'Lat: ${location.latitude.toStringAsFixed(6)}\n'
                        'Long: ${location.longitude.toStringAsFixed(6)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteLocation(location),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLocation,
        child: const Icon(Icons.add),
      ),
    );
  }
}
