import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CreateTaskScreen extends StatefulWidget {
  final String listId;

  const CreateTaskScreen({super.key, required this.listId});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDeadline;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  Future<void> _createTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a task title'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.red[800],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      DateTime? deadline;
      if (_selectedDeadline != null && _selectedTime != null) {
        deadline = DateTime(
          _selectedDeadline!.year,
          _selectedDeadline!.month,
          _selectedDeadline!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      }

      await FirebaseFirestore.instance
          .collection('lists')
          .doc(widget.listId)
          .collection('items')
          .add({
        'name': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'completed': false,
        'addedBy': user.uid,
        'addedByName': user.displayName,
        'addedAt': FieldValue.serverTimestamp(),
        'priority': 'low',
        'deadline': deadline,
      });

      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Task'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[900] : Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task Name
                _buildCard(
                  title: 'Task Name *',
                  child: Hero(
                    tag: 'taskName',
                    child: TextField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Enter task name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.green[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.green[800]!, width: 2),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                      ),
                    ),
                  ),
                ),

                // Deadline
                _buildCard(
                  title: 'Deadline',
                  child: ListTile(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: isDark
                                ? ColorScheme.dark(
                                    primary: Colors.green[800]!,
                                    // header background color
                                    onPrimary: Colors.white,
                                    // header text color
                                    onSurface: Colors.white,
                                    // body text color
                                    surface: Colors
                                        .grey[900]!, // calendar background
                                  )
                                : ColorScheme.light(
                                    primary: Colors.green[800]!,
                                    // header background color
                                    onPrimary: Colors.white,
                                    // header text color
                                    onSurface: Colors.black, // body text color
                                  ),
                          ),
                          child: child!,
                        ),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          builder: (context, child) {
                            final isDark =
                                Theme.of(context).brightness == Brightness.dark;
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
                                  dialBackgroundColor: isDark
                                      ? Colors.grey[800]
                                      : Colors.green[50],
                                  hourMinuteTextColor: Colors.green[300],
                                  dayPeriodTextColor: Colors.green[300],
                                  dayPeriodBorderSide: BorderSide.none,
                                  dayPeriodShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  dayPeriodColor:
                                      MaterialStateColor.resolveWith((states) {
                                    if (states
                                        .contains(MaterialState.selected)) {
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
                        if (!mounted) return;
                        setState(() {
                          _selectedDeadline = date;
                          _selectedTime = time;
                        });
                      }
                    },
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading:
                        Icon(Icons.calendar_today, color: Colors.green[800]),
                    title: Text(
                      _selectedDeadline != null
                          ? DateFormat('MMM dd, yyyy')
                              .format(_selectedDeadline!)
                          : 'Select Date',
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87),
                    ),
                    subtitle: _selectedTime != null
                        ? Text(_selectedTime!.format(context))
                        : null,
                    trailing: _selectedDeadline != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() {
                              _selectedDeadline = null;
                              _selectedTime = null;
                            }),
                          )
                        : null,
                  ),
                ),

                // Description
                _buildCard(
                  title: 'Description',
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Add description...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.green[800]!, width: 2),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Create Task',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}