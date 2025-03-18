// lib/screens/recycle_bin.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RecycleBinScreen extends StatelessWidget {
  final String listId;

  const RecycleBinScreen({super.key, required this.listId});

  Future<void> _restoreItem(
      String itemId, Map<String, dynamic> itemData) async {
    final batch = FirebaseFirestore.instance.batch();

    // Add back to original items collection
    batch.set(
      FirebaseFirestore.instance
          .collection('lists')
          .doc(listId)
          .collection('items')
          .doc(),
      {
        ...itemData,
        'restoredAt': FieldValue.serverTimestamp(),
      },
    );

    // Remove from recycled items
    batch.delete(
      FirebaseFirestore.instance
          .collection('lists')
          .doc(listId)
          .collection('recycled_items')
          .doc(itemId),
    );

    await batch.commit();
  }

  Future<void> _deletePermanently(String itemId) async {
    await FirebaseFirestore.instance
        .collection('lists')
        .doc(listId)
        .collection('recycled_items')
        .doc(itemId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : Colors.green[800],
        foregroundColor: Colors.white,
        title: const Text('Recycle Bin'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lists')
            .doc(listId)
            .collection('recycled_items')
            .orderBy('deletedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 64,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Recycle Bin is Empty',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Items you delete will appear here',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final itemData = doc.data() as Map<String, dynamic>;
              final deletedAt = (itemData['deletedAt'] as Timestamp).toDate();

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              itemData['name'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.grey[800],
                                decoration: TextDecoration.lineThrough,
                                decorationColor:
                                    isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            icon: Icon(Icons.restore, color: Colors.green[600]),
                            label: Text(
                              'Restore',
                              style: TextStyle(color: Colors.green[600]),
                            ),
                            onPressed: () => _restoreItem(doc.id, itemData),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.delete_forever,
                                color: Colors.red),
                            label: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () => _deletePermanently(doc.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Deleted by: ${itemData['deletedByName']}',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Deleted on: ${DateFormat('MMM dd, yyyy').format(deletedAt)}',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}