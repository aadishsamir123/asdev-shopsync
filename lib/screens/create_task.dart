import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '/widgets/loading_spinner.dart';
import '/widgets/place_selector.dart';

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
  Map<String, dynamic>? _location;
  bool _isLoading = false;
  int _counter = 1;

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
        'location': _location,
        'counter': _counter,
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
        title: const Text(
          'Create Task',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.green[800],
        elevation: 0,
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
              icon:
                  const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Go Back',
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Name
            _buildCard(
              title: 'Task Name',
              child: Card(
                elevation: 8,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: FaIcon(
                              FontAwesomeIcons.pen,
                              color: Colors.green[800],
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Task Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Enter task name...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.green[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.green[800]!, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.green[200]!),
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[850]
                                  : Colors.grey[50],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Deadline Card
            _buildCard(
              title: 'Deadline',
              child: Card(
                elevation: 8,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: InkWell(
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
                                  onPrimary: Colors.white,
                                  onSurface: Colors.white,
                                  surface: Colors.grey[900]!,
                                )
                              : ColorScheme.light(
                                  primary: Colors.green[800]!,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
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
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: FaIcon(FontAwesomeIcons.calendar,
                              color: Colors.green[800]),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Deadline',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedDeadline != null
                                    ? '${DateFormat('MMM dd, yyyy').format(_selectedDeadline!)} ${_selectedTime?.format(context) ?? ''}'
                                    : 'Set deadline',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedDeadline != null)
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.xmark),
                            onPressed: () => setState(() {
                              _selectedDeadline = null;
                              _selectedTime = null;
                            }),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            _buildCard(
              title: 'Location',
              child: Card(
                elevation: 8,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => LocationSelector(
                        initialLocation: null,
                        onLocationSelected: (location) {
                          if (!mounted) return;
                          if (location.isNotEmpty) {
                            _location = location;
                          }
                          setState(() {});
                        },
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: FaIcon(FontAwesomeIcons.locationDot,
                              color: Colors.green[800]),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Location',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _location != null
                                    ? '${_location!['name']}\n${_location!['address']}'
                                    : 'Set location',
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
            ),

            // Counter Card
            _buildCard(
              title: 'Counter',
              child: Card(
                elevation: 8,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: FaIcon(FontAwesomeIcons.hashtag,
                                color: Colors.green[800]),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Counter',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
                            icon: FaIcon(
                              FontAwesomeIcons.minus,
                              color: _counter > 1
                                  ? Colors.green[800]
                                  : Colors.grey[400],
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: _counter > 1
                                  ? Colors.green[100]
                                  : Colors.grey[200],
                              shape: const CircleBorder(),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[850]
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green[200]!,
                              ),
                            ),
                            child: Text(
                              '$_counter',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            onPressed: _counter < 99
                                ? () => setState(() => _counter++)
                                : null,
                            icon: FaIcon(
                              FontAwesomeIcons.plus,
                              color: _counter < 99
                                  ? Colors.green[800]
                                  : Colors.grey[400],
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: _counter < 99
                                  ? Colors.green[100]
                                  : Colors.grey[200],
                              shape: const CircleBorder(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Description Card
            _buildCard(
              title: 'Description',
              child: Card(
                elevation: 8,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: FaIcon(FontAwesomeIcons.fileLines,
                                color: Colors.green[800]),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 5,
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
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.green[200]!),
                          ),
                          filled: true,
                          fillColor:
                              isDark ? Colors.grey[850] : Colors.grey[50],
                        ),
                      ),
                    ],
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
                    child: CustomLoadingSpinner(
                      color: Colors.green,
                      size: 20.0,
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
      child: child,
    );
  }
}
