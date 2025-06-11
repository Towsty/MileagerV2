import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/trip_tracking_service.dart';
import '../services/bluetooth_service.dart';
import '../services/location_service.dart';

enum StatusLightState {
  inactive, // Red
  connecting, // Flashing yellow
  active // Green
}

class StatusLights extends StatefulWidget {
  final StatusLightState tripStatus;
  final StatusLightState gpsStatus;
  final StatusLightState bluetoothStatus;

  const StatusLights({
    super.key,
    required this.tripStatus,
    required this.gpsStatus,
    required this.bluetoothStatus,
  });

  @override
  State<StatusLights> createState() => _StatusLightsState();
}

class _StatusLightsState extends State<StatusLights>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  bool _isExpanded = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.repeat(reverse: true);

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _expandController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _expandController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _showExpandedView() {
    if (_isExpanded) return;

    setState(() {
      _isExpanded = true;
    });

    HapticFeedback.mediumImpact();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildExpandedOverlay(position, renderBox.size),
    );

    overlay.insert(_overlayEntry!);
    _expandController.forward();
  }

  void _hideExpandedView() {
    if (!_isExpanded) return;

    setState(() {
      _isExpanded = false;
    });

    _expandController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  Widget _buildExpandedOverlay(Offset position, Size size) {
    return Positioned(
      left: 20,
      top: 100,
      right: 20,
      child: GestureDetector(
        onTap: _hideExpandedView,
        child: Material(
          color: Colors.transparent,
          child: AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _expandAnimation.value,
                child: Container(
                  constraints: BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'System Status',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCompactStatusLight(
                            state: widget.tripStatus,
                            icon: Icons.trip_origin,
                            label: 'Trip',
                            onTap: () => _handleTripStatusTap(),
                            details: _getTripDetails(),
                          ),
                          _buildCompactStatusLight(
                            state: widget.gpsStatus,
                            icon: Icons.gps_fixed,
                            label: 'GPS',
                            onTap: () => _handleGpsStatusTap(),
                            details: _getGpsDetails(),
                          ),
                          _buildCompactStatusLight(
                            state: widget.bluetoothStatus,
                            icon: Icons.bluetooth,
                            label: 'Bluetooth',
                            onTap: () => _handleBluetoothStatusTap(),
                            details: _getBluetoothDetails(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap for details • Touch outside to close',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatusLight({
    required StatusLightState state,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Map<String, String> details,
  }) {
    Color color;
    switch (state) {
      case StatusLightState.inactive:
        color = Colors.red;
        break;
      case StatusLightState.connecting:
        color = Colors.orange;
        break;
      case StatusLightState.active:
        color = Colors.green;
        break;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            // Show just the first detail as a preview
            if (details.isNotEmpty) ...[
              Text(
                details.values.first,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 8,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, String> _getTripDetails() {
    return {
      'Status': _getTripStatusText(),
      'Distance': _getCurrentTripDistance(),
      'Duration': _getCurrentTripDuration(),
    };
  }

  Map<String, String> _getGpsDetails() {
    final locationService = context.read<LocationService>();
    return {
      'Mode': locationService.isHighPrecisionMode
          ? 'High Precision'
          : 'Power Saving',
      'Accuracy': _getGpsAccuracy(),
      'Last Update': _getLastGpsUpdate(),
    };
  }

  Map<String, String> _getBluetoothDetails() {
    final bluetoothService = context.read<BluetoothService>();
    return {
      'Device': _getConnectedDevice(),
      'Signal': _getBluetoothSignal(),
      'RSSI': bluetoothService.rssi != null
          ? '${bluetoothService.rssi} dBm'
          : 'Unknown',
    };
  }

  Future<void> _handleTripStatusTap() async {
    final tripService = context.read<TripTrackingService>();

    if (tripService.isTracking) {
      _showStatusDialog(
        'Trip Status',
        'Currently tracking: ${tripService.currentVehicle?.make ?? 'Unknown'} ${tripService.currentVehicle?.model ?? ''}\n\n'
            'Distance: ${tripService.totalDistance.toStringAsFixed(1)} miles\n'
            'Duration: ${_getCurrentTripDuration()}\n'
            'GPS Points: ${tripService.routePoints.length}',
        [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Trip'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              tripService.manualStopTrip();
            },
            child: const Text('Stop Trip'),
          ),
        ],
      );
    } else {
      _showStatusDialog(
        'Trip Status',
        'No active trip\n\nTo start automatic tracking:\n'
            '• Connect to vehicle Bluetooth\n'
            '• Or manually start from vehicle details',
        [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }
  }

  Future<void> _handleGpsStatusTap() async {
    final locationPermission = await Permission.location.status;

    if (locationPermission.isDenied) {
      _showPermissionDialog(
        'Location Permission Required',
        'Location access is needed for accurate trip tracking and mileage calculation.',
        () async {
          final result = await Permission.location.request();
          if (result.isGranted) {
            context.read<LocationService>().initialize();
          }
        },
      );
    } else if (locationPermission.isPermanentlyDenied) {
      _showPermissionDialog(
        'Location Permission Denied',
        'Location permission was permanently denied. Please enable it in Settings.',
        () => openAppSettings(),
      );
    } else {
      final locationService = context.read<LocationService>();
      final precisionMode = locationService.isHighPrecisionMode
          ? 'High Precision'
          : 'Power Saving';
      final statusColor =
          locationService.isHighPrecisionMode ? 'Green' : 'Yellow';

      _showStatusDialog(
        'GPS Status',
        'Location: ${locationService.hasLocation ? 'Active' : 'Inactive'}\n'
            'Mode: $precisionMode ($statusColor)\n'
            'Accuracy: ${_getGpsAccuracy()}\n'
            'Last Update: ${_getLastGpsUpdate()}\n\n'
            'GPS Modes:\n'
            '• Yellow: Power saving mode\n'
            '• Green: High precision (during trips)\n\n'
            'GPS is used for:\n'
            '• Trip distance calculation\n'
            '• Route tracking\n'
            '• Location-based features',
        [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }
  }

  Future<void> _handleBluetoothStatusTap() async {
    final bluetoothPermission = await Permission.bluetooth.status;

    if (bluetoothPermission.isDenied) {
      _showPermissionDialog(
        'Bluetooth Permission Required',
        'Bluetooth access is needed for automatic trip detection when connecting to your vehicle.',
        () async {
          await Permission.bluetooth.request();
          await Permission.bluetoothConnect.request();
          await Permission.bluetoothScan.request();
        },
      );
    } else {
      final bluetoothService = context.read<BluetoothService>();
      _showStatusDialog(
        'Bluetooth Status',
        'Connection: ${bluetoothService.isConnected ? 'Connected' : 'Disconnected'}\n'
            'Device: ${_getConnectedDevice()}\n'
            'Signal: ${_getBluetoothSignal()}\n\n'
            'Bluetooth is used for:\n'
            '• Automatic trip detection\n'
            '• Vehicle identification\n'
            '• Hands-free operation',
        [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }
  }

  void _showPermissionDialog(
      String title, String message, VoidCallback onEnable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onEnable();
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(String title, String message, List<Widget> actions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: actions,
      ),
    );
  }

  // Helper methods for getting current status details
  String _getTripStatusText() {
    switch (widget.tripStatus) {
      case StatusLightState.inactive:
        return 'Inactive';
      case StatusLightState.connecting:
        return 'Starting';
      case StatusLightState.active:
        return 'Active';
    }
  }

  String _getCurrentTripDistance() {
    final tripService = context.read<TripTrackingService>();
    return tripService.isTracking
        ? '${tripService.totalDistance.toStringAsFixed(1)} mi'
        : '0.0 mi';
  }

  String _getCurrentTripDuration() {
    final tripService = context.read<TripTrackingService>();
    if (!tripService.isTracking || tripService.currentTrip == null) {
      return '0m';
    }

    final duration =
        DateTime.now().difference(tripService.currentTrip!.startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _getGpsAccuracy() {
    final locationService = context.read<LocationService>();
    final accuracy = locationService.accuracy;
    if (accuracy != null) {
      return '${accuracy.toInt()}m';
    }
    return 'Unknown';
  }

  String _getSatelliteCount() {
    final locationService = context.read<LocationService>();
    return locationService.accuracyDescription;
  }

  String _getLastGpsUpdate() {
    final locationService = context.read<LocationService>();
    final lastUpdate = locationService.lastUpdateTime;
    if (lastUpdate != null) {
      final now = DateTime.now();
      final diff = now.difference(lastUpdate);

      if (diff.inSeconds < 60) {
        return '${diff.inSeconds}s ago';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else {
        return '${diff.inHours}h ago';
      }
    }
    return 'Never';
  }

  String _getConnectedDevice() {
    final bluetoothService = context.read<BluetoothService>();
    return bluetoothService.connectedDevice?.platformName ?? 'None';
  }

  String _getBluetoothSignal() {
    final bluetoothService = context.read<BluetoothService>();
    return bluetoothService.signalStrength;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _showExpandedView,
      onTap: _isExpanded ? _hideExpandedView : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _isExpanded
              ? Colors.black.withOpacity(0.9)
              : Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: _isExpanded
              ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusLight(
              state: widget.tripStatus,
              icon: Icons.trip_origin,
              tooltip: _getTripStatusTooltip(),
            ),
            const SizedBox(width: 6),
            _buildStatusLight(
              state: widget.gpsStatus,
              icon: Icons.gps_fixed,
              tooltip: _getGpsStatusTooltip(),
            ),
            const SizedBox(width: 6),
            _buildStatusLight(
              state: widget.bluetoothStatus,
              icon: Icons.bluetooth,
              tooltip: _getBluetoothStatusTooltip(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLight({
    required StatusLightState state,
    required IconData icon,
    required String tooltip,
  }) {
    Color color;
    Widget child;

    switch (state) {
      case StatusLightState.inactive:
        color = Colors.red;
        child = Icon(icon, color: color, size: 12);
        break;
      case StatusLightState.connecting:
        color = Colors.orange;
        child = AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Opacity(
              opacity: _animation.value,
              child: Icon(icon, color: color, size: 12),
            );
          },
        );
        break;
      case StatusLightState.active:
        color = Colors.green;
        child = Icon(icon, color: color, size: 12);
        break;
    }

    return Tooltip(
      message: '$tooltip\n\nLong press for details',
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.2),
          border: Border.all(color: color, width: 1),
        ),
        child: Center(child: child),
      ),
    );
  }

  String _getTripStatusTooltip() {
    switch (widget.tripStatus) {
      case StatusLightState.inactive:
        return 'No active trip';
      case StatusLightState.connecting:
        return 'Starting trip...';
      case StatusLightState.active:
        return 'Trip in progress';
    }
  }

  String _getGpsStatusTooltip() {
    switch (widget.gpsStatus) {
      case StatusLightState.inactive:
        return 'GPS unavailable';
      case StatusLightState.connecting:
        return 'Acquiring GPS...';
      case StatusLightState.active:
        return 'GPS connected';
    }
  }

  String _getBluetoothStatusTooltip() {
    switch (widget.bluetoothStatus) {
      case StatusLightState.inactive:
        return 'Bluetooth disconnected';
      case StatusLightState.connecting:
        return 'Connecting to Bluetooth...';
      case StatusLightState.active:
        return 'Bluetooth connected';
    }
  }
}
