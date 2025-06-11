import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_widget/home_widget.dart';
import 'package:mileager/providers/vehicle_provider.dart';
import 'package:mileager/providers/trip_provider.dart';
import 'package:mileager/services/location_service.dart';
import 'package:mileager/services/trip_tracking_service.dart';
import 'package:mileager/models/vehicle.dart';
import 'package:mileager/models/trip.dart';
import 'package:mileager/screens/add_vehicle_screen.dart';
import 'package:mileager/screens/add_trip_screen.dart';
import 'package:mileager/screens/vehicle_details_screen.dart';
import 'package:mileager/widgets/status_lights.dart';
import 'package:mileager/screens/trip_history_screen.dart';
import 'package:mileager/screens/settings_screen.dart';
import 'package:mileager/utils/string_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mileager/services/trip_widget_service.dart';
import 'edit_trip_screen.dart';

// Top-level background callback for widget button presses
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri == null) return;

  print('Widget background callback: ${uri.toString()}');

  try {
    if (uri.scheme == 'widget') {
      switch (uri.path) {
        case '/trip/toggle':
          await _handleBackgroundTripToggle();
          break;
        case '/trip/pause':
          await _handleBackgroundTripPause();
          break;
        default:
          print('Unknown widget action: ${uri.path}');
      }
    }
  } catch (e) {
    print('Error in background callback: $e');
  }
}

Future<void> _handleBackgroundTripToggle() async {
  try {
    // Read current trip state from widget data
    final isTracking =
        await HomeWidget.getWidgetData<bool>('is_tracking') ?? false;

    if (isTracking) {
      // Stop trip
      await HomeWidget.saveWidgetData('is_tracking', false);
      await HomeWidget.saveWidgetData('trip_status', 'Not Active');
      await HomeWidget.saveWidgetData('trip_distance', '0.0 mi');
      await HomeWidget.saveWidgetData('trip_duration', '00:00');
      print('Trip stopped from widget background');
    } else {
      // Start trip
      await HomeWidget.saveWidgetData('is_tracking', true);
      await HomeWidget.saveWidgetData('trip_status', 'Active');
      await HomeWidget.saveWidgetData('trip_distance', '0.0 mi');
      await HomeWidget.saveWidgetData('trip_duration', '00:00');
      print('Trip started from widget background');
    }

    // Update widget display
    await HomeWidget.updateWidget(
        name: 'trip_widget', androidName: 'TripWidgetProvider');
  } catch (e) {
    print('Error handling background trip toggle: $e');
  }
}

