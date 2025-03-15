import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MaintenanceScreen extends StatelessWidget {
  final String message;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isPredictive;

  const MaintenanceScreen({
    super.key,
    required this.message,
    this.startTime,
    this.endTime,
    this.isPredictive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPredictive ? Icons.warning_rounded : Icons.build_rounded,
                size: 64,
                color: isPredictive ? Colors.amber : Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                isPredictive ? 'Upcoming Maintenance' : 'Under Maintenance',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              if (startTime != null && endTime != null) ...[
                const SizedBox(height: 16),
                Text(
                  isPredictive
                      ? 'Scheduled for:\n${_formatDateTime(startTime!)} -\n${_formatDateTime(endTime!)}'
                      : 'Expected duration:\n${_formatDateTime(startTime!)} -\n${_formatDateTime(endTime!)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
              if (isPredictive) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('MMM d, yyyy HH:mm');
    return formatter.format(dateTime);
  }
}
