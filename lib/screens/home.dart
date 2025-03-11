import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'recycle_bin.dart';
import 'task_details.dart';
import 'create_task.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String? _selectedListId;
  final _newListController = TextEditingController();
  final bool _isReorderingMode = false;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
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
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
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
      builder: (context) => AlertDialog(
        title: const Text('Edit List Name'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'List name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[700]),
            ),
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
      ),
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

  void _showShareMenu() {
    final TextEditingController emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.people_outline),
                SizedBox(width: 8),
                Text(
                  'Share with others',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'Enter email address',
                prefixIcon: Icon(Icons.email, color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green[800]!),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final email = emailController.text.trim();
                    if (email.isEmpty) return;

                    try {
                      // First check if the list exists
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

                      // Query users by email
                      final userQuery = await FirebaseFirestore.instance
                          .collection('users')
                          .where('email', isEqualTo: email)
                          .limit(1)
                          .get();

                      if (userQuery.docs.isEmpty) {
                        // User not found - invite flow would go here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'User not found. Invite them to ShopSync!'),
                          ),
                        );
                        return;
                      }

                      final userId = userQuery.docs.first.id;
                      final currentMembers =
                          List<String>.from(listDoc.data()!['members'] as List);

                      if (currentMembers.contains(userId)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('User already has access to this list')),
                        );
                        return;
                      }

                      // Add user to the list's members
                      currentMembers.add(userId);
                      await _firestore
                          .collection('lists')
                          .doc(_selectedListId)
                          .update({'members': currentMembers});

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('User added successfully')),
                      );

                      emailController.clear();
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Error sharing list: ${e.toString()}')),
                      );
                    }
                  },
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  label: const Text('Add User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // Current Members List
            SizedBox(
              height: 200,
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('lists')
                    .doc(_selectedListId)
                    .snapshots(),
                builder: (context, listSnapshot) {
                  if (!listSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final members =
                      List<String>.from(listSnapshot.data!['members'] as List);

                  if (members.isEmpty) {
                    return const Center(child: Text('No members yet'));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final memberId = members[index];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(memberId)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return const ListTile(
                              leading: CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text('Loading...'),
                            );
                          }

                          final userData = userSnapshot.data!.data()
                              as Map<String, dynamic>?;
                          final name =
                              userData?['displayName'] ?? 'Unknown User';
                          final email = userData?['email'] ?? '';
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
                                        ? null // Can't remove self
                                        : () async {
                                            // Remove user logic
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(String? priority) {
    final Color color;
    switch (_standardizePriority(priority)) {
      case 'high':
        color = Colors.red[700]!;
        break;
      case 'medium':
        color = Colors.orange[700]!;
        break;
      case 'low':
        color = Colors.grey[400]!;
        break;
      default:
        color = Colors.grey[400]!;
    }
    return Container(
      width: 4,
      height: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.green[800],
          foregroundColor: Colors.white,
          elevation: 0,
          title: _selectedListId == null
              ? const Text('ShopSync')
              : StreamBuilder<DocumentSnapshot>(
                  stream: _firestore
                      .collection('lists')
                      .doc(_selectedListId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Text('Loading...');
                    }

                    final listName = snapshot.data!['name'] ?? 'Unnamed List';
              return Text(listName);
            },
          ),
          actions: _selectedListId != null
              ? [
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('lists')
                  .doc(_selectedListId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                      final isOwner =
                          snapshot.data!['createdBy'] == _auth.currentUser?.uid;
                      final listName = snapshot.data!['name'] ?? 'Unnamed List';

                      return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) =>
                  [
                    if (isOwner)
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Edit List Name'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    PopupMenuItem(
                      value: 'recycle',
                      child: ListTile(
                        leading: const Icon(Icons.delete_outline),
                        title: const Text('Recycle Bin'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: ListTile(
                        leading: const Icon(Icons.share),
                        title: const Text('Share List'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    // PopupMenuItem(
                    //   value: 'reorder',
                    //   child: ListTile(
                    //     leading: const Icon(Icons.reorder),
                    //     title: const Text('Rearrange Tasks'),
                    //     contentPadding: EdgeInsets.zero,
                    //   ),
                    // ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editListName(_selectedListId!, listName);
                        break;
                      case 'recycle':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RecycleBinScreen(
                                  listId: _selectedListId!,
                                ),
                          ),
                        );
                        break;
                      case 'share':
                        _showShareMenu();
                        break;
                    // case 'reorder':
                    //   setState(() {
                    //     _isReorderingMode = !_isReorderingMode;
                    //   });
                    //   break;
                    }
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _selectedListId = null;
                });
              },
              tooltip: 'Close list',
            ),
          ]
              : null,
        ),
        drawer: Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: Theme
                      .of(context)
                      .brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.green[800],
                ),
                accountName: Text(_auth.currentUser?.displayName ?? 'User'),
                accountEmail: Text(_auth.currentUser?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    (_auth.currentUser?.displayName?.isNotEmpty == true)
                        ? _auth.currentUser!.displayName![0].toUpperCase()
                        : 'U',
                    style: TextStyle(fontSize: 24, color: Colors.green[800]),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('lists')
                      .where('members', arrayContains: _auth.currentUser?.uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading lists',
                          style: TextStyle(color: Colors.red[300]),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.list_alt,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No lists yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create your first grocery list',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final listId = doc.id;
                        final listName = doc['name'] ?? 'Unnamed List';

                        return ListTile(
                          leading: Icon(
                            Icons.shopping_cart,
                            color: _selectedListId == listId
                                ? Colors.green[300]
                                : Colors.grey[600],
                          ),
                          title: Text(
                            listName,
                            style: TextStyle(
                              fontWeight: _selectedListId == listId
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _selectedListId == listId
                                  ? Colors.green[300]
                                  : Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[300]
                                      : Colors.grey[800],
                            ),
                          ),
                          selectedTileColor:
                              Colors.green[800]?.withOpacity(0.1),
                          selected: _selectedListId == listId,
                          onTap: () {
                            setState(() {
                              _selectedListId = listId;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create New List'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Create New List'),
                      content: TextField(
                        controller: _newListController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'List name',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _createList,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[800],
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Create'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('My Profile'),
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.announcement_outlined),
                title: const Text('Release Notes'),
                onTap: () async {
                  final Uri url = Uri.parse(
                      'https://github.com/aadishsamir123/asdev-shopsync/releases');
                  if (!await launchUrl(url)) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open release notes'),
                      ),
                    );
                  }
                  if (!mounted) return;
                  Navigator.pop(context); // Close drawer after clicking
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onTap: _signOut,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: _selectedListId == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // App Icon
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
                                    : Colors.green[800]?.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Welcome Text
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
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[900]
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.menu,
                                        color: Colors.green[800],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Open the drawer from the left',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.shopping_cart,
                                        color: Colors.green[800],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Select a shopping list to view',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.green[800],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Or create a new list to get started',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Create New List Button
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Create New List'),
                                    content: TextField(
                                      controller: _newListController,
                                      autofocus: true,
                                      decoration: const InputDecoration(
                                        hintText: 'List name',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          'Cancel',
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: _createList,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green[800],
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Create'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Create New List'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[800],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading items',
                        style: TextStyle(color: Colors.red[300]),
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
                                          : Colors.green[800]?.withOpacity(0.7),
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
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Quick suggestions:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            'Milk',
                                            'Bread',
                                            'Eggs',
                                            'Bananas',
                                            'Coffee'
                                          ]
                                              .map((item) => ActionChip(
                                                    label: Text(item),
                                                    avatar: const Icon(
                                                        Icons.add,
                                                        size: 16),
                                                    onPressed: () async {
                                                      final user =
                                                          _auth.currentUser!;
                                                      await _firestore
                                                          .collection('lists')
                                                          .doc(_selectedListId)
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
                                                          ? Colors.green[800]
                                                          : Colors.green[200],
                                                  ))
                                              .toList(),
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Add button
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add,
                                        color: Colors.white),
                                    label: const Text('Add Item'),
                                    onPressed: () => _addTask(_selectedListId!),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[800],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
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
                      final addedByName = docData['addedByName'];
                      final priority = docData.containsKey('priority')
                          ? docData['priority']
                          : null;

                            return Card(
                              key: Key(doc.id),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TaskDetailsScreen(
                                        listId: _selectedListId!,
                                        taskId: doc.id,
                                      ),
                                    ),
                                  );
                                },
                                child: ListTile(
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: isCompleted
                                              ? (Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[
                                                      500] // Dark mode, darker grey
                                                  : Colors.grey[
                                                      600]) // Light mode, normal grey
                                              : (Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors
                                                      .white // Dark mode, white text
                                                  : Colors.black),
                                          // Light mode, black text
                                          decoration: isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (docData.containsKey('deadline') &&
                                          docData['deadline'] != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.schedule,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                DateFormat(
                                                        'MMM dd, yyyy - hh:mm a')
                                                    .format((docData['deadline']
                                                            as Timestamp)
                                                        .toDate()),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (docData['addedByName'] != null &&
                                          !_isReorderingMode)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Added by ${docData['addedByName']}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          isCompleted
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          color: isCompleted
                                              ? Colors.green[800]
                                              : Colors.grey[400],
                                        ),
                                        onPressed: () => _toggleTaskCompletion(
                                          _selectedListId!,
                                          doc.id,
                                          isCompleted,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Colors.red[300],
                                        ),
                                        onPressed: () => _deleteTask(
                                            _selectedListId!, doc.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          // onReorder: (oldIndex, newIndex) async {
                          //   if (oldIndex < newIndex) {
                          //     newIndex -= 1;
                          //   }
                          //   final docs = snapshot.data!.docs;
                          //   final batch = _firestore.batch();
                          //   final movingDoc = docs[oldIndex];
                          //
                          //   try {
                          //     // Get all documents and their current orders
                          //     final items = docs.asMap().map((index, doc) {
                          //       final data = doc.data() as Map<String, dynamic>;
                          //       return MapEntry(index, data['order'] as num? ?? index.toDouble());
                          //     });
                          //
                          //     // Calculate new order
                          //     double newOrder;
                          //     if (newIndex == 0) {
                          //       // Moving to start
                          //       newOrder = items[0]! - 1.0;
                          //     } else if (newIndex == docs.length - 1) {
                          //       // Moving to end
                          //       newOrder = items[docs.length - 1]! + 1.0;
                          //     } else {
                          //       // Moving between items
                          //       final beforeOrder = items[newIndex]!;
                          //       final afterOrder = items[newIndex + 1]!;
                          //       newOrder = (beforeOrder + afterOrder) / 2;
                          //     }
                          //
                          //     // Update the document
                          //     batch.update(movingDoc.reference, {'order': newOrder});
                          //     await batch.commit();
                          //   } catch (e) {
                          //     print('Error reordering: $e');
                          //     // Show error to user
                          //     ScaffoldMessenger.of(context).showSnackBar(
                          //       SnackBar(content: Text('Error reordering items: $e')),
                          //     );
                          //   }
                          // },
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
                      color: Colors.black.withOpacity(0.05),
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
                      return const Center(child: CircularProgressIndicator());
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
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red[700],
                              elevation: 2,
                              label: const Text('Clear Completed'),
                              icon:
                                  const Icon(Icons.cleaning_services_outlined),
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
      ),);
  }
}
