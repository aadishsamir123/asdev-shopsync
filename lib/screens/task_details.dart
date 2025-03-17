import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '/widgets/place_selector.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String listId;
  final String taskId;

  const TaskDetailsScreen({
    super.key,
    required this.listId,
    required this.taskId,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  late TextEditingController _descriptionController;
  DateTime? _selectedDeadline;
  String? _priority;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateTask(Map<String, dynamic> data) async {
    await _firestore
        .collection('lists')
        .doc(widget.listId)
        .collection('items')
        .doc(widget.taskId)
        .update(data);
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: Colors.green[800]!, // header background color
                    onPrimary: Colors.white, // header text color
                    onSurface: Colors.white, // body text color
                    surface: Colors.grey[900]!, // calendar background
                  )
                : ColorScheme.light(
                    primary: Colors.green[800]!, // header background color
                    onPrimary: Colors.white, // header text color
                    onSurface: Colors.black, // body text color
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark
                  ? ColorScheme.dark(
                      primary: Colors.green[800]!,
                      onPrimary: Colors.white,
                      onSurface: Colors.white,
                      surface: Colors.grey[900]!,
                    )
                  : ColorScheme.light(
                      primary: Colors.green[800]!,
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
              timePickerTheme: TimePickerThemeData(
                dialBackgroundColor:
                    isDark ? Colors.grey[800] : Colors.green[50],
                hourMinuteTextColor: Colors.green[300],
                dayPeriodTextColor: Colors.green[300],
                dayPeriodBorderSide: BorderSide.none,
                dayPeriodShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                dayPeriodColor: MaterialStateColor.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.green[800]!;
                  }
                  return Colors.transparent;
                }),
              ),
            ),
            child: child!,
          );
        },
      );

      if (timePicked != null) {
        setState(() {
          _selectedDeadline = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
        await _updateTask({'deadline': _selectedDeadline});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('lists')
            .doc(widget.listId)
            .collection('items')
            .doc(widget.taskId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final task = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          // Safely get values with null checks
          final name = task['name'] ?? 'Untitled Task';
          final description = task['description'] ?? '';
          final addedByName = task['addedByName'] ?? 'Unknown';
          final completed = task['completed'] ?? false;
          final priority = task['priority'] ?? 'low';

          // Safely update controllers and state
          _descriptionController.text = description;
          _selectedDeadline = task['deadline']?.toDate();
          _priority = priority;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task Name
                Card(
                  child: ListTile(
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text('Added by $addedByName'),
                  ),
                ),
                const SizedBox(height: 16),

                // Status
                Card(
                  child: SwitchListTile(
                    title: const Text('Completed'),
                    value: completed,
                    onChanged: (value) => _updateTask({'completed': value}),
                    activeColor: Colors.green[800],
                    inactiveThumbColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey[800],
                    inactiveTrackColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[900]
                            : Colors.grey[100],
                    trackOutlineColor:
                        MaterialStateProperty.resolveWith<Color?>(
                      (states) =>
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[200]
                              : Colors.grey[900],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Priority
                // Card(
                //   child: Padding(
                //     padding: const EdgeInsets.all(16),
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         const Text(
                //           'Priority',
                //           style: TextStyle(
                //             fontSize: 16,
                //             fontWeight: FontWeight.bold,
                //           ),
                //         ),
                //         const SizedBox(height: 8),
                //         SegmentedButton<String>(
                //           segments: const [
                //             ButtonSegment(value: 'low', label: Text('Low')),
                //             ButtonSegment(value: 'medium', label: Text('Medium')),
                //             ButtonSegment(value: 'high', label: Text('High')),
                //           ],
                //           selected: {priority},
                //           onSelectionChanged: (Set<String> newSelection) {
                //             _updateTask({'priority': newSelection.first});
                //           },
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 16),

                // Deadline
                Card(
                  child: InkWell(
                    onTap: _selectDeadline,
                    child: ListTile(
                      title: const Text('Deadline'),
                      subtitle: Text(
                        _selectedDeadline != null
                            ? DateFormat('MMM dd, yyyy - hh:mm a')
                                .format(_selectedDeadline!)
                            : 'No deadline set',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedDeadline != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _updateTask(
                                  {'deadline': FieldValue.delete()}),
                            ),
                          const Icon(Icons.edit_calendar),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Store location
                Card(
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => LocationSelector(
                          initialLocation: task['location'],
                          onLocationSelected: (location) {
                            if (location.isEmpty) {
                              _updateTask({'location': FieldValue.delete()});
                            } else {
                              _updateTask({'location': location});
                            }
                          },
                        ),
                      );
                    },
                    child: ListTile(
                      title: const Text('Store Location'),
                      subtitle: Text(
                        task['location'] != null
                            ? '${task['location']['name']}\n${task['location']['address']}'
                            : 'No location set',
                      ),
                      trailing: const Icon(Icons.location_on),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Add description...',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.green[800]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.green[800]!, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.green[200]!),
                            ),
                          ),
                          cursorColor: Colors.green[800],
                          style: TextStyle(color: Colors.green[900]),
                          onChanged: (value) =>
                              _updateTask({'description': value}),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
