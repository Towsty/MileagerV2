import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../models/trip.dart';
import '../providers/trip_provider.dart';
import '../providers/vehicle_provider.dart';
import '../services/trip_tracking_service.dart';
import '../services/report_service.dart';
import 'add_vehicle_screen.dart';
import 'add_trip_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailsScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().fetchTrips(vehicleId: widget.vehicle.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.vehicle.year} ${widget.vehicle.make} ${widget.vehicle.model}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: _generateMonthlyReport,
            tooltip: 'Generate Monthly Report',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddVehicleScreen(vehicle: widget.vehicle),
                ),
              ).then((_) {
                // Refresh the screen when returning from edit
                setState(() {});
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vehicle Photo
            if (widget.vehicle.photoPath != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(widget.vehicle.photoPath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Vehicle Information
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vehicle Information',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Nickname', widget.vehicle.nickname),
                          _buildInfoRow('Color', widget.vehicle.color),
                          _buildInfoRow('VIN', widget.vehicle.vin),
                          _buildInfoRow('License Plate', widget.vehicle.tag),
                          _buildInfoRow(
                            'Start',
                            '${widget.vehicle.startingOdometer.toStringAsFixed(0)} miles',
                          ),
                          if (widget.vehicle.bluetoothDeviceName != null)
                            _buildInfoRow(
                              'Bluetooth Device',
                              widget.vehicle.bluetoothDeviceName!,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quick Actions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    context
                                        .read<TripTrackingService>()
                                        .manualStartTrip(widget.vehicle);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Trip started manually!')),
                                    );
                                  },
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Start Trip'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddTripScreen(
                                            selectedVehicle: widget.vehicle),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Trip'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Trip History
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trip History',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<List<Trip>>(
                            stream: context
                                .read<TripProvider>()
                                .getTripsForVehicle(widget.vehicle.id),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                  child: Column(
                                    children: [
                                      const Icon(Icons.error,
                                          size: 48, color: Colors.red),
                                      const SizedBox(height: 8),
                                      Text('Error: ${snapshot.error}'),
                                    ],
                                  ),
                                );
                              }

                              if (!snapshot.hasData) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final trips = snapshot.data!;
                              if (trips.isEmpty) {
                                return Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.route,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No trips recorded yet',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Start tracking trips to see your mileage history',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.grey[500],
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final totalTripMiles = trips.fold<double>(
                                  0, (sum, trip) => sum + trip.distance);
                              final currentOdometer =
                                  widget.vehicle.startingOdometer +
                                      totalTripMiles;

                              return Column(
                                children: [
                                  // Trip summary
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                              '${trips.length}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const Text('Total Trips'),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              '${totalTripMiles.toStringAsFixed(1)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const Text('Total Miles'),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              '${currentOdometer.toStringAsFixed(0)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const Text('Odometer'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Trip list
                                  ...trips
                                      .take(5)
                                      .map((trip) => _buildTripCard(trip)),

                                  if (trips.length > 5)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: TextButton(
                                        onPressed: () {
                                          // TODO: Navigate to full trip history
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Full trip history coming soon!')),
                                          );
                                        },
                                        child: Text(
                                            'View all ${trips.length} trips'),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not specified',
              style: TextStyle(
                color: value != null ? null : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    final dateFormat = DateFormat('MMM d, y h:mm a');
    final purpose =
        trip.purpose?.toString().split('.').last ?? 'Unspecified Purpose';
    final icon = trip.purpose == TripPurpose.business
        ? Icons.work
        : Icons.directions_car;
    final iconColor =
        trip.purpose == TripPurpose.business ? Colors.blue : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          purpose
              .replaceAllMapped(
                  RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
              .trim(),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distance: ${trip.distance.toStringAsFixed(1)} miles'),
            Text(
              dateFormat.format(trip.startTime),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: trip.memo != null
            ? const Icon(Icons.note, color: Colors.orange)
            : null,
        onTap: trip.memo != null
            ? () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Trip Memo'),
                    content: Text(trip.memo!),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              }
            : null,
      ),
    );
  }

  void _generateMonthlyReport() async {
    final tripProvider = context.read<TripProvider>();
    final vehicleProvider = context.read<VehicleProvider>();

    // Get all trips for this vehicle
    final allTrips = tripProvider.trips
        .where((trip) => trip.vehicleId == widget.vehicle.id)
        .toList();

    if (allTrips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No trips found for this vehicle')),
      );
      return;
    }

    // Get available months
    final availableMonths =
        await ReportService.getAvailableReportMonths(allTrips);

    if (availableMonths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No trip data available for reports')),
      );
      return;
    }

    // Show month selector dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Month for Report'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableMonths.length,
              itemBuilder: (context, index) {
                final month = availableMonths[index];
                return ListTile(
                  title: Text(DateFormat('MMMM yyyy').format(month)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _selectReportAction(
                        month, allTrips, vehicleProvider.vehicles);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectReportAction(
      DateTime month, List<Trip> trips, List<Vehicle> vehicles) async {
    // Check if email reports are enabled
    final prefs = await SharedPreferences.getInstance();
    final emailEnabled = prefs.getBool('email_reports_enabled') ?? false;
    final emailAddress = prefs.getString('report_email_address') ?? '';

    final monthYear = DateFormat('MMMM yyyy').format(month);

    if (emailEnabled && emailAddress.isNotEmpty) {
      // Show dialog with both email and save options
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Generate Report for $monthYear'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How would you like to receive your report?'),
              const SizedBox(height: 16),

              // Email report option
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _emailReportForMonth(month, trips, vehicles, emailAddress);
                  },
                  icon: const Icon(Icons.email),
                  label: Text('Email to $emailAddress'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Opens your email app with the report attached and ready to send.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),

              const SizedBox(height: 16),

              // Save locally option
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _generateReportForMonth(month, trips, vehicles);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save to Device Only'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } else {
      // If email not configured, show setup message and generate normally
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Generate Report for $monthYear'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 48, color: Colors.blue),
              const SizedBox(height: 16),
              const Text('Want to email your reports automatically?'),
              const SizedBox(height: 8),
              const Text(
                'Set up email delivery in Settings to get reports sent directly to your email instead of searching for files on your phone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
              child: const Text('Go to Settings'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _generateReportForMonth(month, trips, vehicles);
              },
              child: const Text('Generate Report'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _emailReportForMonth(DateTime month, List<Trip> trips,
      List<Vehicle> vehicles, String emailAddress) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Preparing email...'),
            ],
          ),
        ),
      );

      // Generate the report with sharing enabled
      final filePath = await ReportService.generateAndShareMonthlyReport(
        trips: trips,
        vehicles: vehicles,
        month: month,
      );

      // Hide loading
      Navigator.pop(context);

      // Show success message with email info
      final monthYear = DateFormat('MMMM yyyy').format(month);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening email app with $monthYear report...'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Hide loading
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error preparing email: $e')),
      );
    }
  }

  Future<void> _generateReportForMonth(
      DateTime month, List<Trip> trips, List<Vehicle> vehicles) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating report...'),
            ],
          ),
        ),
      );

      // Generate the report
      final filePath = await ReportService.generateMonthlyReport(
        trips: trips,
        vehicles: vehicles,
        month: month,
      );

      // Hide loading
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report saved to: ${filePath.split('/').last}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Hide loading
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: const Text(
          'Are you sure you want to delete this vehicle? This action cannot be undone and will also delete all associated trip data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;

      try {
        await context.read<VehicleProvider>().deleteVehicle(widget.vehicle.id);
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle deleted successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete vehicle: $e')),
        );
      }
    }
  }
}
