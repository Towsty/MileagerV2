import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../providers/vehicle_provider.dart';
import '../models/trip.dart';
import '../models/vehicle.dart';
import '../utils/string_extensions.dart';
import 'edit_trip_screen.dart';
import 'dart:io';
import 'package:mileager/screens/add_trip_screen.dart';
import 'package:mileager/widgets/cached_vehicle_image.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  String? _selectedVehicleId;
  TripPurpose? _selectedPurpose;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().fetchTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Consumer2<TripProvider, VehicleProvider>(
        builder: (context, tripProvider, vehicleProvider, child) {
          if (tripProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (tripProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading trips',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(tripProvider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => tripProvider.fetchTrips(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final trips = _filterTrips(tripProvider.trips);

          if (trips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.route_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No trips found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Try adjusting your filters or add some trips'),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (_selectedVehicleId != null || _selectedPurpose != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_alt,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getFilterText(vehicleProvider.vehicles),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    final vehicle = vehicleProvider.vehicles
                        .where((v) => v.id == trip.vehicleId)
                        .firstOrNull;

                    return _buildTripCard(trip, vehicle);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTripCard(Trip trip, Vehicle? vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTripDetails(trip, vehicle),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background: Vehicle photo or default car icon
                      CachedVehicleImage(
                        vehicle: vehicle,
                        radius: 24,
                        child: Icon(
                          Icons.directions_car,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                      ),
                      // Overlay: Purpose icon in bottom-right corner
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: trip.purpose == TripPurpose.business
                                ? Colors.blue
                                : Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            trip.purpose == TripPurpose.business
                                ? Icons.work
                                : Icons.home,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle != null
                              ? '${vehicle.year} ${vehicle.make} ${vehicle.model}'
                              : 'Unknown Vehicle',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatDateTime(trip.startTime),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${trip.distance.toStringAsFixed(1)} mi',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        trip.purpose.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                          color: trip.purpose == TripPurpose.business
                              ? Colors.blue
                              : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (trip.memo != null && trip.memo!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          trip.memo!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (trip.deviceName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone_android,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Recorded with ${trip.deviceName}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTripDetails(Trip trip, Vehicle? vehicle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Trip Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                  'Vehicle',
                  vehicle != null
                      ? '${vehicle.year} ${vehicle.make} ${vehicle.model}'
                      : 'Unknown Vehicle'),
              _buildDetailRow(
                  'Distance', '${trip.distance.toStringAsFixed(2)} miles'),
              _buildDetailRow('Purpose',
                  trip.purpose.toString().split('.').last.capitalize()),
              _buildDetailRow('Start Time', _formatDateTime(trip.startTime)),
              if (trip.endTime != null)
                _buildDetailRow('End Time', _formatDateTime(trip.endTime!)),
              if (trip.endTime != null)
                _buildDetailRow('Duration',
                    _formatDuration(trip.endTime!.difference(trip.startTime))),
              if (trip.memo != null && trip.memo!.isNotEmpty)
                _buildDetailRow('Memo', trip.memo!),
              if (trip.deviceName != null)
                _buildDetailRow('Device', trip.deviceName!),
              _buildDetailRow(
                  'Entry Type', trip.isManualEntry ? 'Manual' : 'Tracked'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _editTrip(trip, vehicle);
              },
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<VehicleProvider>(
          builder: (context, vehicleProvider, child) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('Filter Trips'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedVehicleId,
                        decoration: const InputDecoration(labelText: 'Vehicle'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Vehicles'),
                          ),
                          ...vehicleProvider.vehicles.map((vehicle) {
                            return DropdownMenuItem<String>(
                              value: vehicle.id,
                              child: Text(
                                  '${vehicle.year} ${vehicle.make} ${vehicle.model}'),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedVehicleId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<TripPurpose>(
                        value: _selectedPurpose,
                        decoration: const InputDecoration(labelText: 'Purpose'),
                        items: [
                          const DropdownMenuItem<TripPurpose>(
                            value: null,
                            child: Text('All Purposes'),
                          ),
                          ...TripPurpose.values.map((purpose) {
                            return DropdownMenuItem<TripPurpose>(
                              value: purpose,
                              child: Text(purpose
                                  .toString()
                                  .split('.')
                                  .last
                                  .capitalize()),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedPurpose = value;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedVehicleId = null;
                          _selectedPurpose = null;
                        });
                      },
                      child: const Text('Clear'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        this.setState(() {});
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  List<Trip> _filterTrips(List<Trip> trips) {
    return trips.where((trip) {
      if (_selectedVehicleId != null && trip.vehicleId != _selectedVehicleId) {
        return false;
      }
      if (_selectedPurpose != null && trip.purpose != _selectedPurpose) {
        return false;
      }
      return true;
    }).toList();
  }

  String _getFilterText(List<Vehicle> vehicles) {
    final filters = <String>[];

    if (_selectedVehicleId != null) {
      final vehicle =
          vehicles.where((v) => v.id == _selectedVehicleId).firstOrNull;
      if (vehicle != null) {
        filters
            .add('Vehicle: ${vehicle.year} ${vehicle.make} ${vehicle.model}');
      }
    }

    if (_selectedPurpose != null) {
      filters.add(
          'Purpose: ${_selectedPurpose.toString().split('.').last.capitalize()}');
    }

    return filters.join(', ');
  }

  void _clearFilters() {
    setState(() {
      _selectedVehicleId = null;
      _selectedPurpose = null;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  void _editTrip(Trip trip, Vehicle? vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTripScreen(trip: trip, vehicle: vehicle),
      ),
    ).then((result) {
      // If changes were made, refresh the trip list to reflect updates
      if (result == true) {
        context.read<TripProvider>().fetchTrips();
      }
    });
  }

  Widget _buildVehicleImage(Vehicle vehicle) {
    return CachedVehicleImage(
      vehicle: vehicle,
      radius: 20,
      child: const Icon(Icons.directions_car, color: Colors.white),
    );
  }
}
