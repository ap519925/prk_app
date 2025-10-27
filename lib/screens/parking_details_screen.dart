import 'dart:io';
import 'package:flutter/material.dart';
import '../models/parking_spot.dart';

class ParkingDetailsScreen extends StatelessWidget {
  final ParkingSpot parkingSpot;
  final VoidCallback onDelete;
  final Function(ParkingSpot) onUpdate;

  const ParkingDetailsScreen({
    super.key,
    required this.parkingSpot,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmation(context);
            },
            tooltip: 'Delete parking spot',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo section
            if (parkingSpot.photoPath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(parkingSpot.photoPath!),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Location card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (parkingSpot.address != null)
                      Text(
                        parkingSpot.address!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      parkingSpot.coordinates,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (parkingSpot.city != null ||
                        parkingSpot.state != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${parkingSpot.city ?? ''}${parkingSpot.city != null && parkingSpot.state != null ? ', ' : ''}${parkingSpot.state ?? ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Time info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Time Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                        'Saved', _formatDateTime(parkingSpot.savedAt)),
                    if (parkingSpot.timerEnd != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        'Timer Expires',
                        _formatDateTime(parkingSpot.timerEnd!),
                      ),
                      const SizedBox(height: 8),
                      _buildTimeRemaining(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Parking alerts card
            if (parkingSpot.alerts != null &&
                parkingSpot.alerts!.isNotEmpty) ...[
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Parking Alerts (${parkingSpot.alerts!.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...parkingSpot.alerts!.map((alert) => Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(alert.emoji,
                                          style: const TextStyle(fontSize: 24)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          alert.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    alert.description,
                                    style:
                                        TextStyle(color: Colors.grey.shade700),
                                  ),
                                  if (alert.timeRange != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      alert.timeRange!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                  if (alert.source != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Source: ${alert.source}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildTimeRemaining() {
    final now = DateTime.now();
    final remaining = parkingSpot.timerEnd!.difference(now);

    Color color;
    IconData icon;
    String text;

    if (remaining.isNegative) {
      color = Colors.red;
      icon = Icons.error;
      text = 'EXPIRED ${_formatDuration(remaining.abs())} ago';
    } else if (remaining.inMinutes < 15) {
      color = Colors.red;
      icon = Icons.warning;
      text = '${_formatDuration(remaining)} remaining';
    } else if (remaining.inMinutes < 30) {
      color = Colors.orange;
      icon = Icons.warning_amber;
      text = '${_formatDuration(remaining)} remaining';
    } else {
      color = Colors.green;
      icon = Icons.check_circle;
      text = '${_formatDuration(remaining)} remaining';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Parking Spot?'),
        content: const Text(
            'Are you sure you want to delete this parking spot? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              onDelete(); // Call delete callback
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
