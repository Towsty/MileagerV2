import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../models/vehicle.dart';

class TripConfirmationDialog extends StatefulWidget {
  final Trip trip;
  final Vehicle vehicle;
  final Function(TripPurpose purpose, String? memo, double? adjustedDistance)
      onConfirm;
  final VoidCallback onCancel;

  const TripConfirmationDialog({
    super.key,
    required this.trip,
    required this.vehicle,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<TripConfirmationDialog> createState() => _TripConfirmationDialogState();
}

class _TripConfirmationDialogState extends State<TripConfirmationDialog> {
  late TripPurpose _selectedPurpose;
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPurpose = widget.trip.purpose;
    _memoController.text = widget.trip.memo ?? '';
    _distanceController.text = widget.trip.distance.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.trip.endTime != null
        ? widget.trip.endTime!.difference(widget.trip.startTime)
        : Duration.zero;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.trip_origin,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trip Completed',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${widget.vehicle.year} ${widget.vehicle.make} ${widget.vehicle.model}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Trip Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            icon: Icons.access_time,
                            label: 'Duration',
                            value: _formatDuration(duration),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            icon: Icons.straighten,
                            label: 'Distance',
                            value:
                                '${widget.trip.distance.toStringAsFixed(1)} mi',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            icon: Icons.play_arrow,
                            label: 'Started',
                            value: _formatTime(widget.trip.startTime),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            icon: Icons.stop,
                            label: 'Ended',
                            value: widget.trip.endTime != null
                                ? _formatTime(widget.trip.endTime!)
                                : 'Now',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Adjustable Distance
              Text(
                'Adjust Distance (if needed)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _distanceController,
                decoration: const InputDecoration(
                  labelText: 'Distance (miles)',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.edit),
                  helperText: 'Tap to adjust if GPS tracking was inaccurate',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: 16),

              // Purpose Selection
              Text(
                'Trip Purpose',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildPurposeCard(
                      purpose: TripPurpose.business,
                      icon: Icons.work,
                      color: Colors.blue,
                      label: 'Business',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPurposeCard(
                      purpose: TripPurpose.personal,
                      icon: Icons.home,
                      color: Colors.green,
                      label: 'Personal',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Memo
              Text(
                'Add Notes (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _memoController,
                decoration: const InputDecoration(
                  labelText: 'Trip notes',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Client meeting, grocery shopping...',
                ),
                maxLines: 2,
                maxLength: 200,
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : widget.onCancel,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _confirmTrip,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isLoading ? 'Saving...' : 'Confirm Trip'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPurposeCard({
    required TripPurpose purpose,
    required IconData icon,
    required Color color,
    required String label,
  }) {
    final isSelected = _selectedPurpose == purpose;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPurpose = purpose;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmTrip() {
    setState(() {
      _isLoading = true;
    });

    final adjustedDistance = double.tryParse(_distanceController.text);
    final memo = _memoController.text.trim().isEmpty
        ? null
        : _memoController.text.trim();

    widget.onConfirm(_selectedPurpose, memo, adjustedDistance);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _memoController.dispose();
    _distanceController.dispose();
    super.dispose();
  }
}
