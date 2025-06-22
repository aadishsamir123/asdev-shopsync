import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'task_details.dart';
import 'create_task.dart';
import 'list_options.dart';
import '/widgets/loading_spinner.dart';
import '/libraries/icons/food_icons_map.dart';

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

class _ListViewScreenState extends State<ListViewScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final _firestore = FirebaseFirestore.instance;
  late AnimationController _tasksAnimationController;
  late AnimationController _optionsAnimationController;
  late Animation<double> _tasksBounceAnimation;
  late Animation<double> _tasksRotateAnimation;
  late Animation<double> _optionsSpinAnimation;

  @override
  void initState() {
    super.initState();

    // Tasks animation controller for bouncy effect
    _tasksAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _tasksBounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _tasksAnimationController,
      curve: Curves.elasticOut,
    ));
    _tasksRotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1, // Small rotation for playful effect
    ).animate(CurvedAnimation(
      parent: _tasksAnimationController,
      curve: Curves.elasticOut,
    ));

    // Options animation controller for spin effect
    _optionsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _optionsSpinAnimation = Tween<double>(
      begin: 0.0,
      end: 2.5, // 2.5 full rotations for extra playfulness
    ).animate(CurvedAnimation(
      parent: _optionsAnimationController,
      curve: Curves.easeInOutBack, // More playful curve with overshoot
    ));
  }

  @override
  void dispose() {
    _tasksAnimationController.dispose();
    _optionsAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Add haptic feedback
    HapticFeedback.selectionClick();

    // Play different animations based on selected tab
    if (index == 0) {
      // Tasks tab - bouncy animation
      _tasksAnimationController.forward().then((_) {
        _tasksAnimationController.reverse();
      });
    } else if (index == 1) {
      // Options tab - spin animation
      _optionsAnimationController.forward().then((_) {
        _optionsAnimationController.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('lists').doc(widget.listId).snapshots(),
          builder: (context, snapshot) {
            String listName = widget.listName;
            if (snapshot.hasData && snapshot.data != null) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              listName = data?['name'] ?? widget.listName;
            }
            return Text(
              listName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          },
        ),
        backgroundColor: isDark ? Colors.grey[800] : Colors.green[800],
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          TasksTab(listId: widget.listId, listName: widget.listName),
          ListOptionsScreen(listId: widget.listId, listName: widget.listName),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
            indicatorColor: isDark ? Colors.green[800] : Colors.green[600],
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  color: isDark ? Colors.white : Colors.green[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                );
              }
              return TextStyle(
                color: isDark ? Colors.grey[400] : Colors.green[600],
                fontWeight: FontWeight.w500,
                fontSize: 12,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(
                  color: Colors.white,
                  size: 24,
                );
              }
              return IconThemeData(
                color: isDark ? Colors.grey[400] : Colors.green[600],
                size: 20,
              );
            }),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: [
            NavigationDestination(
              icon: AnimatedBuilder(
                animation: _tasksAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale:
                        _selectedIndex == 0 ? _tasksBounceAnimation.value : 1.0,
                    child: Transform.rotate(
                      angle: _selectedIndex == 0
                          ? _tasksRotateAnimation.value * 2 * 3.14159
                          : 0.0,
                      child: const Icon(Icons.checklist_outlined),
                    ),
                  );
                },
              ),
              selectedIcon: AnimatedBuilder(
                animation: _tasksAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale:
                        _selectedIndex == 0 ? _tasksBounceAnimation.value : 1.0,
                    child: Transform.rotate(
                      angle: _selectedIndex == 0
                          ? _tasksRotateAnimation.value * 2 * 3.14159
                          : 0.0,
                      child: const Icon(Icons.checklist),
                    ),
                  );
                },
              ),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: AnimatedBuilder(
                animation: _optionsSpinAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _selectedIndex == 1
                        ? _optionsSpinAnimation.value * 2 * 3.14159
                        : 0.0,
                    child: const Icon(Icons.settings_outlined),
                  );
                },
              ),
              selectedIcon: AnimatedBuilder(
                animation: _optionsSpinAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _selectedIndex == 1
                        ? _optionsSpinAnimation.value * 2 * 3.14159
                        : 0.0,
                    child: const Icon(Icons.settings),
                  );
                },
              ),
              label: 'Options',
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateTaskScreen(listId: widget.listId),
                  ),
                );
              },
              backgroundColor: isDark ? Colors.green[700] : Colors.green[800],
              child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
            )
          : null,
    );
  }
}

class TasksTab extends StatefulWidget {
  final String listId;
  final String listName;

