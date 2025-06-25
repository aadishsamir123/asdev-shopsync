import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ListGroupsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new list group
  static Future<String?> createListGroup(String name) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final docRef = await _firestore.collection('list_groups').add({
        'name': name,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'members': [user.uid],
        'position': await _getNextPosition(),
        'isExpanded': true,
        'listIds': <String>[],
      });

      return docRef.id;
    } catch (error, stackTrace) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'action': 'create_list_group',
          'group_name': name,
        }),
      );
      return null;
    }
  }

  // Update list group name
  static Future<bool> updateListGroupName(String groupId, String name) async {
    try {
      await _firestore.collection('list_groups').doc(groupId).update({
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (error, stackTrace) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'action': 'update_list_group_name',
          'group_id': groupId,
          'group_name': name,
        }),
      );
      return false;
    }
  }

  // Delete a list group
  static Future<bool> deleteListGroup(String groupId) async {
    try {
      // First, get the group to find all lists that need to be ungrouped
      final groupDoc =
          await _firestore.collection('list_groups').doc(groupId).get();

      if (!groupDoc.exists) {
        return true; // Group doesn't exist, consider it successfully deleted
      }

      final data = groupDoc.data() as Map<String, dynamic>;
      final listIds = List<String>.from(data['listIds'] ?? []);

      // Use multiple smaller batches to avoid hitting Firestore batch limits
      // and improve reliability
      final batchSize = 400; // Firestore limit is 500 operations per batch

      for (int i = 0; i < listIds.length; i += batchSize) {
        final batch = _firestore.batch();
        final endIndex =
            (i + batchSize < listIds.length) ? i + batchSize : listIds.length;
        final batchListIds = listIds.sublist(i, endIndex);

        // Remove groupId from each list in this batch
        for (String listId in batchListIds) {
          batch.update(_firestore.collection('lists').doc(listId), {
            'groupId': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
      }

      // Finally, delete the group document
      await _firestore.collection('list_groups').doc(groupId).delete();

      return true;
    } catch (error, stackTrace) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'action': 'delete_list_group',
          'group_id': groupId,
        }),
      );
      return false;
    }
  }

  // Add a list to a group
  static Future<bool> addListToGroup(String listId, String groupId) async {
    try {
      final batch = _firestore.batch();

      // Update the list with groupId
      batch.update(_firestore.collection('lists').doc(listId), {
        'groupId': groupId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add listId to group's listIds array
      batch.update(_firestore.collection('list_groups').doc(groupId), {
        'listIds': FieldValue.arrayUnion([listId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (error, stackTrace) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'action': 'add_list_to_group',
          'list_id': listId,
          'group_id': groupId,
        }),
      );
      return false;
    }
  }

  // Remove a list from a group
  static Future<bool> removeListFromGroup(String listId, String groupId) async {
    try {
      final batch = _firestore.batch();

      // Remove groupId from the list
      batch.update(_firestore.collection('lists').doc(listId), {
        'groupId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove listId from group's listIds array
      batch.update(_firestore.collection('list_groups').doc(groupId), {
        'listIds': FieldValue.arrayRemove([listId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (error, stackTrace) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'action': 'remove_list_from_group',
          'list_id': listId,
          'group_id': groupId,
        }),
      );
      return false;
    }
  }

  // Toggle group expansion state
  static Future<bool> toggleGroupExpansion(
      String groupId, bool isExpanded) async {
    try {
      await _firestore.collection('list_groups').doc(groupId).update({
        'isExpanded': isExpanded,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (error, stackTrace) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'action': 'toggle_group_expansion',
          'group_id': groupId,
          'is_expanded': isExpanded,
        }),
      );
      return false;
    }
  }

  // Reorder list groups
  static Future<bool> reorderListGroups(List<String> groupIds) async {
    try {
      final batch = _firestore.batch();

      for (int i = 0; i < groupIds.length; i++) {
        batch.update(_firestore.collection('list_groups').doc(groupIds[i]), {
          'position': i,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return true;
    } catch (error, stackTrace) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'action': 'reorder_list_groups',
          'group_ids': groupIds,
        }),
      );
      return false;
    }
  }

  // Get next position for new groups
  static Future<int> _getNextPosition() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection('list_groups')
          .where('members', arrayContains: user.uid)
          .orderBy('position', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return 0;

      final data = snapshot.docs.first.data();
      return (data['position'] ?? 0) + 1;
    } catch (e) {
      return 0;
    }
  }

  // Get user's list groups stream
  static Stream<QuerySnapshot> getUserListGroups() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('list_groups')
        .where('members', arrayContains: user.uid)
        .orderBy('position')
        .snapshots();
  }

  // Get ungrouped lists
  static Stream<List<QueryDocumentSnapshot>> getUngroupedLists() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('lists')
        .where('members', arrayContains: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      // Get all existing group IDs
      final groupsSnapshot = await _firestore
          .collection('list_groups')
          .where('members', arrayContains: user.uid)
          .get();

      final existingGroupIds = groupsSnapshot.docs.map((doc) => doc.id).toSet();

      // Filter out lists that belong to existing groups
      final ungroupedDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        final groupId = data['groupId'];

        // Consider ungrouped if:
        // 1. groupId is null
        // 2. groupId doesn't exist as a field
        // 3. groupId references a group that no longer exists
        final isUngrouped =
            groupId == null || !existingGroupIds.contains(groupId);

        return isUngrouped;
      }).toList();

      return ungroupedDocs;
    });
  }

  // Get lists in a specific group
  static Stream<QuerySnapshot> getListsInGroup(String groupId) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('lists')
        .where('members', arrayContains: user.uid)
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Clean up orphaned lists (lists that reference deleted groups)
  static Future<void> cleanupOrphanedLists() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get all user's lists that have a groupId
      final listsSnapshot = await _firestore
          .collection('lists')
          .where('members', arrayContains: user.uid)
          .where('groupId', isNull: false)
          .get();

      if (listsSnapshot.docs.isEmpty) return;

      // Get all existing group IDs
      final groupsSnapshot = await _firestore
          .collection('list_groups')
          .where('members', arrayContains: user.uid)
          .get();

      final existingGroupIds = groupsSnapshot.docs.map((doc) => doc.id).toSet();

      // Find lists with orphaned groupIds
      final orphanedLists = listsSnapshot.docs.where((doc) {
        final data = doc.data();
        final groupId = data['groupId'] as String?;
        return groupId != null && !existingGroupIds.contains(groupId);
      }).toList();

      if (orphanedLists.isEmpty) return;

      // Clean up orphaned lists in batches
      const batchSize = 400;
      for (int i = 0; i < orphanedLists.length; i += batchSize) {
        final batch = _firestore.batch();
        final endIndex = (i + batchSize < orphanedLists.length)
            ? i + batchSize
            : orphanedLists.length;
        final batchLists = orphanedLists.sublist(i, endIndex);

        for (final listDoc in batchLists) {
          batch.update(_firestore.collection('lists').doc(listDoc.id), {
            'groupId': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
      }
    } catch (error, stackTrace) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'action': 'cleanup_orphaned_lists',
        }),
      );
    }
  }
}
