import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ExportService {
  static Future<void> exportList(String listId, String listName) async {
    final firestore = FirebaseFirestore.instance;

    // Get all items in the list
    final items = await firestore
        .collection('lists')
        .doc(listId)
        .collection('items')
        .get();

    // Create CSV data with new column order
    String csvData = 'Item,Status,Deadline,Added By,Added Date\n';

    for (var doc in items.docs) {
      final item = doc.data();

      // Format dates
      final addedAt = item['addedAt'] as Timestamp?;
      final addedDate = addedAt != null
          ? DateFormat('yyyy-MM-dd').format(addedAt.toDate())
          : 'N/A';

      final deadline = item['deadline'] as Timestamp?;
      final deadlineDate = deadline != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(deadline.toDate())
          : 'N/A';

      csvData +=
          '${item['name']},${item['completed'] ? 'Completed' : 'Pending'},'
          '$deadlineDate,${item['addedByName'] ?? 'N/A'},$addedDate\n';
    }

    // Get temporary directory
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$listName.csv');

    // Write CSV data
    await file.writeAsString(csvData);

    // Share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Shopping List: $listName',
    );
  }
}