  const TasksTab({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // String _standardizePriority(String? priority) {
  //   switch (priority?.toLowerCase()) {
  //     case 'high':
  //       return 'high';
  //     case 'medium':
  //       return 'medium';
  //     case 'low':
  //       return 'low';
  //     default:
  //       return 'low';
  //   }
  // }

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

  // Widget _buildPriorityBadge(String priority) {
  //   Color color;
  //   IconData icon;

  //   switch (priority.toLowerCase()) {
  //     case 'high':
  //       color = Colors.red;
  //       icon = FontAwesomeIcons.exclamation;
  //       break;
  //     case 'medium':
  //       color = Colors.orange;
  //       icon = FontAwesomeIcons.minus;
  //       break;
  //     case 'low':
  //     default:
  //       color = Colors.green;
  //       icon = FontAwesomeIcons.arrowDown;
  //       break;
  //   }

  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //     decoration: BoxDecoration(
  //       color: color.withValues(alpha: 0.1),
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: color, width: 1),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         FaIcon(icon, size: 10, color: color),
  //         const SizedBox(width: 4),
  //         Text(
  //           priority.toUpperCase(),
  //           style: TextStyle(
  //             color: color,
  //             fontSize: 10,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildTaskCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isCompleted = data['completed'] ?? false;
    // final priority = _standardizePriority(data['priority']);
    final deadline = data['deadline'] as Timestamp?;
    final location = data['location'] as Map<String, dynamic>?;
    final counter = data['counter'] ?? 1;
    final iconIdentifier = data['iconIdentifier'] as String?;
    final taskIcon =
        iconIdentifier != null ? FoodIconMap.getIcon(iconIdentifier) : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isCompleted
                ? (isDark ? Colors.grey[800] : Colors.grey[100])
                : null,
          ),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: () => _toggleTaskCompletion(doc.id, isCompleted),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isCompleted ? Colors.green[700]! : Colors.grey[400]!,
                      width: 2,
                    ),
                    color: isCompleted ? Colors.green[700] : Colors.transparent,
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),

              // Task Icon
              if (taskIcon != null) ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? (isDark ? Colors.grey[700] : Colors.grey[300])
                        : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCompleted
                          ? (isDark ? Colors.grey[600]! : Colors.grey[400]!)
                          : Colors.green[200]!,
                      width: 1,
                    ),
                  ),
                  child: taskIcon.buildIcon(
                    width: 28,
                    height: 28,
                    color: isCompleted
                        ? (isDark ? Colors.grey[400] : Colors.grey[600])
                        : Colors.green[800],
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Task content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['name'] ?? 'Unnamed Task',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted ? Colors.grey[600] : null,
                            ),
                          ),
                        ),
                        if (counter > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'x$counter',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (data['description'] != null &&
                        data['description'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          data['description'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Tags row
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // _buildPriorityBadge(priority),
                        if (deadline != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FaIcon(FontAwesomeIcons.clock,
                                    size: 10, color: Colors.orange[800]),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM dd, HH:mm')
                                      .format(deadline.toDate()),
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (location != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FaIcon(FontAwesomeIcons.locationDot,
                                    size: 10, color: Colors.purple[800]),
                                const SizedBox(width: 4),
                                Text(
                                  location['name'] ?? 'Location',
                                  style: TextStyle(
                                    color: Colors.purple[800],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete button
              IconButton(
                onPressed: () => _deleteTask(doc.id),
                icon: FaIcon(
                  FontAwesomeIcons.trash,
                  size: 16,
                  color: Colors.red[400],
                ),
                tooltip: 'Delete task',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(QuerySnapshot tasksSnapshot) {
    final totalTasks = tasksSnapshot.docs.length;
    final completedTasks = tasksSnapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['completed'] ?? false;
    }).length;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Progress circle
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
              strokeWidth: 6,
            ),
          ),
          const SizedBox(width: 16),

          // Stats text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(progress * 100).round()}% Complete',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '$completedTasks of $totalTasks tasks completed',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('lists')
                .doc(widget.listId)
                .collection('items')
                .orderBy('addedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CustomLoadingSpinner());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.triangleExclamation,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading tasks',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.listCheck,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first task to get started',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final tasks = snapshot.data!.docs;
              final incompleteTasks = tasks.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return !(data['completed'] ?? false);
              }).toList();
              final completedTasks = tasks.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['completed'] ?? false;
              }).toList();

              return ListView(
                children: [
                  _buildStatsCard(snapshot.data!),

                  // Incomplete tasks
                  if (incompleteTasks.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        'Pending Tasks',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    ...incompleteTasks.map((doc) => _buildTaskCard(doc)),
                  ],

                  // Completed tasks
                  if (completedTasks.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        'Completed Tasks',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    ...completedTasks.map((doc) => _buildTaskCard(doc)),
                  ],

                  const SizedBox(height: 80), // Space for FAB
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class TasksScreenWithFAB extends StatelessWidget {
  final String listId;
  final String listName;

  const TasksScreenWithFAB({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TasksTab(listId: listId, listName: listName),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateTaskScreen(listId: listId),
            ),
          );
        },
        backgroundColor: Colors.green[800],
        child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
      ),
    );
  }
}
