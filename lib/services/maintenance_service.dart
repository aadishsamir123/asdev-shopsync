import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>?> checkMaintenance() async {
    try {
      final doc =
          await _firestore.collection('maintenance').doc('status').get();

      if (doc.exists) {
        final data = doc.data()!;
        final now = DateTime.now();
        final startTime = data['startTime']?.toDate();

        return {
          'isUnderMaintenance': data['isUnderMaintenance'] ?? false,
          'message': data['message'] ?? '',
          'startTime': startTime,
          'endTime': data['endTime']?.toDate(),
          'isPredictive': !data['isUnderMaintenance'] &&
              startTime != null &&
              startTime.isAfter(now) &&
              startTime.difference(now).inDays <=
                  7, // Show notice if maintenance is within 7 days
        };
      }
      return null;
    } catch (e) {
      print('Error checking maintenance status: $e');
      return null;
    }
  }
}
