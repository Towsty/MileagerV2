import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mileager/providers/trip_provider.dart';
import 'package:mileager/services/location_service.dart';
import 'package:mileager/services/bluetooth_service.dart';

class StatusIndicators extends StatelessWidget {
  const StatusIndicators({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIndicator(
          context,
          'Trip Status',
          context.watch<TripProvider>().activeTrip != null,
          isFlashing: false,
        ),
        const SizedBox(width: 8),
        _buildIndicator(
          context,
          'GPS Status',
          context.watch<LocationService>().hasLocation,
          isFlashing: context.watch<LocationService>().isConnecting,
        ),
        const SizedBox(width: 8),
        _buildIndicator(
          context,
          'Bluetooth Status',
          context.watch<BluetoothService>().isConnected,
          isFlashing: context.watch<BluetoothService>().isConnecting,
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildIndicator(
    BuildContext context,
    String tooltip,
    bool isActive, {
    bool isFlashing = false,
  }) {
    Color color;
    if (isFlashing) {
      color = Colors.yellow;
    } else if (isActive) {
      color = Colors.green;
    } else {
      color = Colors.red;
    }

    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: isFlashing ? 4 : 2,
              spreadRadius: isFlashing ? 2 : 1,
            ),
          ],
        ),
      ),
    );
  }
}