Future<void> _handleBackgroundTripPause() async {
  try {
    // Read current state
    final isTracking =
        await HomeWidget.getWidgetData<bool>('is_tracking') ?? false;
    final isPaused = await HomeWidget.getWidgetData<bool>('is_paused') ?? false;

    if (isTracking) {
      if (isPaused) {
        // Resume trip
        await HomeWidget.saveWidgetData('is_paused', false);
        await HomeWidget.saveWidgetData('trip_status', 'Active');
        print('Trip resumed from widget background');
      } else {
        // Pause trip
        await HomeWidget.saveWidgetData('is_paused', true);
        await HomeWidget.saveWidgetData('trip_status', 'Paused');
        print('Trip paused from widget background');
      }

      // Update widget display
      await HomeWidget.updateWidget(
          name: 'trip_widget', androidName: 'TripWidgetProvider');
    }
  } catch (e) {
    print('Error handling background trip pause: $e');
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TripWidgetService _widgetService = TripWidgetService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _initializeWidget();
      _checkIncomingIntent();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Update widget when app comes to foreground
      _widgetService.updateWidget();
    }
  }

  Future<void> _checkIncomingIntent() async {
    try {
      // Check if app was launched from widget
      final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initialUri != null) {
        print('App launched from widget with URI: $initialUri');
        await _handleWidgetAction(initialUri);
      }
    } catch (e) {
      print('Error checking incoming intent: $e');
    }
  }

  Future<void> _handleWidgetAction(Uri uri) async {
    print('Handling widget action: ${uri.toString()}');

    if (uri.scheme == 'widget' || uri.scheme == 'mileager') {
      switch (uri.path) {
        case '/trip/toggle':
          await _handleTripToggle();
          break;
        case '/trip/pause':
          await _handleTripPause();
          break;
        default:
          print('Unknown widget action: ${uri.path}');
      }
    }
  }

  Future<void> _initializeWidget() async {
    try {
      await _widgetService.initialize(context);
      _setupWidgetCallbacks();
      print('Widget service initialized successfully');
    } catch (e) {
      print('Error initializing trip widget: $e');
    }
  }

  void _setupWidgetCallbacks() {
    HomeWidget.setAppGroupId('group.com.echoseofnumenor.mileager');
    // Register background callback for widget button presses
    HomeWidget.registerInteractivityCallback(backgroundCallback);
    print('Widget callbacks setup - registered background callback');
  }

  Future<void> _widgetCallback(Uri? uri) async {
    if (uri == null) return;
    print('Widget callback received: ${uri.toString()}');

    if (uri.scheme == 'mileager') {
      switch (uri.path) {
        case '/trip/toggle':
          await _handleTripToggle();
          break;
        case '/trip/pause':
          await _handleTripPause();
          break;
        default:
          print('Unknown widget action: ${uri.path}');
      }
    }
  }

  Future<void> _handleTripToggle() async {
    final tripService =
        Provider.of<TripTrackingService>(context, listen: false);
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);

    try {
      if (tripService.isTracking) {
        // Stop current trip
        await tripService.endCurrentTrip();
        print('Trip stopped from widget');
      } else {
        // Start new trip
        if (vehicleProvider.vehicles.isNotEmpty) {
          final vehicle = vehicleProvider.vehicles.first;
          await tripService.startManualTrip(vehicle);
          print('Trip started from widget');
        } else {
          print('No vehicles available to start trip');
        }
      }

      // Update widget with new data
      await _widgetService.updateWidget();
    } catch (e) {
      print('Error handling trip toggle: $e');
    }
  }

  Future<void> _handleTripPause() async {
    final tripService =
        Provider.of<TripTrackingService>(context, listen: false);

    try {
      if (tripService.isTracking) {
        if (tripService.isPaused) {
          await tripService.resumeTrip();
          print('Trip resumed from widget');
        } else {
          await tripService.pauseTrip();
          print('Trip paused from widget');
        }

        // Update widget with new data
        await _widgetService.updateWidget();
      }
    } catch (e) {
      print('Error handling trip pause: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _widgetService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await context.read<VehicleProvider>().loadVehicles();
      await context.read<TripProvider>().fetchTrips();
      await context.read<LocationService>().initialize();
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mileager'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          Consumer2<LocationService, TripTrackingService>(
            builder: (context, locationService, tripTrackingService, child) {
              return StatusLights(
                tripStatus: tripTrackingService.isTracking
                    ? StatusLightState.active
                    : StatusLightState.inactive,
                gpsStatus: locationService.hasLocation
                    ? (locationService.isHighPrecisionMode
                        ? StatusLightState.active
                        : StatusLightState.connecting)
                    : (locationService.isConnecting
                        ? StatusLightState.connecting
                        : StatusLightState.inactive),
                bluetoothStatus: StatusLightState
                    .inactive, // TODO: Connect to Bluetooth service
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Consumer<TripTrackingService>(
            builder: (context, tripTrackingService, child) {
              final isTracking = tripTrackingService.isTracking;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickStatsSection(),
                  const SizedBox(height: 24),
                  _buildTripProgressSection(),
                  if (isTracking) const SizedBox(height: 24),
                  _buildVehiclesSection(),
                  const SizedBox(height: 24),
                  _buildRecentTripsSection(),
                  const SizedBox(height: 24),
                  _buildQuickActionsSection(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Consumer2<VehicleProvider, TripProvider>(
      builder: (context, vehicleProvider, tripProvider, child) {
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                    'Vehicles',
                    '${vehicleProvider.vehicles.length}',
                    Icons.directions_car,
                    Colors.blue),
                _buildStatColumn('Trips', '${tripProvider.trips.length}',
                    Icons.route, Colors.green),
                _buildStatColumn(
                    'Miles',
                    '${_getTotalMiles(tripProvider.trips).toStringAsFixed(1)}',
                    Icons.timeline,
                    Colors.orange),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTripProgressSection() {
    return Consumer<TripTrackingService>(
      builder: (context, tripTrackingService, child) {
        final currentTrip = tripTrackingService.currentTrip;
        final distance = tripTrackingService.totalDistance;
        final isPaused = tripTrackingService.isPaused;
        final isTracking = tripTrackingService.isTracking;
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        // Only show the widget when there's an active trip
        if (!isTracking) {
          return const SizedBox.shrink();
        }

        // Calculate active duration (excluding paused time)
        Duration activeDuration = Duration.zero;
        if (currentTrip != null) {
          final totalDuration =
              DateTime.now().difference(currentTrip.startTime);
          final pausedDuration = currentTrip.totalPausedDuration;
          activeDuration = totalDuration - pausedDuration;
        }

        // Determine status and colors based on theme
        String statusText;
        IconData statusIcon;
        Color statusColor;

        if (isPaused) {
          statusText = 'Trip Paused';
          statusIcon = Icons.pause_circle;
          statusColor = Colors.orange;
        } else {
          statusText = 'Trip in Progress';
          statusIcon = Icons.directions_car;
          statusColor = Colors.green;
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: statusColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        statusText,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _endCurrentTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('End Trip'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${distance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Miles',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          _formatDuration(activeDuration),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Active Time',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isPaused ? _resumeTrip : _pauseTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isPaused ? Colors.green[600] : Colors.orange[600],
                          foregroundColor: Colors.white,
                        ),
                        icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                        label: Text(isPaused ? 'Resume Trip' : 'Pause Trip'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildVehiclesSection() {
    return Consumer<VehicleProvider>(
      builder: (context, vehicleProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Vehicles',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddVehicleScreen(),
                      ),
                    ).then((_) => _loadData());
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Vehicle'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (vehicleProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (vehicleProvider.error != null)
              _buildErrorCard(
                  vehicleProvider.error!, () => vehicleProvider.loadVehicles())
            else if (vehicleProvider.vehicles.isEmpty)
              _buildEmptyVehiclesCard()
            else
              ...vehicleProvider.vehicles
                  .map((vehicle) => _buildVehicleCard(vehicle)),
          ],
        );
      },
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, child) {
        // Force fresh calculation by getting trips for this specific vehicle
        final vehicleTrips = tripProvider.trips
            .where((trip) => trip.vehicleId == vehicle.id)
            .toList();
        final totalTripMiles =
            vehicleTrips.fold(0.0, (sum, trip) => sum + (trip.distance ?? 0.0));
        final currentOdometer = vehicle.startingOdometer + totalTripMiles;

        // Debug logging to help track odometer updates
        print(
            'Vehicle ${vehicle.make} ${vehicle.model}: ${vehicleTrips.length} trips, ${totalTripMiles.toStringAsFixed(2)} miles, odometer: ${currentOdometer.toStringAsFixed(0)}');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            leading: _buildVehiclePhoto(vehicle),
            title: Text(
              '${vehicle.year} ${vehicle.make} ${vehicle.model}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Odometer: ${currentOdometer.toStringAsFixed(0)} miles'),
                if (vehicle.nickname != null)
                  Text('Nickname: ${vehicle.nickname}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${vehicleTrips.length} trips',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VehicleDetailsScreen(vehicle: vehicle),
                ),
              ).then((_) => _loadData());
            },
          ),
        );
      },
    );
  }

  Widget _buildVehiclePhoto(Vehicle vehicle) {
    if (vehicle.photoPath != null && vehicle.photoPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(
          File(vehicle.photoPath!),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.directions_car, color: Colors.white),
            );
          },
        ),
      );
    } else {
      return CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.directions_car, color: Colors.white),
      );
    }
  }

  Widget _buildRecentTripsSection() {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, child) {
        final recentTrips = tripProvider.trips.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Trips',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (tripProvider.trips.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TripHistoryScreen(),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (tripProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (tripProvider.trips.isEmpty)
              _buildEmptyTripsCard()
            else
              ...recentTrips.map((trip) => _buildTripCard(trip)),
          ],
        );
      },
    );
  }

  Widget _buildTripCard(Trip trip) {
    return Consumer<VehicleProvider>(
      builder: (context, vehicleProvider, child) {
        final vehicle = vehicleProvider.vehicles
            .where((v) => v.id == trip.vehicleId)
            .firstOrNull;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: trip.purpose == TripPurpose.business
                  ? Colors.blue
                  : Colors.green,
              child: Icon(
                trip.purpose == TripPurpose.business ? Icons.work : Icons.home,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text('${trip.distance?.toStringAsFixed(1)} miles'),
            subtitle: Text(
              '${_formatDateTime(trip.startTime)} • ${trip.purpose.toString().split('.').last}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTripDetails(trip, vehicle),
          ),
        );
      },
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

  void _editTrip(Trip trip, Vehicle? vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTripScreen(trip: trip, vehicle: vehicle),
      ),
    ).then((result) {
      // If changes were made, refresh the data to update odometer calculations
      if (result == true) {
        _loadData();
      }
    });
  }

  Widget _buildEmptyVehiclesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No vehicles yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first vehicle to start tracking trips',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddVehicleScreen(),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTripsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.route_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No trips yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking your trips by adding vehicles',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error, VoidCallback onRetry) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text('Error: $error'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            Consumer<TripTrackingService>(
              builder: (context, tripTrackingService, child) {
                return _buildActionCard(
                  tripTrackingService.isTracking ? 'End Trip' : 'Start Trip',
                  tripTrackingService.isTracking
                      ? Icons.stop_circle
                      : Icons.play_circle,
                  tripTrackingService.isTracking ? Colors.red : Colors.green,
                  tripTrackingService.isTracking ? _endCurrentTrip : _startTrip,
                );
              },
            ),
            _buildActionCard(
              'Manual Trip',
              Icons.edit_road,
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTripScreen(),
                  ),
                ).then((_) => _loadData());
              },
            ),
            _buildActionCard(
              'Trip History',
              Icons.history,
              Colors.orange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TripHistoryScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              'Settings',
              Icons.settings,
              Colors.purple,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startTrip() async {
    final vehicles = context.read<VehicleProvider>().vehicles;
    if (vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a vehicle first')),
      );
      return;
    }

    // For now, just start tracking without selecting a vehicle
    // The vehicle will be selected when the trip ends
    final tripTrackingService = context.read<TripTrackingService>();
    await tripTrackingService.startManualTrip(vehicles.first);
  }

  void _endCurrentTrip() async {
    final tripTrackingService = context.read<TripTrackingService>();
    if (!tripTrackingService.isTracking ||
        tripTrackingService.currentTrip == null) {
      return;
    }

    await tripTrackingService.endCurrentTrip();

    // Show the completion dialog
    if (mounted) {
      _showTripCompletionDialog();
    }
  }

  void _pauseTrip() async {
    final tripTrackingService = context.read<TripTrackingService>();
    if (!tripTrackingService.isTracking || tripTrackingService.isPaused) {
      return;
    }

    await tripTrackingService.pauseTrip();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip paused - tracking stopped'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _resumeTrip() async {
    final tripTrackingService = context.read<TripTrackingService>();
    if (!tripTrackingService.isTracking || !tripTrackingService.isPaused) {
      return;
    }

    await tripTrackingService.resumeTrip();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip resumed - tracking active'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showTripCompletionDialog() {
    final tripTrackingService = context.read<TripTrackingService>();
    final pendingTrip = tripTrackingService.pendingConfirmationTrip;

    if (pendingTrip == null) return;

    final vehicles = context.read<VehicleProvider>().vehicles;
    Vehicle? selectedVehicle = vehicles.isNotEmpty ? vehicles.first : null;
    TripPurpose selectedPurpose = TripPurpose.personal; // Default to personal
    String memo = '';
    final memoController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Complete Trip'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Distance: ${pendingTrip.distance?.toStringAsFixed(2)} miles'),
                  Text(
                      'Duration: ${_formatDuration(pendingTrip.endTime!.difference(pendingTrip.startTime))}'),
                  const SizedBox(height: 16),

                  // Vehicle selection
                  DropdownButtonFormField<Vehicle>(
                    value: selectedVehicle,
                    decoration: const InputDecoration(labelText: 'Vehicle'),
                    items: vehicles.map((vehicle) {
                      return DropdownMenuItem(
                        value: vehicle,
                        child: Text(
                            '${vehicle.year} ${vehicle.make} ${vehicle.model}'),
                      );
                    }).toList(),
                    onChanged: (vehicle) {
                      setState(() {
                        selectedVehicle = vehicle;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Purpose selection with toggle buttons
                  const Text('Trip Purpose:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedPurpose = TripPurpose.personal;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedPurpose == TripPurpose.personal
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[200],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                              border: Border.all(
                                color: selectedPurpose == TripPurpose.personal
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[400]!,
                              ),
                            ),
                            child: Text(
                              'Personal',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selectedPurpose == TripPurpose.personal
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedPurpose = TripPurpose.business;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedPurpose == TripPurpose.business
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[200],
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              border: Border.all(
                                color: selectedPurpose == TripPurpose.business
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[400]!,
                              ),
                            ),
                            child: Text(
                              'Business',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selectedPurpose == TripPurpose.business
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Memo field
                  TextField(
                    controller: memoController,
                    decoration: InputDecoration(
                      labelText: selectedPurpose == TripPurpose.business
                          ? 'Memo (required for business)'
                          : 'Memo (optional)',
                      hintText: 'Enter trip details...',
                      errorText: selectedPurpose == TripPurpose.business &&
                              memo.trim().isEmpty
                          ? 'Memo is required for business trips'
                          : null,
                    ),
                    maxLines: 2,
                    onChanged: (value) {
                      setState(() {
                        memo = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Discard the trip
                    tripTrackingService.discardPendingTrip();
                  },
                  child: const Text('Discard'),
                ),
                ElevatedButton(
                  onPressed: selectedVehicle == null ||
                          (selectedPurpose == TripPurpose.business &&
                              memo.trim().isEmpty)
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await _saveTripToFirestore(pendingTrip,
                              selectedVehicle!, selectedPurpose, memo);
                        },
                  child: const Text('Save Trip'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveTripToFirestore(
      Trip trip, Vehicle vehicle, TripPurpose purpose, String memo) async {
    try {
      final updatedTrip = trip.copyWith(
        vehicleId: vehicle.id,
        purpose: purpose,
        memo: memo.isNotEmpty ? memo : null,
      );

      // Save to Firestore via TripProvider using the new method
      await context.read<TripProvider>().addCompletedTrip(updatedTrip);

      // Clear the pending trip
      context.read<TripTrackingService>().discardPendingTrip();

      // Force refresh the UI to update odometer readings
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving trip: $e')),
      );
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  double _getTotalMiles(List<Trip> trips) {
    return trips.fold(0.0, (sum, trip) => sum + (trip.distance ?? 0.0));
  }

  int _getThisMonthTrips(List<Trip> trips) {
    final now = DateTime.now();
    return trips.where((trip) {
      return trip.startTime.year == now.year &&
          trip.startTime.month == now.month;
    }).length;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
