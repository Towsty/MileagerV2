import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../models/trip.dart';
import '../providers/vehicle_provider.dart';
import '../providers/trip_provider.dart';
import '../services/location_service.dart';

class EditTripScreen extends StatefulWidget {
  final Trip trip;
  final Vehicle? vehicle;

  const EditTripScreen({super.key, required this.trip, this.vehicle});

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  Vehicle? _selectedVehicle;
  TripPurpose _selectedPurpose = TripPurpose.personal;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedStartTime = TimeOfDay.now();
  TimeOfDay? _selectedEndTime;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    _selectedVehicle = widget.vehicle;
    _selectedPurpose = widget.trip.purpose;
    _selectedDate = DateTime(
      widget.trip.startTime.year,
      widget.trip.startTime.month,
      widget.trip.startTime.day,
    );
    _selectedStartTime = TimeOfDay.fromDateTime(widget.trip.startTime);
    if (widget.trip.endTime != null &&
        widget.trip.endTime != widget.trip.startTime) {
      _selectedEndTime = TimeOfDay.fromDateTime(widget.trip.endTime!);
    }

    _distanceController.text = widget.trip.distance.toStringAsFixed(1);
    _memoController.text = widget.trip.memo ?? '';

    // Add listeners to detect changes
    _distanceController.addListener(() => setState(() => _hasChanges = true));
    _memoController.addListener(() => setState(() => _hasChanges = true));
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null && date != _selectedDate) {
      setState(() {
        _selectedDate = date;
        _hasChanges = true;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime,
    );
    if (time != null && time != _selectedStartTime) {
      setState(() {
        _selectedStartTime = time;
        _hasChanges = true;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ??
          TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))),
    );
    if (time != null && time != _selectedEndTime) {
      setState(() {
        _selectedEndTime = time;
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveChanges() async {
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
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedStartTime.hour,
        _selectedStartTime.minute,
      );

      DateTime? endDateTime;
      if (_selectedEndTime != null) {
        endDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedEndTime!.hour,
          _selectedEndTime!.minute,
        );

        // If end time is before start time, assume it's the next day
        if (endDateTime.isBefore(startDateTime)) {
          endDateTime = endDateTime.add(const Duration(days: 1));
        }
      }

      final updatedTrip = widget.trip.copyWith(
        vehicleId: _selectedVehicle!.id,
        startTime: startDateTime,
        endTime: endDateTime ?? startDateTime,
        distance: double.parse(_distanceController.text),
        purpose: _selectedPurpose,
        memo: _memoController.text.isEmpty ? null : _memoController.text,
      );

      await context.read<TripProvider>().updateTrip(updatedTrip);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip updated successfully!')),
        );
        Navigator.pop(
            context, true); // Return true to indicate changes were saved
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update trip: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cloneTrip() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedStartTime.hour,
        _selectedStartTime.minute,
      );

      DateTime? endDateTime;
      if (_selectedEndTime != null) {
        endDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedEndTime!.hour,
          _selectedEndTime!.minute,
        );

        if (endDateTime.isBefore(startDateTime)) {
          endDateTime = endDateTime.add(const Duration(days: 1));
        }
      }

      // Create a new trip with current form data
      final locationService = LocationService();
      await locationService.initialize();
      final currentLocation =
          locationService.getCurrentGeoPoint() ?? widget.trip.startLocation;

      final clonedTrip = Trip(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        vehicleId: _selectedVehicle!.id,
        startTime: startDateTime,
        endTime: endDateTime ?? startDateTime,
        distance: double.parse(_distanceController.text),
        purpose: _selectedPurpose,
        memo: _memoController.text.isEmpty
            ? null
            : '${_memoController.text} (Clone)',
        startLocation: currentLocation,
        endLocation: widget.trip.endLocation ?? currentLocation,
        isManualEntry: true, // Cloned trips are considered manual entries
        deviceName: widget.trip.deviceName,
        pausePeriods: [], // Don't clone pause periods
      );

      await context.read<TripProvider>().addCompletedTrip(clonedTrip);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip cloned successfully!')),
        );
        Navigator.pop(
            context, true); // Return true to indicate a new trip was added
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clone trip: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text(
            'Are you sure you want to delete this trip? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await context.read<TripProvider>().deleteTrip(widget.trip.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip deleted successfully!')),
          );
          Navigator.pop(
              context, true); // Return true to indicate trip was deleted
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete trip: $e')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
            'You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Trip'),
          actions: [
            // Save button
            IconButton(
              onPressed: _isLoading ? null : _saveChanges,
              icon: const Icon(Icons.save),
              tooltip: 'Save Changes',
            ),
            // Clone button
            IconButton(
              onPressed: _isLoading ? null : _cloneTrip,
              icon: const Icon(Icons.content_copy),
              tooltip: 'Clone Trip',
            ),
            // Delete button
            IconButton(
              onPressed: _isLoading ? null : _deleteTrip,
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Trip',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Original trip info card
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Original Trip Details',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Created: ${_formatDateTime(widget.trip.startTime)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          'Distance: ${widget.trip.distance.toStringAsFixed(1)} miles',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          'Type: ${widget.trip.isManualEntry ? 'Manual' : 'Tracked'}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

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
                                if (vehicle != _selectedVehicle) {
                                  setState(() {
                                    _selectedVehicle = vehicle;
                                    _hasChanges = true;
                                  });
                                }
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

                        // Date Selection
                        InkWell(
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

                        const SizedBox(height: 16),

                        // Time Selection
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _selectStartTime,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Start Time',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.access_time),
                                  ),
                                  child:
                                      Text(_selectedStartTime.format(context)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: _selectEndTime,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'End Time (Optional)',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.access_time),
                                  ),
                                  child: Text(
                                    _selectedEndTime?.format(context) ??
                                        'Same as start',
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
                            helperText:
                                'Adjusting distance will recalculate vehicle odometer',
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

                        // Purpose Selection
                        Text(
                          'Trip Purpose',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<TripPurpose>(
                          segments: TripPurpose.values.map((purpose) {
                            return ButtonSegment<TripPurpose>(
                              value: purpose,
                              label: Text(
                                purpose
                                    .toString()
                                    .split('.')
                                    .last
                                    .toUpperCase(),
                              ),
                              icon: Icon(
                                purpose == TripPurpose.business
                                    ? Icons.work
                                    : Icons.home,
                              ),
                            );
                          }).toList(),
                          selected: {_selectedPurpose},
                          onSelectionChanged: (Set<TripPurpose> selection) {
                            if (selection.first != _selectedPurpose) {
                              setState(() {
                                _selectedPurpose = selection.first;
                                _hasChanges = true;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        // Memo
                        TextFormField(
                          controller: _memoController,
                          decoration: InputDecoration(
                            labelText: _selectedPurpose == TripPurpose.business
                                ? 'Memo (required for business)'
                                : 'Memo (optional)',
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.note),
                            hintText: 'Add notes about this trip...',
                            helperText: _selectedPurpose == TripPurpose.business
                                ? 'Business trips require a memo for tax purposes'
                                : null,
                          ),
                          maxLines: 3,
                          maxLength: 500,
                          validator: (value) {
                            if (_selectedPurpose == TripPurpose.business &&
                                (value?.trim().isEmpty ?? true)) {
                              return 'Memo is required for business trips';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _cloneTrip,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.content_copy),
                        label: Text(_isLoading ? 'Cloning...' : 'Clone Trip'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            (_isLoading || !_hasChanges) ? null : _saveChanges,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Delete Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _deleteTrip,
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete Trip'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _memoController.dispose();
    super.dispose();
  }
}
