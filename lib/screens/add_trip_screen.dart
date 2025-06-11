import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle.dart';
import '../models/trip.dart';
import '../providers/vehicle_provider.dart';
import '../providers/trip_provider.dart';
import '../services/location_service.dart';

class AddTripScreen extends StatefulWidget {
  final Vehicle? selectedVehicle;

  const AddTripScreen({super.key, this.selectedVehicle});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  Vehicle? _selectedVehicle;
  TripPurpose _selectedPurpose = TripPurpose.personal;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedVehicle = widget.selectedVehicle;
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate() || _selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current location as default start location
      final locationService = LocationService();
      await locationService.initialize();
      final currentLocation = locationService.getCurrentGeoPoint() ??
          const GeoPoint(0, 0); // Fallback if location unavailable

      final tripDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final trip = Trip(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        vehicleId: _selectedVehicle!.id,
        startTime: tripDateTime,
        endTime: tripDateTime, // For manual entries, start and end are same
        distance: double.parse(_distanceController.text),
        purpose: _selectedPurpose,
        memo: _memoController.text.isEmpty ? null : _memoController.text,
        startLocation: currentLocation,
        endLocation: currentLocation, // Same for manual entries
        isManualEntry: true,
      );

      await context.read<TripProvider>().addCompletedTrip(trip);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save trip: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Manual Trip'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vehicle Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Consumer<VehicleProvider>(
                        builder: (context, vehicleProvider, child) {
                          return DropdownButtonFormField<Vehicle>(
                            value: _selectedVehicle,
                            decoration: const InputDecoration(
                              labelText: 'Select Vehicle',
                              border: OutlineInputBorder(),
                            ),
                            items: vehicleProvider.vehicles.map((vehicle) {
                              return DropdownMenuItem(
                                value: vehicle,
                                child: Text(
                                  '${vehicle.year} ${vehicle.make} ${vehicle.model}${vehicle.nickname != null ? ' (${vehicle.nickname})' : ''}',
                                ),
                              );
                            }).toList(),
                            onChanged: (vehicle) {
                              setState(() {
                                _selectedVehicle = vehicle;
                              });
                            },
                            validator: (value) => value == null
                                ? 'Please select a vehicle'
                                : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Trip Details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip Details',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),

                      // Date and Time Selection
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: _selectTime,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Time',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.access_time),
                                ),
                                child: Text(
                                  _selectedTime.format(context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Distance
                      TextFormField(
                        controller: _distanceController,
                        decoration: const InputDecoration(
                          labelText: 'Distance (miles)',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.straighten),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter distance';
                          }
                          if (double.tryParse(value!) == null) {
                            return 'Please enter a valid number';
                          }
                          final distance = double.parse(value);
                          if (distance <= 0) {
                            return 'Distance must be greater than 0';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Purpose
                      DropdownButtonFormField<TripPurpose>(
                        value: _selectedPurpose,
                        decoration: const InputDecoration(
                          labelText: 'Purpose',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.work_outline),
                        ),
                        items: TripPurpose.values.map((purpose) {
                          return DropdownMenuItem(
                            value: purpose,
                            child: Row(
                              children: [
                                Icon(
                                  purpose == TripPurpose.business
                                      ? Icons.work
                                      : Icons.directions_car,
                                  color: purpose == TripPurpose.business
                                      ? Colors.blue
                                      : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  purpose
                                      .toString()
                                      .split('.')
                                      .last
                                      .replaceAllMapped(RegExp(r'([A-Z])'),
                                          (match) => ' ${match.group(1)}')
                                      .trim()
                                      .toLowerCase()
                                      .replaceRange(
                                          0,
                                          1,
                                          purpose
                                              .toString()
                                              .split('.')
                                              .last[0]
                                              .toUpperCase()),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (purpose) {
                          if (purpose != null) {
                            setState(() {
                              _selectedPurpose = purpose;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Memo (Optional)
                      TextFormField(
                        controller: _memoController,
                        decoration: const InputDecoration(
                          labelText: 'Memo (Optional)',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.note),
                          hintText: 'Add notes about this trip...',
                        ),
                        maxLines: 3,
                        maxLength: 200,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveTrip,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Saving...' : 'Save Trip'),
                style: ElevatedButton.styleFrom(
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
    _distanceController.dispose();
    _memoController.dispose();
    super.dispose();
  }
}
