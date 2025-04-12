import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'recycle_bin.dart';
import 'task_details.dart';
import 'create_task.dart';
import '/widgets/loading_spinner.dart';
import '/screens/sign_out.dart';
import '/services/export_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class TutorialStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const TutorialStep({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String? _selectedListId;
  final _newListController = TextEditingController();

  // final bool _isReorderingMode = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  double _dragStartX = 0;

  void _handleDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_dragStartX < 50) {
      // Only trigger if starting from left edge
      double dragDistance = details.globalPosition.dx - _dragStartX;
      if (dragDistance > 0) {
        // Only open if dragging right
        _scaffoldKey.currentState?.openDrawer();
      }
    }
  }

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

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child:
                    Text('Cancel', style: TextStyle(color: Colors.grey[700])),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldSignOut) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignOutScreen()),
      );
    }
  }

  Future<void> _createList() async {
    if (_newListController.text.trim().isEmpty) return;

    final user = _auth.currentUser!;
    final DocumentReference docRef = await _firestore.collection('lists').add({
      'name': _newListController.text.trim(),
      'createdBy': user.uid,
      'createdByName': user.displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'members': [user.uid],
    });

    _newListController.clear();
    if (!mounted) return;

    Navigator.pop(context);
    setState(() {
      _selectedListId = docRef.id;
    });
  }

  Future<void> _deleteList(String listId) async {
    // Show confirmation dialog first
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
          .doc(listId)
          .collection('items')
          .get();

      final recycleBinSnapshot = await _firestore
          .collection('lists')
          .doc(listId)
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
      batch.delete(_firestore.collection('lists').doc(listId));

      await batch.commit();

      setState(() {
        _selectedListId = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('List deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting list: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addTask(String listId) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskScreen(listId: listId),
      ),
    );
  }

  Future<void> _clearCompletedTasks(String listId) async {
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
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red[700],
                ),
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
        .doc(listId)
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

  void _toggleTaskCompletion(
      String listId, String taskId, bool currentStatus) async {
    await _firestore
        .collection('lists')
        .doc(listId)
        .collection('items')
        .doc(taskId)
        .update({
      'completed': !currentStatus,
    });
  }

  void _editListName(String listId, String currentName) {
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
                    .doc(listId)
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

  void _deleteTask(String listId, String taskId) async {
    // Get the task data before deleting
    final taskDoc = await _firestore
        .collection('lists')
        .doc(listId)
        .collection('items')
        .doc(taskId)
        .get();

    if (!taskDoc.exists) return;

    final batch = _firestore.batch();

    // Move to recycled_items collection
    batch.set(
      _firestore
          .collection('lists')
          .doc(listId)
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
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.green[900]
                          : Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.more_vert,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.green[100]
                          : Colors.green[800],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'List Options',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Regular options
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delete_outline, color: Colors.orange[700]),
              ),
              title: const Text('View Recycle Bin'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RecycleBinScreen(listId: _selectedListId!),
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
                child: Icon(Icons.import_export, color: Colors.purple[700]),
              ),
              title: const Text('Export List'),
              onTap: () async {
                Navigator.pop(context);
                await ExportService.exportList(
                    _selectedListId!, listData['name'] ?? "Unnamed List");
              },
            ),

            // Owner-only options at the bottom
            if (isOwner) ...[
              const Divider(height: 32),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit, color: Colors.blue[700]),
                ),
                title: const Text('Rename List'),
                onTap: () {
                  Navigator.pop(context);
                  _editListName(
                      _selectedListId!, listData['name'] ?? 'Unnamed List');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete_forever, color: Colors.red[700]),
                ),
                title: const Text('Delete List'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteList(_selectedListId!);
                },
              ),
            ],
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
                  child: Icon(
                    Icons.people,
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
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
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
                    Icons.alternate_email,
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
                        final listDoc = await _firestore
                            .collection('lists')
                            .doc(_selectedListId)
                            .get();

                        if (!listDoc.exists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('List not found')),
                          );
                          Navigator.pop(context);
                          return;
                        }

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
                            .doc(_selectedListId)
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
                  Icons.people_outline,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
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
                    .doc(_selectedListId)
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
                              leading: CircleAvatar(child: Icon(Icons.person)),
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
                                        Icons.remove_circle_outline,
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
                                                  .doc(_selectedListId)
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

  // Widget _buildPriorityIndicator(String? priority) {
  //   final Color color;
  //   switch (_standardizePriority(priority)) {
  //     case 'high':
  //       color = Colors.red[700]!;
  //       break;
  //     case 'medium':
  //       color = Colors.orange[700]!;
  //       break;
  //     case 'low':
  //       color = Colors.grey[400]!;
  //       break;
  //     default:
  //       color = Colors.grey[400]!;
  //   }
  //   return Container(
  //     width: 4,
  //     height: double.infinity,
  //     decoration: BoxDecoration(
  //       color: color,
  //       borderRadius: const BorderRadius.only(
  //         topLeft: Radius.circular(4),
  //         bottomLeft: Radius.circular(4),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildReviewBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber[100]!,
            Colors.amber[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.amber[200]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      color: Colors.amber[800],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Give testing feedback',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'To get my app on the Play Store, please leave feedback.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    final Uri url = Uri.parse(
                      'https://play.google.com/store/apps/details?id=com.aadishsamir.shopsync',
                    );
                    if (!await launchUrl(url,
                        mode: LaunchMode.externalApplication)) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Could not open Play Store')),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.amber[400],
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Give Feedback',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? Colors.grey).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color ?? Colors.grey[600],
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color ??
                (Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[300]
                    : Colors.grey[800]),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final isDesktop = MediaQuery.of(context).size.width > 1024;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    PreferredSize buildCustomAppBar(BuildContext context) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
        child: StreamBuilder<DocumentSnapshot>(
          stream: _selectedListId != null
              ? _firestore.collection('lists').doc(_selectedListId).snapshots()
              : null,
          builder: (context, snapshot) {
            final bool isLoading = _selectedListId != null && !snapshot.hasData;

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
                  leading: isLoading
                      ? Padding(
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
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                              tooltip: 'Go Back',
                            ),
                          ),
                        )
                      : Material(
                          color: Colors.transparent,
                          child: IconButton(
                            icon: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.menu),
                            ),
                            onPressed: () {
                              _scaffoldKey.currentState?.openDrawer();
                            },
                          ),
                        ),
                  title: isLoading
                      ? null
                      : _selectedListId == null
                          ? const Text(
                              'ShopSync',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        snapshot.data?['name'] ??
                                            'Unnamed List',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                  actions: isLoading
                      ? null
                      : _selectedListId != null
                          ? <Widget>[
                              Material(
                                color: Colors.transparent,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: IconButton(
                                    icon: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
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
                                  padding:
                                      const EdgeInsets.only(right: 8, left: 4),
                                  child: IconButton(
                                    icon: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.more_vert),
                                    ),
                                    onPressed: () => _showMoreOptions(
                                        context, snapshot.data),
                                  ),
                                ),
                              ),
                            ]
                          : null,
                ),
              ),
            );
          },
        ),
      );
    }

    return PopScope(
      canPop: _selectedListId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedListId != null) {
          setState(() {
            _selectedListId = null;
          });
        }
      },
      child: GestureDetector(
        onHorizontalDragStart: _handleDragStart,
        onHorizontalDragUpdate: _handleDragUpdate,
        child: Scaffold(
          key: _scaffoldKey,
          appBar: buildCustomAppBar(context),
          drawer: Drawer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [Colors.grey[900]!, Colors.grey[850]!]
                      : [Colors.green[800]!, Colors.green[700]!],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 24,
                      bottom: 32,
                      left: 20,
                      right: 20,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.8),
                                Colors.white.withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[800]
                                    : Colors.green[100],
                            child: Text(
                              (_auth.currentUser?.displayName?.isNotEmpty ==
                                      true)
                                  ? _auth.currentUser!.displayName![0]
                                      .toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.green[800],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _auth.currentUser?.displayName ?? 'User',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _auth.currentUser?.email ?? '',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[900]
                            : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('lists')
                            .where('members',
                                arrayContains: _auth.currentUser?.uid)
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CustomLoadingSpinner(
                                color: Colors.green,
                                size: 60.0,
                              ),
                            );
                          }

                          return CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildReviewBanner(),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'My Lists',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[300]
                                              : Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty)
                                SliverFillRemaining(
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.list_alt,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No lists yet',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final doc = snapshot.data!.docs[index];
                                      final listId = doc.id;
                                      final listName =
                                          doc['name'] ?? 'Unnamed List';

                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _selectedListId == listId
                                              ? (Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.green[900]
                                                  : Colors.green[50])
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: ListTile(
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: _selectedListId == listId
                                                  ? Colors.green[700]
                                                  : Colors.grey
                                                      .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.shopping_cart,
                                              color: _selectedListId == listId
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                              size: 20,
                                            ),
                                          ),
                                          title: Text(
                                            listName,
                                            style: TextStyle(
                                              fontWeight:
                                                  _selectedListId == listId
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                              color: _selectedListId == listId
                                                  ? Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.green[100]
                                                      : Colors.green[900]
                                                  : Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.grey[300]
                                                      : Colors.grey[800],
                                            ),
                                          ),
                                          onTap: () {
                                            setState(() {
                                              _selectedListId = listId;
                                            });
                                            Navigator.pop(context);
                                          },
                                        ),
                                      );
                                    },
                                    childCount: snapshot.data!.docs.length,
                                  ),
                                ),
                              SliverToBoxAdapter(
                                child: Column(
                                  children: [
                                    const Divider(height: 32),
                                    _buildDrawerItem(
                                      icon: Icons.add,
                                      title: 'Create New List',
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            final bool isDark =
                                                Theme.of(context).brightness ==
                                                    Brightness.dark;

                                            return AlertDialog(
                                              backgroundColor: isDark
                                                  ? Colors.black
                                                  : Colors.white,
                                              title: Text(
                                                'Create New List',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: TextField(
                                                controller: _newListController,
                                                autofocus: true,
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                                decoration: InputDecoration(
                                                  hintText: 'List name',
                                                  hintStyle: TextStyle(
                                                    color: isDark
                                                        ? Colors.grey[400]
                                                        : Colors.grey[700],
                                                  ),
                                                  filled: true,
                                                  fillColor: isDark
                                                      ? const Color(0xFF1E1E1E)
                                                      : const Color(0xFFF5F5F5),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: isDark
                                                          ? Colors.grey[600]!
                                                          : Colors.grey[400]!,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color:
                                                          Colors.green.shade400,
                                                      width: 2,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: isDark
                                                        ? Colors.grey[400]
                                                        : Colors.grey[700],
                                                  ),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: _createList,
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green[800],
                                                    foregroundColor:
                                                        Colors.white,
                                                  ),
                                                  child: const Text('Create'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    _buildDrawerItem(
                                      icon: Icons.person_outline,
                                      title: 'My Profile',
                                      onTap: () => Navigator.pushNamed(
                                          context, '/profile'),
                                    ),
                                    _buildDrawerItem(
                                      icon: Icons.announcement_outlined,
                                      title: 'Release Notes',
                                      onTap: () async {
                                        final Uri url = Uri.parse(
                                            'https://github.com/aadishsamir123/asdev-shopsync/releases');
                                        if (!await launchUrl(url)) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Could not open release notes'),
                                            ),
                                          );
                                        }
                                        if (!mounted) return;
                                        Navigator.pop(context);
                                      },
                                    ),
                                    _buildDrawerItem(
                                      icon: Icons.logout,
                                      title: 'Sign Out',
                                      onTap: _signOut,
                                      color: Colors.red[400],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: _selectedListId == null
                    ? StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('lists')
                            .where('members',
                                arrayContains: _auth.currentUser?.uid)
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CustomLoadingSpinner(
                                color: Colors.green,
                                size: 60.0,
                              ),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            // Show tutorial for users with no lists
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.green[900]
                                            : Colors.green[50],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_circle_outline,
                                        size: 64,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.green[100]
                                            : Colors.green[800]
                                                ?.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Welcome to ShopSync',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.green[300]
                                            : Colors.green[800],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Share shopping lists with family and friends',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[300]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    // Instructions Card
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? [
                                                      Colors.grey[900]!,
                                                      Colors.grey[850]!
                                                    ]
                                                  : [
                                                      Colors.green[50]!,
                                                      Colors.green[100]!
                                                    ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[800]!
                                              : Colors.green[200]!,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.green[800]
                                                      : Colors.green[100],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.school,
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.green[100]
                                                      : Colors.green[800],
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Quick Tutorial',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.green[100]
                                                      : Colors.green[900],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeInOut,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[850]
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey[700]!
                                                    : Colors.grey[200]!,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                TutorialStep(
                                                  icon: Icons.menu,
                                                  title:
                                                      'Open the drawer from the left',
                                                  subtitle:
                                                      'Access your lists and settings',
                                                  color: Colors.green[800]!,
                                                ),
                                                const SizedBox(height: 16),
                                                TutorialStep(
                                                  icon: Icons.shopping_cart,
                                                  title:
                                                      'Select a shopping list to view',
                                                  subtitle:
                                                      'Or create a new one to get started',
                                                  color: Colors.green[800]!,
                                                ),
                                                const SizedBox(height: 16),
                                                TutorialStep(
                                                  icon:
                                                      Icons.add_circle_outline,
                                                  title:
                                                      'Add items to your list',
                                                  subtitle:
                                                      'Keep track of what you need to buy',
                                                  color: Colors.green[800]!,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          // Show recent lists for users with existing lists
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildReviewBanner(),
                                  Text(
                                    'Your Lists',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.green[300]
                                          : Colors.green[800],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: snapshot.data!.docs.length,
                                      itemBuilder: (context, index) {
                                        final doc = snapshot.data!.docs[index];
                                        final listName =
                                            doc['name'] ?? 'Unnamed List';
                                        final timestamp =
                                            doc['createdAt'] as Timestamp?;
                                        final createdAt = timestamp != null
                                            ? DateFormat('MMM dd, yyyy')
                                                .format(timestamp.toDate())
                                            : 'Unknown date';

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? [
                                                        Colors.grey[900]!,
                                                        Colors.grey[850]!,
                                                      ]
                                                    : [
                                                        Colors.white,
                                                        Colors.grey[50]!,
                                                      ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.black26
                                                      : Colors.black12,
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                              border: Border.all(
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey[800]!
                                                    : Colors.grey[200]!,
                                                width: 1,
                                              ),
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                onTap: () {
                                                  setState(() {
                                                    _selectedListId = doc.id;
                                                  });
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(12),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors
                                                                  .green[900]
                                                              : Colors
                                                                  .green[50],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Icon(
                                                          Icons
                                                              .shopping_cart_outlined,
                                                          color: Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors
                                                                  .green[200]
                                                              : Colors
                                                                  .green[700],
                                                          size: 24,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              listName,
                                                              style: TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Theme.of(context)
                                                                            .brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Colors
                                                                        .white
                                                                    : Colors.grey[
                                                                        800],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 4),
                                                            Row(
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .calendar_today,
                                                                  size: 14,
                                                                  color: Theme.of(context)
                                                                              .brightness ==
                                                                          Brightness
                                                                              .dark
                                                                      ? Colors.grey[
                                                                          400]
                                                                      : Colors.grey[
                                                                          600],
                                                                ),
                                                                const SizedBox(
                                                                    width: 4),
                                                                Text(
                                                                  createdAt,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    color: Theme.of(context).brightness ==
                                                                            Brightness
                                                                                .dark
                                                                        ? Colors.grey[
                                                                            400]
                                                                        : Colors
                                                                            .grey[600],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors.grey[800]
                                                              : Colors
                                                                  .grey[100],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Icon(
                                                          Icons
                                                              .arrow_forward_ios,
                                                          size: 16,
                                                          color: Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors.grey[400]
                                                              : Colors
                                                                  .grey[600],
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
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('lists')
                            .doc(_selectedListId)
                            .collection('items')
                            .orderBy('completed')
                            .orderBy('deadline',
                                descending:
                                    false) // Show upcoming deadlines first
                            .orderBy('priority',
                                descending: true) // high -> medium -> low
                            .orderBy('addedAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CustomLoadingSpinner(
                                color: Colors.green,
                                size: 60.0,
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error loading items',
                                style: TextStyle(color: Colors.red[300]),
                              ),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Empty illustration
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.green[900]
                                            : Colors.green[50],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.shopping_basket_outlined,
                                        size: 90,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.green[100]
                                            : Colors.green[800]
                                                ?.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    // Empty state title
                                    Text(
                                      'Your shopping list is empty',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.green[300]
                                            : Colors.green[800],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Description
                                    Text(
                                      'Start adding items you need to buy',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[300]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    // Suggestions card
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[900]
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[800]!
                                              : Colors.grey[200]!,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.lightbulb_outline,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.green[300]
                                                    : Colors.green[800],
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Quick suggestions',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.green[300]
                                                      : Colors.green[800],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              'Milk',
                                              'Bread',
                                              'Eggs',
                                              'Fruits',
                                              'Vegetables',
                                              'Water'
                                            ]
                                                .map((item) => ActionChip(
                                                      label: Text(item),
                                                      avatar: const Icon(
                                                        Icons.add,
                                                        size: 16,
                                                      ),
                                                      onPressed: () async {
                                                        final user =
                                                            _auth.currentUser!;
                                                        await _firestore
                                                            .collection('lists')
                                                            .doc(
                                                                _selectedListId)
                                                            .collection('items')
                                                            .add({
                                                          'name': item,
                                                          'completed': false,
                                                          'addedBy': user.uid,
                                                          'addedByName':
                                                              user.displayName,
                                                          'addedAt': FieldValue
                                                              .serverTimestamp(),
                                                          'priority': 'low',
                                                          'deadline': null,
                                                        });
                                                      },
                                                      backgroundColor: Theme.of(
                                                                      context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.grey[800]
                                                          : Colors.grey[100],
                                                      labelStyle: TextStyle(
                                                        color: Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.dark
                                                            ? Colors.grey[300]
                                                            : Colors.grey[800],
                                                      ),
                                                    ))
                                                .toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    // Add button
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.add,
                                          color: Colors.white),
                                      label: const Text('Add Item'),
                                      onPressed: () =>
                                          _addTask(_selectedListId!),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[800],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return // Replace the ListView.builder in the StreamBuilder for tasks
                              ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final doc = snapshot.data!.docs[index];
                              final docData =
                                  doc.data() as Map<String, dynamic>;
                              final isCompleted =
                                  docData.containsKey('completed')
                                      ? docData['completed']
                                      : false;
                              final name = docData['name'] ?? 'Untitled Task';
                              final priority =
                                  _standardizePriority(docData['priority']);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? [
                                              Colors.grey[900]!,
                                              Colors.grey[850]!
                                            ]
                                          : [Colors.white, Colors.grey[50]!],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey[800]!
                                          : Colors.grey[200]!,
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
                                            builder: (context) =>
                                                TaskDetailsScreen(
                                              listId: _selectedListId!,
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
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isCompleted
                                                          ? Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors.grey[500]
                                                              : Colors.grey[600]
                                                          : Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors.white
                                                              : Colors
                                                                  .grey[800],
                                                      decoration: isCompleted
                                                          ? TextDecoration
                                                              .lineThrough
                                                          : null,
                                                    ),
                                                  ),
                                                  if (docData['location'] != null ||
                                                      docData['deadline'] !=
                                                          null ||
                                                      docData['addedByName'] !=
                                                          null)
                                                    const SizedBox(height: 8),
                                                  Wrap(
                                                    spacing: 12,
                                                    children: [
                                                      if (docData['location'] !=
                                                          null)
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .location_on_outlined,
                                                              size: 14,
                                                              color: Theme.of(context)
                                                                          .brightness ==
                                                                      Brightness
                                                                          .dark
                                                                  ? Colors
                                                                      .grey[400]
                                                                  : Colors.grey[
                                                                      600],
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            Text(
                                                              docData['location']
                                                                      [
                                                                      'name'] ??
                                                                  '',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Theme.of(context)
                                                                            .brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Colors.grey[
                                                                        400]
                                                                    : Colors.grey[
                                                                        600],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      if (docData.containsKey(
                                                              'deadline') &&
                                                          docData['deadline'] !=
                                                              null)
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons.schedule,
                                                              size: 14,
                                                              color: Theme.of(context)
                                                                          .brightness ==
                                                                      Brightness
                                                                          .dark
                                                                  ? Colors
                                                                      .grey[400]
                                                                  : Colors.grey[
                                                                      600],
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
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
                                                                color: Theme.of(context)
                                                                            .brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Colors.grey[
                                                                        400]
                                                                    : Colors.grey[
                                                                        600],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      if (docData[
                                                              'addedByName'] !=
                                                          null)
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .person_outline,
                                                              size: 14,
                                                              color: Theme.of(context)
                                                                          .brightness ==
                                                                      Brightness
                                                                          .dark
                                                                  ? Colors
                                                                      .grey[400]
                                                                  : Colors.grey[
                                                                      600],
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            Text(
                                                              docData[
                                                                  'addedByName'],
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Theme.of(context)
                                                                            .brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Colors.grey[
                                                                        400]
                                                                    : Colors.grey[
                                                                        600],
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
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey[800]
                                                    : Colors.grey[100],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                      isCompleted
                                                          ? Icons.check_circle
                                                          : Icons
                                                              .circle_outlined,
                                                      color: isCompleted
                                                          ? Colors.green[400]
                                                          : Colors.grey[400],
                                                    ),
                                                    onPressed: () =>
                                                        _toggleTaskCompletion(
                                                      _selectedListId!,
                                                      doc.id,
                                                      isCompleted,
                                                    ),
                                                  ),
                                                  Container(
                                                    height: 24,
                                                    width: 1,
                                                    color: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.grey[700]
                                                        : Colors.grey[300],
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red[300],
                                                    ),
                                                    onPressed: () =>
                                                        _deleteTask(
                                                            _selectedListId!,
                                                            doc.id),
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
              if (_selectedListId != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[900]
                        : Colors.grey[100],
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
                        .doc(_selectedListId)
                        .collection('items')
                        .orderBy('order')
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
                            style: TextStyle(
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
          floatingActionButton: _selectedListId == null
              ? null
              : Align(
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
                              .doc(_selectedListId)
                              .collection('items')
                              .where('completed', isEqualTo: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            final hasCompletedItems = snapshot.hasData &&
                                snapshot.data!.docs.isNotEmpty;

                            if (!hasCompletedItems) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: FloatingActionButton.extended(
                                onPressed: () =>
                                    _clearCompletedTasks(_selectedListId!),
                                backgroundColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[900]
                                    : Colors.white,
                                foregroundColor: Colors.red[700],
                                elevation: 2,
                                label: const Text('Clear Completed'),
                                icon: const Icon(
                                    Icons.cleaning_services_outlined),
                              ),
                            );
                          },
                        ),

                        // Add item button
                        FloatingActionButton(
                          onPressed: () => _addTask(_selectedListId!),
                          backgroundColor: Colors.green[800],
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
