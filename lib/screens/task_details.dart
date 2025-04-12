import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '/widgets/place_selector.dart';
import '/widgets/loading_spinner.dart';

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

class DottedLinePainter extends CustomPainter {
  final Color color;

  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final dotSize = 2.0;
    final spacingSize = 2.0;
    var currentX = 0.0;

    while (currentX < size.width) {
      canvas.drawLine(
        Offset(currentX, 0),
        Offset(currentX + dotSize, 0),
        paint,
      );
      currentX += dotSize + spacingSize;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  DateTime? _selectedDeadline;

  // String? _priority;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
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
    final date = await showDatePicker(
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

    if (date != null) {
      final time = await showTimePicker(
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
            ),
            child: child!,
          );
        },
      );

      if (time != null && mounted) {
        final deadline = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        await _updateTask({'deadline': deadline});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
          title: Text(
            'Task Details',
            style: const TextStyle(
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
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Go Back',
              ),
            ),
          )),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('lists')
            .doc(widget.listId)
            .collection('items')
            .doc(widget.taskId)
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

          final task = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final name = task['name'] ?? 'Untitled Task';
          final description = task['description'] ?? '';
          final addedByName = task['addedByName'] ?? 'Unknown';
          final addedAt = task['addedAt'].toDate();
          final completed = task['completed'] ?? false;
          _descriptionController.text = description;
          _selectedDeadline = task['deadline']?.toDate();
          _nameController.text = name;

          return SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(bottom: 8),
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              _updateTask({'name': value.trim()});
                            }
                          },
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: CustomPaint(
                            painter: DottedLinePainter(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[600]!
                                  : Colors.grey[300]!,
                            ),
                            size: Size(MediaQuery.of(context).size.width, 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildStatusCard(completed),
                    const SizedBox(height: 16),
                    _buildDeadlineCard(),
                    const SizedBox(height: 16),
                    _buildLocationCard(task),
                    const SizedBox(height: 16),
                    _buildDescriptionCard(),
                    const SizedBox(height: 16),
                    _buildAddedByCard(addedByName),
                    const SizedBox(height: 16),
                    _buildAddedAtCard(addedAt),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(bool completed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: completed
                ? [Colors.green[400]!, Colors.green[600]!]
                : isDark
                    ? [Colors.grey[800]!, Colors.grey[700]!]
                    : [Colors.grey[100]!, Colors.grey[200]!],
          ),
        ),
        child: ListTile(
          title: Text(
            'Status',
            style: TextStyle(
              color: completed
                  ? Colors.white
                  : isDark
                      ? Colors.white
                      : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: Switch.adaptive(
            value: completed,
            onChanged: (value) => _updateTask({'completed': value}),
            activeColor: Colors.white,
            activeTrackColor: Colors.green[800],
            inactiveThumbColor: isDark ? Colors.grey[300] : Colors.grey[50],
            inactiveTrackColor: isDark ? Colors.grey[600] : Colors.grey[300],
          ),
        ),
      ),
    );
  }

  Widget _buildDeadlineCard() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: _selectDeadline,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.event, color: Colors.green[800]),
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
                          ? DateFormat('MMM dd, yyyy - hh:mm a')
                              .format(_selectedDeadline!)
                          : 'Set deadline',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (_selectedDeadline != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      _updateTask({'deadline': FieldValue.delete()}),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> task) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on, color: Colors.green[800]),
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
                      task['location'] != null
                          ? '${task['location']['name']}\n${task['location']['address']}'
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
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.description, color: Colors.green[800]),
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
                  borderSide: BorderSide(color: Colors.green[800]!, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green[200]!),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[850]
                    : Colors.grey[50],
              ),
              onChanged: (value) => _updateTask({'description': value}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddedByCard(String addedByName) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.person, color: Colors.green[800]),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Added by',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  addedByName,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddedAtCard(DateTime addedAt) {
    final formattedAddedAt =
        DateFormat('MMM dd, yyyy - hh:mm a').format(addedAt);

    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.schedule, color: Colors.green[800]),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Added at',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedAddedAt,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
