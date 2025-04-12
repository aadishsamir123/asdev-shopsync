import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MaintenanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>?> checkMaintenance() async {
    try {
      final doc =
          await _firestore.collection('maintenance').doc('status').get();

      if (doc.exists) {
        final data = doc.data()!;
        final startTime = data['startTime']?.toDate();

        return {
          'isUnderMaintenance': data['isUnderMaintenance'] ?? false,
          'message': data['message'] ?? '',
          'startTime': startTime,
          'endTime': data['endTime']?.toDate(),
          'isPredictive': !data['isUnderMaintenance'] &&
              (startTime != null && startTime.isAfter(DateTime.now())),
        };
      }
      return null;
    } catch (e) {
      SnackBar(
        content: Text('Error fetching maintenance status: $e'),
        backgroundColor: Colors.red,
      );
      return null;
    }
  }
}
