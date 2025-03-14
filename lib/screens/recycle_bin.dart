// lib/screens/recycle_bin.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.green[800],
        foregroundColor: Colors.white,
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
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Empty state illustration
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.green[900]
                            : Colors.green[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        size: 64,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.green[100]
                            : Colors.green[800]?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Recycle Bin is Empty',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.green[300]
                            : Colors.green[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Items you delete will appear here',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final itemData = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    itemData['name'],
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text(
                    'Deleted by ${itemData['deletedByName']}',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.restore, color: Colors.green[800]),
                        onPressed: () => _restoreItem(doc.id, itemData),
                        tooltip: 'Restore item',
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: () => _deletePermanently(doc.id),
                        tooltip: 'Delete permanently',
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
