import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '/widgets/place_selector.dart';
import '/widgets/loading_spinner.dart';
import '/services/export_service.dart';
import 'recycle_bin.dart';

class ListOptionsScreen extends StatefulWidget {
  final String listId;
  final String listName;

  const ListOptionsScreen({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<ListOptionsScreen> createState() => _ListOptionsScreenState();
}

class _ListOptionsScreenState extends State<ListOptionsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  void _editListName(String currentName) {
    final TextEditingController nameController =
        TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: const Text(
            'Edit List Name',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: 'Enter list name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[800]!),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  try {
                    await _firestore
                        .collection('lists')
                        .doc(widget.listId)
                        .update({'name': nameController.text.trim()});
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('List name updated')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Failed to update list name')),
                    );
                  }
                }
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

  void _showShareMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareMenuScreen(
          listId: widget.listId,
          listName: widget.listName,
        ),
      ),
    );
  }

  void _showSavedLocations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavedLocationsScreen(listId: widget.listId),
      ),
    );
  }

  void _showSavedTasks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavedTasksScreen(listId: widget.listId),
      ),
    );
  }

  Future<void> _clearCompletedTasks() async {
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

    final QuerySnapshot completedItems = await _firestore
        .collection('lists')
        .doc(widget.listId)
        .collection('items')
        .where('completed', isEqualTo: true)
        .get();

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('lists').doc(widget.listId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CustomLoadingSpinner());
          }

          final listData = snapshot.data!;
          final bool isOwner = listData['createdBy'] == _auth.currentUser?.uid;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // List Management Section
                _buildSectionCard(
                  title: 'List Management',
                  icon: FontAwesomeIcons.listCheck,
                  children: [
                    if (isOwner)
                      _buildOptionTile(
                        icon: FontAwesomeIcons.pen,
                        title: 'Edit List Name',
                        subtitle: 'Change the name of this list',
                        onTap: () => _editListName(listData['name']),
                      ),
                    _buildOptionTile(
                      icon: FontAwesomeIcons.share,
                      title: 'Share List',
                      subtitle: 'Share this list with others',
                      onTap: _showShareMenu,
                    ),
                    _buildOptionTile(
                      icon: FontAwesomeIcons.trashCan,
                      title: 'Clear Completed',
                      subtitle: 'Remove all completed items',
                      onTap: _clearCompletedTasks,
                    ),
                    _buildOptionTile(
                      icon: FontAwesomeIcons.recycle,
                      title: 'Recycle Bin',
                      subtitle: 'View deleted items',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecycleBinScreen(
                            listId: widget.listId,
                          ),
                        ),
                      ),
                    ),
                    if (isOwner)
                      _buildOptionTile(
                        icon: FontAwesomeIcons.trash,
                        title: 'Delete List',
                        subtitle: 'Permanently delete this list',
                        onTap: _deleteList,
                        isDestructive: true,
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Templates Section
                _buildSectionCard(
                  title: 'Templates & Shortcuts',
                  icon: FontAwesomeIcons.bookmark,
                  children: [
                    _buildOptionTile(
                      icon: FontAwesomeIcons.locationDot,
                      title: 'Saved Locations',
                      subtitle: 'Manage your frequently used locations',
                      onTap: _showSavedLocations,
                    ),
                    _buildOptionTile(
                      icon: FontAwesomeIcons.clone,
                      title: 'Saved Tasks',
                      subtitle: 'Create tasks from saved templates',
                      onTap: _showSavedTasks,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Export Section
                _buildSectionCard(
                  title: 'Export & Backup',
                  icon: FontAwesomeIcons.download,
                  children: [
                    _buildOptionTile(
                      icon: FontAwesomeIcons.fileExport,
                      title: 'Export List',
                      subtitle: 'Export list as a CSV',
                      onTap: () async {
                        await ExportService.exportList(
                            widget.listId, widget.listName);
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FaIcon(icon, color: Colors.green[800], size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final iconColor = isDestructive ? Colors.red[700] : Colors.green[800];

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red[50] : Colors.green[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: FaIcon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red[700] : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: FaIcon(
        FontAwesomeIcons.chevronRight,
        size: 14,
        color: Colors.grey[400],
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

// Share Menu Screen
class ShareMenuScreen extends StatefulWidget {
  final String listId;
  final String listName;

  const ShareMenuScreen({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<ShareMenuScreen> createState() => _ShareMenuScreenState();
}

class _ShareMenuScreenState extends State<ShareMenuScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _shareList() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Look up user by email in 'users' collection
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'User not found. They need to sign up for ShopSync first.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final userId = userQuery.docs.first.id;

      // Check if user is already a member
      final listDoc =
          await _firestore.collection('lists').doc(widget.listId).get();
      final listData = listDoc.data() as Map<String, dynamic>;
      final currentMembers = List<String>.from(listData['members'] ?? []);

      if (currentMembers.contains(userId)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User already has access to this list'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Add user to members array
      await _firestore.collection('lists').doc(widget.listId).update({
        'members': FieldValue.arrayUnion([userId]),
      });

      if (!mounted) return;
      _emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('List shared with $email'),
          backgroundColor: Colors.green[800],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share list')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeMember(String userId) async {
    try {
      await _firestore.collection('lists').doc(widget.listId).update({
        'members': FieldValue.arrayRemove([userId]),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User removed'),
          backgroundColor: Colors.green[800],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove user')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Share List',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDark ? Colors.grey[800] : Colors.green[800],
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: FaIcon(
                            FontAwesomeIcons.envelope,
                            color: Colors.green[800],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Add Collaborator',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Enter email address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.green[800]!),
                        ),
                        prefixIcon: const Icon(FontAwesomeIcons.at),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _shareList,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CustomLoadingSpinner(
                                  color: Colors.white,
                                  size: 20,
                                ),
                              )
                            : const Text(
                                'Share List',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            StreamBuilder<DocumentSnapshot>(
              stream:
                  _firestore.collection('lists').doc(widget.listId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final members = List<String>.from(data?['members'] ?? []);
                final ownerId = data?['createdBy'] as String?;

                if (members.isEmpty) return const SizedBox.shrink();

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: FaIcon(
                                FontAwesomeIcons.users,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Current Members',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...members.map((userId) =>
                            FutureBuilder<DocumentSnapshot>(
                              future: _firestore
                                  .collection('users')
                                  .doc(userId)
                                  .get(),
                              builder: (context, userSnapshot) {
                                if (!userSnapshot.hasData) {
                                  return const ListTile(
                                    leading: CircleAvatar(
                                      child: CustomLoadingSpinner(size: 16),
                                    ),
                                    title: Text('Loading...'),
                                  );
                                }

                                final userData = userSnapshot.data!.data()
                                    as Map<String, dynamic>?;
                                final email =
                                    userData?['email'] ?? 'Unknown user';
                                final displayName =
                                    userData?['displayName'] ?? 'User';
                                final isOwner = userId == ownerId;
                                final currentUserId = _auth.currentUser?.uid;

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isOwner
                                        ? Colors.amber[100]
                                        : Colors.green[100],
                                    child: FaIcon(
                                      isOwner
                                          ? FontAwesomeIcons.crown
                                          : FontAwesomeIcons.user,
                                      color: isOwner
                                          ? Colors.amber[800]
                                          : Colors.green[800],
                                      size: 16,
                                    ),
                                  ),
                                  title: Text(
                                    displayName,
                                    style: TextStyle(
                                      fontWeight: isOwner
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(email),
                                      if (isOwner)
                                        Text(
                                          'Owner',
                                          style: TextStyle(
                                            color: Colors.amber[800],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: !isOwner &&
                                          (currentUserId == ownerId ||
                                              currentUserId == userId)
                                      ? IconButton(
                                          icon: FaIcon(
                                            FontAwesomeIcons.trash,
                                            color: Colors.red[700],
                                            size: 16,
                                          ),
                                          onPressed: () async {
                                            final shouldRemove =
                                                await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                        title: const Text(
                                                            'Remove Member'),
                                                        content: Text(
                                                          currentUserId ==
                                                                  userId
                                                              ? 'Are you sure you want to leave this list?'
                                                              : 'Are you sure you want to remove $displayName from this list?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    false),
                                                            child: const Text(
                                                                'Cancel'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    true),
                                                            style: TextButton
                                                                .styleFrom(
                                                              foregroundColor:
                                                                  Colors
                                                                      .red[700],
                                                            ),
                                                            child: Text(
                                                                currentUserId ==
                                                                        userId
                                                                    ? 'Leave'
                                                                    : 'Remove'),
                                                          ),
                                                        ],
                                                      ),
                                                    ) ??
                                                    false;

                                            if (shouldRemove) {
                                              await _removeMember(userId);
                                              // If user removed themselves, go back
                                              if (currentUserId == userId &&
                                                  mounted) {
                                                Navigator.of(context).popUntil(
                                                    (route) => route.isFirst);
                                              }
                                            }
                                          },
                                        )
                                      : null,
                                );
                              },
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Saved Locations Screen
class SavedLocationsScreen extends StatefulWidget {
  final String listId;

  const SavedLocationsScreen({super.key, required this.listId});

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _addLocation() async {
    Map<String, dynamic>? location;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => LocationSelector(
        onLocationSelected: (selectedLocation) {
          location = selectedLocation;
        },
      ),
    );

    if (location != null && location!.isNotEmpty) {
      try {
        await _firestore
            .collection('lists')
            .doc(widget.listId)
            .collection('saved_locations')
            .add({
          ...location!,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': _auth.currentUser!.uid,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location saved successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save location')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Saved Locations',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDark ? Colors.grey[800] : Colors.green[800],
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
            onPressed: _addLocation,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('lists')
            .doc(widget.listId)
            .collection('saved_locations')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingSpinner());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.locationDot,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved locations yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first location',
                    style: TextStyle(
                      color: Colors.grey[500],
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
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.locationDot,
                      color: Colors.green[800],
                    ),
                  ),
                  title: Text(
                    data['name'] ?? 'Unnamed Location',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle:
                      data['address'] != null ? Text(data['address']) : null,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await doc.reference.delete();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Location deleted')),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            FaIcon(FontAwesomeIcons.trash, size: 16),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
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

// Saved Tasks Screen
class SavedTasksScreen extends StatefulWidget {
  final String listId;

  const SavedTasksScreen({super.key, required this.listId});

  @override
  State<SavedTasksScreen> createState() => _SavedTasksScreenState();
}

class _SavedTasksScreenState extends State<SavedTasksScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _addTaskTemplate() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskTemplateScreen(listId: widget.listId),
      ),
    );

    if (result != null) {
      try {
        await _firestore
            .collection('lists')
            .doc(widget.listId)
            .collection('task_templates')
            .add({
          ...result,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': _auth.currentUser!.uid,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task template saved successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save task template')),
        );
      }
    }
  }

  Future<void> _createTaskFromTemplate(Map<String, dynamic> template) async {
    try {
      await _firestore
          .collection('lists')
          .doc(widget.listId)
          .collection('items')
          .add({
        'name': template['name'],
        'description': template['description'] ?? '',
        'completed': false,
        'addedBy': _auth.currentUser!.uid,
        'addedByName': _auth.currentUser!.displayName,
        'addedAt': FieldValue.serverTimestamp(),
        // 'priority': template['priority'] ?? 'low',
        'location': template['location'],
        'counter': template['counter'] ?? 1,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created from template')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create task')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Saved Tasks',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDark ? Colors.grey[800] : Colors.green[800],
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
            onPressed: _addTaskTemplate,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('lists')
            .doc(widget.listId)
            .collection('task_templates')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingSpinner());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.clone,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved tasks yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first task template',
                    style: TextStyle(
                      color: Colors.grey[500],
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
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.clone,
                      color: Colors.blue[800],
                    ),
                  ),
                  title: Text(
                    data['name'] ?? 'Unnamed Task',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['description'] != null &&
                          data['description'].isNotEmpty)
                        Text(data['description']),
                      if (data['location'] != null)
                        Text(
                          'Location: ${data['location']['name'] ?? 'Unknown'}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: FaIcon(
                          FontAwesomeIcons.plus,
                          color: Colors.green[800],
                          size: 16,
                        ),
                        onPressed: () => _createTaskFromTemplate(data),
                        tooltip: 'Create task from template',
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'delete') {
                            await doc.reference.delete();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Template deleted')),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                FaIcon(FontAwesomeIcons.trash, size: 16),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine:
                      data['description'] != null && data['location'] != null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Create Task Template Screen
class CreateTaskTemplateScreen extends StatefulWidget {
  final String listId;

  const CreateTaskTemplateScreen({super.key, required this.listId});

  @override
  State<CreateTaskTemplateScreen> createState() =>
      _CreateTaskTemplateScreenState();
}

class _CreateTaskTemplateScreenState extends State<CreateTaskTemplateScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  Map<String, dynamic>? _location;
  int _counter = 1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Create Task Template',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDark ? Colors.grey[800] : Colors.green[800],
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Task Name
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Template Name',
                    floatingLabelStyle: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                    hintText: 'Enter template name',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: const Icon(FontAwesomeIcons.listCheck,
                        color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Location
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => LocationSelector(
                      initialLocation: _location,
                      onLocationSelected: (location) {
                        setState(() {
                          _location = location.isNotEmpty ? location : null;
                        });
                      },
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.locationDot, color: Colors.green),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Location',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _location != null
                                  ? _location!['name'] ?? 'Unknown location'
                                  : 'Tap to set location',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Counter
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FaIcon(FontAwesomeIcons.hashtag, color: Colors.green),
                        const SizedBox(width: 16),
                        const Text(
                          'Default Counter',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _counter > 1
                              ? () => setState(() => _counter--)
                              : null,
                          icon: const FaIcon(FontAwesomeIcons.minus),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            '$_counter',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _counter < 99
                              ? () => setState(() => _counter++)
                              : null,
                          icon: const FaIcon(FontAwesomeIcons.plus),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Description
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    floatingLabelStyle: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                    hintText: 'Enter template description',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: const Icon(
                      FontAwesomeIcons.penToSquare,
                      color: Colors.green,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green[800]!),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              if (_titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a template name')),
                );
                return;
              }

              Navigator.pop(context, {
                'name': _titleController.text.trim(),
                'description': _descriptionController.text.trim(),
                'location': _location,
                // 'priority': 'low',
                'counter': _counter,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save Template',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
