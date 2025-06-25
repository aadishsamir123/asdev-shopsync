import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopsync/widgets/loading_spinner.dart';
import '/services/list_groups_service.dart';

class ManageListGroupBottomSheet extends StatefulWidget {
  final String groupId;
  final String groupName;
  final List<String> currentListIds;

  const ManageListGroupBottomSheet({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.currentListIds,
  });

  @override
  State<ManageListGroupBottomSheet> createState() =>
      _ManageListGroupBottomSheetState();
}

class _ManageListGroupBottomSheetState
    extends State<ManageListGroupBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  bool _isUpdating = false;
  bool _isDeleting = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.groupName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateGroupName() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    final success = await ListGroupsService.updateListGroupName(
      widget.groupId,
      _nameController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isUpdating = false;
    });

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group renamed to "${_nameController.text.trim()}"'),
          backgroundColor: Colors.green[800],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update group name. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteGroup() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete "${widget.groupName}"? The lists will not be deleted, just ungrouped.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    final success = await ListGroupsService.deleteListGroup(widget.groupId);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group "${widget.groupName}" deleted'),
          backgroundColor: Colors.green[800],
        ),
      );
    } else {
      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete group. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEditTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Name',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[200] : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            enabled: !_isUpdating,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Enter group name',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.green[600]!,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isUpdating ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor:
                        isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _updateGroupName,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CustomLoadingSpinner(),
                        )
                      : const Text(
                          'Update',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _isDeleting ? null : _deleteGroup,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: Colors.red[600],
              ),
              icon: _isDeleting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CustomLoadingSpinner(),
                    )
                  : const FaIcon(FontAwesomeIcons.trash, size: 16),
              label: Text(
                _isDeleting ? 'Deleting...' : 'Delete Group',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageListsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Lists',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add or remove lists from this group',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Current lists in group
          if (widget.currentListIds.isNotEmpty) ...[
            Text(
              'Lists in Group',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[200] : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('lists')
                    .where('groupId', isEqualTo: widget.groupId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CustomLoadingSpinner());
                  }

                  final lists = snapshot.data!.docs;
                  if (lists.isEmpty) {
                    return Text(
                      'No lists in this group',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: lists.length,
                    itemBuilder: (context, index) {
                      final list = lists[index];
                      final data = list.data() as Map<String, dynamic>;
                      final listName = data['name'] ?? 'Unnamed List';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: FaIcon(
                              FontAwesomeIcons.cartShopping,
                              color: Colors.green[700],
                              size: 16,
                            ),
                          ),
                          title: Text(listName),
                          trailing: IconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.xmark,
                              size: 16,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              final success =
                                  await ListGroupsService.removeListFromGroup(
                                list.id,
                                widget.groupId,
                              );
                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('$listName removed from group'),
                                    backgroundColor: Colors.green[800],
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Available lists to add
          Text(
            'Available Lists',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[200] : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: ListGroupsService.getUngroupedLists(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CustomLoadingSpinner());
                }

                final lists = snapshot.data!;
                if (lists.isEmpty) {
                  return Text(
                    'No ungrouped lists available',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    final list = lists[index];
                    final data = list.data() as Map<String, dynamic>;
                    final listName = data['name'] ?? 'Unnamed List';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: FaIcon(
                            FontAwesomeIcons.cartShopping,
                            color: Colors.blue[700],
                            size: 16,
                          ),
                        ),
                        title: Text(listName),
                        trailing: IconButton(
                          icon: const FaIcon(
                            FontAwesomeIcons.plus,
                            size: 16,
                            color: Colors.green,
                          ),
                          onPressed: () async {
                            final success =
                                await ListGroupsService.addListToGroup(
                              list.id,
                              widget.groupId,
                            );
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$listName added to group'),
                                  backgroundColor: Colors.green[800],
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.green[900] : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.layerGroup,
                    color: isDark ? Colors.green[200] : Colors.green[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Group',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.groupName,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0
                            ? Colors.green[600]
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Edit',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _selectedTab == 0
                              ? Colors.white
                              : (isDark ? Colors.grey[300] : Colors.grey[700]),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1
                            ? Colors.green[600]
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Lists',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _selectedTab == 1
                              ? Colors.white
                              : (isDark ? Colors.grey[300] : Colors.grey[700]),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: SingleChildScrollView(
              child:
                  _selectedTab == 0 ? _buildEditTab() : _buildManageListsTab(),
            ),
          ),
        ],
      ),
    );
  }
}
