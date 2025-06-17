import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/widgets/loading_spinner.dart';

class AppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 16);

    path.quadraticBezierTo(
      size.width / 4,
      size.height,
      size.width / 2,
      size.height,
    );

    path.quadraticBezierTo(
      size.width * 3 / 4,
      size.height,
      size.width,
      size.height - 16,
    );

    path.lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class RecycleBinScreen extends StatefulWidget {
  final String listId;

  const RecycleBinScreen({super.key, required this.listId});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen>
    with TickerProviderStateMixin {
  // Changed from SingleTickerProviderStateMixin
  late AnimationController _controller;
  final Map<String, AnimationController> _itemControllers = {};
  final Map<String, Animation<double>> _itemAnimations = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final controller in _itemControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _restoreItem(
      String itemId, Map<String, dynamic> itemData) async {
    try {
      await _itemControllers[itemId]?.reverse();

      final batch = FirebaseFirestore.instance.batch();
      batch.set(
        FirebaseFirestore.instance
            .collection('lists')
            .doc(widget.listId)
            .collection('items')
            .doc(),
        {...itemData, 'restoredAt': FieldValue.serverTimestamp()},
      );
      batch.delete(
        FirebaseFirestore.instance
            .collection('lists')
            .doc(widget.listId)
            .collection('recycled_items')
            .doc(itemId),
      );
      await batch.commit();
    } catch (e, stackTrace) {
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'message': 'Failed to restore item from recycle bin',
          'listId': widget.listId,
          'itemId': itemId,
        }),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to restore item')),
      );
    }
  }

  Future<void> _deletePermanently(String itemId) async {
    try {
      await _itemControllers[itemId]?.reverse();
      await FirebaseFirestore.instance
          .collection('lists')
          .doc(widget.listId)
          .collection('recycled_items')
          .doc(itemId)
          .delete();
    } catch (e, stackTrace) {
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'message': 'Failed to permanently delete item',
          'listId': widget.listId,
          'itemId': itemId,
        }),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete item')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    PreferredSize buildCustomAppBar(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: isDark ? Colors.grey[800] : Colors.green[800],
          elevation: 0,
          leading: IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Recycle Bin",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: buildCustomAppBar(context),
      body: CustomScrollView(
        slivers: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('lists')
                .doc(widget.listId)
                .collection('recycled_items')
                .orderBy('deletedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child:
                        CustomLoadingSpinner(color: Colors.green, size: 60.0),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: FaIcon(
                            FontAwesomeIcons.trashCan,
                            size: 48,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Deleted Items',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Items you delete will appear here for 30 days',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final itemData = doc.data() as Map<String, dynamic>;

                      if (!_itemControllers.containsKey(doc.id)) {
                        _itemControllers[doc.id] = AnimationController(
                          duration: const Duration(milliseconds: 300),
                          vsync: this,
                        )..forward();

                        _itemAnimations[doc.id] =
                            _itemControllers[doc.id]!.drive(
                          Tween<double>(begin: 0, end: 1),
                        );
                      }

                      return AnimatedBuilder(
                        animation: _itemAnimations[doc.id]!,
                        builder: (context, child) => FadeTransition(
                          opacity: _itemAnimations[doc.id]!,
                          child: SizeTransition(
                            sizeFactor: _itemAnimations[doc.id]!,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: isDark ? Colors.grey[850] : Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  itemData['name'],
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.person_outline,
                                            size: 16,
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          itemData['deletedByName'],
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.schedule,
                                            size: 16,
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('MMM dd, yyyy').format(
                                            (itemData['deletedAt'] as Timestamp)
                                                .toDate(),
                                          ),
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.restore,
                                        color: Colors.green[600],
                                      ),
                                      onPressed: () =>
                                          _restoreItem(doc.id, itemData),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_forever,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _deletePermanently(doc.id),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: snapshot.data!.docs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
