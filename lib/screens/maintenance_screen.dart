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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mainColor = isPredictive ? Colors.amber : Colors.orange;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            height: constraints.maxHeight,
            decoration: BoxDecoration(
              color: isDark ? colorScheme.background : mainColor.shade50,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 80,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isDark ? colorScheme.surface : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.3)
                                  : mainColor.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? mainColor.shade900
                                    : mainColor.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPredictive
                                    ? Icons.warning_rounded
                                    : Icons.build_rounded,
                                size: 48,
                                color: isDark
                                    ? mainColor.shade200
                                    : mainColor.shade800,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Center(
                              child: Text(
                                isPredictive
                                    ? 'Upcoming Maintenance'
                                    : 'Under Maintenance',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? mainColor.shade200
                                      : mainColor.shade900,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark
                                    ? colorScheme.onSurface.withOpacity(0.9)
                                    : colorScheme.onSurface.withOpacity(0.8),
                                height: 1.5,
                              ),
                            ),
                            if (startTime != null && endTime != null) ...[
                              const SizedBox(height: 32),
                              _buildTimeDisplay(mainColor, isDark),
                            ],
                            if (isPredictive) ...[
                              const SizedBox(height: 32),
                              FilledButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      isDark ? mainColor.shade800 : mainColor,
                                  minimumSize: const Size(200, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Understood',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeDisplay(MaterialColor mainColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : mainColor.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? mainColor.shade800 : mainColor.shade200,
        ),
      ),
      child: Column(
        children: [
          Text(
            isPredictive ? 'Scheduled Period' : 'Expected Duration',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? mainColor.shade200 : mainColor.shade900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                  child: _buildTimeCard(
                      _formatDate(startTime!), mainColor, isDark)),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward,
                  color: isDark ? mainColor.shade200 : mainColor.shade400),
              const SizedBox(width: 12),
              Expanded(
                  child:
                      _buildTimeCard(_formatDate(endTime!), mainColor, isDark)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'UTC Time Zone',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? mainColor.shade200 : mainColor.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(
      List<String> timeData, MaterialColor mainColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.black38 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? mainColor.shade800 : mainColor.shade200,
        ),
      ),
      child: Column(
        children: [
          Text(
            timeData[0],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? mainColor.shade200 : mainColor.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeData[1],
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _formatDate(DateTime dateTime) {
    return [
      DateFormat('MMM d, yyyy').format(dateTime),
      DateFormat('HH:mm').format(dateTime),
    ];
  }
}
