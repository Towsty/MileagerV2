import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/activity_recognition_service.dart';
import '../services/trip_tracking_service.dart';

class DebugPanel extends StatelessWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ActivityRecognitionService, TripTrackingService>(
      builder: (context, activityService, tripService, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          color: Colors.orange.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bug_report, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Debug Panel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: activityService.debugMode,
                      onChanged: (value) {
                        activityService.toggleDebugMode();
                      },
                      activeColor: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Activity Detection',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusInfo(
                        'Status',
                        activityService.statusText,
                        activityService.isDriving ? Colors.green : Colors.grey,
                      ),
                    ),
                    Expanded(
                      child: _buildStatusInfo(
                        'Activity',
                        activityService.activityDescription,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: activityService.debugMode &&
                                !activityService.isDriving
                            ? () => activityService.debugStartDriving()
                            : null,
                        icon: const Icon(Icons.drive_eta, size: 16),
                        label: const Text('Start Driving'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: activityService.debugMode &&
                                activityService.isDriving
                            ? () => activityService.debugStopDriving()
                            : null,
                        icon: const Icon(Icons.stop, size: 16),
                        label: const Text('Stop Driving'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (tripService.isTracking) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Current Trip',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusInfo(
                          'Distance',
                          '${tripService.totalDistance.toStringAsFixed(1)} mi',
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildStatusInfo(
                          'GPS Points',
                          '${tripService.routePoints.length}',
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Debug mode allows manual control of activity detection. '
                  'Toggle debug mode and use the buttons to simulate driving detection.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusInfo(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.darker(),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darker() {
    return Color.fromARGB(
      alpha,
      (red * 0.7).round(),
      (green * 0.7).round(),
      (blue * 0.7).round(),
    );
  }
}
