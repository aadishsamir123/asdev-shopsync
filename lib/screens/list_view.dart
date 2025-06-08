import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'task_details.dart';
import 'recycle_bin.dart';
import 'create_task.dart';
import '/widgets/loading_spinner.dart';
import '/services/export_service.dart';

class ListViewScreen extends StatefulWidget {
  final String listId;
  final String listName;

  const ListViewScreen({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<ListViewScreen> createState() => _ListViewScreenState();
}

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

class _ListViewScreenState extends State<ListViewScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _standardizePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return 'high';
      case 'medium':
        return 'medium';
      case 'low':
        return 'low';
      default:
        return 'low';
    }
  }

  void _toggleTaskCompletion(String taskId, bool currentStatus) async {
    try {
      await _firestore
          .collection('lists')
          .doc(widget.listId)
          .collection('items')
          .doc(taskId)
          .update({
        'completed': !currentStatus,
      });
    } catch (e, stackTrace) {
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'message': 'Failed to toggle task completion',
          'listId': widget.listId,
          'taskId': taskId,
        }),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update task status')),
      );
    }
  }

  void _deleteTask(String taskId) async {
    try {
      // Get the task data before deleting
      final taskDoc = await _firestore
          .collection('lists')
          .doc(widget.listId)
          .collection('items')
          .doc(taskId)
          .get();

      if (!taskDoc.exists) return;

      final batch = _firestore.batch();

      // Move to recycled_items collection
      batch.set(
        _firestore
            .collection('lists')
            .doc(widget.listId)
            .collection('recycled_items')
            .doc(),
        {
          ...taskDoc.data()!,
          'deletedAt': FieldValue.serverTimestamp(),
          'deletedBy': _auth.currentUser!.uid,
          'deletedByName': _auth.currentUser!.displayName,
        },
      );

      // Delete from original collection
      batch.delete(taskDoc.reference);

      await batch.commit();
    } catch (e, stackTrace) {
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'message': 'Failed to delete task',
          'listId': widget.listId,
          'taskId': taskId,
        }),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete task')),
      );
    }
  }

  Future<void> _clearCompletedTasks() async {
    // Show confirmation dialog
    final shouldClear = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Clear Completed Items'),
            content: const Text(
                'Are you sure you want to remove all completed items?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child:
                    Text('Cancel', style: TextStyle(color: Colors.grey[700])),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
                child: const Text('Clear Items'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldClear || !mounted) return;

    // Get all completed items
    final QuerySnapshot completedItems = await _firestore
        .collection('lists')
        .doc(widget.listId)
        .collection('items')
        .where('completed', isEqualTo: true)
        .get();

    // Delete each item
    final batch = _firestore.batch();
    for (var doc in completedItems.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cleared ${completedItems.docs.length} completed items'),
        backgroundColor: Colors.green[800],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editListName(String currentName) {
    final TextEditingController nameController =
        TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? Colors.black : Colors.white,
          title: Text(
            'Edit List Name',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: 'List name',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.green.shade400,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                await _firestore
                    .collection('lists')
                    .doc(widget.listId)
                    .update({'name': nameController.text.trim()});

                if (!mounted) return;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteList() async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete List'),
            content: const Text(
              'Are you sure you want to delete this list? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red[700],
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete || !mounted) return;

    try {
      // Delete all items in the list
      final itemsSnapshot = await _firestore
          .collection('lists')
          .doc(widget.listId)
          .collection('items')
          .get();

      final recycleBinSnapshot = await _firestore
          .collection('lists')
          .doc(widget.listId)
          .collection('recycled_items')
          .get();

      final batch = _firestore.batch();

      // Delete items
      for (var doc in itemsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete recycled items
      for (var doc in recycleBinSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the list document itself
      batch.delete(_firestore.collection('lists').doc(widget.listId));

      await batch.commit();

      if (!mounted) return;
      Navigator.pop(context); // Return to home screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('List deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'message': 'Failed to delete list',
          'listId': widget.listId,
        }),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete list')),
      );
    }
  }

  void _showMoreOptions(BuildContext context, DocumentSnapshot? listData) {
    if (listData == null) return;

    final bool isOwner = listData['createdBy'] == _auth.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.green[900]
                          : Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.ellipsisVertical,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.green[100]
                          : Colors.green[800],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'List Options',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your list settings',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // List options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(FontAwesomeIcons.trashCan,
                          color: Colors.orange[700]),
                    ),
                    title: const Text('View Recycle Bin'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RecycleBinScreen(listId: widget.listId),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(FontAwesomeIcons.fileExport,
                          color: Colors.purple[700]),
                    ),
                    title: const Text('Export List'),
                    onTap: () async {
                      Navigator.pop(context);
                      await ExportService.exportList(
                          widget.listId, widget.listName);
                    },
                  ),

                  // Owner-only options
                  if (isOwner) ...[
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Divider(),
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(FontAwesomeIcons.penToSquare,
                            color: Colors.blue[700]),
                      ),
                      title: const Text('Rename List'),
                      onTap: () {
                        Navigator.pop(context);
                        _editListName(widget.listName);
                      },
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(FontAwesomeIcons.trash,
                            color: Colors.red[700]),
                      ),
                      title: const Text('Delete List'),
                      onTap: () {
                        Navigator.pop(context);
                        _deleteList();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareMenu() {
    final TextEditingController emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green[900]
                        : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.userGroup,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green[100]
                        : Colors.green[800],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share List',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Collaborate with others',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[850]
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]!
                      : Colors.grey[200]!,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.at,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green[200]
                        : Colors.green[800],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'Enter email address',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[500]
                              : Colors.grey[400],
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey[800],
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final email = emailController.text.trim();
                      if (email.isEmpty) return;

                      try {
                        final userQuery = await _firestore
                            .collection('users')
                            .where('email', isEqualTo: email)
                            .limit(1)
                            .get();

                        if (userQuery.docs.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'User not found. Invite them to ShopSync!'),
                            ),
                          );
                          return;
                        }

                        final userId = userQuery.docs.first.id;
                        final listDoc = await _firestore
                            .collection('lists')
                            .doc(widget.listId)
                            .get();
                        final currentMembers = List<String>.from(
                            listDoc.data()!['members'] as List);

                        if (currentMembers.contains(userId)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('User already has access to this list'),
                            ),
                          );
                          return;
                        }

                        currentMembers.add(userId);
                        await _firestore
                            .collection('lists')
                            .doc(widget.listId)
                            .update({'members': currentMembers});

                        emailController.clear();
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('User added successfully')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Error sharing list: ${e.toString()}')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Share',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.userGroup,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  'Current Members',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[300]
                        : Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('lists')
                    .doc(widget.listId)
                    .snapshots(),
                builder: (context, listSnapshot) {
                  if (!listSnapshot.hasData) {
                    return const Center(
                      child: CustomLoadingSpinner(
                        color: Colors.green,
                        size: 60.0,
                      ),
                    );
                  }

                  final members =
                      List<String>.from(listSnapshot.data!['members'] as List);

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final memberId = members[index];

                      return FutureBuilder<DocumentSnapshot>(
                        future:
                            _firestore.collection('users').doc(memberId).get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return const ListTile(
                              leading: CircleAvatar(
                                  child: Icon(FontAwesomeIcons.user)),
                              title: Text('Loading...'),
                            );
                          }

                          final userData =
                              userSnapshot.data!.data() as Map<String, dynamic>;
                          final name =
                              userData['displayName'] ?? 'Unknown User';
                          final email = userData['email'] ?? '';
                          final isOwner =
                              memberId == listSnapshot.data!['createdBy'];

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  isOwner ? Colors.amber : Colors.green[100],
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: isOwner
                                      ? Colors.white
                                      : Colors.green[800],
                                ),
                              ),
                            ),
                            title: Text(name),
                            subtitle: Text(email),
                            trailing: isOwner
                                ? Chip(
                                    label: const Text('Owner'),
                                    backgroundColor: Colors.amber[100],
                                    labelStyle:
                                        TextStyle(color: Colors.amber[800]),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                        FontAwesomeIcons.circleMinus,
                                        color: Colors.red),
                                    onPressed: memberId ==
                                            _auth.currentUser!.uid
                                        ? null
                                        : () async {
                                            try {
                                              final updatedMembers =
                                                  List<String>.from(members);
                                              updatedMembers.remove(memberId);
                                              await _firestore
                                                  .collection('lists')
                                                  .doc(widget.listId)
                                                  .update({
                                                'members': updatedMembers
                                              });
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content:
                                                        Text('User removed')),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        'Error: ${e.toString()}')),
                                              );
                                            }
                                          },
                                  ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    PreferredSize buildCustomAppBar(BuildContext context) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('lists').doc(widget.listId).snapshots(),
          builder: (context, snapshot) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [Colors.grey[900]!, Colors.grey[850]!]
                      : [Colors.green[800]!, Colors.green[600]!],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipPath(
                clipper: AppBarClipper(),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  foregroundColor: Colors.white,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey[800]!.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey[700]!
                              : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: IconButton(
                        icon: const FaIcon(FontAwesomeIcons.arrowLeft,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Go Back',
                      ),
                    ),
                  ),
                  title: Text(
                    widget.listName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    Material(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: IconButton(
                          icon: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.people),
                          ),
                          onPressed: _showShareMenu,
                          tooltip: 'Share List',
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8, left: 4),
                        child: IconButton(
                          icon: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.more_vert),
                          ),
                          onPressed: () =>
                              _showMoreOptions(context, snapshot.data),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: buildCustomAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('lists')
                  .doc(widget.listId)
                  .collection('items')
                  .orderBy('completed')
                  .orderBy('deadline', descending: false)
                  .orderBy('priority', descending: true)
                  .orderBy('addedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CustomLoadingSpinner(
                      color: Colors.green,
                      size: 60.0,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? Colors.green[900] : Colors.green[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shopping_basket_outlined,
                              size: 90,
                              color: isDark
                                  ? Colors.green[100]
                                  : Colors.green[800]?.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Your shopping list is empty',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.green[300]
                                  : Colors.green[800],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start adding items you need to buy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final docData = doc.data() as Map<String, dynamic>;
                    final isCompleted = docData['completed'] ?? false;
                    final name = docData['name'] ?? 'Untitled Task';
                    final priority = _standardizePriority(docData['priority']);
                    final counter = docData['counter'] ?? 1;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [Colors.grey[900]!, Colors.grey[850]!]
                                : [Colors.white, Colors.grey[50]!],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color:
                                isDark ? Colors.grey[800]! : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskDetailsScreen(
                                    listId: widget.listId,
                                    taskId: doc.id,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: priority == 'high'
                                          ? Colors.red[400]
                                          : priority == 'medium'
                                              ? Colors.orange[400]
                                              : Colors.blue[200],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: isCompleted
                                                    ? isDark
                                                        ? Colors.grey[500]
                                                        : Colors.grey[600]
                                                    : isDark
                                                        ? Colors.white
                                                        : Colors.grey[800],
                                                decoration: isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                            if (counter > 1) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[100],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.green[300]!,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  '${counter}x',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green[800],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (docData['location'] != null ||
                                            docData['deadline'] != null ||
                                            docData['addedByName'] != null)
                                          const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 12,
                                          children: [
                                            if (docData['location'] != null)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  FaIcon(
                                                    FontAwesomeIcons
                                                        .locationDot,
                                                    size: 14,
                                                    color: isDark
                                                        ? Colors.grey[400]
                                                        : Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    docData['location']
                                                            ['name'] ??
                                                        '',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDark
                                                          ? Colors.grey[400]
                                                          : Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            if (docData
                                                    .containsKey('deadline') &&
                                                docData['deadline'] != null)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  FaIcon(
                                                    FontAwesomeIcons.clock,
                                                    size: 12,
                                                    color: isDark
                                                        ? Colors.grey[400]
                                                        : Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    DateFormat(
                                                            'MMM dd, hh:mm a')
                                                        .format(
                                                      (docData['deadline']
                                                              as Timestamp)
                                                          .toDate(),
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDark
                                                          ? Colors.grey[400]
                                                          : Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            if (docData['addedByName'] != null)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  FaIcon(
                                                    FontAwesomeIcons.user,
                                                    size: 14,
                                                    color: isDark
                                                        ? Colors.grey[400]
                                                        : Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    docData['addedByName'],
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDark
                                                          ? Colors.grey[400]
                                                          : Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.grey[800]
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            isCompleted
                                                ? FontAwesomeIcons.circleCheck
                                                : FontAwesomeIcons.circle,
                                            color: isCompleted
                                                ? Colors.green[400]
                                                : Colors.grey[400],
                                          ),
                                          onPressed: () =>
                                              _toggleTaskCompletion(
                                            doc.id,
                                            isCompleted,
                                          ),
                                        ),
                                        Container(
                                          height: 24,
                                          width: 1,
                                          color: isDark
                                              ? Colors.grey[700]
                                              : Colors.grey[300],
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            FontAwesomeIcons.trashCan,
                                            color: Colors.red[300],
                                          ),
                                          onPressed: () => _deleteTask(doc.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Statistics or summary at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('lists')
                  .doc(widget.listId)
                  .collection('items')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CustomLoadingSpinner(
                      color: Colors.green,
                      size: 60.0,
                    ),
                  );
                }

                final totalItems = snapshot.data!.docs.length;
                final completedItems = snapshot.data!.docs
                    .where((doc) => doc['completed'] == true)
                    .length;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedItems of $totalItems items completed',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 0, bottom: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Clear completed tasks button
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('lists')
                    .doc(widget.listId)
                    .collection('items')
                    .where('completed', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  final hasCompletedItems =
                      snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                  if (!hasCompletedItems) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: FloatingActionButton.extended(
                      onPressed: _clearCompletedTasks,
                      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
                      foregroundColor: Colors.red[700],
                      elevation: 2,
                      label: const Text('Clear Completed'),
                      icon: const FaIcon(FontAwesomeIcons.eraser),
                    ),
                  );
                },
              ),

              // Add item button
              FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreateTaskScreen(listId: widget.listId),
                    ),
                  );
                },
                backgroundColor: Colors.green[800],
                child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
